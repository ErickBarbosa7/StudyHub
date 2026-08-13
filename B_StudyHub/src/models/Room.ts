import crypto from 'node:crypto';
import { model, Schema, type InferSchemaType } from 'mongoose';

export const TaskSubSchema = new Schema(
  {
    taskId: { type: String, required: true, unique: true },
    title: { type: String, required: true },
    stateRef: {
      type: Schema.Types.ObjectId,
      ref: 'CatalogTaskState',
      required: true,
    },
    createdAt: { type: Date, required: true, default: Date.now },
  },
  { _id: false },
);

export type TaskSubDoc = InferSchemaType<typeof TaskSubSchema>;

export const RoomSchema = new Schema(
  {
    roomId: { type: String, required: true, unique: true },
    name: { type: String, required: true },
    hostId: { type: String, required: true },
    tasks: { type: [TaskSubSchema], default: [] },
  },
  {
    timestamps: true,
    collection: 'Rooms',
  },
);

export const ROOM_CODE_LENGTH = 6;

const ROOM_CODE_ALPHABET =
  'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

export function generateRoomCode(length = ROOM_CODE_LENGTH): string {
  const bytes = crypto.randomBytes(length);
  let code = '';
  for (let i = 0; i < length; i += 1) {
    code += ROOM_CODE_ALPHABET[bytes[i]! % ROOM_CODE_ALPHABET.length];
  }
  return code;
}

export type Room = InferSchemaType<typeof RoomSchema>;

export const RoomModel = model('Room', RoomSchema);