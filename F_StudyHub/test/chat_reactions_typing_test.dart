import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:studyhub/core/theme.dart';
import 'package:studyhub/data/models/message_model.dart';
import 'package:studyhub/data/models/room_model.dart';
import 'package:studyhub/data/models/user_model.dart';
import 'package:studyhub/data/services/api_service.dart';
import 'package:studyhub/data/services/websocket_service.dart';
import 'package:studyhub/logic/chat_provider.dart';
import 'package:studyhub/logic/room_provider.dart';
import 'package:studyhub/logic/socket_provider.dart';
import 'package:studyhub/ui/widgets/chat_box.dart';

class _FakeWebSocketService extends WebSocketService {
  final Map<String, dynamic Function(dynamic)> handlers = {};
  final List<(String, dynamic)> emitted = [];

  @override
  void connect() {}

  @override
  void disconnect() {}

  @override
  bool get isConnected => false;

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

const _me = User(id: 'u1', name: 'Erick');

Map<String, dynamic> _message(
  String id,
  String senderId,
  String name,
  String text, {
  List<Map<String, dynamic>>? reactions,
}) => {
  'id': id,
  'roomId': 'K7Q2MX',
  'senderId': senderId,
  'senderName': name,
  'text': text,
  'timestamp': '2026-09-25T10:00:00.000Z',
  'reactions': ?reactions,
};

Future<(ProviderContainer, _FakeWebSocketService)> _container() async {
  final socket = _FakeWebSocketService();
  final container = ProviderContainer(
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
  );
  addTearDown(container.dispose);
  container.read(chatProvider);
  return (container, socket);
}

void main() {
  group('Message', () {
    test('sin campo reactions (servidor viejo) queda vacío', () {
      final m = Message.fromJson(_message('m1', 'u2', 'Ana', 'hola'));
      expect(m.reactions, isEmpty);
    });

    test('lee reacciones y descarta emojis sin usuarios', () {
      final m = Message.fromJson(
        _message(
          'm1',
          'u2',
          'Ana',
          'hola',
          reactions: [
            {'emoji': '🚀', 'userIds': ['u1', 'u3']},
            {'emoji': '🔥', 'userIds': <String>[]},
          ],
        ),
      );
      expect(m.reactions, {
        '🚀': ['u1', 'u3'],
      });
    });
  });

  group('reacciones', () {
    test('toggleReaction emite con sala, mensaje y usuario', () async {
      final (container, socket) = await _container();
      container.read(chatProvider.notifier).toggleReaction('m1', '🔥');

      expect(socket.emittedOf('toggle_reaction'), [
        {'roomId': 'K7Q2MX', 'messageId': 'm1', 'userId': 'u1', 'emoji': '🔥'},
      ]);
    });

    test('ignora emojis fuera de la lista permitida', () async {
      final (container, socket) = await _container();
      container.read(chatProvider.notifier).toggleReaction('m1', '💩');
      expect(socket.emittedOf('toggle_reaction'), isEmpty);
    });

    test('message_reactions actualiza solo ese mensaje', () async {
      final (container, socket) = await _container();
      socket.handlers['chat_history']!([
        _message('m1', 'u2', 'Ana', 'hola'),
        _message('m2', 'u2', 'Ana', 'que tal'),
      ]);
      socket.handlers['message_reactions']!({
        'roomId': 'K7Q2MX',
        'messageId': 'm2',
        'reactions': [
          {'emoji': '🍅', 'userIds': ['u1']},
        ],
      });

      final messages = container.read(chatProvider).messages;
      expect(messages[0].reactions, isEmpty);
      expect(messages[1].reactions, {
        '🍅': ['u1'],
      });
    });

    test('reaccionar no cuenta como mensaje no leído', () async {
      final (container, socket) = await _container();
      socket.handlers['chat_history']!([_message('m1', 'u2', 'Ana', 'hola')]);
      socket.handlers['message_reactions']!({
        'roomId': 'K7Q2MX',
        'messageId': 'm1',
        'reactions': [
          {'emoji': '🚀', 'userIds': ['u2']},
        ],
      });
      expect(container.read(chatProvider).unreadCount, 0);
    });
  });

  group('escribiendo', () {
    void typing(_FakeWebSocketService s, String id, String name, bool on) =>
        s.handlers['user_typing']!({
          'roomId': 'K7Q2MX',
          'userId': id,
          'userName': name,
          'isTyping': on,
        });

    test('muestra a quien escribe y lo quita al parar', () async {
      final (container, socket) = await _container();
      typing(socket, 'u2', 'Ana', true);
      expect(container.read(chatProvider).typingUsers, {'u2': 'Ana'});
      typing(socket, 'u2', 'Ana', false);
      expect(container.read(chatProvider).typingUsers, isEmpty);
    });

    test('no se muestra a uno mismo', () async {
      final (container, socket) = await _container();
      typing(socket, 'u1', 'Erick', true);
      expect(container.read(chatProvider).typingUsers, isEmpty);
    });

    test('se quita cuando esa persona envía su mensaje', () async {
      final (container, socket) = await _container();
      typing(socket, 'u2', 'Ana', true);
      socket.handlers['new_message']!(_message('m1', 'u2', 'Ana', 'listo'));
      expect(container.read(chatProvider).typingUsers, isEmpty);
    });

    testWidgets('caduca solo si no se renueva', (tester) async {
      final (container, socket) = await _container();
      typing(socket, 'u2', 'Ana', true);

      await tester.pump(const Duration(seconds: 3));
      typing(socket, 'u2', 'Ana', true);
      await tester.pump(const Duration(seconds: 3));
      expect(container.read(chatProvider).typingUsers, {'u2': 'Ana'});

      await tester.pump(const Duration(seconds: 3));
      expect(container.read(chatProvider).typingUsers, isEmpty);
    });

    test('notifyTyping emite al empezar, no en cada tecla, y al parar', () async {
      final (container, socket) = await _container();
      final chat = container.read(chatProvider.notifier);

      chat.notifyTyping(true);
      chat.notifyTyping(true);
      chat.notifyTyping(true);
      expect(socket.emittedOf('typing'), hasLength(1));

      chat.notifyTyping(false);
      chat.notifyTyping(false);
      expect(socket.emittedOf('typing'), [
        {'roomId': 'K7Q2MX', 'userId': 'u1', 'isTyping': true},
        {'roomId': 'K7Q2MX', 'userId': 'u1', 'isTyping': false},
      ]);
    });

    test('enviar un mensaje avisa que se dejó de escribir', () async {
      final (container, socket) = await _container();
      final chat = container.read(chatProvider.notifier);
      chat.notifyTyping(true);
      chat.sendMessage('hola');

      final events = [for (final e in socket.emitted) e.$1];
      expect(events, ['typing', 'typing', 'send_message']);
      expect(socket.emittedOf('typing').last['isTyping'], false);
    });
  });

  for (final brightness in Brightness.values) {
    group('ChatBox (${brightness.name})', () {
      late _FakeWebSocketService socket;

      Future<void> pumpChat(
        WidgetTester tester, {
        List<Map<String, dynamic>>? history,
      }) async {
        SharedPreferences.setMockInitialValues({});
        tester.view.physicalSize = const Size(400, 700);
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
              home: const Scaffold(
                body: Padding(padding: EdgeInsets.all(16), child: ChatBox()),
              ),
            ),
          ),
        );
        socket.handlers['chat_history']!(
          history ?? [
            _message('m1', 'u2', 'Ana', 'Vamos con todo'),
            _message(
              'm2',
              'u1',
              'Erick',
              'Listo',
              reactions: [
                {'emoji': '🚀', 'userIds': ['u1', 'u2']},
                {'emoji': '🍅', 'userIds': ['u3']},
              ],
            ),
          ],
        );
        await tester.pump();
      }

      testWidgets('muestra chips con cuenta y sin overflow', (tester) async {
        await pumpChat(tester);
        expect(find.text('🚀'), findsOneWidget);
        expect(find.text('2'), findsOneWidget);
        expect(find.text('🍅'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('tocar un mensaje abre el selector y reaccionar emite', (
        tester,
      ) async {
        await pumpChat(tester);
        expect(find.text('🔥'), findsNothing);

        await tester.tap(find.text('Vamos con todo'));
        await tester.pumpAndSettle();
        expect(find.text('🔥'), findsOneWidget);

        await tester.tap(find.text('🔥'));
        await tester.pumpAndSettle();

        final sent = socket.emittedOf('toggle_reaction');
        expect(sent, hasLength(1));
        expect(sent.first['messageId'], 'm1');
        expect(sent.first['emoji'], '🔥');
        expect(find.text('🔥'), findsNothing);
      });

      testWidgets('tocar un chip alterna la reacción propia', (tester) async {
        await pumpChat(tester);
        await tester.tap(find.text('🍅'));
        await tester.pump();

        final sent = socket.emittedOf('toggle_reaction');
        expect(sent.single['messageId'], 'm2');
        expect(sent.single['emoji'], '🍅');
      });

      testWidgets('un usuario con dos emojis de un mensaje viejo marca solo uno', (
        tester,
      ) async {
        // El servidor ya no lo permite, pero un mensaje guardado antes del arreglo
        // puede traerlo: la interfaz solo debe highlighting uno.
        await pumpChat(
          tester,
          history: [
            _message(
              'm1',
              'u2',
              'Ana',
              'Vamos con todo',
              reactions: [
                {'emoji': '🚀', 'userIds': ['u1']},
                {'emoji': '🔥', 'userIds': ['u1', 'u2']},
              ],
            ),
          ],
        );

        await tester.tap(find.text('Vamos con todo'));
        await tester.pumpAndSettle();

        expect(find.bySemanticsLabel('Quitar reacción 🚀'), findsOneWidget);
        expect(find.bySemanticsLabel('Quitar reacción 🔥'), findsNothing);
        expect(find.bySemanticsLabel('Quitar reacción 🍅'), findsNothing);
        expect(
          find.bySemanticsLabel('Reaccionar con 🔥'),
          findsOneWidget,
          reason: 'el resto del selector sigue disponible para cambiar',
        );
      });

      testWidgets('indicador de escribiendo aparece y desaparece', (
        tester,
      ) async {
        await pumpChat(tester);
        expect(find.textContaining('escribiendo'), findsNothing);

        socket.handlers['user_typing']!({
          'roomId': 'K7Q2MX',
          'userId': 'u2',
          'userName': 'Ana',
          'isTyping': true,
        });
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('Ana está escribiendo'), findsOneWidget);

        socket.handlers['user_typing']!({
          'roomId': 'K7Q2MX',
          'userId': 'u3',
          'userName': 'Marco',
          'isTyping': true,
        });
        await tester.pump();
        expect(find.text('Ana y Marco están escribiendo'), findsOneWidget);

        socket.handlers['user_typing']!({
          'roomId': 'K7Q2MX',
          'userId': 'u2',
          'userName': 'Ana',
          'isTyping': false,
        });
        socket.handlers['user_typing']!({
          'roomId': 'K7Q2MX',
          'userId': 'u3',
          'userName': 'Marco',
          'isTyping': false,
        });
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.textContaining('escribiendo'), findsNothing);
      });

      testWidgets('escribir en el campo avisa a la sala', (tester) async {
        await pumpChat(tester);
        await tester.enterText(find.byType(TextFormField), 'ho');
        await tester.pump();

        expect(socket.emittedOf('typing').single['isTyping'], true);

        await tester.enterText(find.byType(TextFormField), '');
        await tester.pump();
        expect(socket.emittedOf('typing').last['isTyping'], false);
      });
    });
  }
}
