import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../data/models/task_model.dart';
import '../../logic/task_provider.dart';

const _kTaskStates = <String, String>{
  'PENDING': 'Pendiente',
  'IN_PROGRESS': 'En progreso',
  'COMPLETED': 'Completada',
};

class TaskList extends ConsumerStatefulWidget {
  const TaskList({super.key});

  @override
  ConsumerState<TaskList> createState() => _TaskListState();
}

class _TaskListState extends ConsumerState<TaskList> {
  final _taskController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }

  void _addTask() {
    if (!_formKey.currentState!.validate()) return;

    ref.read(taskProvider.notifier).addTask(_taskController.text);
    _taskController.clear();
  }

  void _toggleComplete(Task task) {
    final target = task.stateCode == 'COMPLETED' ? 'PENDING' : 'COMPLETED';
    ref.read(taskProvider.notifier).updateTaskStatus(task.taskId, target);
  }

  void _changeState(Task task) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: kColorPaper,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(32, 32, 32, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Cambiar estado',
                textAlign: TextAlign.center,
                style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(
                      color: kColorInk,
                      fontWeight: AppType.weightSemiBold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                task.title,
                textAlign: TextAlign.center,
                style: Theme.of(sheetContext).textTheme.bodyMedium?.copyWith(
                      color: kColorTextSecondary,
                    ),
              ),
              const SizedBox(height: 32),
              ..._kTaskStates.entries.map((entry) => _StateOption(
                    code: entry.key,
                    label: entry.value,
                    selected: entry.key == task.stateCode,
                    onTap: () {
                      ref
                          .read(taskProvider.notifier)
                          .updateTaskStatus(task.taskId, entry.key);
                      Navigator.of(sheetContext).pop();
                    },
                  )),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.of(sheetContext).pop(),
                style: TextButton.styleFrom(
                  foregroundColor: kColorTextSecondary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Cancelar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(taskProvider).tasks;
    final bool compact = MediaQuery.sizeOf(context).width < 600;

    return Container(
      padding: EdgeInsets.all(compact ? 16 : 24),
      decoration: BoxDecoration(
        color: kColorCard,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: kColorTintedShadow,
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(compact ? 8 : 10),
                decoration: BoxDecoration(
                  color: kColorGoldSoft, // Arena dorada
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.checklist_rounded,
                  color: kColorGold, // El hilo de oro del módulo
                  size: compact ? 20 : 24,
                ),
              ),
              SizedBox(width: compact ? 12 : 16),
              Expanded(
                child: Text(
                  'Tareas',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: kColorInk,
                        fontWeight: AppType.weightSemiBold,
                        fontSize: compact ? AppType.sizeTitle : null,
                      ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 12, vertical: compact ? 4 : 6),
                decoration: BoxDecoration(
                  color: kColorGoldSoft,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${tasks.length}',
                  style: const TextStyle(
                    color: kColorInk,
                    fontWeight: AppType.weightSemiBold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 16 : 24),

          Form(
            key: _formKey,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _taskController,
                    textCapitalization: TextCapitalization.sentences,
                    style: const TextStyle(color: kColorInk),
                    decoration: InputDecoration(
                      labelText: 'Nueva tarea',
                      hintText: 'ej. Terminar ejercicios',
                      labelStyle: const TextStyle(color: kColorTextSecondary),
                      hintStyle: TextStyle(
                        color: kColorTextSecondary.withValues(alpha: 0.5),
                      ),
                      prefixIcon:
                          const Icon(Icons.add_task_rounded, color: kColorDeepSage),
                      filled: true,
                      fillColor: kColorPaper,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: compact ? 16 : 24,
                        vertical: compact ? 14 : 18,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide:
                            const BorderSide(color: kColorDeepSage, width: 1.5),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: kColorErrorBorder, width: 1.5),
                      ),
                    ),
                    validator: (value) => (value == null || value.trim().isEmpty)
                        ? 'Requerido'
                        : null,
                    onFieldSubmitted: (_) => _addTask(),
                  ),
                ),
                SizedBox(width: compact ? 8 : 12),
                SizedBox(
                  height: compact ? 48 : 56,
                  width: compact ? 48 : 56,
                  child: ElevatedButton(
                    onPressed: _addTask,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      backgroundColor: kColorDeepSage,
                      foregroundColor: kColorPaper,
                      elevation: 0,
                    ),
                    child: const Icon(Icons.add_rounded, size: 28),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: compact ? 16 : 24),

          if (tasks.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  const Icon(
                    Icons.fact_check_outlined,
                    size: 40,
                    color: kColorGold,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Sin tareas todavía.\nAñade la primera para empezar.',
                    textAlign: TextAlign.center,
                    style: AppType.secondaryItalic(),
                  ),
                ],
              ),
            )
          else
            ...tasks.map((task) => _TaskTile(
                  task: task,
                  onToggleComplete: () => _toggleComplete(task),
                  onOpenMenu: () => _changeState(task),
                )),
        ],
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({
    required this.task,
    required this.onToggleComplete,
    required this.onOpenMenu,
  });

  final Task task;
  final VoidCallback onToggleComplete;
  final VoidCallback onOpenMenu;

  @override
  Widget build(BuildContext context) {
    final bool done = task.stateCode == 'COMPLETED';
    final pill = _pillColors(task.stateCode);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      decoration: BoxDecoration(
        color: kColorPaper,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: GestureDetector(
              onTap: onToggleComplete,
              behavior: HitTestBehavior.opaque,
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: done ? kColorDeepSage : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: done ? kColorDeepSage : kColorGold, // Ornamento dorado al pendiente
                      width: 2,
                    ),
                  ),
                  child: done
                      ? const Icon(
                          Icons.check_rounded,
                          color: kColorPaper,
                          size: 18,
                        )
                      : null,
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: onOpenMenu,
              behavior: HitTestBehavior.opaque,
              child: Text(
                task.title,
                style: TextStyle(
                  color: kColorInk,
                  fontWeight: AppType.weightMedium,
                  decoration: done ? TextDecoration.lineThrough : null,
                  decorationColor: kColorTextSecondary,
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: onOpenMenu,
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: pill.background,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    task.stateLabel,
                    style: TextStyle(
                      color: pill.foreground,
                      fontWeight: AppType.weightSemiBold,
                      fontSize: AppType.sizeCaption,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.expand_more_rounded,
                    size: 16,
                    color: pill.foreground,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  ({Color background, Color foreground}) _pillColors(String code) {
    switch (code) {
      case 'IN_PROGRESS':
        return (
          background: kColorGoldSoft,
          foreground: kColorInk,
        );
      case 'COMPLETED':
        return (
          background: kColorSageSoft,
          foreground: kColorDeepSage,
        );
      case 'PENDING':
      default:
        return (
          background: Colors.transparent,
          foreground: kColorTextSecondary,
        );
    }
  }
}

class _StateOption extends StatelessWidget {
  const _StateOption({
    required this.code,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String code;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: selected ? kColorDeepSage : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: selected
                ? null
                : Border.all(
                    color: kColorBorder,
                    width: 1.5,
                  ),
          ),
          child: Row(
            children: [
              Icon(
                code == 'COMPLETED'
                    ? Icons.check_circle_outline_rounded
                    : code == 'IN_PROGRESS'
                        ? Icons.play_circle_outline_rounded
                        : Icons.schedule_rounded,
                color: selected ? kColorPaper : kColorTextSecondary,
              ),
              const SizedBox(width: 14),
              Text(
                label,
                style: TextStyle(
                  color: selected ? kColorPaper : kColorInk,
                  fontWeight: AppType.weightSemiBold,
                ),
              ),
              const Spacer(),
              if (selected)
                const Icon(Icons.check_rounded, color: kColorPaper, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}