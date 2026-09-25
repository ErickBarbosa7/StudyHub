import crypto from 'node:crypto';
import type { Server, Socket } from 'socket.io';
import {
  CatalogTaskStateModel,
  type CatalogTaskStateCode,
} from '../models/CatalogTaskState.js';
import { RoomModel, type TaskSubDoc } from '../models/Room.js';

interface AddTaskPayload {
  roomId: string;
  title: string;
  creatorName?: string;
}

interface UpdateTaskStatusPayload {
  roomId: string;
  taskId: string;
  newStateRef: CatalogTaskStateCode;
}

interface DeleteTaskPayload {
  roomId: string;
  taskId: string;
}

interface EditTaskPayload {
  roomId: string;
  taskId: string;
  title: string;
}

const STATE_ORDER = ['PENDING', 'IN_PROGRESS', 'COMPLETED'] as const;
const MAX_TASK_TITLE_LENGTH = 100;

type CatalogEntry = { _id: { toString(): string }; code: string; label: string };

interface Catalog {
  byCode: Map<string, CatalogEntry>;
  byId: Map<string, CatalogEntry>;
}

// El catálogo de estados son 3 filas fijas (se siembran al arrancar): se lee
// una sola vez y se reutiliza, en lugar de consultarlo en cada acción.
let catalogPromise: Promise<Catalog> | null = null;

function getCatalog(): Promise<Catalog> {
  catalogPromise ??= CatalogTaskStateModel.find()
    .lean()
    .then((states) => ({
      byCode: new Map(states.map((s) => [s.code, s])),
      byId: new Map(states.map((s) => [s._id.toString(), s])),
    }))
    .catch((error) => {
      catalogPromise = null; // reintenta en la próxima llamada
      throw error;
    });
  return catalogPromise;
}

type TaskPayload = TaskSubDoc & { stateCode: string; stateLabel: string };

async function toTaskPayload(tasks: TaskSubDoc[]): Promise<TaskPayload[]> {
  const { byId } = await getCatalog();
  return tasks.map((task) => {
    const state = byId.get(task.stateRef.toString());
    return {
      ...task,
      stateCode: state?.code ?? 'PENDING',
      stateLabel: state?.label ?? 'Pendiente',
    };
  });
}

async function getRoomTasks(roomId: string): Promise<TaskPayload[] | null> {
  const room = await RoomModel.findOne({ roomId }, { tasks: 1 }).lean();
  if (!room) return null;
  return toTaskPayload(room.tasks ?? []);
}

// Tras guardar se reutiliza la sala ya cargada: evita releerla de la base.
async function sendTaskSync(
  io: Server,
  roomId: string,
  tasks: TaskSubDoc[],
): Promise<void> {
  io.to(roomId).emit('task_sync', await toTaskPayload(tasks));
}

export function registerTaskHandler(io: Server, socket: Socket): void {
  socket.on('add_task', async (payload: AddTaskPayload) => {
    try {
      const { roomId, title } = payload;

      if (
        !roomId ||
        typeof title !== 'string' ||
        title.trim() === '' ||
        title.trim().length > MAX_TASK_TITLE_LENGTH
      ) {
        return;
      }

      const pending = (await getCatalog()).byCode.get('PENDING');
      if (!pending) return;

      const room = await RoomModel.findOne({ roomId });
      if (!room) return;

      room.tasks.push({
        taskId: crypto.randomUUID(),
        title: title.trim(),
        stateRef: pending._id,
        createdAt: new Date(),
        creatorName:
          typeof payload.creatorName === 'string' && payload.creatorName.trim() !== ''
            ? payload.creatorName.trim()
            : undefined,
      });
      await room.save();

      console.log(`[tasks] Tarea agregada en ${roomId}`);
      await sendTaskSync(io, roomId, room.toObject().tasks);
    } catch (error) {
      console.error('[tasks] Error in add_task:', error);
    }
  });

  socket.on('update_task_status', async (payload: UpdateTaskStatusPayload) => {
    try {
      const { roomId, taskId, newStateRef } = payload;

      if (!roomId || !taskId || !STATE_ORDER.includes(newStateRef)) {
        return;
      }

      const target = (await getCatalog()).byCode.get(newStateRef);
      if (!target) return;

      const room = await RoomModel.findOne({ roomId });
      if (!room) return;

      const task = room.tasks.find((item) => item.taskId === taskId);
      if (!task) return;

      task.stateRef = target._id as typeof task.stateRef;
      await room.save();

      console.log(`[tasks] Estado actualizado en ${roomId}`);
      await sendTaskSync(io, roomId, room.toObject().tasks);
    } catch (error) {
      console.error('[tasks] Error in update_task_status:', error);
    }
  });

  socket.on('delete_task', async (payload: DeleteTaskPayload) => {
    try {
      const { roomId, taskId } = payload;

      if (!roomId || !taskId) {
        return;
      }

      const room = await RoomModel.findOne({ roomId });
      if (!room) return;

      const target = room.tasks.find((item) => item.taskId === taskId);
      if (!target) return;

      room.tasks.pull({ taskId });
      await room.save();

      console.log(`[tasks] Tarea eliminada en ${roomId}`);
      await sendTaskSync(io, roomId, room.toObject().tasks);
    } catch (error) {
      console.error('[tasks] Error in delete_task:', error);
    }
  });

  socket.on('edit_task', async (payload: EditTaskPayload) => {
    try {
      const { roomId, taskId, title } = payload;

      if (
        !roomId ||
        !taskId ||
        typeof title !== 'string' ||
        title.trim() === '' ||
        title.trim().length > MAX_TASK_TITLE_LENGTH
      ) {
        return;
      }

      const room = await RoomModel.findOne({ roomId });
      if (!room) return;

      const task = room.tasks.find((item) => item.taskId === taskId);
      if (!task) return;

      task.title = title.trim();
      await room.save();

      console.log(`[tasks] Tarea editada en ${roomId}`);
      await sendTaskSync(io, roomId, room.toObject().tasks);
    } catch (error) {
      console.error('[tasks] Error in edit_task:', error);
    }
  });

  socket.on('join_room', async (payload: { roomId?: string }) => {
    try {
      const { roomId } = payload;
      if (!roomId) return;
      const tasks = await getRoomTasks(roomId);
      if (tasks !== null) {
        socket.emit('task_sync', tasks);
      }
    } catch (error) {
      console.error('[tasks] Error in join_room:', error);
    }
  });
}
