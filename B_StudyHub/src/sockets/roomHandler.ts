import type { Server, Socket } from 'socket.io';
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
      if (users.size === 0) {
        usersByRoom.delete(roomId);
      }
      sendUsersUpdate(io, roomId);
    }
  }
}

export function registerRoomHandler(io: Server, socket: Socket): void {
  socket.on('join_room', (payload: JoinRoomPayload) => {
    const { roomId, user } = payload;

    if (!roomId || !user?.id || !user?.name) {
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
    if (usersByRoom.get(roomId)?.size === 0) {
      usersByRoom.delete(roomId);
    }

    console.log(`[rooms] ${userId} abandonó la sala ${roomId}`);
    sendUsersUpdate(io, roomId);
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
      if (roomUsers?.size === 0) {
        usersByRoom.delete(roomId);
      }

      io.to(targetUser.socketId).emit('kicked', { roomId });
      io.to(roomId).emit('user_kicked', { userId, userName: targetUser.name });
      sendUsersUpdate(io, roomId);

      console.log(`[rooms] ${targetUser.name} fue expulsado de la sala ${roomId}`);
    } catch (error) {
      console.error('[rooms] Error al expulsar usuario:', error);
    }
  });
}