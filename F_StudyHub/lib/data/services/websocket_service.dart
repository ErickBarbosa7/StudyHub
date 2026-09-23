import 'package:flutter/widgets.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../core/constants.dart';

enum SocketConnectionStatus { disconnected, connecting, connected }

const int _kConnectionTimeoutMs = 5000;
const int _kReconnectionAttempts = 5;
const int _kReconnectionDelayMs = 1000;
const int _kReconnectionDelayMaxMs = 3000;

class WebSocketService with WidgetsBindingObserver {
  late io.Socket _socket;
  final ValueNotifier<SocketConnectionStatus> _status =
      ValueNotifier<SocketConnectionStatus>(
        SocketConnectionStatus.disconnected,
      );

  final List<void Function()> _connectedListeners = [];
  final List<void Function(String)> _errorListeners = [];
  final List<void Function()> _gaveUpListeners = [];

  // Guardamos los listeners para poder reasignarlos en el reconnectHard
  final Map<String, List<dynamic Function(dynamic)>> _eventListeners = {};

  bool _isReinitializing = false;
  bool _hasGivenUp = false;

  WebSocketService() {
    _initSocket();
    WidgetsBinding.instance.addObserver(this);
  }

  void _initSocket() {
    // enableForceNew evita reutilizar el Manager cacheado del puerto/host,
    // de modo que cada init parte de un manager limpio sin loops fantasma.
    _socket = io.io(
      kSocketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .enableReconnection()
          .setReconnectionDelay(_kReconnectionDelayMs)
          .setReconnectionDelayMax(_kReconnectionDelayMaxMs)
          .setReconnectionAttempts(_kReconnectionAttempts)
          .setTimeout(_kConnectionTimeoutMs)
          .enableForceNew()
          .build(),
    );
    _hasGivenUp = false;

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
      // No se notifica el error por intento: solo se informa al rendirnos
      // (reconnect_failed) para no hacer parpadear el banner.
      debugPrint('[ws] Error de conexión: $err');
      _status.value = SocketConnectionStatus.disconnected;
    });

    // El evento reconnect_failed lo emite el Manager, no el Socket.
    _socket.io.on('reconnect_failed', (_) {
      debugPrint('[ws] Intentos de reconexión agotados');
      _handleGiveUp();
    });

    // Reasignar los listeners de eventos guardados
    _eventListeners.forEach((event, handlers) {
      for (final handler in handlers) {
        _socket.on(event, handler);
      }
    });
  }

  void _handleGiveUp() {
    if (_hasGivenUp) return;
    _hasGivenUp = true;
    _status.value = SocketConnectionStatus.disconnected;
    const message = 'No se pudo establecer la conexión con el servidor.';
    for (final listener in List.of(_gaveUpListeners)) {
      listener();
    }
    for (final listener in List.of(_errorListeners)) {
      listener(message);
    }
  }

  bool get hasGivenUp => _hasGivenUp;

  /// Realiza un reseteo completo del socket para limpiar conexiones fantasma
  void reconnectHard() {
    if (_isReinitializing) return;
    _isReinitializing = true;
    debugPrint('[ws] Ejecutando reconnectHard...');
    try {
      if (_status.value != SocketConnectionStatus.disconnected) {
        _status.value = SocketConnectionStatus.disconnected;
      }

      // Detener el loop del manager anterior para evitar reconexiones fantasma.
      try {
        final manager = _socket.io;
        manager.skipReconnect = true;
        _socket.clearListeners();
        _socket.disconnect();
        _socket.dispose();
      } catch (e) {
        debugPrint('[ws] Error limpiando socket anterior: $e');
      }

      // Inicializar de nuevo con un Manager nuevo (enableForceNew)
      _initSocket();
      connect();
    } catch (e) {
      debugPrint('[ws] Error en reconnectHard: $e');
    } finally {
      _isReinitializing = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Solo reconectar al volver a la app si no estamos conectados;
    // si ya tenemos conexión no tiene sentido destruir el socket.
    if (state == AppLifecycleState.resumed && !isConnected) {
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

  void addOnGaveUp(void Function() callback) => _gaveUpListeners.add(callback);

  void connect() {
    _hasGivenUp = false;
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
