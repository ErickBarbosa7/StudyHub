import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';

import '../../core/theme.dart';
import '../../data/services/sound_service.dart';
import '../../logic/pomodoro_provider.dart';
import 'help_icon.dart';

const _durationPresets = [5 * 60, 10 * 60, 15 * 60, 30 * 60];

const _kMinCustomMinutes = 1;
const _kMaxCustomMinutes = 180;

class PomodoroTimer extends ConsumerWidget {
  const PomodoroTimer({super.key});

  String _formatTime(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pomodoroProvider);
    final soundState = ref.watch(soundProvider);
    final bool finished = state.isFinished;
    final bool compact = MediaQuery.sizeOf(context).width < 600;

    ref.listen<PomodoroState>(pomodoroProvider, (previous, next) {
      if (next.isFinished && !(previous?.isFinished ?? false)) {
        ref.read(soundProvider.notifier).playPomodoroFinishedSound();

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('¡Tiempo completado! Tómate un descanso.'),
            ),
          );
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
          LayoutBuilder(
            builder: (context, constraints) {
              final bool layoutCompact = constraints.maxWidth < 310;
              return Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(layoutCompact ? 8 : 10),
                    decoration: BoxDecoration(
                      color: kColorSageSoft,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.timer_rounded,
                      color: kColorDeepSage,
                      size: compact ? 20 : 24,
                    ),
                  ),
                  SizedBox(width: layoutCompact ? 12 : 16),
                  Expanded(
                    child: Text(
                      'Pomodoro',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: kColorInk,
                        fontWeight: AppType.weightSemiBold,
                        fontSize: compact ? AppType.sizeTitle : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  HelpIcon(
                    title: 'Temporizador Pomodoro',
                    description:
                        'Cronómetro compartido para que todo el equipo se concentre al mismo tiempo. '
                        'Elige una duración, inicia, y todos verán el mismo conteo. '
                        'Al terminar, sonará una campana para que descanses.',
                    compact: compact,
                  ),
                  const SizedBox(width: 4),
                  if (!compact)
                    IconButton(
                      icon: Icon(
                        soundState.isEnabled
                            ? Icons.volume_up_rounded
                            : Icons.volume_off_rounded,
                        color: soundState.isEnabled
                            ? kColorDeepSage
                            : kColorTextSecondary,
                        size: 20,
                      ),
                      tooltip: soundState.isEnabled
                          ? 'Sonido activado'
                          : 'Sonido silenciado',
                      onPressed: () =>
                          ref.read(soundProvider.notifier).toggleSound(),
                      visualDensity: VisualDensity.compact,
                      splashRadius: 18,
                    ),
                  if (compact)
                    GestureDetector(
                      onTap: () =>
                          ref.read(soundProvider.notifier).toggleSound(),
                      child: Icon(
                        soundState.isEnabled
                            ? Icons.volume_up_rounded
                            : Icons.volume_off_rounded,
                        color: soundState.isEnabled
                            ? kColorDeepSage
                            : kColorTextSecondary,
                        size: 20,
                      ),
                    ),
                  const SizedBox(width: 4),
                  _StatusPill(isRunning: state.isRunning, compact: compact),
                ],
              );
            },
          ),
          SizedBox(height: compact ? 16 : 24),

          if (!state.isRunning) ...[
            _DurationPills(
              selectedSeconds: state.totalSeconds,
              onSelected: (seconds) =>
                  ref.read(pomodoroProvider.notifier).reset(seconds),
            ),
            SizedBox(height: compact ? 16 : 24),
          ],

          Container(
            padding: EdgeInsets.only(
              top: compact ? 10 : 16,
              bottom: compact ? 14 : 24,
              left: compact ? 14 : 24,
              right: compact ? 14 : 24,
            ),
            decoration: BoxDecoration(
              color: state.isRunning
                  ? kColorSageSoft
                  : finished
                  ? kColorGoldSoft
                  : kColorPaper,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: compact ? 140 : 224,
                  height: compact ? 100 : 150,
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: Lottie.asset(
                      'assets/Lottie/claude.json',
                      repeat: true,
                      width: compact ? 140 : 224,
                      height: compact ? 100 : 150,
                    ),
                  ),
                ),

                SizedBox(height: compact ? 2 : 8),

