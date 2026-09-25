import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import '../../core/app_icons.dart';

import '../../core/theme.dart';
import '../../data/services/sound_service.dart';
import '../../logic/pomodoro_provider.dart';
import '../room/room_widgets.dart';

const _durationPresets = [5 * 60, 15 * 60, 30 * 60];

const _kMinCustomMinutes = 1;
const _kMaxCustomMinutes = 180;

/// Colores, textos e icono de cada modo del reloj.
class _ModeStyle {
  const _ModeStyle({
    required this.mode,
    required this.accent,
    required this.soft,
    required this.ink,
    required this.label,
    required this.icon,
  });

  final String mode;
  final Color accent;
  final Color soft;
  final Color ink;
  final String label;
  final IconData icon;

  static const focus = _ModeStyle(
    mode: kModeFocus,
    accent: kRoomStudy,
    soft: kRoomStudySoft,
    ink: kRoomStudy,
    label: 'Estudio',
    icon: AppIcons.bookOpen,
  );
  static const shortBreak = _ModeStyle(
    mode: kModeShortBreak,
    accent: kRoomBreak,
    soft: kRoomBreakSoft,
    ink: kRoomBreakInk,
    label: 'Descanso corto',
    icon: AppIcons.coffee,
  );
  static const longBreak = _ModeStyle(
    mode: kModeLongBreak,
    accent: kRoomLong,
    soft: kRoomLongSoft,
    ink: kRoomLong,
    label: 'Descanso largo',
    icon: AppIcons.moon,
  );

  static const all = [focus, shortBreak, longBreak];

  static _ModeStyle of(String mode) => switch (mode) {
    kModeShortBreak => shortBreak,
    kModeLongBreak => longBreak,
    _ => focus,
  };
}

String _formatTime(int totalSeconds) {
  final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
  final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

String _statusText(PomodoroState state) {
  if (state.isFinished) {
    return state.isBreak
        ? 'Buen trabajo, tu descanso está listo'
        : 'Descanso terminado. ¡A estudiar!';
  }
  if (!state.isRunning) {
    return state.isBreak ? 'Descanso en pausa' : 'En pausa';
  }
  return switch (state.mode) {
    kModeShortBreak => 'Estás en descanso',
    kModeLongBreak => 'Descanso largo, te lo ganaste',
    _ => 'Concentrándote',
  };
}

/// Explica qué hará la flecha de adelantar.
String _nextHint(PomodoroState state) {
  if (state.isBreak) {
    return 'Siguiente: volver a estudiar';
  }
  final isLong = (state.completedFocus + 1) % kFocusRoundsBeforeLong == 0;
  return isLong
      ? 'Siguiente: descanso largo · ${kLongBreakSeconds ~/ 60} min'
      : 'Siguiente: descanso corto · ${kShortBreakSeconds ~/ 60} min';
}

/// Rondas de estudio hechas dentro del ciclo actual (0..4).
int _roundsDone(PomodoroState state) {
  final completed = state.completedFocus;
  if (state.isBreak) {
    return completed == 0 ? 0 : (completed - 1) % kFocusRoundsBeforeLong + 1;
  }
  return completed % kFocusRoundsBeforeLong;
}

/// Reloj Pomodoro de la sala. Con [showTitle] dibuja su propio encabezado
/// (para usarlo dentro de una tarjeta); sin él, solo el contenido.
class PomodoroTimer extends ConsumerWidget {
  const PomodoroTimer({super.key, this.showTitle = true});

  final bool showTitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pomodoroProvider);
    final notifier = ref.read(pomodoroProvider.notifier);
    final style = _ModeStyle.of(state.mode);
    // Los descansos tienen duración fija: no se envía duración al servidor.
    final int? focusDuration = state.isBreak ? null : state.totalSeconds;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final bool bounded =
            constraints.hasBoundedHeight && constraints.maxHeight >= 460;

        final dialSize = math.min(bounded ? 280.0 : 240.0, width);

        final List<Widget> top = [
          if (showTitle) ...[_Title(style: style), const SizedBox(height: 16)],
          _ModeSelector(
            selectedMode: state.mode,
            enabled: !state.isRunning,
            showIcons: width >= 400,
            onSelected: notifier.setMode,
          ),
          const SizedBox(height: 12),
          _Setup(state: state, style: style, onSelectDuration: notifier.reset),
        ];

        final dial = _Dial(size: dialSize, state: state, style: style);

        final List<Widget> bottom = [
          const SizedBox(height: 16),
          _Controls(
            state: state,
            style: style,
            onReset: () => notifier.reset(focusDuration),
            onToggle: () {
              if (state.isRunning) {
                notifier.pause();
              } else {
                ref.read(soundProvider.notifier).unlock();
                notifier.start(focusDuration);
              }
            },
            onSkip: () {
              ref.read(soundProvider.notifier).unlock();
              notifier.skip();
            },
          ),
          const SizedBox(height: 10),
          Text(
            _nextHint(state),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: kRoomMuted,
              fontSize: AppType.sizeLabel,
            ),
          ),
        ];

        if (bounded) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ...top,
              // El reloj se encoge si falta alto, así nunca hay scroll.
              Expanded(
                child: Center(
                  child: FittedBox(fit: BoxFit.scaleDown, child: dial),
                ),
              ),
              ...bottom,
            ],
          );
        }
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ...top,
              const SizedBox(height: 16),
              Center(child: dial),
              ...bottom,
            ],
          ),
        );
      },
    );
  }
}

