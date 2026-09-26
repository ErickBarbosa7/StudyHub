import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_icons.dart';
import '../../core/avatars.dart';
import '../../core/theme.dart';
import '../../logic/room_provider.dart';
import '../room/room_widgets.dart';
import 'custom_snackbar.dart';

/// Hoja para elegir la maceta del avatar. Se aplica al tocar, sin confirmar.
///
/// El servidor mantiene los avatares únicos por sala, así que aquí solo se
/// ofrecen los libres: los que otra persona ya tiene salen atenuados con su
/// nombre. La elección se guarda en el dispositivo y viaja en el `join_room`.
Future<void> showAvatarPicker(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: context.colors.surface,
    isScrollControlled: true,
    constraints: const BoxConstraints(maxWidth: 520),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) => const _AvatarPickerSheet(),
  );
}

class _AvatarPickerSheet extends ConsumerWidget {
  const _AvatarPickerSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final roomState = ref.watch(roomProvider);
    final localUser = roomState.localUser;
    final current = localUser?.avatarSeed;

    // Seed -> nombre de quien la tiene. La tuya no bloquea: es tu opción actual.
    final ownerBySeed = <String, String>{};
    for (final user in roomState.users) {
      final seed = user.avatarSeed;
      if (seed == null) continue;
      if (user.id == localUser?.id) {
        ownerBySeed[seed] = 'tú';
        continue;
      }
      ownerBySeed.putIfAbsent(seed, () => user.name);
    }

    final free = kAvatarSeeds
        .where((seed) => ownerBySeed[seed] == null || ownerBySeed[seed] == 'tú')
        .toList();

    Future<void> pick(String seed) async {
      HapticFeedback.selectionClick();
      final takenBy = await ref.read(roomProvider.notifier).setAvatarSeed(seed);
      if (!context.mounted) return;
      if (takenBy != null) {
        showCustomNotification(
          context,
          title: '$takenBy ya está usando esa maceta',
          icon: AppIcons.circleAlert,
          iconColor: c.error,
        );
        return;
      }
      Navigator.of(context).pop();
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Elige tu avatar',
              style: TextStyle(
                color: c.ink,
                fontSize: AppType.sizeTitle - 2,
                fontWeight: AppType.weightBold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              free.isEmpty
                  ? 'No quedan macetas libres en esta sala.'
                  : 'Los que ya usa alguien más no se pueden elegir.',
              style: TextStyle(color: c.muted, fontSize: AppType.sizeBody),
            ),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, constraints) {
                const cell = 76.0;
                final columns = (constraints.maxWidth / cell)
                    .floor()
                    .clamp(3, 5);
                return GridView.count(
                  crossAxisCount: columns,
                  shrinkWrap: true,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    for (final seed in kAvatarSeeds)
                      _SeedCell(
                        seed: seed,
                        owner: ownerBySeed[seed],
                        isMine: seed == current,
                        onTap: free.contains(seed) ? () => pick(seed) : null,
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SeedCell extends StatelessWidget {
  const _SeedCell({
    required this.seed,
    required this.owner,
    required this.isMine,
    required this.onTap,
  });

  final String seed;
  final String? owner;

  /// `null` = libre, `'tú'` = la tuya, otro nombre = ocupada por esa persona.
  final bool isMine;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bool taken = owner != null && !isMine;
    final label = isMine
        ? 'Tu avatar actual'
        : (taken ? '${owner!} está usando esta maceta' : 'Elegir esta maceta');

    Widget avatar = RoomAvatar(
      name: seed,
      seed: seed,
      index: kAvatarSeeds.indexOf(seed),
      size: 60,
      ringColor: isMine ? c.study : c.surface,
    );

    if (isMine) {
      avatar = Stack(
        clipBehavior: Clip.none,
        children: [
          avatar,
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: c.study,
                shape: BoxShape.circle,
                border: Border.all(color: c.surface, width: 2),
              ),
              child: Icon(AppIcons.check, size: 12, color: c.onAccent),
            ),
          ),
        ],
      );
    } else if (taken) {
      avatar = Opacity(opacity: 0.35, child: avatar);
    }

    if (onTap == null) {
      avatar = Semantics(
        label: label,
        excludeSemantics: true,
        child: Tooltip(message: label, child: avatar),
      );
    } else {
      avatar = Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        child: Tooltip(
          message: label,
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: Padding(padding: const EdgeInsets.all(4), child: avatar),
          ),
        ),
      );
    }

    return Center(child: avatar);
  }
}
