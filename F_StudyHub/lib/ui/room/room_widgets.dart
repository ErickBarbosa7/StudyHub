import 'package:flutter/material.dart';

import '../../core/theme.dart';

/// Tarjeta blanca con borde fino, sin sombra. Base de todos los paneles de la sala.
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
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: kRoomSurface,
        border: Border.all(color: kRoomLine),
        borderRadius: BorderRadius.circular(20),
      ),
      child: child,
    );
  }
}

/// Botón cuadrado de icono (44x44 mínimo) con borde fino.
class RoomIconButton extends StatelessWidget {
  const RoomIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.size = 44,
    this.iconSize = 20,
    this.foreground = kRoomInk,
    this.background = kRoomSurface,
    this.bordered = true,
    this.borderColor = kRoomLine,
    this.iconOffset = Offset.zero,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final double size;
  final double iconSize;
  final Color foreground;
  final Color background;
  final bool bordered;
  final Color borderColor;
  final Offset iconOffset;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: size,
        height: size,
        child: Material(
          color: background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(size > 48 ? 16 : 14),
            side: bordered ? BorderSide(color: borderColor) : BorderSide.none,
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
                    color: enabled ? foreground : kRoomDisabled,
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

/// Círculo con iniciales; el color sale del índice para que cada persona
/// conserve el suyo.
class RoomAvatar extends StatelessWidget {
  const RoomAvatar({
    super.key,
    required this.name,
    required this.index,
    this.size = 36,
    this.ringColor = kRoomBg,
  });

  final String name;
  final int index;
  final double size;
  final Color ringColor;

  static const _palette = [
    (kRoomStudySoft, kRoomStudy),
    (kRoomBreakSoft, kRoomBreakInk),
    (kRoomLongSoft, kRoomLong),
    (kRoomTrack, kRoomMuted),
  ];

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _palette[index % _palette.length];
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(color: ringColor, width: 2),
      ),
      child: Text(
        initialsOf(name),
        style: TextStyle(
          color: fg,
          fontSize: size * 0.34,
          fontWeight: AppType.weightBold,
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
