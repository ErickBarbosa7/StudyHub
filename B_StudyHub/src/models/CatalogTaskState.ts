import { model, Schema, type InferSchemaType } from 'mongoose';

export const CATALOG_TASK_STATES = {
  PENDING: 'PENDING',
  IN_PROGRESS: 'IN_PROGRESS',
  COMPLETED: 'COMPLETED',
} as const;

export type CatalogTaskStateCode =
  (typeof CATALOG_TASK_STATES)[keyof typeof CATALOG_TASK_STATES];

export const CatalogTaskStateSchema = new Schema(
  {
    code: {
      type: String,
      required: true,
      unique: true,
      enum: Object.values(CATALOG_TASK_STATES),
    },
    label: { type: String, required: true },
  },
  {
    timestamps: true,
    collection: 'Catalog_TaskStates',
  },
);

export type CatalogTaskState = InferSchemaType<typeof CatalogTaskStateSchema>;

export const CatalogTaskStateModel = model(
  'CatalogTaskState',
  CatalogTaskStateSchema,
);

export async function seedCatalogTaskStates(): Promise<void> {
  const seedData: Array<{ code: CatalogTaskStateCode; label: string }> = [
    { code: 'PENDING', label: 'Pendiente' },
    { code: 'IN_PROGRESS', label: 'En progreso' },
    { code: 'COMPLETED', label: 'Completada' },
  ];

  for (const item of seedData) {
    await CatalogTaskStateModel.updateOne(
      { code: item.code },
      { $setOnInsert: item },
      { upsert: true },
    );
  }

  console.log('[database] Catálogo de estados de tareas sincronizado');
}