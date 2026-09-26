import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
import 'package:studyhub/ui/widgets/chat_box.dart';

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
const _marco = User(id: 'u3', name: 'Marco', avatarSeed: 'Higo');

Map<String, dynamic> _message(
  String id,
  String senderId,
  String name,
  String text,
) => {
  'id': id,
  'roomId': 'K7Q2MX',
  'senderId': senderId,
  'senderName': name,
  'text': text,
  'timestamp': '2026-09-25T10:00:00.000Z',
  'reactions': <Map<String, dynamic>>[],
};

Finder _avatarWithSeed(String seed) => find.byWidgetPredicate(
  (w) => w is RoomAvatar && w.seed == seed,
);

Future<_FakeWebSocketService> _pumpChat(
  WidgetTester tester, {
  required Size size,
  required List<Map<String, dynamic>> history,
  List<User> users = const [_me, _ana, _marco],
}) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = size;
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
            RoomState(
              room: const Room(roomId: 'K7Q2MX', name: 'Sala', hostId: 'u1'),
              localUser: _me,
              users: users,
            ),
          ),
        ),
      ],
      child: MaterialApp(
        theme: buildTheme(),
        home: const Scaffold(
          body: Padding(padding: EdgeInsets.all(8), child: ChatBox()),
        ),
      ),
    ),
  );
  socket.handlers['chat_history']!(history);
  await tester.pump();
  return socket;
}

void main() {
  for (final brightness in Brightness.values) {
    group('ChatBox avatares (${brightness.name})', () {
      testWidgets('pone el avatar de quien envía y "Tú" en los propios', (
        tester,
      ) async {
        await _pumpChat(
          tester,
          size: const Size(400, 700),
          history: [
            _message('m1', 'u2', 'Ana', 'Hola equipo'),
            _message('m2', 'u1', 'Erick', '¡Listo!'),
          ],
        );

        expect(_avatarWithSeed('Aloe'), findsOneWidget);
        expect(_avatarWithSeed('Cactus'), findsOneWidget);
        expect(find.text('Ana'), findsOneWidget);
        expect(find.text('Tú'), findsOneWidget);
        expect(find.text('Erick'), findsNothing, reason: 'el propio es "Tú"');
        expect(tester.takeException(), isNull);
      });

      testWidgets('agrupa la racha: avatar y nombre solo en el primero', (
        tester,
      ) async {
        await _pumpChat(
          tester,
          size: const Size(400, 700),
          history: [
            _message('m1', 'u2', 'Ana', 'Primera'),
            _message('m2', 'u2', 'Ana', 'Segunda'),
            _message('m3', 'u2', 'Ana', 'Tercera'),
            _message('m4', 'u1', 'Erick', 'Respondo'),
          ],
        );

        expect(
          find.byType(RoomAvatar),
          findsNWidgets(2),
          reason: 'uno al inicio de la racha de Ana y otro en el de Erick',
        );
        expect(_avatarWithSeed('Aloe'), findsOneWidget);
        expect(_avatarWithSeed('Cactus'), findsOneWidget);
        expect(find.text('Ana'), findsOneWidget);
        expect(find.text('Tú'), findsOneWidget);
        expect(find.text('Tercera'), findsOneWidget, reason: 'los mensajes sí');
      });

      testWidgets('corta la racha cuando cambia quien envía', (tester) async {
        await _pumpChat(
          tester,
          size: const Size(400, 700),
          history: [
            _message('m1', 'u2', 'Ana', 'Primera'),
            _message('m2', 'u3', 'Marco', 'Interrumpe'),
            _message('m3', 'u2', 'Ana', 'Vuelve'),
          ],
        );

        expect(find.byType(RoomAvatar), findsNWidgets(3));
        expect(find.text('Ana'), findsNWidgets(2));
        expect(find.text('Marco'), findsOneWidget);
      });

      testWidgets('quien ya no está en la sala cae a las iniciales', (
        tester,
      ) async {
        await _pumpChat(
          tester,
          size: const Size(400, 700),
          history: [_message('m1', 'u9', 'Salta', 'Mensaje viejo')],
        );

        expect(find.byType(SvgPicture), findsNothing);
        expect(find.text('SA'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('sin overflow a 320 de ancho', (tester) async {
        await _pumpChat(
          tester,
          size: const Size(320, 640),
          history: [
            _message('m1', 'u2', 'Ana', 'Un mensaje bastante largo para forzar el ancho máximo de la burbuja'),
            _message('m2', 'u1', 'Erick', 'Y otro propio también larguísimo'),
          ],
        );

        expect(tester.takeException(), isNull);
      });

      testWidgets('tocar tu avatar abre el selector, el ajeno no', (
        tester,
      ) async {
        await _pumpChat(
          tester,
          size: const Size(400, 700),
          history: [
            _message('m1', 'u2', 'Ana', 'Hola equipo'),
            _message('m2', 'u1', 'Erick', '¡Listo!'),
          ],
        );

        await tester.tap(find.bySemanticsLabel('Cambiar tu avatar'));
        await tester.pumpAndSettle();
        expect(find.text('Elige tu avatar'), findsOneWidget);
        expect(
          find.bySemanticsLabel('Tu avatar actual'),
          findsOneWidget,
          reason: 'solo la tuya va marcada como actual',
        );
        expect(
          find.byType(RoomAvatar),
          findsNWidgets(2 + kAvatarSeeds.length),
          reason: 'los 2 mensajes de atrás más la rejilla completa',
        );

        await tester.tapAt(const Offset(5, 5));
        await tester.pumpAndSettle();
        expect(find.text('Elige tu avatar'), findsNothing);
      });
    });
  }
}
