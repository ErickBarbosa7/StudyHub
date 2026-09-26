import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_icons.dart';
import '../../core/theme.dart';
import '../../logic/theme_provider.dart';
import '../room/room_widgets.dart';

// Botón que alterna entre modo claro y oscuro.
//
// El icono muestra el DESTINO, no el estado actual: con la pantalla clara se ve
// la luna (voy a oscurecer) y al revés. Es la convención de iOS y Material, y es
// la correcta porque lo que el usuario necesita para decidir es lo que va a
// pasar al tocarlo, no en qué estado está.
//
// El color sale del tema, no del provider: por eso este widget no se suscribe a
// `themeProvider` (solo usa `read`). Cuando cambia el modo, MaterialApp reconstruye
// con el otro `ThemeData` y el icono se entera solo por `Theme.of(context)`.

/// Tamaño táctil del botón de icono (regla de objetivos mínimos del diseño).
const double _kToggleSize = 44;

/// Variante para superficies del tema (sala, app bar): borde fino y fondo de tarjeta.
class ThemeToggleIconButton extends ConsumerWidget {
  const ThemeToggleIconButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return RoomIconButton(
      icon: _destinationIcon(isDark),
      iconSize: 20,
      tooltip: _label(isDark),
      onPressed: () => ref.read(themeProvider.notifier).toggle(isDark: isDark),
    );
  }
}

/// Variante para el panel verde de marca: píldora translúcida en vez de borde fino.
///
/// El panel no cambia con el modo, así que el control lleva su propia superficie
/// para seguir leyéndose como botón sobre el verde.
class ThemeTogglePillButton extends ConsumerWidget {
  const ThemeTogglePillButton({super.key, this.iconSize = 20});

  final double iconSize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final label = _label(isDark);
    final icon = _destinationIcon(isDark);

    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        child: Material(
          color: const Color(0x24FFFFFF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0x47FFFFFF)),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => ref.read(themeProvider.notifier).toggle(isDark: isDark),
            child: SizedBox(
              width: _kToggleSize,
              height: _kToggleSize,
              child: Center(
                child: _AnimatedThemeIcon(
                  isDark: isDark,
                  icon: icon,
                  iconSize: iconSize,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Variante con etiqueta, para superficies donde un icono suelto no basta
/// (hoja de miembros, ajustes). Muestra el modo actual como texto de apoyo.
class ThemeToggleRow extends ConsumerWidget {
  const ThemeToggleRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final label = _label(isDark);
    final hint = isDark ? 'Oscuro' : 'Claro';

    return Semantics(
      button: true,
      label: '$label. Modo actual: $hint',
      excludeSemantics: true,
      child: Material(
        color: c.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: c.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => ref.read(themeProvider.notifier).toggle(isDark: isDark),
          child: SizedBox(
            height: 52,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    child: Center(
                      child: _AnimatedThemeIcon(
                        isDark: isDark,
                        icon: _destinationIcon(isDark),
                        iconSize: 20,
                        color: c.ink,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: c.ink,
                        fontSize: AppType.sizeBodyMedium,
                        fontWeight: AppType.weightSemiBold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    hint,
                    style: TextStyle(
                      color: c.muted,
                      fontSize: AppType.sizeBody,
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

IconData _destinationIcon(bool isDark) => isDark ? AppIcons.sun : AppIcons.moon;

/// El texto acompaña al icono e invierte con él: si el icono promete pasar a
/// oscuro, el tooltip dice "Modo oscuro", no "Modo claro".
String _label(bool isDark) => isDark ? 'Modo claro' : 'Modo oscuro';

/// Cruce suave entre sol y luna: confirma el cambio y hace que el toque se
/// sienta causal en vez de telepático.
class _AnimatedThemeIcon extends StatelessWidget {
  const _AnimatedThemeIcon({
    required this.isDark,
    required this.icon,
    required this.iconSize,
    required this.color,
  });

  final bool isDark;
  final IconData icon;
  final double iconSize;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.6, end: 1).animate(animation),
            child: RotationTransition(
              turns: Tween<double>(begin: -0.18, end: 0).animate(animation),
              child: child,
            ),
          ),
        );
      },
      child: Icon(icon, size: iconSize, color: color, key: ValueKey(icon)),
    );
  }
}
