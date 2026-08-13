import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/services/websocket_service.dart';

final socketServiceProvider = Provider<WebSocketService>((ref) {
  final service = WebSocketService();
  ref.onDispose(service.disconnect);
  return service;
});
