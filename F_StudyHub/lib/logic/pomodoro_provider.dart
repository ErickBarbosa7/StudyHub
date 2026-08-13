import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:flutter_riverpod/legacy.dart'
    show StateNotifier, StateNotifierProvider;

import '../data/services/websocket_service.dart';
import 'room_provider.dart';
import 'socket_provider.dart';

const int kDefaultPomodoroSeconds = 25 * 60;

class PomodoroState {
  const PomodoroState({
    this.timeRemaining = kDefaultPomodoroSeconds,
    this.totalSeconds = kDefaultPomodoroSeconds,
    this.status = 'PAUSED',
  });

  final int timeRemaining;
  final int totalSeconds;
  final String status;

  bool get isRunning => status == 'RUNNING';

  PomodoroState copyWith({int? timeRemaining, int? totalSeconds, String? status}) {
    return PomodoroState(
      timeRemaining: timeRemaining ?? this.timeRemaining,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      status: status ?? this.status,
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

  void start([int? durationSeconds]) => _action('START', durationSeconds);
  void pause() => _action('PAUSE');
  void reset([int? durationSeconds]) => _action('RESET', durationSeconds);
}

final pomodoroProvider =
    StateNotifierProvider<PomodoroNotifier, PomodoroState>((ref) {
  return PomodoroNotifier(
    ref.watch(socketServiceProvider),
    ref,
  );
});