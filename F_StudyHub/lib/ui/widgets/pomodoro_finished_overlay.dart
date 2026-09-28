import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../core/app_icons.dart';
import '../../core/theme.dart';
import '../../logic/pomodoro_provider.dart';
import 'mascot/mascot_bubble.dart';

/// Pantalla completa que cubre la sala cuando una fase del reloj termina.
/// Se cierra al tocar "Continuar" o sola tras unos segundos.
class PomodoroFinishedOverlay extends StatefulWidget {
  const PomodoroFinishedOverlay({
    super.key,
    required this.finishedMode,
    required this.onDismiss,
  });

  final String? finishedMode;
  final VoidCallback onDismiss;

  @override
  State<PomodoroFinishedOverlay> createState() =>
      _PomodoroFinishedOverlayState();
}

class _PomodoroFinishedOverlayState extends State<PomodoroFinishedOverlay> {
  Timer? _autoDismiss;

  @override
  void initState() {
    super.initState();
    _autoDismiss = Timer(const Duration(seconds: 8), widget.onDismiss);
  }

  @override
  void dispose() {
    _autoDismiss?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final breakEnded =
        widget.finishedMode != null && widget.finishedMode != kModeFocus;

    final title = breakEnded
        ? 'Descanso terminado'
        : '¡Tiempo completado!';
    final subtitle = breakEnded
        ? 'De vuelta al estudio.'
        : 'Tu descanso está listo.';
    final accent = breakEnded ? c.study : c.rest;

    return Positioned.fill(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        builder: (context, t, child) => Opacity(
          opacity: t,
          child: Transform.scale(
            scale: 0.96 + (0.04 * t),
            child: child,
          ),
        ),
        child: Material(
          color: c.bg.withValues(alpha: 0.98),
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 220,
                      child: Lottie.asset(kClawdAsset, repeat: true),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: c.ink,
                        fontSize: AppType.sizeHeadline,
                        fontWeight: AppType.weightBold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: c.muted,
                        fontSize: AppType.sizeBodyLarge,
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: 220,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: widget.onDismiss,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor: c.onAccent,
                        ),
                        icon: const Icon(AppIcons.check, size: 20),
                        label: const Text('Continuar'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
