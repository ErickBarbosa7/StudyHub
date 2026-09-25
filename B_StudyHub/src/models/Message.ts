import { model, Schema, type InferSchemaType } from 'mongoose';

export const MessageSchema = new Schema(
  {
    roomId: { type: String, required: true },
    senderId: { type: String, required: true },
    senderName: { type: String, required: true },
    text: { type: String, required: true },
    timestamp: { type: Date, required: true, default: Date.now },
  },
  {
    timestamps: true,
    collection: 'Messages',
    versionKey: false,
  },
);

// El historial se pide por sala y ordenado por fecha: este índice compuesto
// evita ordenar en memoria (el índice simple de roomId no cubre el orden).
MessageSchema.index({ roomId: 1, timestamp: -1 });

export type Message = InferSchemaType<typeof MessageSchema> & {
  _id: unknown;
};

export const MessageModel = model('Message', MessageSchema);