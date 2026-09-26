import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../../core/theme.dart';
import '../../../logic/pomodoro_provider.dart';
import 'mascot_bubble.dart';

/// Ánimo de la mascota del reloj según la fase del ciclo.
enum MascotMood {
  /// Reloj en pausa en foco: quieta, esperando.
  idle,

  /// Foco corriendo: activa y con rebote.
  focusing,

  /// Descanso (corto o largo): movimiento lento y "zzz".
  resting,

  /// Fase recién terminada: salto de celebración.
  celebrating,
}

/// El ánimo que corresponde a un estado del reloj.
///
/// El estado viene del servidor, así que todos en la sala ven el mismo ánimo.
MascotMood moodFor(PomodoroState s) {
  if (s.isFinished) return MascotMood.celebrating;
  if (s.isBreak) return MascotMood.resting;
  if (s.isRunning) return MascotMood.focusing;
  return MascotMood.idle;
}

/// Asset por ánimo. Un ánimo sin entrada usa [kClawdAsset] más los efectos por
/// código de este widget; para darle animación propia basta añadir su Lottie
/// aquí (y en pubspec.yaml).
const Map<MascotMood, String> kMascotAssets = {};

String _assetFor(MascotMood mood) => kMascotAssets[mood] ?? kClawdAsset;

/// Duración del ciclo en descanso respecto al normal: más lento = más calmado.
const double _kRestSlowdown = 2.5;

/// Mascota del centro del dial. Reacciona al ciclo: quieta en pausa, con rebote
/// en foco, lenta y con "zzz" en descanso y con un salto al terminar la fase.
class PomodoroMascot extends StatefulWidget {
  const PomodoroMascot({super.key, required this.state, required this.height});

  final PomodoroState state;

  /// Alto de la mascota; el ancho sale del lienzo (2750 x 1850).
  final double height;

  @override
  State<PomodoroMascot> createState() => _PomodoroMascotState();
}

class _PomodoroMascotState extends State<PomodoroMascot>
    with TickerProviderStateMixin {
  late final AnimationController _lottie = AnimationController(vsync: this);
  late final AnimationController _bounce = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );

  static final Animatable<double> _popScale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(begin: 1.0, end: 1.18).chain(CurveTween(curve: Curves.easeOut)),
      weight: 40,
    ),
    TweenSequenceItem(
      tween: Tween(begin: 1.18, end: 1.0).chain(CurveTween(curve: Curves.bounceOut)),
      weight: 60,
    ),
  ]);

  Duration? _cycle;
  bool _reduceMotion = false;
  MascotMood? _applied;

  MascotMood get _mood => moodFor(widget.state);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.disableAnimationsOf(context);
    if (reduce != _reduceMotion) {
      _reduceMotion = reduce;
      _apply(force: true);
    }
  }

  @override
  void didUpdateWidget(PomodoroMascot oldWidget) {
    super.didUpdateWidget(oldWidget);
    _apply();
  }

  @override
  void dispose() {
    _lottie.dispose();
    _bounce.dispose();
    _pop.dispose();
    super.dispose();
  }

  void _onLoaded(LottieComposition composition) {
    _cycle = composition.duration;
    _apply(force: true);
  }

  void _apply({bool force = false}) {
    final cycle = _cycle;
    if (cycle == null) return;
    final mood = _mood;
    if (!force && mood == _applied) return;
    _applied = mood;

    if (_reduceMotion || mood == MascotMood.idle) {
      _lottie.stop();
      _lottie.value = 0;
      _bounce.stop();
      _bounce.value = 0;
      return;
    }

    switch (mood) {
      case MascotMood.focusing:
        _lottie.repeat(period: cycle);
        _bounce.repeat(reverse: true);
      case MascotMood.resting:
        _lottie.repeat(period: cycle * _kRestSlowdown);
        _bounce.stop();
        _bounce.value = 0;
      case MascotMood.celebrating:
        _lottie.repeat(period: cycle);
        _bounce.stop();
        _bounce.value = 0;
        _pop.forward(from: 0);
      case MascotMood.idle:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final double height = widget.height;
    final double width = height * 1.4;
    final mood = _mood;

    return RepaintBoundary(
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: AnimatedBuilder(
                animation: Listenable.merge([_bounce, _pop]),
                builder: (context, child) {
                  final lift = -height * 0.05 *
                      Curves.easeInOut.transform(_bounce.value);
                  return Transform.translate(
                    offset: Offset(0, lift),
                    child: Transform.scale(
                      scale: _popScale.evaluate(_pop),
                      child: child,
                    ),
                  );
                },
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 250),
                  opacity: mood == MascotMood.resting ? 0.85 : 1,
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: Lottie.asset(
                      _assetFor(mood),
                      controller: _lottie,
                      onLoaded: _onLoaded,
                      frameRate: FrameRate.composition,
                      width: width,
                      height: height,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: _Snooze(
                visible: mood == MascotMood.resting && !_reduceMotion,
                color: c.muted,
                size: height * 0.24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "zzz" que flota cuando la mascota descansa.
class _Snooze extends StatelessWidget {
  const _Snooze({
    required this.visible,
    required this.color,
    required this.size,
  });

  final bool visible;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
        offset: visible ? Offset.zero : const Offset(0, 0.4),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: visible ? 1 : 0,
          child: Text(
            'z Z',
            maxLines: 1,
            style: TextStyle(
              color: color,
              fontSize: size,
              fontWeight: AppType.weightBold,
              fontStyle: FontStyle.italic,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}
