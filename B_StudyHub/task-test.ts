import { io } from 'socket.io-client';
import mongoose from 'mongoose';
import { RoomModel } from './src/models/Room.js';

const roomId = process.argv[2] ?? 'JJ2UXU';
const serverUrl = 'http://localhost:4000';

type Task = { taskId: string; title: string; stateCode: string };

const socket = io(serverUrl, { transports: ['websocket'] });

let step = 0;
let addedTaskId: string | null = null;
const NEW_TITLE = 'Estudiar capítulo 3 (editada)';

function fail(message: string): never {
  console.error(`[client] FALLO: ${message}`);
  process.exit(1);
}

function done(): never {
  console.log('[client] prueba completada: add + status + edit + delete OK');
  process.exit(0);
}

socket.on('connect', () => {
  console.log('[client] conectado:', socket.id);
  socket.emit('join_room', {
    roomId,
    user: { id: 'user_e2e', name: 'Tester' },
  });
});

socket.on('room_not_found', () => {
  fail(`la sala ${roomId} no existe en la base; créala antes de correr el test`);
});

socket.on('task_sync', (tasks: Task[]) => {
  console.log(`[client] task_sync (${step}):`, JSON.stringify(tasks));
  step += 1;

  if (step === 1) {
    socket.emit('add_task', { roomId, title: 'Estudiar capítulo 3' });
    return;
  }

  if (step === 2) {
    addedTaskId = tasks[0]?.taskId ?? null;
    if (!addedTaskId) fail('add_task no creó la tarea');
    socket.emit('update_task_status', {
      roomId,
      taskId: addedTaskId,
      newStateRef: 'IN_PROGRESS',
    });
    return;
  }

  if (step === 3) {
    const task = tasks.find((t) => t.taskId === addedTaskId);
    if (!task) fail('update_task_status quitó la tarea de la lista');
    if (task.stateCode !== 'IN_PROGRESS') {
      fail(`estado esperado IN_PROGRESS, recibido ${task.stateCode}`);
    }
    console.log('[client] editando título ->', NEW_TITLE);
    socket.emit('edit_task', { roomId, taskId: addedTaskId, title: NEW_TITLE });
    return;
  }

  if (step === 4) {
    const task = tasks.find((t) => t.taskId === addedTaskId);
    if (!task) fail('edit_task quitó la tarea de la lista');
    if (task.title !== NEW_TITLE) {
      fail(`edit_task no aplicó el título: "${task.title}"`);
    }
    console.log('[client] edit_task OK. eliminando ->', addedTaskId);
    socket.emit('delete_task', { roomId, taskId: addedTaskId });
    return;
  }

  if (step === 5) {
    // La regresión: antes del fix el task_sync tras delete_task volvía a
    // incluir la tarea (broadcast con la lista stale de memoria).
    if (tasks.some((t) => t.taskId === addedTaskId)) {
      fail('delete_task no quitó la tarea del task_sync (bug de pull)');
    }
    void verifyPersisted();
  }
});

async function verifyPersisted(): Promise<void> {
  try {
    await mongoose.connect(
      process.env.MONGODB_URI ?? 'mongodb://localhost:27017/studyhub',
    );
    const room = await RoomModel.findOne({ roomId }, { tasks: 1 }).lean();
    const ids = (room?.tasks ?? []).map((t) => t.taskId);
    if (ids.includes(addedTaskId!)) {
      fail('la tarea sigue en Mongo pese a desaparecer del task_sync');
    }
    console.log('[client] Mongo confirma tareas restantes:', ids);
    await mongoose.disconnect();
    done();
  } catch (error) {
    console.error('[client] Error al verificar en Mongo:', error);
    process.exit(2);
  }
}

socket.on('connect_error', (err) => {
  console.error(`[client] no hay servidor en ${serverUrl}: ${err.message}`);
  console.error('[client] inícialo con npm run dev');
  process.exit(2);
});

setTimeout(() => {
  console.error('[client] timeout: el flujo no llegó al final');
  process.exit(2);
}, 15000);
