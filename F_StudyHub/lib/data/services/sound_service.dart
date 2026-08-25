import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart' show StateNotifier, StateNotifierProvider;
import 'package:shared_preferences/shared_preferences.dart';

const String _kPrefSoundEnabled = 'pomodoro_sound_enabled';

class SoundState {
  const SoundState({this.isEnabled = true});
  final bool isEnabled;

  SoundState copyWith({bool? isEnabled}) {
    return SoundState(isEnabled: isEnabled ?? this.isEnabled);
  }
}

class SoundNotifier extends StateNotifier<SoundState> {
  SoundNotifier() : super(const SoundState()) {
    _init();
  }

  final AudioPlayer _player = AudioPlayer();

  Future<void> _init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool(_kPrefSoundEnabled) ?? true;
      state = state.copyWith(isEnabled: enabled);
    } catch (e) {
      debugPrint('[SoundNotifier] Error cargando preferencias de sonido: $e');
    }
  }

  Future<void> toggleSound() async {
    final nextState = !state.isEnabled;
    state = state.copyWith(isEnabled: nextState);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kPrefSoundEnabled, nextState);
    } catch (e) {
      debugPrint('[SoundNotifier] Error guardando preferencia de sonido: $e');
    }
  }

  Future<void> playPomodoroFinishedSound() async {
    if (!state.isEnabled) return;
    try {
      await _player.stop();
      await _player.play(AssetSource('audio/pomodoro_bell.mp3'));
    } catch (e) {
      debugPrint('[SoundNotifier] Error al reproducir sonido: $e');
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}

final soundProvider = StateNotifierProvider<SoundNotifier, SoundState>((ref) {
  final notifier = SoundNotifier();
  ref.onDispose(notifier.dispose);
  return notifier;
});
