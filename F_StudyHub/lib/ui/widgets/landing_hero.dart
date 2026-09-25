import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../core/app_icons.dart';

import '../../core/theme.dart';

/// Ancho desde el que el inicio muestra presentación + formulario en dos
/// columnas (laptop y tablet horizontal). Por debajo, el inicio es una
/// columna con el botón "Crear o unirse a una sala".
const double kLandingBreakpoint = 960;

// Tonos claros sobre el verde de marca; solo para el inicio.
const Color kLandingSoft = Color(0xFFCFE5DF); // textos secundarios
const Color kLandingText = Color(0xFFE3F1EC); // frase
const Color kLandingAccent = Color(0xFF9FD3C4); // "Hub" del nombre

/// Marca + frase corta, en la parte de arriba.
class LandingBrandRow extends StatelessWidget {
  const LandingBrandRow({super.key, this.trailing});

  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0x24FFFFFF),
            borderRadius: BorderRadius.circular(11),
          ),
          child: const Icon(AppIcons.timer, size: 20, color: Colors.white),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Text(
            'SALAS DE ESTUDIO EN TIEMPO REAL',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: kLandingSoft,
              fontSize: AppType.sizeCaption,
              fontWeight: AppType.weightSemiBold,
              letterSpacing: 1.1,
            ),
          ),
        ),
        ?trailing,
      ],
    );
  }
}

/// "StudyHub" en grande: "Study" en blanco y "Hub" en verde claro. Toma todo
/// el ancho disponible (hasta 150 px de fuente) y escala si no cabe.
class LandingWordmark extends StatelessWidget {
  const LandingWordmark({super.key, required this.maxWidth});

  final double maxWidth;

  /// Tamaño de fuente para un ancho dado ("StudyHub" mide ~4.4 veces su
  /// tamaño de fuente).
  static double sizeFor(double width) => math.min(150, width / 4.4);

  @override
  Widget build(BuildContext context) {
    final size = sizeFor(maxWidth);
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text.rich(
        TextSpan(
          style: TextStyle(
            color: Colors.white,
            fontSize: size,
            fontWeight: FontWeight.w800,
            letterSpacing: -size * 0.05,
            height: 0.95,
          ),
          children: const [
            TextSpan(text: 'Study'),
            TextSpan(
              text: 'Hub',
              style: TextStyle(color: kLandingAccent),
            ),
          ],
        ),
        maxLines: 1,
        softWrap: false,
      ),
    );
  }
}

/// La frase de la app bajo el nombre.
class LandingTagline extends StatelessWidget {
  const LandingTagline({super.key, required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Text(
      'Estudia y concéntrate en equipo.',
      style: TextStyle(
        color: kLandingText,
        fontSize: math.min(30, math.max(20, width / 14)),
        fontWeight: AppType.weightMedium,
        height: 1.25,
        letterSpacing: -0.2,
      ),
    );
  }
}

/// Las tres ventajas, como etiquetas con contorno claro.
class LandingFeatures extends StatelessWidget {
  const LandingFeatures({super.key});

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _Feature(icon: AppIcons.timer, label: 'Pomodoro compartido'),
        _Feature(icon: AppIcons.listChecks, label: 'Tareas en vivo'),
        _Feature(icon: AppIcons.userCheck, label: 'Sin registro'),
      ],
    );
  }
}

class _Feature extends StatelessWidget {
  const _Feature({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0x47FFFFFF)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Colors.white),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: AppType.sizeBody,
                fontWeight: AppType.weightSemiBold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// La animación del chico estudiando, directo sobre el verde de marca (sin
/// tarjeta): el amarillo resalta y los grises claros se funden con el fondo.
class LandingIllustration extends StatelessWidget {
  const LandingIllustration({super.key, required this.height});

  final double height;

  /// Proporción de la animación (1080 x 950).
  static const double aspect = 1080 / 950;

  @override
  Widget build(BuildContext context) {
    // RepaintBoundary: la animación repinta sola, sin arrastrar al resto de
    // la pantalla. FrameRate.composition: 25 fps (los de la animación) en vez
    // de 60 repintados por segundo con el mismo dibujo.
    return RepaintBoundary(
      child: SizedBox(
        width: height * aspect,
        height: height,
        child: Lottie.asset(
          'assets/Lottie/STUDENT.json',
          fit: BoxFit.contain,
          repeat: true,
          frameRate: FrameRate.composition,
        ),
      ),
    );
  }
}

/// Panel izquierdo del inicio en pantallas anchas: el nombre de la app en
/// grande, la frase, tres ventajas y la animación del chico estudiando.
class LandingHero extends StatelessWidget {
  const LandingHero({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: kRoomStudy,
      child: ClipRect(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double hPad = math.min(72, constraints.maxWidth * 0.1);
            final double width = constraints.maxWidth - hPad * 2;
            final bool roomy = constraints.maxHeight >= 640;

            final middle = Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LandingWordmark(maxWidth: width),
                SizedBox(
                  height: math.max(12, LandingWordmark.sizeFor(width) * 0.16),
                ),
                LandingTagline(width: width),
                const SizedBox(height: 28),
                const LandingFeatures(),
              ],
            );

            return Padding(
              padding: EdgeInsets.fromLTRB(hPad, 48, hPad, 48),
              child: roomy
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const LandingBrandRow(),
                        const SizedBox(height: 36),
                        middle,
                        // Abajo: la ilustración, centrada, usando el alto que sobre.
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, box) =>
                                _HeroBottom(height: box.maxHeight),
                          ),
                        ),
                      ],
                    )
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const LandingBrandRow(),
                          const SizedBox(height: 32),
                          middle,
                        ],
                      ),
                    ),
            );
          },
        ),
      ),
    );
  }
}

/// Zona inferior del panel: la ilustración, lo más grande que permita el alto.
class _HeroBottom extends StatelessWidget {
  const _HeroBottom({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    const double gap = 24;
    final double avail = height - gap;
    if (avail < 200) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: gap),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: LandingIllustration(height: math.min(avail, 520)),
      ),
    );
  }
}
