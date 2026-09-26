import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:studyhub/core/avatars.dart';
import 'package:studyhub/core/theme.dart';
import 'package:studyhub/data/models/room_model.dart';
import 'package:studyhub/data/models/user_model.dart';
import 'package:studyhub/data/services/api_service.dart';
import 'package:studyhub/data/services/websocket_service.dart';
import 'package:studyhub/logic/room_provider.dart';
import 'package:studyhub/logic/socket_provider.dart';
import 'package:studyhub/ui/room/room_widgets.dart';
import 'package:studyhub/ui/widgets/avatar_picker.dart';

class _FakeWebSocketService extends WebSocketService {
  final Map<String, dynamic Function(dynamic)> handlers = {};
  final List<(String, dynamic)> emitted = [];

  @override
  void connect() {}

  @override
  void disconnect() {}

  @override
  bool get isConnected => true;

  @override
  void emit(String event, [dynamic data]) => emitted.add((event, data));

  @override
  void on(String event, dynamic Function(dynamic data) handler) =>
      handlers[event] = handler;

  @override
  void off(String event) {}

  List<dynamic> emittedOf(String event) => [
    for (final e in emitted)
      if (e.$1 == event) e.$2,
  ];
}

class _TestRoomNotifier extends RoomNotifier {
  _TestRoomNotifier(super.ref, super.api, super.socket, RoomState initial) {
    state = initial;
  }
}

const _me = User(id: 'u1', name: 'Erick', avatarSeed: 'Cactus');
const _ana = User(id: 'u2', name: 'Ana', avatarSeed: 'Aloe');

const _room = Room(roomId: 'K7Q2MX', name: 'Sala', hostId: 'u1');

/// Abre el selector dentro de un esqueleto mínimo con hoja modal.
Future<_FakeWebSocketService> _pumpPicker(
  WidgetTester tester, {
  RoomState? state,
}) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = const Size(400, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final socket = _FakeWebSocketService();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        socketServiceProvider.overrideWithValue(socket),
        roomProvider.overrideWith(
          (ref) => _TestRoomNotifier(
            ref,
            const ApiService(),
            socket,
            state ??
                const RoomState(
                  room: _room,
                  localUser: _me,
                  users: [_me, _ana],
                ),
          ),
        ),
      ],
      child: MaterialApp(
        theme: buildTheme(),
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () => showAvatarPicker(context),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  return socket;
}

Future<void> _openPicker(WidgetTester tester) async {
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
}

Finder _seedCell(String seed) => find.byWidgetPredicate(
  (w) => w is RoomAvatar && w.seed == seed,
);

void main() {
  for (final brightness in Brightness.values) {
    group('Selector de avatar (${brightness.name})', () {
      testWidgets('dibuja las 23 macetas y marca solo la tuya', (tester) async {
        await _pumpPicker(tester);
        await _openPicker(tester);

        expect(find.text('Elige tu avatar'), findsOneWidget);
        expect(find.byType(RoomAvatar), findsNWidgets(kAvatarSeeds.length));
        expect(find.bySemanticsLabel('Tu avatar actual'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('las de otro quedan sin poder tocarse', (tester) async {
        await _pumpPicker(tester);
        await _openPicker(tester);

        expect(find.bySemanticsLabel('Ana está usando esta maceta'), findsOneWidget);
        expect(find.bySemanticsLabel('Elegir esta maceta'), findsNWidgets(21));
        expect(
          find.bySemanticsLabel('Elegir esta maceta'),
          findsNWidgets(kAvatarSeeds.length - 2),
        );
      });

      testWidgets('elegir una libre la aplica, cierra y guarda la preferencia', (
        tester,
      ) async {
        final socket = await _pumpPicker(tester);
        await _openPicker(tester);

        await tester.tap(_seedCell('Lavanda'));
        await tester.pumpAndSettle();

        expect(socket.emittedOf('set_avatar'), [
          {'roomId': 'K7Q2MX', 'userId': 'u1', 'avatarSeed': 'Lavanda'},
        ]);
        expect(find.text('Elige tu avatar'), findsNothing, reason: 'se cierra');

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('avatar_seed'), 'Lavanda');
      });

      testWidgets('la ocupada no se puede tocar: ni emite ni avisa', (
        tester,
      ) async {
        final socket = await _pumpPicker(tester);
        await _openPicker(tester);

        await tester.tap(_seedCell('Aloe'), warnIfMissed: false);
        await tester.pumpAndSettle();

        expect(socket.emittedOf('set_avatar'), isEmpty);
        expect(find.text('Elige tu avatar'), findsOneWidget, reason: 'sigue abierta');
      });
    });
  }

  group('setAvatarSeed', () {
    testWidgets('devuelve el nombre de quien bloquea y no emite', (tester) async {
      final socket = await _pumpPicker(tester);
      final container = ProviderScope.containerOf(
        tester.element(find.text('abrir')),
      );

      final taken = await container.read(roomProvider.notifier).setAvatarSeed('Aloe');

      expect(taken, 'Ana');
      expect(socket.emittedOf('set_avatar'), isEmpty);
    });

    testWidgets('aplica de inmediato y espera el eco del servidor', (
      tester,
    ) async {
      final socket = await _pumpPicker(tester);
      final container = ProviderScope.containerOf(
        tester.element(find.text('abrir')),
      );
      final room = container.read(roomProvider.notifier);

      final taken = await room.setAvatarSeed('Hiedra');
      expect(taken, isNull);
      expect(
        container.read(roomProvider).localUser?.avatarSeed,
        'Hiedra',
        reason: 'optimista: no espera al broadcast',
      );
      expect(socket.emittedOf('set_avatar'), hasLength(1));

      // El servidor confirma (o corrige) con la lista completa.
      socket.handlers['room_users_update']!([
        {'id': 'u2', 'name': 'Ana', 'avatarSeed': 'Aloe'},
        {'id': 'u1', 'name': 'Erick', 'avatarSeed': 'Mora'},
      ]);
      expect(container.read(roomProvider).localUser?.avatarSeed, 'Mora');
    });

    testWidgets('room_users_update trae la seed propia al usuario local', (
      tester,
    ) async {
      final socket = await _pumpPicker(tester);
      final container = ProviderScope.containerOf(
        tester.element(find.text('abrir')),
      );

      // Estado inicial sin seed propia, como tras un join viejo.
      expect(container.read(roomProvider).localUser?.avatarSeed, 'Cactus');
      socket.handlers['room_users_update']!([
        {'id': 'u2', 'name': 'Ana', 'avatarSeed': 'Aloe'},
        {'id': 'u1', 'name': 'Erick', 'avatarSeed': 'Ficus'},
      ]);

      final state = container.read(roomProvider);
      expect(state.localUser?.avatarSeed, 'Ficus');
      expect(state.users.map((u) => u.avatarSeed), ['Aloe', 'Ficus']);
    });

    testWidgets('si la lista no me incluye, conserva el usuario local', (
      tester,
    ) async {
      final socket = await _pumpPicker(tester);
      final container = ProviderScope.containerOf(
        tester.element(find.text('abrir')),
      );
      // Leerlo es lo que construye el notifier y registra los handlers.
      container.read(roomProvider);

      socket.handlers['room_users_update']!([
        {'id': 'u2', 'name': 'Ana', 'avatarSeed': 'Aloe'},
      ]);

      final state = container.read(roomProvider);
      expect(state.localUser?.id, 'u1');
      expect(state.localUser?.avatarSeed, 'Cactus');
    });
  });
}
