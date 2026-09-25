import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme.dart';
import '../../data/models/user_model.dart';
import '../../logic/chat_provider.dart';
import '../../logic/room_provider.dart';
import '../widgets/qr_display.dart';
import 'room_widgets.dart';

void _copyCode(BuildContext context, String roomId) {
  Clipboard.setData(ClipboardData(text: roomId));
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Código $roomId copiado al portapapeles')),
  );
}

/// Barra superior de la sala: nombre, código, personas, chat y ayuda.
class RoomHeader extends ConsumerWidget {
  const RoomHeader({
    super.key,
    required this.layout,
    required this.chatHidden,
    required this.onLeave,
    required this.onHelp,
    required this.onToggleChat,
    required this.onKick,
  });

  final RoomLayout layout;
  final bool chatHidden;
  final VoidCallback onLeave;
  final VoidCallback onHelp;
  final VoidCallback onToggleChat;
  final ValueChanged<User> onKick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomState = ref.watch(roomProvider);
    final room = roomState.room;
    final users = roomState.users;
    final unread =
        chatHidden && ref.watch(chatProvider.select((s) => s.unreadCount)) > 0;

    final chatToggle = Stack(
      clipBehavior: Clip.none,
      children: [
        RoomIconButton(
          icon: chatHidden
              ? LucideIcons.messageSquareOff
              : LucideIcons.messageSquare,
          tooltip: chatHidden ? 'Mostrar chat' : 'Ocultar chat',
          foreground: chatHidden ? kRoomMuted : kRoomInk,
          onPressed: onToggleChat,
        ),
        if (unread)
          Positioned(
            top: -2,
            right: -2,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: kRoomError,
                shape: BoxShape.circle,
                border: Border.all(color: kRoomBg, width: 2),
              ),
            ),
          ),
      ],
    );

    void openMembers() => showRoomMembersSheet(context, onKick: onKick);

    if (layout == RoomLayout.phone) {
      return SizedBox(
        height: 64,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              RoomIconButton(
                icon: LucideIcons.arrowLeft,
                tooltip: 'Salir de la sala',
                bordered: false,
                background: Colors.transparent,
                onPressed: onLeave,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: room == null
                      ? null
                      : () => _copyCode(context, room.roomId),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        room?.name ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: kRoomInk,
                          fontSize: 17,
                          fontWeight: AppType.weightBold,
                        ),
                      ),
                      if (room != null)
                        Row(
                          children: [
                            Text(
                              room.roomId,
                              style: const TextStyle(
                                color: kRoomMuted,
                                fontSize: AppType.sizeCaption,
                                fontWeight: AppType.weightSemiBold,
                                letterSpacing: 1.4,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              LucideIcons.copy,
                              size: 13,
                              color: kRoomMuted,
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              chatToggle,
              const SizedBox(width: 8),
              _PeopleButton(count: users.length, onPressed: openMembers),
            ],
          ),
        ),
      );
    }

    final bool wide = layout == RoomLayout.wide;
    return SizedBox(
      height: wide ? 80 : 76,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: wide ? 24 : 20),
        child: Row(
          children: [
            RoomIconButton(
              icon: LucideIcons.logOut,
              tooltip: 'Salir de la sala',
              onPressed: onLeave,
            ),
            const SizedBox(width: 16),
            Flexible(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    room?.name ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: kRoomInk,
                      fontSize: wide ? 22 : 20,
                      fontWeight: AppType.weightBold,
                      letterSpacing: -0.2,
                    ),
                  ),
                  if (wide)
                    const Text(
                      'Sala de estudio',
                      style: TextStyle(
                        color: kRoomMuted,
                        fontSize: AppType.sizeLabel,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            if (room != null) ...[
              _CodeChip(roomId: room.roomId, showLabel: wide),
              const SizedBox(width: 10),
              RoomIconButton(
                icon: LucideIcons.qrCode,
                tooltip: 'Mostrar código QR',
                onPressed: () => QrDisplaySheet.show(context, room.roomId),
              ),
            ],
            const Spacer(),
            _AvatarStack(users: users, showLabel: wide, onPressed: openMembers),
            const SizedBox(width: 12),
            chatToggle,
            const SizedBox(width: 10),
            RoomIconButton(
              icon: LucideIcons.circleHelp,
              tooltip: '¿Cómo funciona?',
              onPressed: onHelp,
            ),
          ],
        ),
      ),
    );
  }
}

class _CodeChip extends StatelessWidget {
  const _CodeChip({required this.roomId, required this.showLabel});

