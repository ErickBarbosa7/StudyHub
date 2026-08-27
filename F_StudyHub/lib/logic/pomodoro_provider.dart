import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:flutter_riverpod/legacy.dart'
    show StateNotifier, StateNotifierProvider;

import '../data/services/websocket_service.dart';
import 'room_provider.dart';
import 'socket_provider.dart';

const int kDefaultPomodoroSeconds = 30 * 60;

class PomodoroState {
  const PomodoroState({
    this.timeRemaining = kDefaultPomodoroSeconds,
    this.totalSeconds = kDefaultPomodoroSeconds,
    this.status = 'PAUSED',
    this.isFinished = false,
  });

  final int timeRemaining;
  final int totalSeconds;
  final String status;
  final bool isFinished;

  bool get isRunning => status == 'RUNNING';

  PomodoroState copyWith({
    int? timeRemaining,
    int? totalSeconds,
    String? status,
    bool? isFinished,
  }) {
    return PomodoroState(
      timeRemaining: timeRemaining ?? this.timeRemaining,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      status: status ?? this.status,
      isFinished: isFinished ?? this.isFinished,
    );
  }
}

class PomodoroNotifier extends StateNotifier<PomodoroState> {
  PomodoroNotifier(this._socketService, this._roomProvider)
      : super(const PomodoroState()) {
    _socketService.on('timer_tick', (data) {
      final map = data as Map<String, dynamic>;
      final timeRemaining = (map['timeRemaining'] as num).round();
      final status = map['status'] as String;
      final totalSeconds =
          map.containsKey('totalSeconds') ? (map['totalSeconds'] as num).round() : null;
      state = state.copyWith(
        timeRemaining: timeRemaining,
        status: status,
        totalSeconds: totalSeconds ?? state.totalSeconds,
        // Nueva sesión en curso: descarta un 'completado' previo.
        isFinished: status == 'RUNNING' ? false : state.isFinished,
      );
    });

    _socketService.on('pomodoro_finished', (data) {
      final map = data as Map<String, dynamic>;
      final totalSeconds =
          map.containsKey('totalSeconds') ? (map['totalSeconds'] as num).round() : null;
      debugPrint('[pomodoro] Sesión completada');
      state = state.copyWith(
        timeRemaining: 0,
        status: 'PAUSED',
        isFinished: true,
        totalSeconds: totalSeconds ?? state.totalSeconds,
      );
    });
  }

  final WebSocketService _socketService;
  final riverpod.Ref _roomProvider;

  String? get _roomId => _roomProvider.read(roomProvider).room?.roomId;

  void _action(String action, [int? durationSeconds]) {
    final roomId = _roomId;
    if (roomId == null) return;

    _socketService.emit('pomodoro_action', {
      'roomId': roomId,
      'action': action,
      'duration': ?durationSeconds,
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
}

final pomodoroProvider =
    StateNotifierProvider<PomodoroNotifier, PomodoroState>((ref) {
  return PomodoroNotifier(
    ref.watch(socketServiceProvider),
    ref,
  );
});