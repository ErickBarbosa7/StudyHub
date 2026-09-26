import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_icons.dart';

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

  // ── Arrastrar a la papelera ───────────────────────────────
  //
  // ReorderableListView maneja el arrastre por dentro y no expone la posición
  // del dedo. Pero los eventos de puntero siguen llegando a los ancestros del
  // asa aunque el dedo salga de ella, así que un Listener sobre la lista basta
  // para saber si el dedo está sobre la papelera.
  final _trashKey = GlobalKey();
  Task? _draggedTask;
  bool _overTrash = false;
  bool _releasedOverTrash = false;

  /// Al soltar sobre la papelera no se debe reordenar: se pregunta si eliminar.
  bool _skipNextReorder = false;

  bool get _dragging => _draggedTask != null;

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

  void _onReorderStart(int index, List<Task> tasks) {
    _skipNextReorder = false;
    _releasedOverTrash = false;
    HapticFeedback.selectionClick();
    setState(() {
      _draggedTask = tasks[index];
      _overTrash = false;
    });
  }

  void _onReorderEnd() {
    final task = _draggedTask;
    final delete = _releasedOverTrash;
    _skipNextReorder = delete;
    _releasedOverTrash = false;
    setState(() {
      _draggedTask = null;
      _overTrash = false;
    });
    if (delete && task != null && mounted) _confirmDelete(task);
  }

  void _onReorderItem(int oldIndex, int newIndex) {
    if (_skipNextReorder) {
      _skipNextReorder = false;
      return;
    }
    ref.read(taskProvider.notifier).reorderTasks(oldIndex, newIndex);
  }

  void _onPointerMove(PointerEvent event) {
    if (!_dragging) return;
    final over = _isOverTrash(event.position);
    if (over == _overTrash) return;
    if (over) HapticFeedback.selectionClick();
    setState(() => _overTrash = over);
  }

  void _onPointerUp(PointerEvent event) {
    if (!_dragging) return;
    _releasedOverTrash = _isOverTrash(event.position);
  }

  bool _isOverTrash(Offset globalPosition) {
    final box = _trashKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.attached) return false;
    final rect = box.localToGlobal(Offset.zero) & box.size;
    // Margen para no exigir puntería exacta con el dedo.
    return rect.inflate(16).contains(globalPosition);
  }

  void _showTaskActions(Task task) {
    final c = context.colors;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: c.surface,
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
                style: TextStyle(
                  color: c.ink,
                  fontSize: AppType.sizeTitle - 2,
                  fontWeight: AppType.weightBold,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Estado',
                style: TextStyle(
                  color: c.muted,
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
                icon: AppIcons.pencil,
                label: 'Editar nombre',
                color: c.ink,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _editTask(task);
                },
              ),
              const SizedBox(height: 10),
              _SheetAction(
                icon: AppIcons.trash2,
                label: 'Eliminar esta tarea',
                color: c.error,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _confirmDelete(task);
                },
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(sheetContext).pop(),
                style: TextButton.styleFrom(
                  foregroundColor: c.muted,
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
    final c = context.colors;
    final controller = TextEditingController(text: task.title);
    final editFormKey = GlobalKey<FormState>();

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Editar tarea',
          style: TextStyle(color: c.ink, fontWeight: AppType.weightSemiBold),
        ),
        content: Form(
          key: editFormKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            maxLength: _kMaxTaskLength,
            maxLengthEnforcement: MaxLengthEnforcement.enforced,
            textCapitalization: TextCapitalization.sentences,
            style: TextStyle(color: c.ink),
            decoration: InputDecoration(
              labelText: 'Nombre de la tarea',
              labelStyle: TextStyle(color: c.muted),
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
            style: TextButton.styleFrom(foregroundColor: c.muted),
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
            style: TextButton.styleFrom(foregroundColor: c.study),
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
    final c = context.colors;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          '¿Eliminar tarea?',
          style: TextStyle(color: c.ink, fontWeight: AppType.weightSemiBold),
        ),
        content: Text(
          '"${task.title}" se eliminará permanentemente. Esta acción no se puede deshacer.',
          style: TextStyle(color: c.muted, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            style: TextButton.styleFrom(foregroundColor: c.muted),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              ref.read(taskProvider.notifier).deleteTask(task.taskId);
              Navigator.of(dialogContext).pop();
            },
            style: TextButton.styleFrom(foregroundColor: c.error),
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
    final c = context.colors;
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
        : Listener(
            onPointerMove: _onPointerMove,
            onPointerUp: _onPointerUp,
            child: Stack(
              children: [
                Positioned.fill(
                  child: ReorderableListView.builder(
                    buildDefaultDragHandles: false,
                    itemCount: tasks.length,
                    onReorderStart: (i) => _onReorderStart(i, tasks),
                    onReorderEnd: (_) => _onReorderEnd(),
                    onReorderItem: _onReorderItem,
                    proxyDecorator: (child, index, animation) => Material(
                      color: c.surface,
                      elevation: 4,
                      borderRadius: BorderRadius.circular(12),
                      child: child,
                    ),
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return _TaskTile(
                        key: ValueKey(task.taskId),
                        index: index,
                        task: task,
                        showCreator: !solo,
                        onToggleComplete: () => _toggleComplete(task),
                        onOpenMenu: () => _showTaskActions(task),
                      );
                    },
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _TrashDropZone(
                    key: _trashKey,
                    visible: _dragging,
                    active: _overTrash,
                  ),
                ),
              ],
            ),
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
                  Icon(
                    AppIcons.listChecks,
                    size: 20,
                    color: c.study,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Tareas',
                      style: TextStyle(
                        color: c.ink,
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
                    style: TextStyle(
                      color: c.muted,
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
                      style: TextStyle(color: c.ink, fontSize: 15),
                      decoration: InputDecoration(
                        hintText:
                            'Nueva tarea, por ejemplo: leer el capítulo 2',
                        counterText: '',
                        hintStyle: TextStyle(color: c.muted),
                        filled: true,
                        fillColor: c.surface,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        border: _fieldBorder(c.line),
                        enabledBorder: _fieldBorder(c.line),
                        focusedBorder: _fieldBorder(c.study, width: 1.5),
                        errorBorder: _fieldBorder(c.error),
                        focusedErrorBorder: _fieldBorder(
                          c.error,
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
                    icon: AppIcons.plus,
                    tooltip: 'Agregar tarea',
                    foreground: c.study,
                    background: c.studySoft,
                    bordered: false,
                    iconOffset: const Offset(0, 3),
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

/// Papelera que aparece al arrastrar una tarea. Solo indica y resalta: quien
/// decide si se suelta encima es `_TaskListState`, que conoce el dedo.
class _TrashDropZone extends StatelessWidget {
  const _TrashDropZone({super.key, required this.visible, required this.active});

  final bool visible;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final Color fg = active ? c.onAccent : c.error;

    return IgnorePointer(
      child: ExcludeSemantics(
        child: AnimatedSlide(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          offset: visible ? Offset.zero : const Offset(0, 1.2),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 150),
            opacity: visible ? 1 : 0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              height: 56,
              decoration: BoxDecoration(
                color: active ? c.error : c.errorSoft,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: active ? c.error : c.errorLine),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedScale(
                    duration: const Duration(milliseconds: 150),
                    scale: active ? 1.2 : 1,
                    child: Icon(AppIcons.trash2, size: 20, color: fg),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      active ? 'Suelta para eliminar' : 'Arrastra aquí para eliminar',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: fg,
                        fontSize: AppType.sizeBody,
                        fontWeight: AppType.weightSemiBold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: value.clamp(0.0, 1.0)),
        duration: const Duration(milliseconds: 300),
        builder: (context, v, _) => LinearProgressIndicator(
          value: v,
          minHeight: 6,
          backgroundColor: c.track,
          valueColor: AlwaysStoppedAnimation(c.study),
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
    final c = context.colors;
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
                  color: c.studySoft,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  AppIcons.listChecks,
                  size: 26,
                  color: c.study,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Anota lo que quieres lograr',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: c.ink,
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
                style: TextStyle(
                  color: c.muted,
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
    super.key,
    required this.index,
    required this.task,
    required this.showCreator,
    required this.onToggleComplete,
    required this.onOpenMenu,
  });

  final int index;
  final Task task;
  final bool showCreator;
  final VoidCallback onToggleComplete;
  final VoidCallback onOpenMenu;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bool done = task.stateCode == 'COMPLETED';
    final chip = _chipColors(task.stateCode, c);
    final creator = showCreator ? task.creatorName : null;

    return Container(
      constraints: const BoxConstraints(minHeight: 60),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.track)),
      ),
      child: Row(
        children: [
          // Asa de arrastre para reordenar.
          ReorderableDragStartListener(
            index: index,
            child: MouseRegion(
              cursor: SystemMouseCursors.grab,
              child: SizedBox(
                width: 32,
                height: 44,
                child: Icon(
                  AppIcons.gripVertical,
                  size: 18,
                  color: c.disabled,
                ),
              ),
            ),
          ),
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
                        color: done ? c.study : c.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: done ? c.study : c.disabled,
                          width: 2,
                        ),
                      ),
                      child: done
                          ? Icon(
                              AppIcons.check,
                              size: 15,
                              color: c.onAccent,
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
                          color: done ? c.muted : c.ink,
                          fontSize: 15,
                          height: 1.3,
                          fontWeight: done
                              ? AppType.weightRegular
                              : AppType.weightSemiBold,
                          decoration: done ? TextDecoration.lineThrough : null,
                          decorationColor: c.muted,
                        ),
                      ),
                      if (creator != null && creator.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            'Añadida por $creator',
                            style: TextStyle(
                              color: c.muted,
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

({Color background, Color foreground}) _chipColors(String code, AppColors c) {
  switch (code) {
    case 'IN_PROGRESS':
      return (background: c.restSoft, foreground: c.restInk);
    case 'COMPLETED':
      return (background: c.studySoft, foreground: c.study);
    case 'PENDING':
    default:
      return (background: c.track, foreground: c.muted);
  }
}

class _SheetAction extends StatelessWidget {
  const _SheetAction({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.track,
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
    final c = context.colors;
    final chip = _chipColors(code, c);
    final Color accent = code == 'PENDING' ? c.ink : chip.foreground;
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
              color: selected ? accent : c.line,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  color: selected ? accent : c.ink,
                  fontWeight: AppType.weightSemiBold,
                ),
              ),
              const Spacer(),
              if (selected) Icon(AppIcons.check, color: accent, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
