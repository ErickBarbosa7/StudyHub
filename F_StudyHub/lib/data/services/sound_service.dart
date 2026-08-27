import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart'
    show StateNotifier, StateNotifierProvider;
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
    _configureAudioContext();
  }

  final AudioPlayer _player = AudioPlayer();
  bool _unlocked = false;

  Future<void> _configureAudioContext() async {
    if (kIsWeb) return;
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android) {
        final audioContext = AudioContext(
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: const {
              AVAudioSessionOptions.mixWithOthers,
              AVAudioSessionOptions.duckOthers,
            },
          ),
          android: const AudioContextAndroid(
            isSpeakerphoneOn: true,
            stayAwake: true,
            contentType: AndroidContentType.sonification,
            usageType: AndroidUsageType.alarm,
            audioFocus: AndroidAudioFocus.gainTransientMayDuck,
          ),
        );
        await AudioPlayer.global.setAudioContext(audioContext);
      }
    } catch (e) {
      debugPrint('[SoundNotifier] Error configurando AudioContext: $e');
    }
  }

  Future<void> _init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool(_kPrefSoundEnabled) ?? true;
      state = state.copyWith(isEnabled: enabled);
    } catch (e) {
      debugPrint('[SoundNotifier] Error cargando preferencias de sonido: $e');
    }
  }

  Future<void> unlock() async {
    if (_unlocked) return;
    _unlocked = true;
    try {
      if (kIsWeb) {
        final unlocker = AudioPlayer();
        await unlocker.setVolume(0);
        await unlocker.play(AssetSource('audio/pomodoro_bell.mp3'));
        await Future<void>.delayed(const Duration(milliseconds: 100));
        await unlocker.stop();
        await unlocker.dispose();
      } else {
        await _configureAudioContext();
      }
    } catch (e) {
      debugPrint('[SoundNotifier] Error desbloqueando audio: $e');
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
      await _configureAudioContext();
      final player = AudioPlayer();
      await player.play(AssetSource('audio/pomodoro_bell.mp3'), volume: 1.0);
      player.onPlayerComplete.first.then((_) => player.dispose()).catchError((_) {});
    } catch (e) {
      debugPrint('[SoundNotifier] Error al reproducir sonido pomodoro: $e');
      try {
        await _player.stop();
        await _player.play(AssetSource('audio/pomodoro_bell.mp3'), volume: 1.0);
      } catch (e2) {
        debugPrint('[SoundNotifier] Fallback pomodoro falló: $e2');
      }
    }
  }

  Future<void> playTaskNotificationSound() async {
    if (!state.isEnabled) return;
    try {
      await _configureAudioContext();
      final player = AudioPlayer();
      await player.play(AssetSource('audio/task_notification.mp3'), volume: 1.0);
      player.onPlayerComplete.first.then((_) => player.dispose()).catchError((_) {});
    } catch (e) {
      debugPrint('[SoundNotifier] Error al reproducir sonido de tarea: $e');
      try {
        await _player.stop();
        await _player.play(AssetSource('audio/task_notification.mp3'), volume: 1.0);
      } catch (e2) {
        debugPrint('[SoundNotifier] Fallback tarea falló: $e2');
      }
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
