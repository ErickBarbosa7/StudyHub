import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:studyhub/core/app_icons.dart';
import 'package:studyhub/core/theme.dart';
import 'package:studyhub/data/models/room_model.dart';
import 'package:studyhub/data/models/user_model.dart';
import 'package:studyhub/data/services/api_service.dart';
import 'package:studyhub/data/services/websocket_service.dart';
import 'package:studyhub/logic/room_provider.dart';
import 'package:studyhub/logic/socket_provider.dart';
import 'package:studyhub/ui/room/room_workspace.dart';

class _FakeWebSocketService extends WebSocketService {
  final Map<String, dynamic Function(dynamic)> handlers = {};

  @override
  void connect() {}

  @override
  void disconnect() {}

  @override
  bool get isConnected => false;

  @override
  void emit(String event, [dynamic data]) {}

  @override
  void on(String event, dynamic Function(dynamic data) handler) =>
      handlers[event] = handler;

  @override
  void off(String event) {}
}

class _TestRoomNotifier extends RoomNotifier {
  _TestRoomNotifier(super.ref, super.api, super.socket, RoomState initial) {
    state = initial;
  }
}

const _me = User(id: 'u1', name: 'Erick');

Map<String, dynamic> _message(String id, String text) => {
  'id': id,
  'roomId': 'K7Q2MX',
  'senderId': 'u2',
  'senderName': 'Ana',
  'text': text,
  'timestamp': '2026-09-25T10:00:00.000Z',
};

void main() {
  late _FakeWebSocketService socket;

  Future<void> pumpRoom(
    WidgetTester tester, {
    required Size size,
    bool hidden = false,
    Brightness brightness = Brightness.light,
  }) async {
    SharedPreferences.setMockInitialValues({'chat_hidden': hidden});
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    socket = _FakeWebSocketService();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          socketServiceProvider.overrideWithValue(socket),
          roomProvider.overrideWith(
            (ref) => _TestRoomNotifier(
              ref,
              const ApiService(),
              socket,
              const RoomState(
                room: Room(roomId: 'K7Q2MX', name: 'Sala', hostId: 'u1'),
                localUser: _me,
                users: [_me],
              ),
            ),
          ),
        ],
        child: MaterialApp(
          theme: buildTheme(brightness),
          home: Scaffold(
            body: SafeArea(
              child: RoomWorkspace(
                onLeave: () {},
                onHelp: () {},
                onKick: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 400));
  }

  Future<bool> storedHidden() async =>
      (await SharedPreferences.getInstance()).getBool('chat_hidden') ?? false;

  const wide = Size(1440, 900);

  for (final brightness in Brightness.values) {
    group('laptop (${brightness.name})', () {
      testWidgets('plegado deja el riel y no el chat', (tester) async {
        final handle = tester.ensureSemantics();
        await pumpRoom(tester, size: wide, hidden: true, brightness: brightness);

        expect(find.bySemanticsLabel('Mostrar chat'), findsOneWidget);
        expect(find.byTooltip('Ocultar chat'), findsOneWidget);
        expect(tester.takeException(), isNull);
        handle.dispose();
      });

      testWidgets('abierto muestra el chat y no el riel', (tester) async {
        final handle = tester.ensureSemantics();
        await pumpRoom(tester, size: wide, brightness: brightness);

        expect(find.bySemanticsLabel('Mostrar chat'), findsNothing);
        expect(find.bySemanticsLabel('Ocultar chat'), findsOneWidget);
        expect(tester.takeException(), isNull);
        handle.dispose();
      });
    });
  }

  testWidgets('tocar el riel abre el chat y lo recuerda', (tester) async {
    await pumpRoom(tester, size: wide, hidden: true);

    await tester.tap(find.byTooltip('Mostrar chat'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(await storedHidden(), isFalse);
    final handle = tester.ensureSemantics();
    await tester.pump();
    expect(find.bySemanticsLabel('Ocultar chat'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('el botón de la tarjeta pliega el chat y lo recuerda', (
    tester,
  ) async {
    await pumpRoom(tester, size: wide);

    await tester.tap(find.byTooltip('Ocultar chat'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(await storedHidden(), isTrue);
    final handle = tester.ensureSemantics();
    await tester.pump();
    expect(find.bySemanticsLabel('Mostrar chat'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('el borrador sobrevive a plegar y abrir', (tester) async {
    await pumpRoom(tester, size: wide);

    await tester.enterText(find.byType(TextFormField).last, 'mi borrador');
    await tester.pump();

    await tester.tap(find.byTooltip('Ocultar chat'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byTooltip('Mostrar chat'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('mi borrador'), findsOneWidget);
  });

  testWidgets('el riel cuenta los mensajes sin leer', (tester) async {
    await pumpRoom(tester, size: wide, hidden: true);
    expect(find.text('1'), findsNothing);

    socket.handlers['new_message']!(_message('m1', 'hola'));
    await tester.pump();
    socket.handlers['new_message']!(_message('m2', 'estás?'));
    await tester.pump();

    expect(find.text('2'), findsOneWidget);
    final handle = tester.ensureSemantics();
    await tester.pump();
    expect(find.bySemanticsLabel('Mostrar chat, 2 sin leer'), findsOneWidget);
    handle.dispose();

    await tester.tap(find.byTooltip('Mostrar chat'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    expect(find.text('2'), findsNothing);
  });

  testWidgets('en tablet el botón sigue en el header', (tester) async {
    await pumpRoom(tester, size: const Size(834, 1112));

    expect(find.byTooltip('Ocultar chat'), findsOneWidget);
    await tester.tap(find.byTooltip('Ocultar chat'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(await storedHidden(), isTrue);
    expect(find.byTooltip('Mostrar chat'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('en tablet el chat se cierra con la X junto a las pestañas', (
    tester,
  ) async {
    await pumpRoom(tester, size: const Size(834, 1112));
    expect(find.byIcon(AppIcons.x), findsNothing);

    await tester.tap(find.text('Chat'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byIcon(AppIcons.x), findsOneWidget);

    await tester.tap(find.byIcon(AppIcons.x));
    await tester.pump(const Duration(milliseconds: 400));

    expect(await storedHidden(), isTrue);
    expect(find.byIcon(AppIcons.x), findsNothing);
    expect(find.text('Chat'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('en celular el chat trae una X que lo cierra', (tester) async {
    await pumpRoom(tester, size: const Size(390, 844));
    await tester.tap(find.text('Chat').last);
    await tester.pump(const Duration(milliseconds: 400));

    final close = find.descendant(
      of: find.byType(RoomWorkspace),
      matching: find.byIcon(AppIcons.x),
    );
    expect(close, findsOneWidget);

    await tester.tap(close);
    await tester.pump(const Duration(milliseconds: 400));

    expect(await storedHidden(), isTrue);
    expect(find.byIcon(AppIcons.x), findsNothing);
    expect(find.text('Chat'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('en el límite de 1100 px no hay overflow con el riel', (
    tester,
  ) async {
    await pumpRoom(tester, size: const Size(1100, 640), hidden: true);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('Mostrar chat'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull);
  });
}
