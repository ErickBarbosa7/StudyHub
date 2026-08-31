import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../logic/socket_provider.dart';

class InactivityDetector extends ConsumerStatefulWidget {
  const InactivityDetector({
    super.key,
    required this.child,
    this.inactivityDuration = const Duration(minutes: 15),
  });

  final Widget child;
  final Duration inactivityDuration;

  @override
  ConsumerState<InactivityDetector> createState() => _InactivityDetectorState();
}

class _InactivityDetectorState extends ConsumerState<InactivityDetector> {
  Timer? _inactivityTimer;
  bool _isInactive = false;

  @override
  void initState() {
    super.initState();
    _resetTimer();
  }

  void _resetTimer() {
    // Si veníamos de un estado inactivo, forzamos el hard reset al primer toque
    if (_isInactive) {
      _isInactive = false;
      debugPrint('[Inactivity] Usuario regresó. Ejecutando reconnectHard...');
      final socketService = ref.read(socketServiceProvider);
      socketService.reconnectHard();
    }

    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(widget.inactivityDuration, () {
      _isInactive = true;
      debugPrint('[Inactivity] Tiempo excedido. Desconectando socket proactivamente...');
      final socketService = ref.read(socketServiceProvider);
      socketService.disconnect();
    });
  }

  void _handleInteraction(PointerEvent details) {
    _resetTimer();
  }

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _handleInteraction,
      onPointerMove: _handleInteraction,
      onPointerUp: _handleInteraction,
      behavior: HitTestBehavior.translucent,
      child: widget.child,
    );
  }
}
