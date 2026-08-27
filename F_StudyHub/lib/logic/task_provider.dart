import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:flutter_riverpod/legacy.dart'
    show StateNotifier, StateNotifierProvider;

import '../data/models/task_model.dart';
import '../data/services/websocket_service.dart';
import 'room_provider.dart';
import 'socket_provider.dart';

class TaskState {
  const TaskState({
    this.tasks = const [],
    this.error,
  });

  final List<Task> tasks;
  final String? error;

  TaskState copyWith({
    List<Task>? tasks,
    String? error,
    bool clearError = false,
  }) {
    return TaskState(
      tasks: tasks ?? this.tasks,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class TaskNotifier extends StateNotifier<TaskState> {
  TaskNotifier(this._socketService, this._roomProvider)
      : super(const TaskState()) {
    _socketService.on('task_sync', (data) {
      final tasks = (data as List)
          .map((item) => Task.fromJson(item as Map<String, dynamic>))
          .toList();
      state = state.copyWith(tasks: tasks, clearError: true);
    });
  }

  final WebSocketService _socketService;
  final riverpod.Ref _roomProvider;

  String? get _roomId => _roomProvider.read(roomProvider).room?.roomId;

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  void addTask(String title) {
    final roomId = _roomId;
    if (roomId == null || title.trim().isEmpty) {
      state = state.copyWith(error: 'No se pudo agregar la tarea. Asegúrate de estar dentro de una sala.');
      return;
    }

    _socketService.emit('add_task', {
      'roomId': roomId,
      'title': title.trim(),
    });
  }

  void updateTaskStatus(String taskId, String newStateRef) {
    final roomId = _roomId;
    if (roomId == null) {
      state = state.copyWith(error: 'No se pudo actualizar la tarea. Asegúrate de estar dentro de una sala.');
      return;
    }

    _socketService.emit('update_task_status', {
      'roomId': roomId,
      'taskId': taskId,
      'newStateRef': newStateRef,
    });
  }

  void deleteTask(String taskId) {
    final roomId = _roomId;
    if (roomId == null) {
      state = state.copyWith(error: 'No se pudo eliminar la tarea.');
      return;
    }

    _socketService.emit('delete_task', {
      'roomId': roomId,
      'taskId': taskId,
    });
  }

  void editTask(String taskId, String newTitle) {
    final roomId = _roomId;
    if (roomId == null || newTitle.trim().isEmpty) {
      state = state.copyWith(error: 'No se pudo editar la tarea.');
      return;
    }

    _socketService.emit('edit_task', {
      'roomId': roomId,
      'taskId': taskId,
      'title': newTitle.trim(),
    });
  }
}

final taskProvider = StateNotifierProvider<TaskNotifier, TaskState>((ref) {
  return TaskNotifier(
    ref.watch(socketServiceProvider),
    ref,
  );
});
