import type { Request, Response } from 'express';
import { generateRoomCode, RoomModel, type Room } from '../models/Room.js';

const MAX_CODE_ATTEMPTS = 5;

async function findUniqueRoomCode(): Promise<string> {
  for (let attempt = 0; attempt < MAX_CODE_ATTEMPTS; attempt += 1) {
    const code = generateRoomCode();
    const exists = await RoomModel.exists({ roomId: code });
    if (!exists) {
      return code;
    }
  }
  throw new Error('No se pudo generar un código único de sala');
}

export async function createRoom(
  req: Request,
  res: Response,
): Promise<void> {
  const { name, hostId } = req.body as { name?: unknown; hostId?: unknown };

  if (typeof name !== 'string' || name.trim() === '') {
    res.status(400).json({ error: 'El nombre de la sala es obligatorio' });
    return;
  }
  if (typeof hostId !== 'string' || hostId.trim() === '') {
    res.status(400).json({ error: 'El hostId es obligatorio' });
    return;
  }

  const room: Room = await RoomModel.create({
    roomId: await findUniqueRoomCode(),
    name: name.trim(),
    hostId: hostId.trim(),
  });

  res.status(201).json({
    roomId: room.roomId,
    name: room.name,
    hostId: room.hostId,
  });
}

export async function getRoomByCode(
  req: Request,
  res: Response,
): Promise<void> {
  const { roomId } = req.params;

  if (typeof roomId !== 'string' || roomId.trim() === '') {
    res.status(400).json({ error: 'El código de la sala es obligatorio' });
    return;
  }

  const room = await RoomModel.findOne({ roomId: roomId.trim() });

  if (!room) {
    res.status(404).json({ error: 'No se encontró la sala' });
    return;
  }

  res.status(200).json({
    roomId: room.roomId,
    name: room.name,
    hostId: room.hostId,
  });
}