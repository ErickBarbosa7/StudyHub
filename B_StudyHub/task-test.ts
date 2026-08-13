import { io } from 'socket.io-client';

const roomId = process.argv[2] ?? 'JJ2UXU';

const socket = io('http://localhost:4000', { transports: ['websocket'] });

let step = 0;

socket.on('connect', () => {
  console.log('[client] conectado:', socket.id);
  socket.emit('join_room', {
    roomId,
    user: { id: 'user_e2e', name: 'Tester' },
  });
});

socket.on('task_sync', (tasks) => {
  console.log(`[client] task_sync (${step}):`, JSON.stringify(tasks));
  step += 1;
  if (step === 1) {
    socket.emit('add_task', { roomId, title: 'Estudiar capítulo 3' });
  } else if (step === 2) {
    const taskId = tasks[0]?.taskId;
    console.log('[client] actualizando estado -> IN_PROGRESS:', taskId);
    socket.emit('update_task_status', { roomId, taskId, newStateRef: 'IN_PROGRESS' });
  } else if (step === 3) {
    console.log('[client] prueba completada');
    process.exit(0);
  }
});

setTimeout(() => process.exit(2), 10000);