import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme.dart';
import '../../data/models/task_model.dart';
import '../../logic/room_provider.dart';
import '../../logic/task_provider.dart';
import '../room/room_widgets.dart';

const _kTaskStates = <String, String>{
  'PENDING': 'Pendiente',
  'IN_PROGRESS': 'En progreso',
  'COMPLETED': 'Completada',
};

// Límite de caracteres centralizado
const int _kMaxTaskLength = 100;

/// Lista de tareas compartida de la sala. Necesita alto acotado (la lista
/// hace scroll por dentro), así que va dentro de un panel con alto fijo.
class TaskList extends ConsumerStatefulWidget {
  const TaskList({super.key, this.showTitle = true});

  /// Sin título cuando una pestaña ya dice "Tareas".
  final bool showTitle;

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

  void _showTaskActions(Task task) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: kRoomSurface,
      isScrollControlled: true,
      constraints: const BoxConstraints(maxWidth: 520),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                task.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: kRoomInk,
                  fontSize: AppType.sizeTitle - 2,
                  fontWeight: AppType.weightBold,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Estado',
                style: TextStyle(
                  color: kRoomMuted,
                  fontSize: AppType.sizeLabel,
                  fontWeight: AppType.weightSemiBold,
                ),
              ),
              const SizedBox(height: 10),
              ..._kTaskStates.entries.map(
                (entry) => _StateOption(
                  code: entry.key,
                  label: entry.value,
                  selected: entry.key == task.stateCode,
                  onTap: () {
                    ref
                        .read(taskProvider.notifier)
                        .updateTaskStatus(task.taskId, entry.key);
                    Navigator.of(sheetContext).pop();
                  },
                ),
              ),
              const SizedBox(height: 8),
              _SheetAction(
                icon: LucideIcons.pencil,
                label: 'Editar nombre',
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _editTask(task);
                },
              ),
              const SizedBox(height: 10),
              _SheetAction(
                icon: LucideIcons.trash2,
                label: 'Eliminar esta tarea',
                color: kRoomError,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _confirmDelete(task);
                },
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(sheetContext).pop(),
                style: TextButton.styleFrom(
                  foregroundColor: kRoomMuted,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Cancelar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _editTask(Task task) {
    final controller = TextEditingController(text: task.title);
    final editFormKey = GlobalKey<FormState>();

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: kRoomSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Editar tarea',
          style: TextStyle(color: kRoomInk, fontWeight: AppType.weightSemiBold),
        ),
        content: Form(
          key: editFormKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            maxLength: _kMaxTaskLength,
            maxLengthEnforcement: MaxLengthEnforcement.enforced,
            textCapitalization: TextCapitalization.sentences,
            style: const TextStyle(color: kRoomInk),
            decoration: const InputDecoration(
              labelText: 'Nombre de la tarea',
              labelStyle: TextStyle(color: kRoomMuted),
              counterText: '',
            ),
            validator: (value) {
              final text = value?.trim() ?? '';
              if (text.isEmpty) return 'Requerido';
              if (text.length > _kMaxTaskLength) return 'Excede el límite';
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            style: TextButton.styleFrom(foregroundColor: kRoomMuted),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              if (!editFormKey.currentState!.validate()) return;
              ref
                  .read(taskProvider.notifier)
                  .editTask(task.taskId, controller.text);
              Navigator.of(dialogContext).pop();
            },
            style: TextButton.styleFrom(foregroundColor: kRoomStudy),
            child: const Text(
              'Guardar',
              style: TextStyle(fontWeight: AppType.weightSemiBold),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(Task task) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: kRoomSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          '¿Eliminar tarea?',
          style: TextStyle(color: kRoomInk, fontWeight: AppType.weightSemiBold),
        ),
        content: Text(
          '"${task.title}" se eliminará permanentemente. Esta acción no se puede deshacer.',
          style: const TextStyle(color: kRoomMuted, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            style: TextButton.styleFrom(foregroundColor: kRoomMuted),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              ref.read(taskProvider.notifier).deleteTask(task.taskId);
              Navigator.of(dialogContext).pop();
            },
            style: TextButton.styleFrom(foregroundColor: kRoomError),
            child: const Text(
              'Eliminar',
              style: TextStyle(fontWeight: AppType.weightSemiBold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(taskProvider.select((s) => s.tasks));
    final solo = ref.watch(roomProvider.select((s) => s.users.length <= 1));

    ref.listen<TaskState>(taskProvider, (previous, next) {
      if (next.error != null && next.error != previous?.error) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(next.error!)));
          ref.read(taskProvider.notifier).clearError();
        });
      }
    });

    final int done = tasks.where((t) => t.stateCode == 'COMPLETED').length;

    final listArea = tasks.isEmpty
        ? _EmptyTasks(solo: solo)
        : ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return _TaskTile(
                task: task,
                showCreator: !solo,
                onToggleComplete: () => _toggleComplete(task),
                onOpenMenu: () => _showTaskActions(task),
              );
            },
          );

    return LayoutBuilder(
      builder: (context, constraints) {
        // Con muy poco alto (celular horizontal) todo el panel hace scroll.
        final bool tight =
            constraints.hasBoundedHeight && constraints.maxHeight < 320;
        final column = Column(
          mainAxisSize: tight ? MainAxisSize.min : MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                if (widget.showTitle) ...[
                  const Icon(
                    LucideIcons.listChecks,
                    size: 20,
                    color: kRoomStudy,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Tareas',
                      style: TextStyle(
                        color: kRoomInk,
                        fontSize: AppType.sizeTitle - 2,
                        fontWeight: AppType.weightBold,
                      ),
                    ),
                  ),
                ] else
                  const Spacer(),
                if (tasks.isNotEmpty)
                  Text(
                    done == 1
                        ? '1 de ${tasks.length} completada'
                        : '$done de ${tasks.length} completadas',
                    style: const TextStyle(
                      color: kRoomMuted,
                      fontSize: AppType.sizeLabel,
                      fontWeight: AppType.weightSemiBold,
                    ),
                  ),
              ],
            ),
            if (tasks.isNotEmpty) ...[
              const SizedBox(height: 12),
              _ProgressBar(value: done / tasks.length),
            ],
            SizedBox(height: widget.showTitle || tasks.isNotEmpty ? 16 : 0),
            Form(
              key: _formKey,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _taskController,
                      textCapitalization: TextCapitalization.sentences,
                      maxLength: _kMaxTaskLength,
                      maxLengthEnforcement: MaxLengthEnforcement.enforced,
                      scrollPadding: const EdgeInsets.only(bottom: 60),
                      style: const TextStyle(color: kRoomInk, fontSize: 15),
                      decoration: InputDecoration(
                        hintText:
                            'Nueva tarea, por ejemplo: leer el capítulo 2',
                        counterText: '',
                        hintStyle: const TextStyle(color: kRoomMuted),
                        filled: true,
                        fillColor: kRoomSurface,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 17,
                        ),
                        border: _fieldBorder(kRoomLine),
                        enabledBorder: _fieldBorder(kRoomLine),
                        focusedBorder: _fieldBorder(kRoomStudy, width: 1.5),
                        errorBorder: _fieldBorder(kRoomError),
                        focusedErrorBorder: _fieldBorder(
                          kRoomError,
                          width: 1.5,
                        ),
                      ),
                      validator: (value) {
                        final text = value?.trim() ?? '';
                        if (text.isEmpty) return 'Escribe una tarea';
                        if (text.length > _kMaxTaskLength) {
                          return 'Excede el límite';
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) => _addTask(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  RoomIconButton(
                    size: 52,
                    iconSize: 22,
                    icon: LucideIcons.plus,
                    tooltip: 'Agregar tarea',
                    foreground: kRoomStudy,
                    background: kRoomStudySoft,
                    bordered: false,
                    onPressed: _addTask,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            tight
                ? SizedBox(height: 240, child: listArea)
                : Expanded(child: listArea),
          ],
        );
        return tight ? SingleChildScrollView(child: column) : column;
      },
    );
  }

  OutlineInputBorder _fieldBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: value.clamp(0.0, 1.0)),
        duration: const Duration(milliseconds: 300),
        builder: (context, v, _) => LinearProgressIndicator(
          value: v,
          minHeight: 6,
          backgroundColor: kRoomTrack,
          valueColor: const AlwaysStoppedAnimation(kRoomStudy),
        ),
      ),
    );
  }
}

