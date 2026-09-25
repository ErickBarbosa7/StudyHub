import type { Server, Socket } from 'socket.io';

export type PomodoroStatus = 'RUNNING' | 'PAUSED';
export type PomodoroMode = 'FOCUS' | 'SHORT_BREAK' | 'LONG_BREAK';
export type PomodoroAction = 'START' | 'PAUSE' | 'RESET' | 'SKIP' | 'SET_MODE';

interface PomodoroSession {
  timeRemaining: number;
  totalSeconds: number;
  status: PomodoroStatus;
  mode: PomodoroMode;
  // Duración elegida para estudiar; se conserva para volver tras un descanso.
  focusSeconds: number;
  // Rondas de estudio completadas; cada FOCUS_ROUNDS_BEFORE_LONG toca descanso largo.
  completedFocus: number;
  timeout: NodeJS.Timeout | null;
}

interface PomodoroActionPayload {
  roomId: string;
  action: PomodoroAction;
  duration?: number;
  mode?: PomodoroMode;
}

interface JoinRoomPayload {
  roomId?: string;
}

export const DEFAULT_POMODORO_SECONDS = 30 * 60;
export const SHORT_BREAK_SECONDS = 5 * 60;
export const LONG_BREAK_SECONDS = 15 * 60;
export const FOCUS_ROUNDS_BEFORE_LONG = 4;

const MIN_DURATION_SECONDS = 1;
const MAX_DURATION_SECONDS = 180 * 60;

const TICK_INTERVAL_MS = 1000;

const VALID_MODES: readonly PomodoroMode[] = ['FOCUS', 'SHORT_BREAK', 'LONG_BREAK'];

const sessions = new Map<string, PomodoroSession>();

function sanitizeDuration(duration: unknown): number | null {
  if (typeof duration !== 'number' || !Number.isFinite(duration)) return null;
  if (duration < MIN_DURATION_SECONDS) return MIN_DURATION_SECONDS;
  if (duration > MAX_DURATION_SECONDS) return MAX_DURATION_SECONDS;
  return Math.round(duration);
}

function isValidMode(mode: unknown): mode is PomodoroMode {
  return typeof mode === 'string' && VALID_MODES.includes(mode as PomodoroMode);
}

function getSession(roomId: string): PomodoroSession {
  let session = sessions.get(roomId);
  if (!session) {
    session = {
      timeRemaining: DEFAULT_POMODORO_SECONDS,
      totalSeconds: DEFAULT_POMODORO_SECONDS,
      status: 'PAUSED',
      mode: 'FOCUS',
      focusSeconds: DEFAULT_POMODORO_SECONDS,
      completedFocus: 0,
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

function secondsForMode(session: PomodoroSession, mode: PomodoroMode): number {
  switch (mode) {
    case 'SHORT_BREAK':
      return SHORT_BREAK_SECONDS;
    case 'LONG_BREAK':
      return LONG_BREAK_SECONDS;
    default:
      return session.focusSeconds;
  }
}

function applyMode(session: PomodoroSession, mode: PomodoroMode): void {
  session.mode = mode;
  session.totalSeconds = secondsForMode(session, mode);
  session.timeRemaining = session.totalSeconds;
}

// Estudio -> descanso (largo cada N rondas); descanso -> estudio.
function nextPhase(session: PomodoroSession): void {
  if (session.mode === 'FOCUS') {
    session.completedFocus += 1;
    const isLong = session.completedFocus % FOCUS_ROUNDS_BEFORE_LONG === 0;
    applyMode(session, isLong ? 'LONG_BREAK' : 'SHORT_BREAK');
  } else {
    applyMode(session, 'FOCUS');
  }
}

function tickPayload(roomId: string, session: PomodoroSession) {
  return {
    roomId,
    timeRemaining: session.timeRemaining,
    totalSeconds: session.totalSeconds,
    status: session.status,
    mode: session.mode,
    completedFocus: session.completedFocus,
  };
}

function emitTick(io: Server, roomId: string): void {
  const session = sessions.get(roomId);
  if (!session) return;
  io.to(roomId).emit('timer_tick', tickPayload(roomId, session));
}

function startTimer(io: Server, roomId: string, duration?: number): void {
  const session = getSession(roomId);

  // Los descansos tienen duración fija: solo el modo estudio acepta duración.
  const sanitized = session.mode === 'FOCUS' ? sanitizeDuration(duration) : null;
  if (sanitized !== null) {
    session.focusSeconds = sanitized;
    if (sanitized !== session.totalSeconds) {
      session.timeRemaining = sanitized;
    }
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
        mode: current.mode,
      });
      // Deja preparada la siguiente fase, en pausa hasta que alguien inicie.
      nextPhase(current);
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

  const sanitized = session.mode === 'FOCUS' ? sanitizeDuration(duration) : null;
  if (sanitized !== null) {
    session.focusSeconds = sanitized;
    session.totalSeconds = sanitized;
  }

  session.timeRemaining = session.totalSeconds;
  session.status = 'PAUSED';
  emitTick(io, roomId);
}

function skipPhase(io: Server, roomId: string): void {
  const session = getSession(roomId);
  const wasRunning = session.status === 'RUNNING';
  clearSessionTimer(roomId);
  nextPhase(session);

  if (wasRunning) {
    startTimer(io, roomId);
  } else {
    session.status = 'PAUSED';
    emitTick(io, roomId);
  }
}

function setMode(io: Server, roomId: string, mode: PomodoroMode): void {
  const session = getSession(roomId);
  clearSessionTimer(roomId);
  session.status = 'PAUSED';
  applyMode(session, mode);
  emitTick(io, roomId);
}

export function registerPomodoroHandler(io: Server, socket: Socket): void {
  socket.on(
    'pomodoro_action',
    (payload: PomodoroActionPayload) => {
      const { roomId, action, duration, mode } = payload;

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
        case 'SKIP':
          console.log(`[pomodoro] SKIP en sala ${roomId}`);
          skipPhase(io, roomId);
          break;
        case 'SET_MODE':
          if (!isValidMode(mode)) return;
          console.log(`[pomodoro] SET_MODE ${mode} en sala ${roomId}`);
          setMode(io, roomId, mode);
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
    socket.emit('timer_tick', tickPayload(roomId, session));
  });
}

export function cleanupPomodoroSession(roomId: string): void {
  clearSessionTimer(roomId);
  sessions.delete(roomId);
}
