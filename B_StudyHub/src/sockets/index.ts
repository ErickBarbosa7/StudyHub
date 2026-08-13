import type { Server, Socket } from 'socket.io';
import { registerRoomHandler } from './roomHandler.js';
import { registerTaskHandler } from './taskHandler.js';
import { registerChatHandler } from './chatHandler.js';
import { registerPomodoroHandler } from './pomodoroHandler.js';

export function registerSocketHandlers(io: Server): void {
  io.on('connection', (socket: Socket) => {
    console.log('Nuevo cliente conectado:', socket.id);

    registerRoomHandler(io, socket);
    registerTaskHandler(io, socket);
    registerChatHandler(io, socket);
    registerPomodoroHandler(io, socket);

    socket.on('disconnect', () => {
      console.log('Cliente desconectado:', socket.id);
    });
  });
}