                Text(
                  _formatTime(state.timeRemaining),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppType.monoTimer(
                    color: finished ? kColorDeepSage : kColorInk,
                    fontSize: compact
                        ? AppType.sizeTimerCompact
                        : AppType.sizeTimerLarge,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 4),

                SizedBox(
                  height: compact ? 24 : 32,
                  child: Center(
                    child: finished
                        ? Text(
                            '¡Tiempo completado!',
                            style: AppType.secondaryItalic(
                              color: kColorInk,
                              size: compact
                                  ? AppType.sizeBody
                                  : AppType.sizeBodyMedium,
                            ).copyWith(fontWeight: AppType.weightSemiBold),
                            textAlign: TextAlign.center,
                          )
                        : state.isRunning
                        ? Transform.scale(
                            scale: 1.5,
                            child: Lottie.asset(
                              'assets/Lottie/Loading.json',
                              repeat: true,
                            ),
                          )
                        : Text(
                            'En pausa',
                            style: AppType.secondaryItalic(
                              color: kColorTextSecondary,
                              size: compact
                                  ? AppType.sizeBody
                                  : AppType.sizeBodyMedium,
                            ).copyWith(fontWeight: AppType.weightSemiBold),
                            textAlign: TextAlign.center,
                          ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: compact ? 16 : 24),

          if (state.isRunning)
            SizedBox(
              height: compact ? 48 : 56,
              child: ElevatedButton.icon(
                onPressed: () => ref.read(pomodoroProvider.notifier).pause(),
                icon: const Icon(Icons.pause_rounded, size: 24),
                label: const Text('Pausar'),
              ),
            )
          else
            SizedBox(
              height: compact ? 48 : 56,
              child: ElevatedButton.icon(
                onPressed: () {
                  ref.read(soundProvider.notifier).unlock();
                  ref.read(pomodoroProvider.notifier).start(state.totalSeconds);
                },
                icon: const Icon(Icons.play_arrow_rounded, size: 24),
                label: const Text('Iniciar'),
              ),
            ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () =>
                ref.read(pomodoroProvider.notifier).reset(state.totalSeconds),
            icon: const Icon(Icons.restart_alt_rounded, size: 20),
            label: const Text('Reiniciar'),
            style: TextButton.styleFrom(
              foregroundColor: kColorTextSecondary,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      ),
    );
  }
}

class _DurationPills extends StatelessWidget {
  const _DurationPills({
    required this.selectedSeconds,
    required this.onSelected,
  });

  final int selectedSeconds;
  final ValueChanged<int> onSelected;

  String _formatMinutes(int seconds) => '${seconds ~/ 60} min';

  @override
  Widget build(BuildContext context) {
    final bool compact = MediaQuery.sizeOf(context).width < 600;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Duración',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: kColorTextSecondary,
            fontWeight: AppType.weightSemiBold,
            fontSize: compact ? AppType.sizeCaption : null,
          ),
        ),
        SizedBox(height: compact ? 6 : 10),
        Wrap(
          spacing: compact ? 6 : 8,
          runSpacing: compact ? 6 : 8,
          children: [
            ..._durationPresets.map((seconds) {
              final bool selected = seconds == selectedSeconds;
              return GestureDetector(
                onTap: () => onSelected(seconds),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 12 : 16,
                    vertical: compact ? 8 : 10,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? kColorDeepSage : kColorSageSoft,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _formatMinutes(seconds),
                    style: TextStyle(
                      color: selected ? kColorPaper : kColorTextSecondary,
                      fontWeight: AppType.weightSemiBold,
                      fontSize: compact
                          ? AppType.sizeCaption
                          : AppType.sizeLabel,
                    ),
                  ),
                ),
              );
            }),
            _buildCustomPill(context),
          ],
        ),
      ],
    );
  }

  Widget _buildCustomPill(BuildContext context) {
    final bool selected = !_durationPresets.contains(selectedSeconds);
    final bool compact = MediaQuery.sizeOf(context).width < 600;
    return GestureDetector(
      onTap: () => _promptCustomDuration(context),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 12 : 16,
          vertical: compact ? 8 : 10,
        ),
        decoration: BoxDecoration(
          color: selected ? kColorDeepSage : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? kColorDeepSage : kColorBorder,
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.tune_rounded,
              size: compact ? 14 : 16,
              color: selected ? kColorPaper : kColorTextSecondary,
            ),
            SizedBox(width: compact ? 4 : 6),
            Text(
              'Personalizado',
              style: TextStyle(
                color: selected ? kColorPaper : kColorTextSecondary,
                fontWeight: AppType.weightSemiBold,
                fontSize: compact ? AppType.sizeCaption : AppType.sizeLabel,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _promptCustomDuration(BuildContext context) async {
    final controller = TextEditingController();
    final compact = MediaQuery.sizeOf(context).width < 600;

    final minutes = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: kColorPaper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (sheetContext) {
        final bottomInset = MediaQuery.viewInsetsOf(sheetContext).bottom;
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(bottom: bottomInset),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                compact ? 24 : 32,
                compact ? 20 : 28,
                compact ? 24 : 32,
                16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Duración personalizada',
                    textAlign: TextAlign.center,
                    style: Theme.of(sheetContext).textTheme.titleLarge
                        ?.copyWith(
                          color: kColorInk,
                          fontWeight: AppType.weightSemiBold,
                        ),
                  ),
                  SizedBox(height: compact ? 16 : 24),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(3),
                    ],
                    style: const TextStyle(color: kColorInk),
                    decoration: const InputDecoration(
                      labelText: 'Minutos',
                      hintText: 'ej. 20',
                      labelStyle: TextStyle(color: kColorTextSecondary),
                    ),
                    onSubmitted: (_) {
                      final value = int.tryParse(controller.text.trim());
                      if (value == null) return;
                      Navigator.of(sheetContext).pop(value);
                    },
                  ),
                  SizedBox(height: compact ? 12 : 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        style: TextButton.styleFrom(
                          foregroundColor: kColorTextSecondary,
                        ),
                        child: const Text('Cancelar'),
                      ),
                      TextButton(
                        onPressed: () {
                          final value = int.tryParse(controller.text.trim());
                          if (value == null) return;
                          Navigator.of(sheetContext).pop(value);
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: kColorDeepSage,
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
        );
      },
    );

    final clamped = minutes
        ?.clamp(_kMinCustomMinutes, _kMaxCustomMinutes)
        .toInt();
    controller.dispose();
    if (clamped == null) return;
    onSelected(clamped * 60);
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.isRunning, this.compact = false});

  final bool isRunning;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isRunning ? kColorSageSoft : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isRunning)
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.symmetric(vertical: 5),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: kColorDeepSage,
              ),
            )
          else
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.symmetric(vertical: 5),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: kColorTextSecondary,
              ),
            ),
          if (!compact) ...[
            const SizedBox(width: 6),
            Text(
              isRunning ? 'Activo' : 'En pausa',
              style: TextStyle(
                color: isRunning ? kColorInk : kColorTextSecondary,
                fontWeight: AppType.weightSemiBold,
                fontSize: AppType.sizeCaption,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
