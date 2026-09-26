import type { Server, Socket } from 'socket.io';
import { MessageModel } from '../models/Message.js';
import { RoomModel } from '../models/Room.js';
import { isValidAvatarSeed, pickAvatarSeed } from '../config/avatarSeeds.js';
import { cleanupPomodoroSession } from './pomodoroHandler.js';

export interface RoomUser {
  id: string;
  name: string;
  avatarSeed: string;
  socketId: string;
  /** true mientras el socket está caído pero dentro del periodo de gracia. */
  disconnected?: boolean;
}

interface JoinRoomPayload {
  roomId: string;
  user: {
    id: string;
    name: string;
    avatarSeed?: string;
  };
}

interface SetAvatarPayload {
  roomId: string;
  userId: string;
  avatarSeed: string;
}

interface LeaveRoomPayload {
  roomId: string;
  userId: string;
}

interface KickUserPayload {
  roomId: string;
  hostId: string;
  userId: string;
}

const usersByRoom = new Map<string, Map<string, RoomUser>>();
const MAX_USER_NAME_LENGTH = 15;

// Tiempo que se conserva a un usuario (y su sala) tras perder el socket, para
// que pueda volver tras inactividad o recargar la página (F5).
const DISCONNECT_GRACE_MS = 60 * 60 * 1000;
const pendingRemovals = new Map<string, NodeJS.Timeout>();

function removalKey(roomId: string, userId: string): string {
  return `${roomId}:${userId}`;
}

function cancelPendingRemoval(roomId: string, userId: string): void {
  const key = removalKey(roomId, userId);
  const timer = pendingRemovals.get(key);
  if (timer) {
    clearTimeout(timer);
    pendingRemovals.delete(key);
  }
}

function getRoomUsers(roomId: string): RoomUser[] {
  return Array.from(usersByRoom.get(roomId)?.values() ?? []).filter(
    (u) => !u.disconnected,
  );
}

// Seeds ocupadas por OTRA persona: la de uno mismo nunca bloquea elegir la suya.
function takenSeeds(roomId: string, exceptUserId: string): Set<string> {
  return new Set(
    getRoomUsers(roomId)
      .filter((u) => u.id !== exceptUserId)
      .map((u) => u.avatarSeed),
  );
}

function sendUsersUpdate(io: Server, roomId: string): void {
  const users = getRoomUsers(roomId).map(({ id, name, avatarSeed }) => ({
    id,
    name,
    avatarSeed,
  }));
  io.to(roomId).emit('room_users_update', users);
}

export function getRoomUserName(
  roomId: string,
  userId: string,
): string | undefined {
  return usersByRoom.get(roomId)?.get(userId)?.name;
}

function markUserDisconnected(io: Server, socket: Socket): void {
  for (const [roomId, users] of usersByRoom) {
    let changed = false;
    for (const [userId, user] of users) {
      if (user.socketId !== socket.id || user.disconnected) continue;
      user.disconnected = true;
      changed = true;

      cancelPendingRemoval(roomId, userId);
      const timer = setTimeout(() => {
        pendingRemovals.delete(removalKey(roomId, userId));
        const current = usersByRoom.get(roomId)?.get(userId);
        // Si volvió (nuevo socket) ya no está marcado como desconectado.
        if (!current?.disconnected) return;
        usersByRoom.get(roomId)?.delete(userId);
        void handleRoomAfterLeave(io, roomId).catch((error) => {
          console.error('[rooms] Error tras remoción por desconexión:', error);
        });
      }, DISCONNECT_GRACE_MS);
      timer.unref();
      pendingRemovals.set(removalKey(roomId, userId), timer);
    }
    if (changed) {
      sendUsersUpdate(io, roomId);
    }
  }
}

async function handleRoomAfterLeave(io: Server, roomId: string): Promise<void> {
  const users = usersByRoom.get(roomId);
  if (!users || users.size === 0) {
    usersByRoom.delete(roomId);
    await RoomModel.deleteOne({ roomId });
    await MessageModel.deleteMany({ roomId });
    cleanupPomodoroSession(roomId);
    console.log(`[rooms] Sala ${roomId} eliminada por quedar vacía`);
    return;
  }

  // Determinar si el host que acaba de salir era el dueño actual.
  const room = await RoomModel.findOne({ roomId }).lean();
  if (!room) return;

  const hostStillPresent = Array.from(users.values()).some(
    (u) => u.id === room.hostId,
  );
  if (hostStillPresent) {
    sendUsersUpdate(io, roomId);
    return;
  }

  // El dueño se fue y quedan usuarios: transferir el cargo al primero en orden
  // de ingreso (el que "se queda").
  const newHost = Array.from(users.values())[0];
  if (!newHost) {
    sendUsersUpdate(io, roomId);
    return;
  }

  await RoomModel.updateOne({ roomId }, { hostId: newHost.id });
  io.to(roomId).emit('host_transferred', {
    roomId,
    newHostId: newHost.id,
    newHostName: newHost.name,
  });
  sendUsersUpdate(io, roomId);
  console.log(
    `[rooms] Dueño transferido en ${roomId} a ${newHost.name} (${newHost.id})`,
  );
}

