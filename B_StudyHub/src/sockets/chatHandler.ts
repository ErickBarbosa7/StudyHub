import type { Server, Socket } from 'socket.io';
import { MessageModel } from '../models/Message.js';
import { getRoomUserName } from './roomHandler.js';

interface SendMessagePayload {
  roomId: string;
  senderId: string;
  text: string;
}

interface JoinRoomPayload {
  roomId?: string;
}

export interface ChatMessage {
  id: string;
  roomId: string;
  senderId: string;
  senderName: string;
  text: string;
  timestamp: string;
}

const HISTORY_LIMIT = 100;

async function sendHistory(socket: Socket, roomId: string) {
  const messages = await MessageModel.find({ roomId })
    .sort({ timestamp: 1 })
    .limit(HISTORY_LIMIT)
    .lean();
  socket.emit(
    'chat_history',
    messages.map((message) => mapToChatMessage(message)),
  );
}

function mapToChatMessage(
  message: {
    _id: unknown;
    roomId: string;
    senderId: string;
    senderName: string;
    text: string;
    timestamp: Date;
  },
): ChatMessage {
  return {
    id: String(message._id),
    roomId: message.roomId,
    senderId: message.senderId,
    senderName: message.senderName,
    text: message.text,
    timestamp: message.timestamp.toISOString(),
  };
}

export function registerChatHandler(io: Server, socket: Socket): void {
  socket.on('send_message', async (payload: SendMessagePayload) => {
    const { roomId, senderId, text } = payload;

    if (
      !roomId ||
      !senderId ||
      typeof text !== 'string' ||
      text.trim() === ''
    ) {
      return;
    }

    const senderName = getRoomUserName(roomId, senderId) ?? senderId;

    try {
      const message = await MessageModel.create({
        roomId,
        senderId,
        senderName,
        text: text.trim(),
        timestamp: new Date(),
      });
      io.to(roomId).emit('new_message', mapToChatMessage(message));
    } catch (error) {
      console.error('[chat] Error al guardar el mensaje:', error);
    }
  });

  socket.on('join_room', (payload: JoinRoomPayload) => {
    const { roomId } = payload;
    if (!roomId) return;
    void sendHistory(socket, roomId).catch((error) => {
      console.error('[chat] Error al cargar historial:', error);
    });
  });

  socket.on('get_chat_history', (payload: JoinRoomPayload) => {
    const { roomId } = payload;
    if (!roomId) return;
    void sendHistory(socket, roomId).catch((error) => {
      console.error('[chat] Error al cargar historial:', error);
    });
  });
}