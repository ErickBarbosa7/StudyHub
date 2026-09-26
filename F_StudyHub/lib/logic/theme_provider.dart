import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart' show Provider;
import 'package:flutter_riverpod/legacy.dart'
    show StateNotifier, StateNotifierProvider;
import 'package:shared_preferences/shared_preferences.dart';

const String _kPrefThemeMode = 'theme_mode';

/// Modo guardado, leído ANTES de `runApp` para que el primer frame ya salga con
/// el tema correcto (si se leyera después, un usuario en oscuro vería un
/// destello claro al abrir la app). `main` lo sobrescribe en el `ProviderScope`.
final initialThemeModeProvider = Provider<ThemeMode>((ref) => ThemeMode.system);

/// Lee la preferencia guardada. Sin preferencia (o si falla la lectura) se
/// sigue al sistema.
Future<ThemeMode> loadSavedThemeMode() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kPrefThemeMode);
    for (final mode in ThemeMode.values) {
      if (mode.name == saved) return mode;
    }
  } catch (e) {
    debugPrint('[Theme] Error cargando preferencias: $e');
  }
  return ThemeMode.system;
}

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier(super.initial);

  /// Alterna entre claro y oscuro según el brillo que se está viendo.
  ///
  /// La primera vez el usuario toca el botón, deja de seguir al sistema y se
  /// guarda la elección: a partir de ahí el botón es un interruptor de dos
  /// estados. [isDark] es el brillo efectivo de la pantalla, no el guardado.
  Future<void> toggle({required bool isDark}) async {
    final next = isDark ? ThemeMode.light : ThemeMode.dark;
    state = next;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kPrefThemeMode, next.name);
    } catch (e) {
      debugPrint('[Theme] Error guardando preferencia: $e');
    }
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier(ref.read(initialThemeModeProvider));
});