class _Title extends StatelessWidget {
  const _Title({required this.style});

  final _ModeStyle style;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(AppIcons.timer, size: 20, color: style.accent),
        const SizedBox(width: 10),
        const Expanded(
          child: Text(
            'Pomodoro',
            style: TextStyle(
              color: kRoomInk,
              fontSize: AppType.sizeTitle - 2,
              fontWeight: AppType.weightBold,
            ),
          ),
        ),
      ],
    );
  }
}

/// Selector de modo: Estudio · Descanso corto · Descanso largo.
class _ModeSelector extends StatelessWidget {
  const _ModeSelector({
    required this.selectedMode,
    required this.enabled,
    required this.showIcons,
    required this.onSelected,
  });

  final String selectedMode;
  final bool enabled;
  final bool showIcons;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: kRoomTrack,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          for (final style in _ModeStyle.all)
            Expanded(child: _segment(style, style.mode == selectedMode)),
        ],
      ),
    );
  }

  Widget _segment(_ModeStyle style, bool selected) {
    final Color foreground = selected ? style.accent : kRoomMuted;
    return Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      label: style.label,
      excludeSemantics: true,
      child: Opacity(
        // Mientras corre el reloj solo se destaca el modo actual.
        opacity: enabled || selected ? 1 : 0.5,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: enabled && !selected ? () => onSelected(style.mode) : null,
          child: MouseRegion(
            cursor: enabled && !selected
                ? SystemMouseCursors.click
                : SystemMouseCursors.basic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              constraints: const BoxConstraints(minHeight: 48),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              decoration: BoxDecoration(
                color: selected ? kRoomSurface : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                boxShadow: selected
                    ? const [
                        BoxShadow(
                          color: Color(0x1A1C2321),
                          blurRadius: 2,
                          offset: Offset(0, 1),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (showIcons) ...[
                    Icon(style.icon, size: 18, color: foreground),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(
                      style.label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: TextStyle(
                        color: foreground,
                        fontWeight: AppType.weightSemiBold,
                        fontSize: showIcons
                            ? AppType.sizeBody
                            : AppType.sizeLabel,
                        height: 1.15,
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

/// Zona bajo el selector: aviso si corre, info del descanso o duraciones.
class _Setup extends StatelessWidget {
  const _Setup({
    required this.state,
    required this.style,
    required this.onSelectDuration,
  });

  final PomodoroState state;
  final _ModeStyle style;
  final ValueChanged<int> onSelectDuration;

  @override
  Widget build(BuildContext context) {
    if (state.isRunning) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Text(
          'Pausa el reloj para cambiar de modo',
          textAlign: TextAlign.center,
          style: TextStyle(color: kRoomMuted, fontSize: AppType.sizeLabel),
        ),
      );
    }
    if (state.isBreak) {
      final isLong = state.isLongBreak;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: style.soft,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(style.icon, size: 20, color: style.ink),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isLong
                    ? '${kLongBreakSeconds ~/ 60} min. Tómatelos sin pensar en lo que sigue.'
                    : '${kShortBreakSeconds ~/ 60} min. Estírate, toma agua y vuelve cuando quieras.',
                style: TextStyle(
                  color: style.ink,
                  fontSize: AppType.sizeLabel,
                  fontWeight: AppType.weightSemiBold,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      );
    }
    return _DurationPills(
      selectedSeconds: state.totalSeconds,
      accent: style.accent,
      soft: style.soft,
      onSelected: onSelectDuration,
    );
  }
}

/// Anillo con mascota, tiempo y estado; debajo, los puntos de ronda.
class _Dial extends StatelessWidget {
  const _Dial({required this.size, required this.state, required this.style});

  final double size;
  final PomodoroState state;
  final _ModeStyle style;

  @override
  Widget build(BuildContext context) {
    final double progress = state.totalSeconds > 0
        ? (state.timeRemaining / state.totalSeconds).clamp(0.0, 1.0)
        : 0;
    final double crab = size * 0.34;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.none,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(end: progress),
                duration: const Duration(milliseconds: 900),
                curve: Curves.linear,
                builder: (context, value, child) => CustomPaint(
                  painter: _RingPainter(
                    progress: value,
                    color: style.accent,
                    track: kRoomRingTrack,
                    stroke: 8,
                  ),
                  child: child,
                ),
                child: Padding(
                  padding: EdgeInsets.all(size * 0.12),
                  // Si el texto no cabe (fuentes grandes), todo el interior escala.
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: SizedBox(
                      width: size * 0.76,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Mascota: cangrejo de Claude.
                          // Capa propia + 12 fps (los de la animación): el anillo
                          // y el resto no se repintan con cada cuadro del cangrejo.
                          RepaintBoundary(
                            child: SizedBox(
                              width: crab * 1.4,
                              height: crab,
                              child: FittedBox(
                                fit: BoxFit.contain,
                                child: Lottie.asset(
                                  'assets/Lottie/claude.json',
                                  repeat: true,
                                  frameRate: FrameRate.composition,
                                  width: crab * 1.4,
                                  height: crab,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _formatTime(state.timeRemaining),
                            maxLines: 1,
                            style: AppType.monoTimer(
                              color: state.isBreak ? style.accent : kRoomInk,
                              fontSize: size * 0.19,
                            ),
                          ),
                          const SizedBox(height: 4),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            child: Text(
                              _statusText(state),
                              key: ValueKey(_statusText(state)),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              style: TextStyle(
                                color: state.isFinished
                                    ? kRoomInk
                                    : state.isRunning
                                    ? style.accent
                                    : kRoomMuted,
                                fontWeight: AppType.weightSemiBold,
                                fontSize: AppType.sizeBody,
                                height: 1.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Silenciar o activar el sonido de fin de fase.
              const Positioned(top: -6, right: -6, child: _SoundToggle()),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _RoundDots(state: state, accent: style.accent),
      ],
    );
  }
}

/// Botón para activar o silenciar el sonido de fin de fase. Al activarlo suena
/// un aviso corto, para confirmar que se oye.
class _SoundToggle extends ConsumerWidget {
  const _SoundToggle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(soundProvider.select((s) => s.isEnabled));
    return RoomIconButton(
      icon: enabled ? AppIcons.volume2 : AppIcons.volumeX,
      tooltip: enabled ? 'Silenciar sonido' : 'Activar sonido',
      foreground: enabled ? kRoomMuted : kRoomDisabled,
      bordered: false,
      background: Colors.transparent,
      onPressed: () => ref.read(soundProvider.notifier).toggleSound(),
    );
  }
}

/// Puntos de progreso del ciclo: tras [kFocusRoundsBeforeLong] rondas de
/// estudio toca un descanso largo.
class _RoundDots extends StatelessWidget {
  const _RoundDots({required this.state, required this.accent});

  final PomodoroState state;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final int done = _roundsDone(state);
    final String caption = state.isBreak
        ? '$done de $kFocusRoundsBeforeLong rondas'
        : 'Ronda ${done + 1} de $kFocusRoundsBeforeLong';

    return Semantics(
      label: caption,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < kFocusRoundsBeforeLong; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < done ? accent : kRoomLine,
              ),
            ),
          const SizedBox(width: 8),
          Text(
            caption,
            style: const TextStyle(
              color: kRoomMuted,
              fontWeight: AppType.weightSemiBold,
              fontSize: AppType.sizeLabel,
            ),
          ),
        ],
      ),
    );
  }
}

/// Reiniciar · Iniciar/Pausar · Siguiente.
class _Controls extends StatelessWidget {
  const _Controls({
    required this.state,
    required this.style,
    required this.onReset,
    required this.onToggle,
    required this.onSkip,
  });

  final PomodoroState state;
  final _ModeStyle style;
  final VoidCallback onReset;
  final VoidCallback onToggle;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final bool canReset = state.timeRemaining < state.totalSeconds;
    return Row(
      children: [
        RoomIconButton(
          size: 52,
          icon: AppIcons.rotateCcw,
          tooltip: 'Reiniciar',
          onPressed: canReset ? onReset : null,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: style.accent,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: onToggle,
              icon: Icon(
                state.isRunning ? AppIcons.pause : AppIcons.play,
                size: 20,
              ),
              label: Text(
                state.isRunning
                    ? 'Pausar'
                    : state.isBreak
                    ? 'Iniciar descanso'
                    : 'Iniciar',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        RoomIconButton(
          size: 52,
          icon: AppIcons.skipForward,
          tooltip: state.isBreak ? 'Volver a estudiar' : 'Adelantar descanso',
          foreground: style.accent,
          background: style.soft,
          bordered: false,
          onPressed: onSkip,
        ),
      ],
    );
  }
}

/// Barra compacta del reloj, para mostrarlo cuando se está en otra sección.
class MiniTimerBar extends ConsumerWidget {
  const MiniTimerBar({super.key, this.onOpen});

  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pomodoroProvider);
    final notifier = ref.read(pomodoroProvider.notifier);
    final style = _ModeStyle.of(state.mode);
    final int done = _roundsDone(state);
    final String label = state.isBreak
        ? style.label
        : 'Estudio · Ronda ${done + 1} de $kFocusRoundsBeforeLong';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      decoration: BoxDecoration(
        color: kRoomSurface,
        border: Border.all(color: kRoomLine),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onOpen,
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: style.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: kRoomMuted,
                            fontSize: AppType.sizeCaption,
                            fontWeight: AppType.weightSemiBold,
                          ),
                        ),
                        Text(
                          _formatTime(state.timeRemaining),
                          style: AppType.monoTimer(
                            color: kRoomInk,
                            fontSize: 24,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          RoomIconButton(
            icon: state.isRunning ? AppIcons.pause : AppIcons.play,
            tooltip: state.isRunning ? 'Pausar' : 'Iniciar',
            onPressed: () {
              if (state.isRunning) {
                notifier.pause();
              } else {
                ref.read(soundProvider.notifier).unlock();
                notifier.start(state.isBreak ? null : state.totalSeconds);
              }
            },
          ),
          const SizedBox(width: 6),
          RoomIconButton(
            icon: AppIcons.skipForward,
            tooltip: state.isBreak ? 'Volver a estudiar' : 'Adelantar descanso',
            foreground: style.accent,
            background: style.soft,
            bordered: false,
            onPressed: notifier.skip,
          ),
        ],
      ),
    );
  }
}

/// Anillo de progreso: se vacía conforme avanza el tiempo.
class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.color,
    required this.track,
    required this.stroke,
  });

  final double progress;
  final Color color;
  final Color track;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (math.min(size.width, size.height) - stroke) / 2;
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, base..color = track);
    if (progress <= 0) return;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      base..color = color,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color || old.stroke != stroke;
}