  final String roomId;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Copiar código de la sala',
      child: Material(
        color: kRoomSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: kRoomLine),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _copyCode(context, roomId),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: SizedBox(
              height: 44,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showLabel) ...[
                    const Text(
                      'Código',
                      style: TextStyle(
                        color: kRoomMuted,
                        fontSize: AppType.sizeCaption,
                        fontWeight: AppType.weightSemiBold,
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Text(
                    roomId,
                    style: const TextStyle(
                      color: kRoomInk,
                      fontSize: 15,
                      fontWeight: AppType.weightBold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(LucideIcons.copy, size: 17, color: kRoomMuted),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Avatares superpuestos; al tocarlos abre la lista de la sala.
class _AvatarStack extends StatelessWidget {
  const _AvatarStack({
    required this.users,
    required this.showLabel,
    required this.onPressed,
  });

  final List<User> users;
  final bool showLabel;
  final VoidCallback onPressed;

  static const _max = 4;

  @override
  Widget build(BuildContext context) {
    final shown = users.take(_max).toList();
    final extra = users.length - shown.length;
    final label = users.length <= 1 ? 'Solo tú' : '${users.length} en la sala';

    return Tooltip(
      message: 'Ver personas en la sala',
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 36,
                width: shown.isEmpty
                    ? 0
                    : 36 + (shown.length - 1 + (extra > 0 ? 1 : 0)) * 26.0,
                child: Stack(
                  children: [
                    for (var i = 0; i < shown.length; i++)
                      Positioned(
                        left: i * 26.0,
                        child: RoomAvatar(name: shown[i].name, index: i),
                      ),
                    if (extra > 0)
                      Positioned(
                        left: shown.length * 26.0,
                        child: Container(
                          width: 36,
                          height: 36,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: kRoomTrack,
                            shape: BoxShape.circle,
                            border: Border.all(color: kRoomBg, width: 2),
                          ),
                          child: Text(
                            '+$extra',
                            style: const TextStyle(
                              color: kRoomMuted,
                              fontSize: 12,
                              fontWeight: AppType.weightBold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (showLabel) ...[
                const SizedBox(width: 12),
                Text(
                  label,
                  style: const TextStyle(
                    color: kRoomMuted,
                    fontSize: AppType.sizeBody,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PeopleButton extends StatelessWidget {
  const _PeopleButton({required this.count, required this.onPressed});

  final int count;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Personas en la sala e invitación',
      child: Material(
        color: kRoomSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: kRoomLine),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onPressed,
          child: SizedBox(
            height: 44,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.users, size: 18, color: kRoomInk),
                  const SizedBox(width: 8),
                  Text(
                    '$count',
                    style: const TextStyle(
                      color: kRoomInk,
                      fontSize: 14,
                      fontWeight: AppType.weightBold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Hoja con la invitación (código y QR) y las personas de la sala.
Future<void> showRoomMembersSheet(
  BuildContext context, {
  required ValueChanged<User> onKick,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: kRoomSurface,
    isScrollControlled: true,
    constraints: const BoxConstraints(maxWidth: 520),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) => _MembersSheet(
      onKick: (user) {
        Navigator.of(sheetContext).pop();
        onKick(user);
      },
    ),
  );
}

class _MembersSheet extends ConsumerWidget {
  const _MembersSheet({required this.onKick});

  final ValueChanged<User> onKick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomState = ref.watch(roomProvider);
    final room = roomState.room;
    final users = roomState.users;
    final bool iAmHost = room?.hostId == roomState.localUser?.id;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Invita a tu equipo',
              style: TextStyle(
                color: kRoomInk,
                fontSize: AppType.sizeTitle - 2,
                fontWeight: AppType.weightBold,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Comparte el código o el QR para que entren a esta sala.',
              style: TextStyle(color: kRoomMuted, fontSize: AppType.sizeBody),
            ),
            if (room != null) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _CodeChip(roomId: room.roomId, showLabel: true),
                  ),
                  const SizedBox(width: 10),
                  RoomIconButton(
                    icon: LucideIcons.qrCode,
                    tooltip: 'Mostrar código QR',
                    onPressed: () => QrDisplaySheet.show(context, room.roomId),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            Text(
              users.length == 1
                  ? 'En la sala · 1 persona'
                  : 'En la sala · ${users.length} personas',
              style: const TextStyle(
                color: kRoomInk,
                fontSize: AppType.sizeBodyLarge,
                fontWeight: AppType.weightBold,
              ),
            ),
            const SizedBox(height: 8),
            for (var i = 0; i < users.length; i++)
              _MemberRow(
                user: users[i],
                index: i,
                isHost: room?.hostId == users[i].id,
                isMe: roomState.localUser?.id == users[i].id,
                canKick:
                    iAmHost &&
                    room?.hostId != users[i].id &&
                    roomState.localUser?.id != users[i].id,
                onKick: () => onKick(users[i]),
              ),
          ],
        ),
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({
    required this.user,
    required this.index,
    required this.isHost,
    required this.isMe,
    required this.canKick,
    required this.onKick,
  });

  final User user;
  final int index;
  final bool isHost;
  final bool isMe;
  final bool canKick;
  final VoidCallback onKick;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          RoomAvatar(name: user.name, index: index, ringColor: kRoomSurface),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              user.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: kRoomInk,
                fontSize: 15,
                fontWeight: AppType.weightSemiBold,
              ),
            ),
          ),
          if (isHost) ...[
            const SizedBox(width: 8),
            const RoomChip(
              label: 'Anfitrión',
              background: kRoomBreakSoft,
              foreground: kRoomBreakInk,
            ),
          ],
          if (isMe) ...[
            const SizedBox(width: 8),
            const RoomChip(
              label: 'Tú',
              background: kRoomStudySoft,
              foreground: kRoomStudy,
            ),
          ],
          if (canKick) ...[
            const SizedBox(width: 8),
            RoomIconButton(
              icon: LucideIcons.userX,
              tooltip: 'Expulsar a ${user.name}',
              foreground: kRoomError,
              onPressed: onKick,
            ),
          ],
        ],
      ),
    );
  }
}
