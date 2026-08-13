import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:studyhub/data/services/websocket_service.dart';
import 'package:studyhub/logic/socket_provider.dart';
import 'package:studyhub/main.dart';

class _FakeWebSocketService extends WebSocketService {
  _FakeWebSocketService();

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

void main() {
  testWidgets('StudyHub renders home screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          socketServiceProvider.overrideWithValue(_FakeWebSocketService()),
        ],
        child: const StudyHubApp(),
      ),
    );
    await tester.pump();

    expect(find.text('StudyHub'), findsOneWidget);
    expect(
      find.text('Crea una sala o únete con un código.'),
      findsOneWidget,
    );
  });
}