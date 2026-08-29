import type { Server, Socket } from 'socket.io';

export type PomodoroStatus = 'RUNNING' | 'PAUSED';
export type PomodoroAction = 'START' | 'PAUSE' | 'RESET';

interface PomodoroSession {
  timeRemaining: number;
  totalSeconds: number;
  status: PomodoroStatus;
  timeout: NodeJS.Timeout | null;
}

interface PomodoroActionPayload {
  roomId: string;
  action: PomodoroAction;
  duration?: number;
}

interface JoinRoomPayload {
  roomId?: string;
}

export const DEFAULT_POMODORO_SECONDS = 30 * 60;

const MIN_DURATION_SECONDS = 1;
const MAX_DURATION_SECONDS = 180 * 60;

const TICK_INTERVAL_MS = 1000;

const sessions = new Map<string, PomodoroSession>();

function sanitizeDuration(duration: unknown): number | null {
  if (typeof duration !== 'number' || !Number.isFinite(duration)) return null;
  if (duration < MIN_DURATION_SECONDS) return MIN_DURATION_SECONDS;
  if (duration > MAX_DURATION_SECONDS) return MAX_DURATION_SECONDS;
  return Math.round(duration);
}

function getSession(roomId: string): PomodoroSession {
  let session = sessions.get(roomId);
  if (!session) {
    session = {
      timeRemaining: DEFAULT_POMODORO_SECONDS,
      totalSeconds: DEFAULT_POMODORO_SECONDS,
      status: 'PAUSED',
      timeout: null,
    };
    sessions.set(roomId, session);
  }
  return session;
}

function clearSessionTimer(roomId: string): void {
  const session = sessions.get(roomId);
  if (session?.timeout) {
    clearInterval(session.timeout);
    session.timeout = null;
  }
}

function emitTick(io: Server, roomId: string): void {
  const session = sessions.get(roomId);
  if (!session) return;
  io.to(roomId).emit('timer_tick', {
    roomId,
    timeRemaining: session.timeRemaining,
    totalSeconds: session.totalSeconds,
    status: session.status,
  });
}

function startTimer(io: Server, roomId: string, duration?: number): void {
  const session = getSession(roomId);

  const sanitized = sanitizeDuration(duration);
  if (sanitized !== null && sanitized !== session.totalSeconds) {
    session.totalSeconds = sanitized;
    session.timeRemaining = sanitized;
  } else if (sanitized !== null) {
    session.totalSeconds = sanitized;
  }

  if (session.timeRemaining <= 0) {
    session.timeRemaining = session.totalSeconds;
  }

  clearSessionTimer(roomId);
  session.status = 'RUNNING';
  session.timeout = setInterval(() => {
    const current = sessions.get(roomId);
    if (!current) return;

    current.timeRemaining = Math.max(0, current.timeRemaining - 1);

    if (current.timeRemaining <= 0) {
      clearSessionTimer(roomId);
      current.status = 'PAUSED';
      io.to(roomId).emit('pomodoro_finished', {
        roomId,
        totalSeconds: current.totalSeconds,
      });
    }

    emitTick(io, roomId);
  }, TICK_INTERVAL_MS);

  emitTick(io, roomId);
}

function pauseTimer(io: Server, roomId: string): void {
  const session = getSession(roomId);
  clearSessionTimer(roomId);
  session.status = 'PAUSED';
  emitTick(io, roomId);
}

function resetTimer(io: Server, roomId: string, duration?: number): void {
  const session = getSession(roomId);
  clearSessionTimer(roomId);

  const sanitized = sanitizeDuration(duration);
  if (sanitized !== null) {
    session.totalSeconds = sanitized;
  }

  session.timeRemaining = session.totalSeconds;
  session.status = 'PAUSED';
  emitTick(io, roomId);
}

export function registerPomodoroHandler(io: Server, socket: Socket): void {
  socket.on(
    'pomodoro_action',
    (payload: PomodoroActionPayload) => {
      const { roomId, action, duration } = payload;

      if (!roomId || !action) {
        return;
      }

      switch (action) {
        case 'START':
          console.log(`[pomodoro] START en sala ${roomId}`);
          startTimer(io, roomId, duration);
          break;
        case 'PAUSE':
          console.log(`[pomodoro] PAUSE en sala ${roomId}`);
          pauseTimer(io, roomId);
          break;
        case 'RESET':
          console.log(`[pomodoro] RESET en sala ${roomId}`);
          resetTimer(io, roomId, duration);
          break;
        default:
          return;
      }
    },
  );

  socket.on('join_room', (payload: JoinRoomPayload) => {
    const { roomId } = payload;
    if (!roomId) return;

    const session = getSession(roomId);
    socket.emit('timer_tick', {
      roomId,
      timeRemaining: session.timeRemaining,
      totalSeconds: session.totalSeconds,
      status: session.status,
    });
  });
}