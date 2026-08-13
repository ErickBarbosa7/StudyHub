import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:flutter_riverpod/legacy.dart'
    show StateNotifier, StateNotifierProvider;

import '../data/models/task_model.dart';
import '../data/services/websocket_service.dart';
import 'room_provider.dart';
import 'socket_provider.dart';

class TaskState {
  const TaskState({this.tasks = const []});

  final List<Task> tasks;

  TaskState copyWith({List<Task>? tasks}) {
    return TaskState(tasks: tasks ?? this.tasks);
  }
}

class TaskNotifier extends StateNotifier<TaskState> {
  TaskNotifier(this._socketService, this._roomProvider)
      : super(const TaskState()) {
    _socketService.on('task_sync', (data) {
      final tasks = (data as List)
          .map((item) => Task.fromJson(item as Map<String, dynamic>))
          .toList();
      state = state.copyWith(tasks: tasks);
    });
  }

  final WebSocketService _socketService;
  final riverpod.Ref _roomProvider;

  String? get _roomId => _roomProvider.read(roomProvider).room?.roomId;

  void addTask(String title) {
    final roomId = _roomId;
    if (roomId == null || title.trim().isEmpty) return;

    _socketService.emit('add_task', {
      'roomId': roomId,
      'title': title.trim(),
    });
  }

  void updateTaskStatus(String taskId, String newStateRef) {
    final roomId = _roomId;
    if (roomId == null) return;

    _socketService.emit('update_task_status', {
      'roomId': roomId,
      'taskId': taskId,
      'newStateRef': newStateRef,
    });
  }
}

final taskProvider = StateNotifierProvider<TaskNotifier, TaskState>((ref) {
  return TaskNotifier(
    ref.watch(socketServiceProvider),
    ref,
  );
});