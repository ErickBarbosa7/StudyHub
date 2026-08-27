import type { Server, Socket } from 'socket.io';
import { MessageModel } from '../models/Message.js';
import { RoomModel } from '../models/Room.js';

export interface RoomUser {
  id: string;
  name: string;
  socketId: string;
}

interface JoinRoomPayload {
  roomId: string;
  user: {
    id: string;
    name: string;
  };
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

function getRoomUsers(roomId: string): RoomUser[] {
  return Array.from(usersByRoom.get(roomId)?.values() ?? []);
}

function sendUsersUpdate(io: Server, roomId: string): void {
  const users = getRoomUsers(roomId).map(({ id, name }) => ({ id, name }));
  io.to(roomId).emit('room_users_update', users);
}

export function getRoomUserName(
  roomId: string,
  userId: string,
): string | undefined {
  return usersByRoom.get(roomId)?.get(userId)?.name;
}

function removeUserFromAllRooms(io: Server, socket: Socket): void {
  for (const [roomId, users] of usersByRoom) {
    let changed = false;
    for (const [userId, user] of users) {
      if (user.socketId === socket.id) {
        users.delete(userId);
        changed = true;
      }
    }
    if (changed) {
      void handleRoomAfterLeave(io, roomId).catch((error) => {
        console.error('[rooms] Error tras remoción por desconexión:', error);
      });
    }
  }
}

async function handleRoomAfterLeave(io: Server, roomId: string): Promise<void> {
  const users = usersByRoom.get(roomId);
  if (!users || users.size === 0) {
    usersByRoom.delete(roomId);
    await RoomModel.deleteOne({ roomId });
    await MessageModel.deleteMany({ roomId });
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
  socket.on('join_room', (payload: JoinRoomPayload) => {
    const { roomId, user } = payload;

    if (!roomId || !user?.id || !user?.name) {
      return;
    }
    if (user.name.trim().length > MAX_USER_NAME_LENGTH) {
      return;
    }

    void socket.join(roomId);

    const roomUsers = usersByRoom.get(roomId) ?? new Map<string, RoomUser>();
    roomUsers.set(user.id, { ...user, socketId: socket.id });
    usersByRoom.set(roomId, roomUsers);

    console.log(`[rooms] ${user.name} se unió a la sala ${roomId}`);
    sendUsersUpdate(io, roomId);
  });

  socket.on('leave_room', (payload: LeaveRoomPayload) => {
    const { roomId, userId } = payload;

    if (!roomId || !userId) {
      return;
    }

    void socket.leave(roomId);
    usersByRoom.get(roomId)?.delete(userId);

    void handleRoomAfterLeave(io, roomId).catch((error) => {
      console.error('[rooms] Error al procesar salida:', error);
    });
  });

  socket.on('disconnect', () => {
    removeUserFromAllRooms(io, socket);
    console.log('[rooms] Cliente desconectado y removido de sus salas');
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