import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/avatars.dart';
import '../../core/theme.dart';

/// Tarjeta de la sala con borde fino, sin sombra. Base de todos los paneles.
class RoomCard extends StatelessWidget {
  const RoomCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(20),
      ),
      child: child,
    );
  }
}

/// Botón cuadrado de icono (44x44 mínimo) con borde fino.
///
/// Los colores son opcionales: si no se pasan se toman del tema. Nadie debería
/// tener que escribir `c.ink` en cada llamada.
class RoomIconButton extends StatelessWidget {
  const RoomIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.size = 44,
    this.iconSize = 20,
    this.foreground,
    this.background,
    this.bordered = true,
    this.borderColor,
    this.iconOffset = Offset.zero,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final double size;
  final double iconSize;
  final Color? foreground;
  final Color? background;
  final bool bordered;
  final Color? borderColor;
  final Offset iconOffset;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fg = foreground ?? c.ink;
    final bg = background ?? c.surface;
    final line = borderColor ?? c.line;
    final enabled = onPressed != null;

    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: size,
        height: size,
        child: Material(
          color: bg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(size > 48 ? 16 : 14),
            side: bordered ? BorderSide(color: line) : BorderSide.none,
          ),
          child: InkWell(
            onTap: onPressed,
            customBorder: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(size > 48 ? 16 : 14),
            ),
            child: Semantics(
              button: true,
              label: tooltip,
              excludeSemantics: true,
              child: Center(
                child: Transform.translate(
                  offset: iconOffset,
                  child: Icon(
                    icon,
                    size: iconSize,
                    color: enabled ? fg : c.disabled,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Pastilla de estado pequeña.
class RoomChip extends StatelessWidget {
  const RoomChip({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        style: TextStyle(
          color: foreground,
          fontSize: AppType.sizeCaption,
          fontWeight: AppType.weightSemiBold,
        ),
      ),
    );
  }
}

/// Iniciales de un nombre ("Erick Barbosa" -> "EB").
String initialsOf(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
  final list = parts.toList();
  if (list.isEmpty) return '?';
  if (list.length == 1) {
    return list.first.substring(0, list.first.length.clamp(1, 2)).toUpperCase();
  }
  return (list.first[0] + list[1][0]).toUpperCase();
}

/// Avatar de una persona: su dibujo por defecto (`seed`, asignada por el
/// servidor) o, sin seed, las iniciales. El fondo del círculo sale del índice
/// para que cada persona conserve el suyo.
class RoomAvatar extends StatelessWidget {
  const RoomAvatar({
    super.key,
    required this.name,
    required this.index,
    this.seed,
    this.size = 36,
    this.ringColor,
  });

  final String name;
  final int index;
  final String? seed;
  final double size;
  final Color? ringColor;

  /// Pares (fondo, texto) por posición. Se resuelven con la paleta activa para
  /// que los cuatro tonos se lean también en oscuro.
  static List<(Color, Color)> paletteOf(AppColors c) => [
    (c.studySoft, c.study),
    (c.restSoft, c.restInk),
    (c.longRestSoft, c.longRest),
    (c.track, c.muted),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (bg, fg) = paletteOf(c)[index % 4];
    final seed = this.seed;
    return Semantics(
      label: name,
      image: true,
      excludeSemantics: true,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          border: Border.all(color: ringColor ?? c.bg, width: 2),
        ),
        child: seed == null
            ? Text(
                initialsOf(name),
                style: TextStyle(
                  color: fg,
                  fontSize: size * 0.34,
                  fontWeight: AppType.weightBold,
                ),
              )
            : SvgPicture.string(
                avatarSvg(seed),
                width: size - 4,
                height: size - 4,
                fit: BoxFit.cover,
              ),
      ),
    );
  }
}

/// Distribución de la sala según el ancho disponible.
enum RoomLayout {
  /// Laptop / escritorio: tres columnas.
  wide,

  /// Tablet: reloj a un lado, tareas y chat en pestañas.
  tablet,

  /// Celular: una sección a la vez con navegación inferior.
  phone;

  static RoomLayout of(double width) {
    if (width >= 1100) return RoomLayout.wide;
    if (width >= 700) return RoomLayout.tablet;
    return RoomLayout.phone;
  }
}
