import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../core/constants.dart';

class WebSocketService {
  late final io.Socket _socket;
  bool _connected = false;
  void Function()? _onConnected;

  WebSocketService() {
    _socket = io.io(kSocketUrl, io.OptionBuilder()
        .setTransports(['websocket'])
        .disableAutoConnect()
        .build());
    _socket.onConnect((_) {
      _connected = true;
      debugPrint('[ws] Conectado al servidor');
      _onConnected?.call();
    });
    _socket.onDisconnect((_) {
      _connected = false;
      debugPrint('[ws] Desconectado del servidor');
    });
    _socket.onConnectError((err) => debugPrint('[ws] Error de conexión: $err'));
  }

  set onConnected(void Function()? callback) => _onConnected = callback;

  void connect() => _socket.connect();

  void disconnect() => _socket.disconnect();

  bool get isConnected => _connected;

  void emit(String event, [dynamic data]) {
    _socket.emit(event, data);
  }

  void on(String event, dynamic Function(dynamic data) handler) {
    _socket.on(event, handler);
  }

  void off(String event) {
    _socket.off(event);
  }
}