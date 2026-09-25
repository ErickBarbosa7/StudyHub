import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:studyhub/core/theme.dart';
import 'package:studyhub/logic/onboarding_provider.dart';
import 'package:studyhub/ui/widgets/mascot/onboarding_tour.dart';

const _sizes = [
  Size(320, 568),
  Size(390, 844),
  Size(640, 360),
  Size(834, 1112),
  Size(1440, 900),
];

void main() {
  for (final inRoom in [false, true]) {
    for (final size in _sizes) {
      testWidgets(
        'Guía ${inRoom ? 'en la sala' : 'en el inicio'} '
        '${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
          SharedPreferences.setMockInitialValues({});
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);

          await tester.pumpWidget(
            ProviderScope(
              child: MaterialApp(
                theme: buildTheme(),
                home: Consumer(
                  builder: (context, ref, _) => Scaffold(
                    body: Center(
                      child: TextButton(
                        onPressed: () => showOnboardingTour(
                          context,
                          ref.read(onboardingProvider.notifier),
                          inRoom: inRoom,
                        ),
                        child: const Text('Abrir'),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );

          await tester.tap(find.text('Abrir'));
          await tester.pump(); // arranca la animación de apertura
          await tester.pump(const Duration(milliseconds: 500));

          var steps = 1;
          final next = find.widgetWithText(FilledButton, 'Siguiente');
          while (next.evaluate().isNotEmpty && steps < 10) {
            expect(tester.takeException(), isNull);
            await tester.tap(next);
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 400));
            steps++;
          }
          expect(tester.takeException(), isNull);
          expect(steps, inRoom ? 5 : 6);

          // Último paso: el botón principal cierra la guía.
          final done = find.widgetWithText(FilledButton, 'Entendido');
          await tester.tap(done);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));
          expect(done, findsNothing);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
