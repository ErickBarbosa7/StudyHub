import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:flutter_riverpod/legacy.dart'
    show StateNotifier, StateNotifierProvider;

import '../data/services/sound_service.dart';
import '../data/services/websocket_service.dart';
import 'room_provider.dart';
import 'socket_provider.dart';

const int kDefaultPomodoroSeconds = 30 * 60;
const int kShortBreakSeconds = 5 * 60;
const int kLongBreakSeconds = 15 * 60;
const int kFocusRoundsBeforeLong = 4;

const String kModeFocus = 'FOCUS';
const String kModeShortBreak = 'SHORT_BREAK';
const String kModeLongBreak = 'LONG_BREAK';

class PomodoroState {
  const PomodoroState({
    this.timeRemaining = kDefaultPomodoroSeconds,
    this.totalSeconds = kDefaultPomodoroSeconds,
    this.status = 'PAUSED',
    this.isFinished = false,
    this.mode = kModeFocus,
    this.completedFocus = 0,
    this.finishedMode,
  });

  final int timeRemaining;
  final int totalSeconds;
  final String status;
  final bool isFinished;
  final String mode;
  final int completedFocus;
  // Fase que acaba de terminar (para mostrar el mensaje adecuado).
  final String? finishedMode;

  bool get isRunning => status == 'RUNNING';
  bool get isBreak => mode != kModeFocus;
  bool get isLongBreak => mode == kModeLongBreak;

  PomodoroState copyWith({
    int? timeRemaining,
    int? totalSeconds,
    String? status,
    bool? isFinished,
    String? mode,
    int? completedFocus,
    String? finishedMode,
  }) {
    return PomodoroState(
      timeRemaining: timeRemaining ?? this.timeRemaining,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      status: status ?? this.status,
      isFinished: isFinished ?? this.isFinished,
      mode: mode ?? this.mode,
      completedFocus: completedFocus ?? this.completedFocus,
      finishedMode: finishedMode ?? this.finishedMode,
    );
  }
}

class PomodoroNotifier extends StateNotifier<PomodoroState> {
  PomodoroNotifier(this._socketService, this._roomProvider)
      : super(const PomodoroState()) {
    _roomProvider.listen<RoomState>(roomProvider, (previous, next) {
      final prevRoomId = previous?.room?.roomId;
      final nextRoomId = next.room?.roomId;
      if (prevRoomId != nextRoomId) {
        // Al entrar a una sala nueva, limpiamos el estado local para no
        // arrastrar el tiempo de una sala anterior. El servidor (fuente única
        // de verdad) sobrescribirá estos valores con el timer_tick real.
        state = const PomodoroState();
      }
    });

    _socketService.on('timer_tick', (data) {
      final map = data as Map<String, dynamic>;
      final timeRemaining = (map['timeRemaining'] as num).round();
      final status = map['status'] as String;
      final totalSeconds =
          map.containsKey('totalSeconds') ? (map['totalSeconds'] as num).round() : null;
      final mode = map['mode'] as String? ?? state.mode;
      final completedFocus = map.containsKey('completedFocus')
          ? (map['completedFocus'] as num).round()
          : state.completedFocus;
      final wasRunning = state.isRunning;
      final finishedAtZero = timeRemaining == 0 && wasRunning;
      if (finishedAtZero && !state.isFinished) {
        _roomProvider.read(soundProvider.notifier).playPomodoroFinishedSound();
      }
      // Si el modo cambia por algo distinto a terminar la fase actual
      // (flecha o selector), el 'completado' previo ya no aplica.
      final modeChangedManually =
          mode != state.mode && state.finishedMode != state.mode;
      state = state.copyWith(
        timeRemaining: timeRemaining,
        status: status,
        totalSeconds: totalSeconds ?? state.totalSeconds,
        mode: mode,
        completedFocus: completedFocus,
        // Nueva sesión en curso: descarta un 'completado' previo.
        isFinished: status == 'RUNNING' || modeChangedManually
            ? false
            : (finishedAtZero || state.isFinished),
      );
    });

    _socketService.on('pomodoro_finished', (data) {
      final map = data as Map<String, dynamic>;
      final totalSeconds =
          map.containsKey('totalSeconds') ? (map['totalSeconds'] as num).round() : null;
      final finishedMode = map['mode'] as String? ?? state.mode;
      debugPrint('[pomodoro] Fase $finishedMode completada');
      if (!state.isFinished) {
        _roomProvider.read(soundProvider.notifier).playPomodoroFinishedSound();
      }
      state = state.copyWith(
        timeRemaining: 0,
        status: 'PAUSED',
        isFinished: true,
        finishedMode: finishedMode,
        totalSeconds: totalSeconds ?? state.totalSeconds,
      );
    });
  }

  final WebSocketService _socketService;
  final riverpod.Ref _roomProvider;

  String? get _roomId => _roomProvider.read(roomProvider).room?.roomId;

  void _action(String action, [int? durationSeconds, String? mode]) {
    final roomId = _roomId;
    if (roomId == null) return;

    _socketService.emit('pomodoro_action', {
      'roomId': roomId,
      'action': action,
      'duration': ?durationSeconds,
      'mode': ?mode,
    });
  }

  void start([int? durationSeconds]) {
    state = state.copyWith(isFinished: false);
    _action('START', durationSeconds);
  }

  void pause() => _action('PAUSE');

  void reset([int? durationSeconds]) {
    state = state.copyWith(isFinished: false);
    _action('RESET', durationSeconds);
  }

  /// Adelanta a la siguiente fase: estudio -> descanso, descanso -> estudio.
  void skip() {
    state = state.copyWith(isFinished: false);
    _action('SKIP');
  }

  void setMode(String mode) {
    if (mode == state.mode) return;
    state = state.copyWith(isFinished: false);
    _action('SET_MODE', null, mode);
  }
}

final pomodoroProvider =
    StateNotifierProvider<PomodoroNotifier, PomodoroState>((ref) {
  return PomodoroNotifier(
    ref.watch(socketServiceProvider),
    ref,
  );
});