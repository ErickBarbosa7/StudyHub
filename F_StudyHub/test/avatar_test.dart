import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyhub/core/avatars.dart';
import 'package:studyhub/core/theme.dart';
import 'package:studyhub/data/models/user_model.dart';
import 'package:studyhub/ui/room/room_widgets.dart';

void main() {
  group('avatarSvg', () {
    test('el mismo seed da el mismo dibujo y se genera una sola vez', () {
      final a = avatarSvg('Aloe');
      expect(a, startsWith('<svg'));
      expect(identical(avatarSvg('Aloe'), a), isTrue);
    });

    test('seeds distintos dan dibujos distintos', () {
      const seeds = ['Aloe', 'Brote', 'Cactus', 'Albahaca', 'Romero', 'Lavanda'];
      expect({for (final s in seeds) avatarSvg(s)}, hasLength(seeds.length));
    });

    test('sin fondo propio: lo pone el círculo del tema', () {
      final svg = avatarSvg('Aloe');
      expect(
        RegExp(r'<rect[^>]*width="100"[^>]*height="100"[^>]*fill=').hasMatch(svg),
        isFalse,
      );
      expect(svg, isNot(contains('<metadata')));
    });
  });

  group('User', () {
    test('lee avatarSeed y lo conserva en toJson', () {
      final u = User.fromJson({'id': 'u1', 'name': 'Ana', 'avatarSeed': 'Aloe'});
      expect(u.avatarSeed, 'Aloe');
      expect(u.toJson()['avatarSeed'], 'Aloe');
    });

    test('un servidor sin avatarSeed sigue funcionando', () {
      final u = User.fromJson({'id': 'u1', 'name': 'Ana'});
      expect(u.avatarSeed, isNull);
      expect(u.toJson().containsKey('avatarSeed'), isFalse);
    });

    test('copyWith cambia el avatar sin tocar id ni nombre', () {
      const u = User(id: 'u1', name: 'Ana', avatarSeed: 'Aloe');
      final b = u.copyWith(avatarSeed: 'Cactus');
      expect(b.id, 'u1');
      expect(b.name, 'Ana');
      expect(b.avatarSeed, 'Cactus');
      expect(u.avatarSeed, 'Aloe', reason: 'el original no se toca');
    });
  });

  group('kAvatarSeeds', () {
    test('es el espejo de AVATAR_SEEDS del servidor (23 macetas)', () {
      expect(kAvatarSeeds, hasLength(23));
      expect(kAvatarSeeds, contains('Aloe'));
      expect(kAvatarSeeds.toSet(), hasLength(23), reason: 'sin repetidas');
    });
  });

  for (final brightness in Brightness.values) {
    group('RoomAvatar (${brightness.name})', () {
      Future<void> pump(WidgetTester tester, Widget avatar) => tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(brightness),
          home: Scaffold(body: Center(child: avatar)),
        ),
      );

      testWidgets('con seed dibuja el avatar, no las iniciales', (tester) async {
        await pump(
          tester,
          const RoomAvatar(name: 'Ana Lu', index: 0, seed: 'Aloe'),
        );
        expect(find.byType(SvgPicture), findsOneWidget);
        expect(find.text('AL'), findsNothing);
        expect(tester.takeException(), isNull);
      });

      testWidgets('sin seed usa las iniciales', (tester) async {
        await pump(tester, const RoomAvatar(name: 'Ana Lu', index: 0));
        expect(find.byType(SvgPicture), findsNothing);
        expect(find.text('AL'), findsOneWidget);
      });

      testWidgets('el círculo mantiene su tamaño y dice el nombre', (
        tester,
      ) async {
        await pump(
          tester,
          const RoomAvatar(name: 'Ana Lu', index: 1, seed: 'Cactus', size: 44),
        );
        expect(tester.getSize(find.byType(RoomAvatar)), const Size(44, 44));
        expect(find.bySemanticsLabel('Ana Lu'), findsOneWidget);
      });
    });
  }
}
