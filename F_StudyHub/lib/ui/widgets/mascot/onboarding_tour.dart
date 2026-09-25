import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../../logic/onboarding_provider.dart';
import 'mascot_bubble.dart';

class OnboardingStep {
  const OnboardingStep({required this.title, required this.message});

  final String title;
  final String message;
}

const List<OnboardingStep> kOnboardingSteps = [
  OnboardingStep(
    title: '¡Hola! Soy Clawd, tu guía',
    message:
        'StudyHub es una web app para estudiar a distancia en equipo. '
        'En los siguientes pasos te cuento qué puedes hacer aquí.',
  ),
  OnboardingStep(
    title: 'Salas',
    message:
        'Crea una sala y comparte su código o el QR con tu equipo. '
        'Tus amigos entran al instante y todo queda sincronizado.',
  ),
  OnboardingStep(
    title: 'Tareas',
    message:
        'Una sola lista de tareas en tiempo real: lo que agregue, edite o '
        'complete alguien, lo verá toda la sala al momento.',
  ),
  OnboardingStep(
    title: 'Pomodoro',
    message:
        'Un solo temporizador para concentrarse juntos: enciéndelo y '
        'estudien al mismo ritmo. Al terminar llega un descanso corto o '
        'largo, y con la flecha ⏭ puedes adelantarlo.',
  ),
  OnboardingStep(
    title: 'Chat',
    message:
        'Coordina sin salir de la app: envía mensajes para compartir dudas, '
        'links o solo mantener el ánimo del equipo.',
  ),
];

/// Abre la guía de bienvenida con la mascota.
Future<void> showOnboardingTour(
  BuildContext context,
  OnboardingNotifier notifier,
) async {
  final isWide = MediaQuery.sizeOf(context).width >= 600;
  notifier.markOpened();

  if (isWide) {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => Dialog(
        backgroundColor: kColorPaper,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: const _OnboardingTourView(),
        ),
      ),
    );
  } else {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: kColorPaper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (sheetContext) => SafeArea(
        child: const _OnboardingTourView(),
      ),
    );
  }

  // Al cerrar (terminar o saltar) se marca como vista.
  await notifier.complete();
}

class _OnboardingTourView extends StatefulWidget {
  const _OnboardingTourView();

  @override
  State<_OnboardingTourView> createState() => _OnboardingTourViewState();
}

class _OnboardingTourViewState extends State<_OnboardingTourView> {
  int _index = 0;

  bool get _isLast => _index == kOnboardingSteps.length - 1;

  void _close() {
    Navigator.of(context).pop();
  }

  void _next() {
    if (_isLast) {
      _close();
      return;
    }
    setState(() => _index += 1);
  }

  @override
  Widget build(BuildContext context) {
    final step = kOnboardingSteps[_index];
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 28, 32, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: ClawdAvatar(height: 150)),
          const SizedBox(height: 16),
          Center(
            child: Text(
              '${_index + 1} de ${kOnboardingSteps.length}',
              style: AppType.secondaryItalic(size: AppType.sizeCaption),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            step.title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: kColorInk,
                  fontWeight: AppType.weightSemiBold,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            step.message,
            textAlign: TextAlign.center,
            style: AppType.secondaryItalic(
              color: kColorInk,
              size: AppType.sizeBody,
            ),
          ),
          const SizedBox(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(kOnboardingSteps.length, (i) {
              final active = i == _index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 22 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: active ? kColorDeepSage : kColorBorder,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: _close,
                  style: TextButton.styleFrom(
                    foregroundColor: kColorTextSecondary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Saltar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: _next,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(_isLast ? 'Empezar' : 'Siguiente'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}