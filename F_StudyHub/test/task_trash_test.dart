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
import 'package:studyhub/ui/widgets/task_list.dart';

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
}

class _TestRoomNotifier extends RoomNotifier {
  _TestRoomNotifier(super.ref, super.api, super.socket, RoomState initial) {
    state = initial;
  }
}

Map<String, dynamic> _task(String id, String title) => {
  'taskId': id,
  'title': title,
  'stateCode': 'PENDING',
  'stateLabel': 'Pendiente',
};

void main() {
  late _FakeWebSocketService socket;

  Future<void> pumpList(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(600, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    socket = _FakeWebSocketService();
    const me = User(id: 'u1', name: 'Erick');
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
                localUser: me,
                users: [me],
              ),
            ),
          ),
        ],
        child: MaterialApp(
          theme: buildTheme(),
          home: const Scaffold(
            body: Padding(padding: EdgeInsets.all(16), child: TaskList()),
          ),
        ),
      ),
    );
    socket.handlers['task_sync']!([
      _task('a', 'Leer capítulo'),
      _task('b', 'Resolver guía'),
    ]);
    await tester.pump();
  }

  Finder handle(int i) => find.byIcon(AppIcons.gripVertical).at(i);

  testWidgets('la papelera solo aparece mientras se arrastra', (tester) async {
    await pumpList(tester);
    expect(find.text('Arrastra aquí para eliminar'), findsOneWidget);
    final slide = tester.widget<AnimatedOpacity>(
      find.ancestor(
        of: find.byIcon(AppIcons.trash2),
        matching: find.byType(AnimatedOpacity),
      ),
    );
    expect(slide.opacity, 0);

    final g = await tester.startGesture(tester.getCenter(handle(0)));
    await g.moveBy(const Offset(0, 30));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    final shown = tester.widget<AnimatedOpacity>(
      find.ancestor(
        of: find.byIcon(AppIcons.trash2),
        matching: find.byType(AnimatedOpacity),
      ),
    );
    expect(shown.opacity, 1);
    await g.up();
    await tester.pump(const Duration(milliseconds: 500));
  });

  testWidgets('soltar sobre la papelera pide confirmar y elimina', (
    tester,
  ) async {
    await pumpList(tester);

    final g = await tester.startGesture(tester.getCenter(handle(0)));
    await g.moveBy(const Offset(0, 40));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await g.moveTo(tester.getCenter(find.byIcon(AppIcons.trash2)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Suelta para eliminar'), findsOneWidget);
    await g.up();
    await tester.pumpAndSettle();

    expect(find.text('¿Eliminar tarea?'), findsOneWidget);
    expect(socket.emitted.where((e) => e.$1 == 'reorder_tasks'), isEmpty);

    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();
    final deletes = socket.emitted.where((e) => e.$1 == 'delete_task');
    expect(deletes, hasLength(1));
    expect(deletes.first.$2['taskId'], 'a');
  });

  testWidgets('soltar fuera de la papelera solo reordena', (tester) async {
    await pumpList(tester);

    final g = await tester.startGesture(tester.getCenter(handle(0)));
    await g.moveBy(const Offset(0, 40));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await g.moveBy(const Offset(0, 80));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await g.up();
    await tester.pumpAndSettle();

    expect(find.text('¿Eliminar tarea?'), findsNothing);
    expect(socket.emitted.where((e) => e.$1 == 'delete_task'), isEmpty);
  });
}
