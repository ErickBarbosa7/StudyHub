import { isValidObjectId } from 'mongoose';
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

interface ToggleReactionPayload {
  roomId: string;
  messageId: string;
  userId: string;
  emoji: string;
}

interface TypingPayload {
  roomId: string;
  userId: string;
  isTyping: boolean;
}

export interface ChatReaction {
  emoji: string;
  userIds: string[];
}

export interface ChatMessage {
  id: string;
  roomId: string;
  senderId: string;
  senderName: string;
  text: string;
  timestamp: string;
  reactions: ChatReaction[];
}

export const ALLOWED_REACTIONS: readonly string[] = ['🚀', '🔥', '🍅'];

const HISTORY_LIMIT = 100;
const MAX_MESSAGE_LENGTH = 1000;

async function sendHistory(socket: Socket, roomId: string) {
  // Los HISTORY_LIMIT más recientes (antes se devolvían los más antiguos), y se
  // invierten para entregarlos en orden cronológico.
  const messages = await MessageModel.find({ roomId })
    .sort({ timestamp: -1 })
    .limit(HISTORY_LIMIT)
    .lean();
  socket.emit(
    'chat_history',
    messages.reverse().map((message) => mapToChatMessage(message)),
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
    reactions?: { emoji: string; userIds: string[] }[];
  },
): ChatMessage {
  return {
    id: String(message._id),
    roomId: message.roomId,
    senderId: message.senderId,
    senderName: message.senderName,
    text: message.text,
    timestamp: message.timestamp.toISOString(),
    reactions: mapReactions(message.reactions),
  };
}

function mapReactions(
  reactions: { emoji: string; userIds: string[] }[] | undefined,
): ChatReaction[] {
  return (reactions ?? []).map((reaction) => ({
    emoji: reaction.emoji,
    userIds: [...reaction.userIds],
  }));
}

// Borra del mensaje los emojis que se quedaron sin nadie. Sin ellos, el cliente
// recibiría entradas con la lista de usuarios vacía.
async function purgeEmptyReactions(base: {
  _id: string;
  roomId: string;
}): Promise<void> {
  await MessageModel.updateOne(base, {
    $pull: { reactions: { userIds: { $size: 0 } } },
  });
}

// Alterna la reacción de un usuario con operaciones atómicas de Mongo (dos
// personas distintas pulsando a la vez no se pisan). Un usuario solo puede
// tener UN emoji por mensaje: al elegir otro, el anterior se sustituye.
// Devuelve null si el mensaje no existe en esa sala.
async function toggleReaction(
  roomId: string,
  messageId: string,
  userId: string,
  emoji: string,
): Promise<ChatReaction[] | null> {
  const base = { _id: messageId, roomId };

  // 1. Si ya tenía ESTE emoji, se quita y ya está.
  const removed = await MessageModel.updateOne(
    { ...base, reactions: { $elemMatch: { emoji, userIds: userId } } },
    { $pull: { 'reactions.$.userIds': userId } },
  );

  if (removed.modifiedCount > 0) {
    await purgeEmptyReactions(base);
  } else {
    // 2. Antes de añadir, se le saca de los OTROS emojis del mensaje: por eso
    //    elegir uno nuevo mueve el anterior en lugar de acumularlos. El '$'
    //    posicional de $pull solo toca el primer elemento, así que se repite
    //    hasta que no queden (nunca hay más entradas que emojis permitidos).
    for (let i = 0; i < ALLOWED_REACTIONS.length; i++) {
      const cleared = await MessageModel.updateOne(
        {
          ...base,
          reactions: {
            $elemMatch: { emoji: { $ne: emoji }, userIds: userId },
          },
        },
        { $pull: { 'reactions.$.userIds': userId } },
      );
      if (cleared.modifiedCount === 0) break;
    }
    await purgeEmptyReactions(base);

    // 3. Se añade al emoji destino, reutilizando su entrada si ya existe.
    const added = await MessageModel.updateOne(
      { ...base, 'reactions.emoji': emoji },
      { $addToSet: { 'reactions.$.userIds': userId } },
    );
    if (added.matchedCount === 0) {
      await MessageModel.updateOne(
        { ...base, 'reactions.emoji': { $ne: emoji } },
        { $push: { reactions: { emoji, userIds: [userId] } } },
      );
    }
  }

  const message = await MessageModel.findOne(base, { reactions: 1 }).lean();
  return message ? mapReactions(message.reactions) : null;
}

export function registerChatHandler(io: Server, socket: Socket): void {
  socket.on('send_message', async (payload: SendMessagePayload) => {
    const { roomId, senderId, text } = payload;

    if (
      !roomId ||
      !senderId ||
      typeof text !== 'string' ||
      text.trim() === '' ||
      text.trim().length > MAX_MESSAGE_LENGTH
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

  socket.on('toggle_reaction', async (payload: ToggleReactionPayload) => {
    const { roomId, messageId, userId, emoji } = payload ?? {};

    if (
      !roomId ||
      !messageId ||
      !userId ||
      !isValidObjectId(messageId) ||
      !ALLOWED_REACTIONS.includes(emoji) ||
      getRoomUserName(roomId, userId) === undefined
    ) {
      return;
    }

    try {
      const reactions = await toggleReaction(roomId, messageId, userId, emoji);
      if (!reactions) return;
      io.to(roomId).emit('message_reactions', {
        roomId,
        messageId,
        reactions,
      });
    } catch (error) {
      console.error('[chat] Error al reaccionar al mensaje:', error);
    }
  });

  // Efímero: no se guarda. Va a todos menos a quien escribe.
  socket.on('typing', (payload: TypingPayload) => {
    const { roomId, userId, isTyping } = payload ?? {};
    if (!roomId || !userId || typeof isTyping !== 'boolean') return;

    const userName = getRoomUserName(roomId, userId);
    if (userName === undefined) return;

    socket.to(roomId).emit('user_typing', {
      roomId,
      userId,
      userName,
      isTyping,
    });
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