export function registerRoomHandler(io: Server, socket: Socket): void {
  socket.on('join_room', async (payload: JoinRoomPayload) => {
    const { roomId, user } = payload;

    if (!roomId || !user?.id || !user?.name) {
      return;
    }
    if (user.name.trim().length > MAX_USER_NAME_LENGTH) {
      return;
    }

    // Validar que la sala siga existiendo: evita "revivir" salas fantasma
    // ya borradas cuando se restaura una sesión vieja.
    let roomExists = true;
    try {
      const room = await RoomModel.findOne({ roomId }).lean();
      roomExists = room !== null;
    } catch (error) {
      console.error('[rooms] Error al validar la sala:', error);
    }

    if (!roomExists) {
      console.log(
        `[rooms] Se intentó unirse a la sala inexistente ${roomId}`,
      );
      socket.emit('room_not_found', { roomId });
      return;
    }

    void socket.join(roomId);

    const roomUsers = usersByRoom.get(roomId) ?? new Map<string, RoomUser>();
    cancelPendingRemoval(roomId, user.id);
    // Prioridad: la que eligió a mano si sigue libre, la que ya tenía (F5,
    // reconexión) y si no una libre al azar entre las que nadie más usa.
    const taken = takenSeeds(roomId, user.id);
    const chosen = isValidAvatarSeed(user.avatarSeed) && !taken.has(user.avatarSeed)
      ? user.avatarSeed
      : undefined;
    const avatarSeed =
      chosen ??
      roomUsers.get(user.id)?.avatarSeed ??
      pickAvatarSeed(taken, user.id);
    roomUsers.set(user.id, {
      id: user.id,
      name: user.name,
      avatarSeed,
      socketId: socket.id,
    });
    usersByRoom.set(roomId, roomUsers);

    console.log(`[rooms] ${user.name} se unió a la sala ${roomId}`);
    sendUsersUpdate(io, roomId);
  });

  socket.on('set_avatar', (payload: SetAvatarPayload) => {
    const { roomId, userId, avatarSeed } = payload ?? {};

    if (!roomId || !userId || !isValidAvatarSeed(avatarSeed)) {
      return;
    }

    const user = usersByRoom.get(roomId)?.get(userId);
    if (!user) {
      return;
    }

    // Alguien más pudo cogerla entre el render del selector y este evento: si
    // está ocupada se re-emite la lista para que el cliente se resincronice.
    if (takenSeeds(roomId, userId).has(avatarSeed)) {
      sendUsersUpdate(io, roomId);
      return;
    }

    if (user.avatarSeed !== avatarSeed) {
      user.avatarSeed = avatarSeed;
    }
    sendUsersUpdate(io, roomId);
  });

  socket.on('leave_room', (payload: LeaveRoomPayload) => {
    const { roomId, userId } = payload;

    if (!roomId || !userId) {
      return;
    }

    void socket.leave(roomId);
    cancelPendingRemoval(roomId, userId);
    usersByRoom.get(roomId)?.delete(userId);

    void handleRoomAfterLeave(io, roomId).catch((error) => {
      console.error('[rooms] Error al procesar salida:', error);
    });
  });

  socket.on('disconnect', () => {
    markUserDisconnected(io, socket);
    console.log('[rooms] Cliente desconectado; se conserva su lugar en la sala');
  });

  socket.on('kick_user', async (payload: KickUserPayload) => {
    const { roomId, hostId, userId } = payload;

    if (!roomId || !hostId || !userId || hostId === userId) {
      return;
    }

    try {
      const room = await RoomModel.findOne({ roomId });
      if (!room || room.hostId !== hostId) {
        return;
      }

      const roomUsers = usersByRoom.get(roomId);
      const targetUser = roomUsers?.get(userId);

      if (!targetUser) {
        return;
      }

      cancelPendingRemoval(roomId, userId);
      roomUsers?.delete(userId);

      io.to(targetUser.socketId).emit('kicked', { roomId });
      io.to(roomId).emit('user_kicked', { userId, userName: targetUser.name });

      void handleRoomAfterLeave(io, roomId).catch((error) => {
        console.error('[rooms] Error tras expulsión:', error);
      });

      console.log(`[rooms] ${targetUser.name} fue expulsado de la sala ${roomId}`);
    } catch (error) {
      console.error('[rooms] Error al expulsar usuario:', error);
    }
  });
}