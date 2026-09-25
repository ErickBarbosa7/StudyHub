import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:studyhub/data/services/websocket_service.dart';
import 'package:studyhub/logic/socket_provider.dart';
import 'package:studyhub/main.dart';

class _FakeWebSocketService extends WebSocketService {
  @override
  void connect() {}

  @override
  void disconnect() {}

  @override
  bool get isConnected => false;

  @override
  void emit(String event, [dynamic data]) {}

  @override
  void on(String event, dynamic Function(dynamic data) handler) {}

  @override
  void off(String event) {}
}

Future<void> _pump(WidgetTester tester, Size size) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        socketServiceProvider.overrideWithValue(_FakeWebSocketService()),
      ],
      child: const StudyHubApp(),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  // Laptop y tablet horizontal: presentación + formulario a la vista.
  for (final size in const [
    Size(1920, 1080),
    Size(1440, 900),
    Size(1366, 640),
    Size(1024, 768),
    Size(960, 540),
  ]) {
    testWidgets(
      'Inicio en dos columnas ${size.width.toInt()}x${size.height.toInt()}',
      (tester) async {
        await _pump(tester, size);
        expect(tester.takeException(), isNull);

        // Presentación a la izquierda y formulario directo a la derecha.
        // El nombre de la app en grande y su frase.
        expect(find.text('StudyHub', findRichText: true), findsOneWidget);
        expect(find.text('Estudia y concéntrate en equipo.'), findsOneWidget);
        expect(find.text('Empieza ahora'), findsOneWidget);
        expect(find.text('Crear sala'), findsWidgets);
        expect(find.text('Crear o unirse a una sala'), findsNothing);

        // Cambiar a "Unirse" muestra el código sin salir de la pantalla.
        await tester.tap(find.text('Unirte').first);
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('Código de la sala'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  // Celular y tablet vertical: se mantiene el inicio con botón.
  for (final size in const [
    Size(390, 844),
    Size(360, 640),
    Size(320, 568),
    Size(640, 360),
    Size(834, 1112),
  ]) {
    testWidgets(
      'Inicio de una columna ${size.width.toInt()}x${size.height.toInt()}',
      (tester) async {
        await _pump(tester, size);
        expect(tester.takeException(), isNull);
        // Mismo lenguaje visual que en laptop: nombre grande y frase.
        expect(find.text('StudyHub', findRichText: true), findsOneWidget);
        expect(find.text('Estudia y concéntrate en equipo.'), findsOneWidget);
        expect(find.text('Crear o unirse a una sala'), findsOneWidget);
        expect(find.text('Empieza ahora'), findsNothing);
      },
    );
  }
}