class _DurationPills extends StatelessWidget {
  const _DurationPills({
    required this.selectedSeconds,
    required this.accent,
    required this.soft,
    required this.onSelected,
  });

  final int selectedSeconds;
  final Color accent;
  final Color soft;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final bool customSelected = !_durationPresets.contains(selectedSeconds);
    return Row(
      children: [
        for (final seconds in _durationPresets) ...[
          Expanded(
            child: _pill(
              label: '${seconds ~/ 60} min',
              selected: seconds == selectedSeconds,
              onTap: () => onSelected(seconds),
            ),
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: _pill(
            label: customSelected ? '${selectedSeconds ~/ 60} min' : 'Otro',
            selected: customSelected,
            onTap: () => _promptCustomDuration(context),
          ),
        ),
      ],
    );
  }

  Widget _pill({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? soft : kRoomSurface,
              border: Border.all(color: selected ? accent : kRoomLine),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              label,
              maxLines: 1,
              style: TextStyle(
                color: selected ? accent : kRoomMuted,
                fontWeight: AppType.weightSemiBold,
                fontSize: AppType.sizeLabel,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _promptCustomDuration(BuildContext context) async {
    final minutes = await showGeneralDialog<int>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Cerrar',
      barrierColor: Colors.black45,
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return const _CustomDurationDialog();
      },
    );

    final clamped = minutes
        ?.clamp(_kMinCustomMinutes, _kMaxCustomMinutes)
        .toInt();
    if (clamped == null) return;
    onSelected(clamped * 60);
  }
}

class _CustomDurationDialog extends StatefulWidget {
  const _CustomDurationDialog();

