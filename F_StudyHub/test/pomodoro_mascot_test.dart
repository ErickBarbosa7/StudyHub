import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyhub/core/theme.dart';
import 'package:studyhub/logic/pomodoro_provider.dart';
import 'package:studyhub/ui/widgets/mascot/pomodoro_mascot.dart';

void main() {
  group('moodFor', () {
    test('pausado en foco: idle', () {
      expect(moodFor(const PomodoroState()), MascotMood.idle);
    });

    test('foco corriendo: focusing', () {
      expect(
        moodFor(const PomodoroState(status: 'RUNNING')),
        MascotMood.focusing,
      );
    });

    test('descansos, corriendo o en pausa: resting', () {
      for (final mode in [kModeShortBreak, kModeLongBreak]) {
        for (final status in ['RUNNING', 'PAUSED']) {
          expect(
            moodFor(PomodoroState(mode: mode, status: status)),
            MascotMood.resting,
          );
        }
      }
    });

    test('fase terminada: celebrating, gana sobre lo demás', () {
      expect(
        moodFor(const PomodoroState(isFinished: true, status: 'RUNNING')),
        MascotMood.celebrating,
      );
      expect(
        moodFor(const PomodoroState(isFinished: true, mode: kModeShortBreak)),
        MascotMood.celebrating,
      );
    });
  });

  for (final brightness in Brightness.values) {
    testWidgets('monta sin overflow en cada ánimo (${brightness.name})',
        (tester) async {
      const states = [
        PomodoroState(),
        PomodoroState(status: 'RUNNING'),
        PomodoroState(mode: kModeShortBreak, status: 'RUNNING'),
        PomodoroState(isFinished: true),
      ];
      for (final s in states) {
        await tester.pumpWidget(
          MaterialApp(
            theme: buildTheme(brightness),
            home: Scaffold(
              body: Center(child: PomodoroMascot(state: s, height: 60)),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 600));
        expect(tester.takeException(), isNull);
      }
    });
  }
}
