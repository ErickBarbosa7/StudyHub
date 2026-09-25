import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../core/app_icons.dart';

import '../../core/theme.dart';
import '../room/room_widgets.dart';
import 'mascot/mascot_bubble.dart';

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

/// Muestra de una sala en curso (datos de ejemplo, sin interacción): el
/// reloj con el cangrejo, quién está y una tarea hecha. Usa los mismos
/// componentes que la sala real.
class LandingRoomPreview extends StatelessWidget {
  const LandingRoomPreview({super.key});

  /// Alto aproximado, para decidir si cabe.
  static const double height = 200;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kRoomSurface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              SizedBox(
                width: 104,
                height: 104,
                child: CustomPaint(
                  painter: const _MiniRingPainter(progress: 0.72),
                  child: const Padding(
                    padding: EdgeInsets.all(14),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Mascota: cangrejo de Claude.
                          ClawdAvatar(height: 27),
                          SizedBox(height: 4),
                          Text(
                            '21:30',
                            style: TextStyle(
                              color: kRoomInk,
                              fontSize: 20,
                              fontWeight: AppType.weightSemiBold,
                              fontFamily: kFontFamilyMono,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 18),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RoomChip(
                      label: 'Estudio · Ronda 2 de 4',
                      background: kRoomStudySoft,
                      foreground: kRoomStudy,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Cálculo II · Repaso',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: kRoomInk,
                        fontSize: 18,
                        fontWeight: AppType.weightBold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        _AvatarTrio(),
                        SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            '3 en la sala',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: kRoomMuted,
                              fontSize: AppType.sizeLabel,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.only(top: 14),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: kRoomTrack)),
            ),
            child: const Row(
              children: [
                _DoneBox(),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Repasar límites y continuidad',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: kRoomMuted,
                      fontSize: AppType.sizeBody,
                      decoration: TextDecoration.lineThrough,
                      decorationColor: kRoomMuted,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  '1 de 3',
                  style: TextStyle(
                    color: kRoomMuted,
                    fontSize: AppType.sizeCaption,
                    fontWeight: AppType.weightSemiBold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarTrio extends StatelessWidget {
  const _AvatarTrio();

  @override
  Widget build(BuildContext context) {
    const size = 32.0;
    const step = 24.0;
    return SizedBox(
      width: size + step * 2,
      height: size,
      child: const Stack(
        children: [
          RoomAvatar(
            name: 'Erick Barbosa',
            index: 0,
            size: size,
            ringColor: kRoomSurface,
          ),
          Positioned(
            left: step,
            child: RoomAvatar(
              name: 'Marco',
              index: 1,
              size: size,
              ringColor: kRoomSurface,
            ),
          ),
          Positioned(
            left: step * 2,
            child: RoomAvatar(
              name: 'Ana Lu',
              index: 2,
              size: size,
              ringColor: kRoomSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _DoneBox extends StatelessWidget {
  const _DoneBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: kRoomStudy,
        borderRadius: BorderRadius.circular(7),
      ),
      child: const Icon(AppIcons.check, size: 13, color: Colors.white),
    );
  }
}

/// Anillo de la muestra: pista clara y arco de progreso.
class _MiniRingPainter extends CustomPainter {
  const _MiniRingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 6.0;
    final center = size.center(Offset.zero);
    final radius = (math.min(size.width, size.height) - stroke) / 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, paint..color = kRoomRingTrack);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      paint..color = kRoomStudy,
    );
  }

  @override
  bool shouldRepaint(_MiniRingPainter old) => old.progress != progress;
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
                        // Abajo: la ilustración a la derecha y la muestra de una
                        // sala al frente, a la izquierda. Se adapta al alto.
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, box) => _HeroBottom(
                              height: box.maxHeight,
                              width: width,
                              bleed: hPad,
                            ),
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

/// Zona inferior del panel: ilustración + tarjeta, o solo la tarjeta si el
/// alto no alcanza para ambas, o nada.
class _HeroBottom extends StatelessWidget {
  const _HeroBottom({
    required this.height,
    required this.width,
    required this.bleed,
  });

  final double height;
  final double width;

  /// Cuánto puede salirse la ilustración por la derecha (el margen del panel).
  final double bleed;

  @override
  Widget build(BuildContext context) {
    const double cardH = LandingRoomPreview.height;
    const double gap = 28;
    final double avail = height - gap;
    if (avail < cardH) return const SizedBox.shrink();

    final double cardW = math.min(420, width);
    final bool both = avail >= cardH + 170;
    final double illuH = math.min(avail, 460);

    return Padding(
      padding: const EdgeInsets.only(top: gap),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (both)
            Positioned(
              right: -bleed + 12,
              bottom: 0,
              child: LandingIllustration(height: illuH),
            ),
          Positioned(
            left: 0,
            bottom: 0,
            width: cardW,
            child: const LandingRoomPreview(),
          ),
        ],
      ),
    );
  }
}