  @override
  State<_CustomDurationDialog> createState() => _CustomDurationDialogState();
}

class _CustomDurationDialogState extends State<_CustomDurationDialog> {
  final _controller = TextEditingController();
  final _editFormKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_editFormKey.currentState!.validate()) return;
    final value = int.tryParse(_controller.text.trim());
    if (value == null) return;
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Material(
      type: MaterialType.transparency,
      child: SafeArea(
        child: Center(
          child: AnimatedPadding(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              bottom: bottomInset > 0 ? (bottomInset * 0.35) : 0,
            ),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 340),
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              decoration: BoxDecoration(
                color: kRoomSurface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Duración personalizada',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: kRoomInk,
                      fontWeight: AppType.weightSemiBold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Form(
                    key: _editFormKey,
                    child: TextFormField(
                      controller: _controller,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      maxLength: 3,
                      maxLengthEnforcement: MaxLengthEnforcement.enforced,
                      scrollPadding: EdgeInsets.zero,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(3),
                      ],
                      style: const TextStyle(color: kRoomInk),
                      decoration: const InputDecoration(
                        labelText: 'Minutos',
                        hintText: 'ej. 30',
                        labelStyle: TextStyle(color: kRoomMuted),
                        counterText: '',
                      ),
                      validator: (value) {
                        final text = value?.trim() ?? '';
                        if (text.isEmpty) {
                          return 'Ups, olvidaste poner los minutos.';
                        }
                        final parsed = int.tryParse(text);
                        if (parsed == null ||
                            parsed < _kMinCustomMinutes ||
                            parsed > _kMaxCustomMinutes) {
                          return 'Elige un tiempo de $_kMinCustomMinutes a $_kMaxCustomMinutes minutos.';
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) => _submit(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          foregroundColor: kRoomMuted,
                        ),
                        child: const Text('Cancelar'),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: _submit,
                        style: TextButton.styleFrom(
                          foregroundColor: kRoomStudy,
                        ),
                        child: const Text(
                          'Aceptar',
                          style: TextStyle(fontWeight: AppType.weightSemiBold),
                        ),
                      ),
                    ],
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
