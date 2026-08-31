import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:flutter_riverpod/legacy.dart'
    show StateNotifier, StateNotifierProvider;

import '../data/services/websocket_service.dart';

class SocketState {
  const SocketState({
    this.isConnecting = false,
    this.isConnected = false,
    this.error,
  });

  final bool isConnecting;
  final bool isConnected;
  final String? error;

  SocketState copyWith({
    bool? isConnecting,
    bool? isConnected,
    String? error,
    bool clearError = false,
  }) {
    return SocketState(
      isConnecting: isConnecting ?? this.isConnecting,
      isConnected: isConnected ?? this.isConnected,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class SocketNotifier extends StateNotifier<SocketState> {
  SocketNotifier(this._service) : super(const SocketState()) {
    _service.addOnConnected(() {
      state = state.copyWith(isConnecting: false, isConnected: true);
    });
    _service.addOnError((err) {
      state = state.copyWith(
        isConnecting: false,
        isConnected: _service.isConnected,
        error: err,
      );
    });
    _service.status.addListener(_onStatusChanged);
  }

  final WebSocketService _service;
  Timer? _connectTimeout;

  void _onStatusChanged() {
    final status = _service.status.value;
    switch (status) {
      case SocketConnectionStatus.connecting:
        state = state.copyWith(isConnecting: true, isConnected: false);
        break;
      case SocketConnectionStatus.connected:
        state = state.copyWith(isConnecting: false, isConnected: true);
        break;
      case SocketConnectionStatus.disconnected:
        state = state.copyWith(isConnecting: false, isConnected: false);
        break;
    }
  }

  void connect() {
    if (_service.isConnected) {
      state = state.copyWith(isConnecting: false, isConnected: true);
      return;
    }
    _service.connect();
  }

  Future<bool> ensureConnected({
    Duration timeout = const Duration(seconds: 8),
  }) async {
    if (_service.isConnected) {
      state = state.copyWith(isConnecting: false, isConnected: true);
      return true;
    }
    connect();
    _connectTimeout?.cancel();
    final completer = Completer<bool>();
    void onStatus() {
      if (_service.isConnected && !completer.isCompleted) {
        completer.complete(true);
      }
    }

    _service.status.addListener(onStatus);
    final timer = Timer(timeout, () {
      if (!completer.isCompleted) {
        completer.complete(false);
      }
    });
    _connectTimeout = timer;
    final result = await completer.future;
    timer.cancel();
    _service.status.removeListener(onStatus);
    return result;
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  @override
  void dispose() {
    _connectTimeout?.cancel();
    _service.status.removeListener(_onStatusChanged);
    super.dispose();
  }
}

final socketServiceProvider = riverpod.Provider<WebSocketService>((ref) {
  final service = WebSocketService();
  ref.onDispose(service.dispose);
  return service;
});

final socketStateProvider = StateNotifierProvider<SocketNotifier, SocketState>((
  ref,
) {
  return SocketNotifier(ref.watch(socketServiceProvider));
});