/// Estado vacío: explica para qué sirven las tareas (solo / en equipo).
class _EmptyTasks extends StatelessWidget {
  const _EmptyTasks({required this.solo});

  final bool solo;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: kRoomStudySoft,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  LucideIcons.listChecks,
                  size: 26,
                  color: kRoomStudy,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Anota lo que quieres lograr',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: kRoomInk,
                  fontSize: AppType.sizeTitle,
                  fontWeight: AppType.weightBold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                solo
                    ? 'Escribe arriba tus pendientes de hoy, como leer un '
                          'capítulo o hacer ejercicios, y márcalos al terminar. '
                          'Así sabes qué te falta y avanzas paso a paso.'
                    : 'Escribe arriba lo que hay que hacer, como repasar, '
                          'entregar o investigar. Todos en la sala ven la lista '
                          'y pueden marcar lo que van terminando.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: kRoomMuted,
                  fontSize: AppType.sizeBodyMedium,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({
    required this.task,
    required this.showCreator,
    required this.onToggleComplete,
    required this.onOpenMenu,
  });

  final Task task;
  final bool showCreator;
  final VoidCallback onToggleComplete;
  final VoidCallback onOpenMenu;

  @override
  Widget build(BuildContext context) {
    final bool done = task.stateCode == 'COMPLETED';
    final chip = _chipColors(task.stateCode);
    final creator = showCreator ? task.creatorName : null;

    return Container(
      constraints: const BoxConstraints(minHeight: 60),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: kRoomTrack)),
      ),
      child: Row(
        children: [
          // Acción rápida: marcar/desmarcar. Área táctil de 44x44.
          Semantics(
            button: true,
            checked: done,
            label: done ? 'Marcar como pendiente' : 'Marcar como completada',
            excludeSemantics: true,
            child: GestureDetector(
              onTap: onToggleComplete,
              behavior: HitTestBehavior.opaque,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: done ? kRoomStudy : kRoomSurface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: done ? kRoomStudy : kRoomDisabled,
                          width: 2,
                        ),
                      ),
                      child: done
                          ? const Icon(
                              LucideIcons.check,
                              size: 15,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Acción profunda: abre el menú de la tarea.
          Expanded(
            child: GestureDetector(
              onTap: onOpenMenu,
              behavior: HitTestBehavior.opaque,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: TextStyle(
                          color: done ? kRoomMuted : kRoomInk,
                          fontSize: 15,
                          height: 1.3,
                          fontWeight: done
                              ? AppType.weightRegular
                              : AppType.weightSemiBold,
                          decoration: done ? TextDecoration.lineThrough : null,
                          decorationColor: kRoomMuted,
                        ),
                      ),
                      if (creator != null && creator.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            'Añadida por $creator',
                            style: const TextStyle(
                              color: kRoomMuted,
                              fontSize: AppType.sizeCaption,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onOpenMenu,
            behavior: HitTestBehavior.opaque,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: RoomChip(
                label: task.stateLabel,
                background: chip.background,
                foreground: chip.foreground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

({Color background, Color foreground}) _chipColors(String code) {
  switch (code) {
    case 'IN_PROGRESS':
      return (background: kRoomBreakSoft, foreground: kRoomBreakInk);
    case 'COMPLETED':
      return (background: kRoomStudySoft, foreground: kRoomStudy);
    case 'PENDING':
    default:
      return (background: kRoomTrack, foreground: kRoomMuted);
  }
}

class _SheetAction extends StatelessWidget {
  const _SheetAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = kRoomInk,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: kRoomTrack,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 14),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: AppType.weightSemiBold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
    final chip = _chipColors(code);
    final Color accent = code == 'PENDING' ? kRoomInk : chip.foreground;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
          decoration: BoxDecoration(
            color: selected ? chip.background : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? accent : kRoomLine,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  color: selected ? accent : kRoomInk,
                  fontWeight: AppType.weightSemiBold,
                ),
              ),
              const Spacer(),
              if (selected) Icon(LucideIcons.check, color: accent, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
