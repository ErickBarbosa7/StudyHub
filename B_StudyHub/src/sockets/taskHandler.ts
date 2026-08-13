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
}

interface UpdateTaskStatusPayload {
  roomId: string;
  taskId: string;
  newStateRef: CatalogTaskStateCode;
}

const STATE_ORDER = ['PENDING', 'IN_PROGRESS', 'COMPLETED'] as const;

async function getRoomTasks(roomId: string): Promise<Array<TaskSubDoc & {
  stateCode: string;
  stateLabel: string;
}> | null> {
  const room = await RoomModel.findOne({ roomId }).lean();
  if (!room) return null;

  const tasks = room.tasks ?? [];
  const stateRefs = tasks.map((task) => task.stateRef);
  const states = await CatalogTaskStateModel.find({
    _id: { $in: stateRefs },
  }).lean();
  const stateByRef = new Map(
    states.map((state) => [state._id.toString(), state]),
  );

  return tasks.map((task) => {
    const state = stateByRef.get(task.stateRef.toString());
    return {
      ...task,
      stateCode: state?.code ?? 'PENDING',
      stateLabel: state?.label ?? 'Pendiente',
    };
  });
}

async function sendTaskSync(io: Server, roomId: string): Promise<void> {
  const tasks = await getRoomTasks(roomId);
  if (tasks !== null) {
    io.to(roomId).emit('task_sync', tasks);
  }
}

export function registerTaskHandler(io: Server, socket: Socket): void {
  socket.on('add_task', async (payload: AddTaskPayload) => {
    const { roomId, title } = payload;

    if (!roomId || typeof title !== 'string' || title.trim() === '') {
      return;
    }

    const pending = await CatalogTaskStateModel.findOne({ code: 'PENDING' });
    if (!pending) return;

    const room = await RoomModel.findOne({ roomId });
    if (!room) return;

    room.tasks.push({
      taskId: crypto.randomUUID(),
      title: title.trim(),
      stateRef: pending._id,
      createdAt: new Date(),
    });
    await room.save();

    console.log(`[tasks] Tarea agregada en ${roomId}`);
    await sendTaskSync(io, roomId);
  });

  socket.on('update_task_status', async (payload: UpdateTaskStatusPayload) => {
    const { roomId, taskId, newStateRef } = payload;

    if (!roomId || !taskId || !STATE_ORDER.includes(newStateRef)) {
      return;
    }

    const target = await CatalogTaskStateModel.findOne({ code: newStateRef });
    if (!target) return;

    const room = await RoomModel.findOne({ roomId });
    if (!room) return;

    const task = room.tasks.find((item) => item.taskId === taskId);
    if (!task) return;

    task.stateRef = target._id;
    await room.save();

    console.log(`[tasks] Estado actualizado en ${roomId}`);
    await sendTaskSync(io, roomId);
  });

  socket.on('join_room', async (payload: { roomId?: string }) => {
    const { roomId } = payload;
    if (!roomId) return;
    const tasks = await getRoomTasks(roomId);
    if (tasks !== null) {
      socket.emit('task_sync', tasks);
    }
  });
}