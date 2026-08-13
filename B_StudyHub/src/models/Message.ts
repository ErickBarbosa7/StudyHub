import { model, Schema, type InferSchemaType } from 'mongoose';

export const MessageSchema = new Schema(
  {
    roomId: { type: String, required: true, index: true },
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

export type Message = InferSchemaType<typeof MessageSchema> & {
  _id: unknown;
};

export const MessageModel = model('Message', MessageSchema);