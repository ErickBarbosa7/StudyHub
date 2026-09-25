import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/sound_service.dart';
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
  // Cada movimiento del puntero solo guarda la hora (barato). Un temporizador
  // periódico revisa cada tanto si pasó demasiado tiempo; antes se cancelaba
  // y creaba un Timer por cada evento de puntero.
  static const Duration _checkEvery = Duration(seconds: 30);

  Timer? _checkTimer;
  DateTime _lastActivity = DateTime.now();
  bool _isInactive = false;

  @override
  void initState() {
    super.initState();
    _checkTimer = Timer.periodic(_checkEvery, (_) => _checkInactivity());
  }

  void _checkInactivity() {
    if (_isInactive) return;
    if (DateTime.now().difference(_lastActivity) < widget.inactivityDuration) {
      return;
    }
    _isInactive = true;
    debugPrint(
      '[Inactivity] Tiempo excedido. Desconectando socket proactivamente...',
    );
    ref.read(socketServiceProvider).disconnect();
  }

  void _resetTimer() {
    _lastActivity = DateTime.now();
    // Si veníamos de un estado inactivo, forzamos el hard reset al primer toque
    if (_isInactive) {
      _isInactive = false;
      debugPrint('[Inactivity] Usuario regresó. Ejecutando reconnectHard...');
      ref.read(socketServiceProvider).reconnectHard();
    }
  }

  void _handleInteraction(PointerEvent details) {
    _resetTimer();
  }

  // Cualquier toque cuenta como gesto del usuario para habilitar el audio.
  void _handleGesture(PointerEvent details) {
    _handleInteraction(details);
    ref.read(soundProvider.notifier).unlock();
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _handleGesture,
      onPointerMove: _handleInteraction,
      onPointerUp: _handleGesture,
      behavior: HitTestBehavior.translucent,
      child: widget.child,
    );
  }
}
