import 'package:flutter/widgets.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../core/constants.dart';

enum SocketConnectionStatus { disconnected, connecting, connected }

class WebSocketService with WidgetsBindingObserver {
  late io.Socket _socket;
  final ValueNotifier<SocketConnectionStatus> _status =
      ValueNotifier<SocketConnectionStatus>(
        SocketConnectionStatus.disconnected,
      );
      
  final List<void Function()> _connectedListeners = [];
  final List<void Function(String)> _errorListeners = [];
  
  // Guardamos los listeners para poder reasignarlos en el reconnectHard
  final Map<String, List<dynamic Function(dynamic)>> _eventListeners = {};

  WebSocketService() {
    _initSocket();
    WidgetsBinding.instance.addObserver(this);
  }

  void _initSocket() {
    _socket = io.io(
      kSocketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
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

    // Reasignar los listeners de eventos guardados
    _eventListeners.forEach((event, handlers) {
      for (final handler in handlers) {
        _socket.on(event, handler);
      }
    });
  }

  /// Realiza un reseteo completo del socket para limpiar conexiones fantasma
  void reconnectHard() {
    debugPrint('[ws] Ejecutando reconnectHard...');
    try {
      if (_status.value != SocketConnectionStatus.disconnected) {
        _status.value = SocketConnectionStatus.disconnected;
      }
      
      // Limpiar y destruir instancia actual
      _socket.clearListeners();
      _socket.disconnect();
      _socket.dispose();
      
      // Inicializar de nuevo
      _initSocket();
      connect();
    } catch (e) {
      debugPrint('[ws] Error en reconnectHard: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      debugPrint('[ws] App resumida, forzando reconnectHard');
      reconnectHard();
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _socket.clearListeners();
    _socket.disconnect();
    _socket.dispose();
  }

  void addOnConnected(void Function() callback) => _connectedListeners.add(callback);

  void addOnError(void Function(String) callback) => _errorListeners.add(callback);

  void connect() {
    if (!isConnected) {
      _status.value = SocketConnectionStatus.connecting;
    }
    _socket.connect();
  }

  void disconnect() {
    _socket.disconnect();
  }

  bool get isConnected => _status.value == SocketConnectionStatus.connected;
  bool get isConnecting => _status.value == SocketConnectionStatus.connecting;

  ValueNotifier<SocketConnectionStatus> get status => _status;

  void emit(String event, [dynamic data]) {
    try {
      _socket.emit(event, data);
    } catch (e) {
      debugPrint('[ws] Error emitiendo evento $event: $e');
    }
  }

  void on(String event, dynamic Function(dynamic data) handler) {
    if (!_eventListeners.containsKey(event)) {
      _eventListeners[event] = [];
    }
    // Evitar duplicación de handlers idénticos
    if (!_eventListeners[event]!.contains(handler)) {
      _eventListeners[event]!.add(handler);
      _socket.on(event, handler);
    }
  }

  void off(String event) {
    _eventListeners.remove(event);
    _socket.off(event);
  }
}
