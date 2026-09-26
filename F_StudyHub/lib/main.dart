import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/app_icons.dart';
import 'ui/widgets/inactivity_detector.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/avatars.dart';
import 'core/theme.dart';
import 'logic/theme_provider.dart';
import 'ui/screens/create_room_screen.dart';
import 'ui/screens/home_screen.dart';

Widget _buildErrorWidget(FlutterErrorDetails errorDetails) {
  // Esta pantalla se dibuja cuando el árbol ya está roto, así que no hay
  // MaterialApp del que sacar el tema: se queda en la paleta clara.
  const c = AppColors.light;

  return Builder(
    builder: (context) {
      return Material(
        color: c.bg,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: c.studySoft,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    AppIcons.circleAlert,
                    color: c.study,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Algo salió mal',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: c.ink,
                        fontWeight: AppType.weightSemiBold,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Ocurrió un error inesperado. Por favor, reinicia la aplicación.',
                  textAlign: TextAlign.center,
                  style: AppType.secondaryItalic(context: context, color: c.ink),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: 200,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (_) => const HomeScreen(),
                        ),
                        (route) => false,
                      );
                    },
                    icon: const Icon(AppIcons.house),
                    label: const Text('Volver al inicio'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      final initialThemeMode = await loadSavedThemeMode();
      FlutterError.onError = (details) {
        debugPrint('[FlutterError] ${details.exceptionAsString()}');
        debugPrint('${details.stack}');
      };
      ErrorWidget.builder = _buildErrorWidget;
      // Tras el primer cuadro: la primera vez que se dibuja un avatar el estilo
      // se interpreta (cientos de ms) y así no cae sobre la sala.
      WidgetsBinding.instance.addPostFrameCallback((_) => warmUpAvatars());
      runApp(
        ProviderScope(
          overrides: [
            initialThemeModeProvider.overrideWithValue(initialThemeMode),
          ],
          child: const StudyHubApp(),
        ),
      );
    },
    (error, stackTrace) {
      debugPrint('[ZoneError] $error');
      debugPrint('$stackTrace');
    },
  );
}


class StudyHubApp extends ConsumerWidget {
  const StudyHubApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return InactivityDetector(
      child: MaterialApp(
        title: 'StudyHub',
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        themeMode: themeMode,
        builder: (context, child) {
          // Iconos de la barra de estado legibles sobre el fondo del modo activo.
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: isDark
                ? SystemUiOverlayStyle.light
                : SystemUiOverlayStyle.dark,
            child: child!,
          );
        },
        home: const HomeScreen(),
        routes: {
          CreateRoomScreen.routeName: (_) => const CreateRoomScreen(),
        },
      ),
    );
  }
}
