import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:studyhub/logic/theme_provider.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('sin preferencia guardada sigue al sistema', () async {
    expect(await loadSavedThemeMode(), ThemeMode.system);
  });

  test('toggle alterna según el brillo visible y persiste la elección', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(themeProvider.notifier);

    await notifier.toggle(isDark: false);
    expect(container.read(themeProvider), ThemeMode.dark);
    expect(await loadSavedThemeMode(), ThemeMode.dark);

    await notifier.toggle(isDark: true);
    expect(container.read(themeProvider), ThemeMode.light);
    expect(await loadSavedThemeMode(), ThemeMode.light);
  });

  test('arranca con el modo guardado sin pasar por claro', () async {
    SharedPreferences.setMockInitialValues({'theme_mode': 'dark'});
    final saved = await loadSavedThemeMode();
    final container = ProviderContainer(
      overrides: [initialThemeModeProvider.overrideWithValue(saved)],
    );
    addTearDown(container.dispose);

    expect(container.read(themeProvider), ThemeMode.dark);
  });
}
