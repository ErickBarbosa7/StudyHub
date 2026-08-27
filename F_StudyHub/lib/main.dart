import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme.dart';
import 'ui/screens/create_room_screen.dart';
import 'ui/screens/home_screen.dart';

Widget _buildErrorWidget(FlutterErrorDetails errorDetails) {
  return Builder(
    builder: (context) {
      return Material(
        color: kColorPaper,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: kColorSageSoft,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.error_outline_rounded,
                    color: kColorDeepSage,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Algo salió mal',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: kColorInk,
                        fontWeight: AppType.weightSemiBold,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Ocurrió un error inesperado. Por favor, reinicia la aplicación.',
                  textAlign: TextAlign.center,
                  style: AppType.secondaryItalic(color: kColorInk),
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
                    icon: const Icon(Icons.home_rounded),
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
    () {
      FlutterError.onError = (details) {
        debugPrint('[FlutterError] ${details.exceptionAsString()}');
        debugPrint('${details.stack}');
      };
      ErrorWidget.builder = _buildErrorWidget;
      runApp(const ProviderScope(child: StudyHubApp()));
    },
    (error, stackTrace) {
      debugPrint('[ZoneError] $error');
      debugPrint('$stackTrace');
    },
  );
}

class StudyHubApp extends StatelessWidget {
  const StudyHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StudyHub',
      theme: buildTheme(),
      home: const HomeScreen(),
      routes: {
        CreateRoomScreen.routeName: (_) => const CreateRoomScreen(),
      },
    );
  }
}
