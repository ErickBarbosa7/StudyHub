import "package:shared_preferences/shared_preferences.dart";
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../data/models/task_model.dart';
import '../../logic/task_provider.dart';
import 'help_icon.dart';

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
  bool _isExpanded = true;
  bool _isFirstLoad = true;
  static const _prefsKey = 'tasks_expanded';

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        if (prefs.containsKey(_prefsKey)) {
          _isExpanded = prefs.getBool(_prefsKey) ?? true;
        }
        _isFirstLoad = false;
      });
    }
  }

  Future<void> _toggleExpanded() async {
    setState(() {
      _isExpanded = !_isExpanded;
      _isFirstLoad = false;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, _isExpanded);
  }

  // Límite de caracteres centralizado
  static const int maxTaskLength = 100;

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
                task.title,
                textAlign: TextAlign.center,
                style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(
                      color: kColorInk,
                      fontWeight: AppType.weightSemiBold,
                    ),
              ),
              const SizedBox(height: 28),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _editTask(task);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: kColorSageSoft,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.edit_rounded, color: kColorDeepSage, size: 20),
                        const SizedBox(width: 14),
                        Text(
                          'Editar nombre',
                          style: TextStyle(
                            color: kColorInk,
                            fontWeight: AppType.weightSemiBold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Cambiar estado',
                style: Theme.of(sheetContext).textTheme.labelLarge?.copyWith(
                      color: kColorTextSecondary,
                      fontWeight: AppType.weightSemiBold,
                    ),
              ),
              const SizedBox(height: 12),
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
              const SizedBox(height: 20),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _confirmDelete(task);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: kColorError.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded, color: kColorError, size: 20),
                        const SizedBox(width: 14),
                        Text(
                          'Eliminar esta tarea',
                          style: TextStyle(
                            color: kColorError,
                            fontWeight: AppType.weightSemiBold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
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

  void _editTask(Task task) {
    final controller = TextEditingController(text: task.title);
    final editFormKey = GlobalKey<FormState>();

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: kColorPaper,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Editar tarea',
          style: TextStyle(
            color: kColorInk,
            fontWeight: AppType.weightSemiBold,
          ),
        ),
        content: Form(
          key: editFormKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            
            // --- PROTECCIÓN EN EDICIÓN ---
            maxLength: maxTaskLength,
            maxLengthEnforcement: MaxLengthEnforcement.enforced,
            
            textCapitalization: TextCapitalization.sentences,
            style: const TextStyle(color: kColorInk),
            decoration: const InputDecoration(
              labelText: 'Nombre de la tarea',
              labelStyle: TextStyle(color: kColorTextSecondary),
              counterText: '', // Oculta el contador aquí para mantener el diseño limpio
            ),
            validator: (value) {
              final text = value?.trim() ?? '';
              if (text.isEmpty) return 'Requerido';
              if (text.length > maxTaskLength) return 'Excede el límite';
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            style: TextButton.styleFrom(foregroundColor: kColorTextSecondary),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              if (!editFormKey.currentState!.validate()) return;
              ref.read(taskProvider.notifier).editTask(task.taskId, controller.text);
              Navigator.of(dialogContext).pop();
            },
            style: TextButton.styleFrom(foregroundColor: kColorDeepSage),
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
        backgroundColor: kColorPaper,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          '¿Eliminar tarea?',
          style: TextStyle(
            color: kColorInk,
            fontWeight: AppType.weightSemiBold,
          ),
        ),
        content: Text(
          '"${task.title}" se eliminará permanentemente. Esta acción no se puede deshacer.',
          style: AppType.secondaryItalic(color: kColorInk),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            style: TextButton.styleFrom(foregroundColor: kColorTextSecondary),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              ref.read(taskProvider.notifier).deleteTask(task.taskId);
              Navigator.of(dialogContext).pop();
            },
            style: TextButton.styleFrom(foregroundColor: kColorError),
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
    final bool compact = MediaQuery.sizeOf(context).width < 600;

    ref.listen<TaskState>(taskProvider, (previous, next) {
      if (next.error != null && next.error != previous?.error) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(next.error!)),
          );
          ref.read(taskProvider.notifier).clearError();
        });
      }
    });

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
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: _toggleExpanded,
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(compact ? 8 : 10),
                    decoration: BoxDecoration(
                      color: kColorGoldSoft,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.checklist_rounded,
                      color: kColorGold,
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
                  HelpIcon(
                    title: 'Tareas colaborativas',
                    description:
                        'Lista de tareas que todos pueden ver y actualizar en tiempo real. '
                        'Agrega tareas, márcalas como pendientes, en progreso o completadas. '
                        'Todo se sincroniza automáticamente entre todos los miembros de la sala.',
                    compact: compact,
                  ),
                  const SizedBox(width: 8),
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
                  const SizedBox(width: 8),
                  Icon(
                    _isExpanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: kColorTextSecondary,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: _isFirstLoad ? Duration.zero : const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: !_isExpanded
                ? const SizedBox(width: double.infinity)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
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
                                
                                maxLength: maxTaskLength,
                                maxLengthEnforcement: MaxLengthEnforcement.enforced,
                                
                                scrollPadding: const EdgeInsets.only(bottom: 60), 
                                
                                style: const TextStyle(color: kColorInk),
                                decoration: InputDecoration(
                                  labelText: 'Nueva tarea',
                                  hintText: 'ej. Terminar ejercicios',
                                  
                                  counterText: '', 
                                  helperText: ' ', 
                                  
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
                                    borderSide: const BorderSide(color: kColorErrorBorder, width: 1.5),
                                  ),
                                ),
                                validator: (value) {
                                  final text = value?.trim() ?? '';
                                  if (text.isEmpty) return 'Requerido';
                                  if (text.length > maxTaskLength) return 'Excede el límite';
                                  return null;
                                },
                                onFieldSubmitted: (_) => _addTask(),
                              ),
                            ),
                            SizedBox(width: compact ? 8 : 12),
                            
                            Padding(
                              padding: const EdgeInsets.only(bottom: 22.0), 
                              child: SizedBox(
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
                              onOpenMenu: () => _showTaskActions(task),
                            )),
                    ],
                  ),
          ),
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
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: onToggleComplete,
                behavior: HitTestBehavior.opaque,
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: done ? _getStateColor(task.stateCode) : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: done ? _getStateColor(task.stateCode) : (task.stateCode == 'IN_PROGRESS' ? _getStateColor(task.stateCode) : kColorBorder),
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
          ),
          Expanded(
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
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
          ),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: onOpenMenu,
              behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: pill.background,
                borderRadius: BorderRadius.circular(12),
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
          ),
        ],
      ),
    );
  }

  ({Color background, Color foreground}) _pillColors(String code) {
    final color = _getStateColor(code);
    return (
      background: color.withValues(alpha: 0.1),
      foreground: color,
    );
  }
}

Color _getStateColor(String code) {
  switch (code) {
    case 'IN_PROGRESS':
      return kColorStateInProgress;
    case 'COMPLETED':
      return kColorStateDone;
    case 'PENDING':
    default:
      return kColorStatePending;
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
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: selected ? _getStateColor(code).withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? _getStateColor(code) : kColorBorder,
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
                        : Icons.radio_button_unchecked_rounded,
                color: selected ? _getStateColor(code) : kColorTextSecondary,
              ),
              const SizedBox(width: 14),
              Text(
                label,
                style: TextStyle(
                  color: selected ? _getStateColor(code) : kColorInk,
                  fontWeight: AppType.weightSemiBold,
                ),
              ),
              const Spacer(),
              if (selected)
                Icon(Icons.check_rounded, color: _getStateColor(code), size: 20),
            ],
          ),
        ),
      ),
      ),
    );
  }
}