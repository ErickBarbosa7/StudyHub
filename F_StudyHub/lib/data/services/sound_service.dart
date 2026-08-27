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
            },
          ),
          android: const AudioContextAndroid(
            isSpeakerphoneOn: false,
            stayAwake: false,
            contentType: AndroidContentType.music,
            usageType: AndroidUsageType.media,
            audioFocus: AndroidAudioFocus.none,
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
      await _configureAudioContext();
      await _player.setReleaseMode(ReleaseMode.stop);
      await _player.setVolume(0);
      await _player.play(AssetSource('audio/pomodoro_bell.mp3'));
      await Future<void>.delayed(const Duration(milliseconds: 120));
      await _player.stop();
      await _player.setVolume(1.0);
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
      await _player.stop();
      await _player.setReleaseMode(ReleaseMode.stop);
      await _player.setVolume(1.0);
      await _player.play(
        AssetSource('audio/pomodoro_bell.mp3'),
        volume: 1.0,
      );
    } catch (e) {
      debugPrint('[SoundNotifier] Error al reproducir sonido pomodoro: $e');
      try {
        await _player.play(
          AssetSource('audio/pomodoro_bell.wav'),
          volume: 1.0,
        );
      } catch (e2) {
        debugPrint('[SoundNotifier] Error al reproducir fallback wav: $e2');
      }
    }
  }

  Future<void> playTaskNotificationSound() async {
    if (!state.isEnabled) return;
    try {
      await _configureAudioContext();
      await _player.stop();
      await _player.setReleaseMode(ReleaseMode.stop);
      await _player.setVolume(1.0);
      await _player.play(
        AssetSource('audio/task_notification.mp3'),
        volume: 1.0,
      );
    } catch (e) {
      debugPrint('[SoundNotifier] Error al reproducir sonido de tarea: $e');
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
