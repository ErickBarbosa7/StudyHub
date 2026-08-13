import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../logic/pomodoro_provider.dart';

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

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: kColorSurfaceWhite,
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: kColorOlive.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.timer_rounded,
                  color: kColorDarkGreen,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Pomodoro',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: kColorOffBlack,
                        fontWeight: AppType.weightSemiBold,
                      ),
                ),
              ),
              _StatusPill(isRunning: state.isRunning),
            ],
          ),
          const SizedBox(height: 24),

          if (!state.isRunning) ...[
            _DurationPills(
              selectedSeconds: state.totalSeconds,
              onSelected: (seconds) =>
                  ref.read(pomodoroProvider.notifier).reset(seconds),
            ),
            const SizedBox(height: 24),
          ],

          Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: state.isRunning
                  ? kColorOlive.withValues(alpha: 0.3)
                  : kColorSurfaceSoft,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                Text(
                  _formatTime(state.timeRemaining),
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        color: kColorDarkGreen,
                        fontWeight: AppType.weightSemiBold,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  state.isRunning ? 'En progreso' : 'En pausa',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: state.isRunning
                            ? kColorDarkGreen
                            : kColorTextSecondary,
                        fontWeight: AppType.weightSemiBold,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          if (state.isRunning)
            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () => ref.read(pomodoroProvider.notifier).pause(),
                icon: const Icon(Icons.pause_rounded, size: 24),
                label: const Text('Pausar'),
              ),
            )
          else
            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () => ref
                    .read(pomodoroProvider.notifier)
                    .start(state.totalSeconds),
                icon: const Icon(Icons.play_arrow_rounded, size: 24),
                label: const Text('Iniciar'),
              ),
            ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => ref
                .read(pomodoroProvider.notifier)
                .reset(state.totalSeconds),
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
  const _DurationPills({required this.selectedSeconds, required this.onSelected});

  final int selectedSeconds;
  final ValueChanged<int> onSelected;

  String _formatMinutes(int seconds) => '${seconds ~/ 60} min';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Duración',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: kColorTextSecondary,
                fontWeight: AppType.weightSemiBold,
              ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ..._durationPresets.map((seconds) {              final bool selected = seconds == selectedSeconds;
              return GestureDetector(
                onTap: () => onSelected(seconds),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected
                        ? kColorDarkGreen
                        : kColorOlive.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _formatMinutes(seconds),
                    style: TextStyle(
                      color: selected ? kColorCream : kColorDarkGreen,
                      fontWeight: AppType.weightSemiBold,
                      fontSize: AppType.sizeLabel,
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
    final bool selected =
        !_durationPresets.contains(selectedSeconds);
    return GestureDetector(
      onTap: () => _promptCustomDuration(context),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? kColorDarkGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: kColorDarkGreen, width: 1.2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.tune_rounded,
              size: 16,
              color: selected ? kColorCream : kColorDarkGreen,
            ),
            const SizedBox(width: 6),
            Text(
              'Personalizado',
              style: TextStyle(
                color: selected ? kColorCream : kColorDarkGreen,
                fontWeight: AppType.weightSemiBold,
                fontSize: AppType.sizeLabel,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _promptCustomDuration(BuildContext context) async {
    final controller = TextEditingController();
    final minutes = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: kColorSurfaceWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Duración personalizada',
          style: TextStyle(color: kColorOffBlack, fontWeight: AppType.weightSemiBold),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: kColorOffBlack),
          decoration: const InputDecoration(
            labelText: 'Minutos',
            hintText: 'ej. 20',
            labelStyle: TextStyle(color: kColorTextSecondary),
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
              final value = int.tryParse(controller.text.trim());
              if (value == null) return;
              Navigator.of(dialogContext).pop(value);
            },
            style: TextButton.styleFrom(foregroundColor: kColorDarkGreen),
            child: const Text('Aceptar', style: TextStyle(fontWeight: AppType.weightSemiBold)),
          ),
        ],
      ),
    );

    if (minutes == null) return;
    final clamped = minutes.clamp(_kMinCustomMinutes, _kMaxCustomMinutes);
    onSelected(clamped * 60);
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.isRunning});

  final bool isRunning;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isRunning
            ? kColorOlive.withValues(alpha: 0.3)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isRunning ? kColorDarkGreen : kColorTextSecondary,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isRunning ? 'Activo' : 'En pausa',
            style: TextStyle(
              color: isRunning ? kColorDarkGreen : kColorTextSecondary,
              fontWeight: AppType.weightSemiBold,
              fontSize: AppType.sizeCaption,
            ),
          ),
        ],
      ),
    );
  }
}