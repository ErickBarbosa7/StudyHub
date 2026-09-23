import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart'
    show StateNotifier, StateNotifierProvider;
import 'package:shared_preferences/shared_preferences.dart';

const String _kPrefOnboardingCompleted = 'onboarding_completed';

class OnboardingState {
  const OnboardingState({
    this.isCompleted = false,
    this.hasChecked = false,
    this.isOpen = false,
  });

  final bool isCompleted;

  /// Se vuelve true cuando ya se leyeron las preferencias.
  final bool hasChecked;

  /// Evita que se intente abrir la guía dos veces a la vez.
  final bool isOpen;

  OnboardingState copyWith({
    bool? isCompleted,
    bool? hasChecked,
    bool? isOpen,
  }) {
    return OnboardingState(
      isCompleted: isCompleted ?? this.isCompleted,
      hasChecked: hasChecked ?? this.hasChecked,
      isOpen: isOpen ?? this.isOpen,
    );
  }
}

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  OnboardingNotifier() : super(const OnboardingState()) {
    load();
  }

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final completed = prefs.getBool(_kPrefOnboardingCompleted) ?? false;
      state = OnboardingState(isCompleted: completed, hasChecked: true);
    } catch (e) {
      debugPrint('[Onboarding] Error cargando preferencias: $e');
      state = const OnboardingState(hasChecked: true);
    }
  }

  void markOpened() {
    state = state.copyWith(isOpen: true);
  }

  /// Marca la guía como vista (se llama al cerrarla o saltarla).
  Future<void> complete() async {
    state = state.copyWith(isCompleted: true, isOpen: false);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kPrefOnboardingCompleted, true);
    } catch (e) {
      debugPrint('[Onboarding] Error guardando preferencia: $e');
    }
  }
}

final onboardingProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingState>((ref) {
  return OnboardingNotifier();
});