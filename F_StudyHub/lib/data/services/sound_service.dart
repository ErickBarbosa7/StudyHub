import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart'
    show StateNotifier, StateNotifierProvider;
import 'package:shared_preferences/shared_preferences.dart';

const String _kPrefSoundEnabled = 'pomodoro_sound_enabled';

const String _kFocusEnd = 'audio/focus_end.mp3';
const String _kBreakEnd = 'audio/break_end.mp3';
const String _kTaskCue = 'audio/task_notification.mp3';

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

  // Un reproductor por tipo de sonido: un aviso de tarea no corta la campana
  // del Pomodoro (antes compartían uno y se pisaban).
  final AudioPlayer _alarmPlayer = AudioPlayer();
  final AudioPlayer _cuePlayer = AudioPlayer();

  bool _unlocked = false;
  Future<void>? _unlocking;

  Future<void> _configureAudioContext() async {
    if (kIsWeb) return;
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android) {
        final audioContext = AudioContext(
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: const {AVAudioSessionOptions.mixWithOthers},
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

  /// Los navegadores (sobre todo Safari e iOS) solo dejan sonar el audio si
  /// antes hubo un gesto del usuario. Se llama en cada toque de la app (ver
  /// InactivityDetector): así también suena para quien nunca pulsó "Iniciar"
  /// porque otra persona de la sala arrancó el reloj. Es barato cuando ya
  /// está desbloqueado, y si falla se reintenta en el siguiente toque.
  Future<void> unlock() {
    if (_unlocked) return Future.value();
    return _unlocking ??= _doUnlock().whenComplete(() => _unlocking = null);
  }

  Future<void> _doUnlock() async {
    try {
      await _configureAudioContext();
      for (final (player, asset) in [
        (_alarmPlayer, _kFocusEnd),
        (_cuePlayer, _kTaskCue),
      ]) {
        await player.setReleaseMode(ReleaseMode.stop);
        await player.setVolume(0);
        await player.play(AssetSource(asset));
        await Future<void>.delayed(const Duration(milliseconds: 80));
        await player.stop();
        await player.setVolume(1.0);
      }
      _unlocked = true;
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
    // Al activarlo suena un aviso corto, para confirmar que se oye.
    if (nextState) {
      await unlock();
      await _play(_cuePlayer, _kTaskCue);
    }
  }

  /// Fin de una fase del Pomodoro. Cada fase tiene su propia campana:
  /// estudio (tres notas que bajan, "ya puedes descansar") y descanso
  /// (dos notas que suben, "vuelve a estudiar").
  Future<void> playPomodoroFinishedSound({bool focusFinished = true}) async {
    if (!state.isEnabled) return;
    await _play(_alarmPlayer, focusFinished ? _kFocusEnd : _kBreakEnd);
  }

  Future<void> playTaskNotificationSound() async {
    if (!state.isEnabled) return;
    await _play(_cuePlayer, _kTaskCue);
  }

  Future<void> _play(AudioPlayer player, String asset) async {
    try {
      await player.stop();
      await player.setReleaseMode(ReleaseMode.stop);
      await player.setVolume(1.0);
      await player.play(AssetSource(asset), volume: 1.0);
    } catch (e) {
      debugPrint('[SoundNotifier] Error al reproducir $asset: $e');
      // Un reintento tras volver a desbloquear (p. ej. si el navegador
      // había suspendido el audio).
      try {
        _unlocked = false;
        await unlock();
        await player.play(AssetSource(asset), volume: 1.0);
      } catch (e2) {
        debugPrint('[SoundNotifier] Reintento fallido para $asset: $e2');
      }
    }
  }

  @override
  void dispose() {
    _alarmPlayer.dispose();
    _cuePlayer.dispose();
    super.dispose();
  }
}

// StateNotifierProvider ya llama a dispose() del notificador al cerrarse.
final soundProvider = StateNotifierProvider<SoundNotifier, SoundState>(
  (ref) => SoundNotifier(),
);
