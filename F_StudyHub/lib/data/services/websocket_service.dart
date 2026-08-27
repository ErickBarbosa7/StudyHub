import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../core/constants.dart';

enum SocketConnectionStatus { disconnected, connecting, connected }

class WebSocketService {
  late final io.Socket _socket;
  final ValueNotifier<SocketConnectionStatus> _status =
      ValueNotifier<SocketConnectionStatus>(
        SocketConnectionStatus.disconnected,
      );
  final List<void Function()> _connectedListeners = [];
  final List<void Function(String)> _errorListeners = [];

  WebSocketService() {
    _socket = io.io(
      kSocketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setReconnectionAttempts(5)
          .setReconnectionDelay(1000)
          .enableReconnection()
          .build(),
    );
    _socket.onConnect((_) {
      _status.value = SocketConnectionStatus.connected;
      debugPrint('[ws] Conectado al servidor');
      for (final listener in List.of(_connectedListeners)) {
        listener();
      }
    });
    _socket.onDisconnect((_) {
      _status.value = SocketConnectionStatus.disconnected;
      debugPrint('[ws] Desconectado del servidor');
    });
    _socket.onConnectError((err) {
      debugPrint('[ws] Error de conexión: $err');
      _status.value = SocketConnectionStatus.disconnected;
      for (final listener in List.of(_errorListeners)) {
        listener(err.toString());
      }
    });
  }

  void addOnConnected(void Function() callback) =>
      _connectedListeners.add(callback);

  void addOnError(void Function(String) callback) =>
      _errorListeners.add(callback);

  void connect() {
    if (!isConnected) {
      _status.value = SocketConnectionStatus.connecting;
    }
    _socket.connect();
  }

  void disconnect() => _socket.disconnect();

  bool get isConnected => _status.value == SocketConnectionStatus.connected;

  bool get isConnecting => _status.value == SocketConnectionStatus.connecting;

  ValueNotifier<SocketConnectionStatus> get status => _status;

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
