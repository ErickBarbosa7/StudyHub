import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

const _sizes = [
  Size(1440, 900), // laptop
  Size(1100, 640), // laptop baja
  Size(834, 1112), // tablet vertical
  Size(720, 700), // tablet chica
  Size(390, 844), // celular
  Size(320, 568), // celular pequeño
  Size(640, 360), // celular horizontal
];

void main() {
  for (final chatHidden in [false, true]) {
    for (final size in _sizes) {
      for (final mode in ['FOCUS', 'SHORT_BREAK']) {
        testWidgets(
          'Sala sin overflow: ${size.width.toInt()}x${size.height.toInt()} '
          '$mode ${chatHidden ? 'sin chat' : 'con chat'}',
          (tester) async {
            SharedPreferences.setMockInitialValues({'chat_hidden': chatHidden});
            tester.view.physicalSize = size;
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.reset);

            final socket = _FakeWebSocketService();
            const me = User(id: 'u1', name: 'Erick Barbosa');
            final room = const Room(
              roomId: 'K7Q2MX',
              name: 'Cálculo II · Repaso',
              hostId: 'u1',
            );
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
                        room: room,
                        localUser: me,
                        users: const [
                          me,
                          User(id: 'u2', name: 'Marco'),
                          User(id: 'u3', name: 'Ana Lu'),
                        ],
                      ),
                    ),
                  ),
                ],
                child: MaterialApp(
                  theme: buildTheme(),
                  home: Scaffold(
                    backgroundColor: AppColors.light.bg,
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

            socket.handlers['timer_tick']!({
              'timeRemaining': 125,
              'totalSeconds': 300,
              'status': 'RUNNING',
              'mode': mode,
              'completedFocus': 2,
            });
            await tester.pump(const Duration(seconds: 1));
            final first = tester.takeException();
            if (first != null) {
              // ignore: avoid_print
              print('EXC: $first');
            }
            expect(first, isNull);

            // Celular: recorre las secciones de la barra inferior.
            if (size.width < 700) {
              for (final label in ['Tareas', if (!chatHidden) 'Chat', 'Foco']) {
                await tester.tap(find.text(label).last);
                await tester.pump(const Duration(milliseconds: 400));
                expect(
                  tester.takeException(),
                  isNull,
                  reason: 'sección $label',
                );
              }
              expect(
                find.text('Chat'),
                chatHidden ? findsNothing : findsWidgets,
              );
            }
          },
        );
      }
    }
  }
}
