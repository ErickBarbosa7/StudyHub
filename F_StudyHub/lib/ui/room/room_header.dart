import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_icons.dart';

import '../../core/theme.dart';
import '../../data/models/user_model.dart';
import '../../logic/chat_provider.dart';
import '../../logic/room_provider.dart';
import '../widgets/qr_display.dart';
import '../widgets/theme_toggle.dart';
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
    final c = context.colors;
    final roomState = ref.watch(roomProvider);
    final room = roomState.room;
    final users = roomState.users;
    // Se observa solo "hay o no hay no leídos", no cada cambio del contador.
    final hasUnread = ref.watch(chatProvider.select((s) => s.unreadCount > 0));
    final unread = chatHidden && hasUnread;

    final chatToggle = Stack(
      clipBehavior: Clip.none,
      children: [
        RoomIconButton(
          icon: chatHidden
              ? AppIcons.messageSquareOff
              : AppIcons.messageSquare,
          tooltip: chatHidden ? 'Mostrar chat' : 'Ocultar chat',
          foreground: chatHidden ? c.muted : c.ink,
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
                color: c.error,
                shape: BoxShape.circle,
                border: Border.all(color: c.bg, width: 2),
              ),
            ),
          ),
      ],
    );

    void openMembers() =>
        showRoomMembersSheet(context, onKick: onKick, layout: layout);

    if (layout == RoomLayout.phone) {
      return SizedBox(
        height: 64,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              RoomIconButton(
                icon: AppIcons.arrowLeft,
                tooltip: 'Salir de la sala',
                bordered: false,
                foreground: c.error,
                background: c.errorSoft,
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
                        style: TextStyle(
                          color: c.ink,
                          fontSize: 17,
                          fontWeight: AppType.weightBold,
                        ),
                      ),
                      if (room != null)
                        Row(
                          children: [
                            Text(
                              room.roomId,
                              style: TextStyle(
                                color: c.muted,
                                fontSize: AppType.sizeCaption,
                                fontWeight: AppType.weightSemiBold,
                                letterSpacing: 1.4,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              AppIcons.copy,
                              size: 13,
                              color: c.muted,
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
              icon: AppIcons.logOut,
              tooltip: 'Salir de la sala',
              foreground: c.error,
              background: c.errorSoft,
              borderColor: c.errorLine,
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
                      color: c.ink,
                      fontSize: wide ? 22 : 20,
                      fontWeight: AppType.weightBold,
                      letterSpacing: -0.2,
                    ),
                  ),
                  if (wide)
                    Text(
                      'Sala de estudio',
                      style: TextStyle(
                        color: c.muted,
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
                icon: AppIcons.qrCode,
                tooltip: 'Mostrar código QR',
                onPressed: () => QrDisplaySheet.show(context, room.roomId),
              ),
            ],
            const Spacer(),
            _AvatarStack(users: users, showLabel: wide, onPressed: openMembers),
            const SizedBox(width: 12),
            chatToggle,
            const SizedBox(width: 10),
            // Esta rama solo se alcanza en tablet y laptop; en celular la fila
            // está llena y el toggle vive en la hoja de miembros.
            const ThemeToggleIconButton(),
            const SizedBox(width: 10),
            RoomIconButton(
              icon: AppIcons.circleHelp,
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
    final c = context.colors;
    return Tooltip(
      message: 'Copiar código de la sala',
      child: Material(
        color: c.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: c.line),
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
                    Text(
                      'Código',
                      style: TextStyle(
                        color: c.muted,
                        fontSize: AppType.sizeCaption,
                        fontWeight: AppType.weightSemiBold,
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Text(
                    roomId,
                    style: TextStyle(
                      color: c.ink,
                      fontSize: 15,
                      fontWeight: AppType.weightBold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(AppIcons.copy, size: 17, color: c.muted),
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
    final c = context.colors;
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
                        child: RoomAvatar(
                          name: shown[i].name,
                          seed: shown[i].avatarSeed,
                          index: i,
                        ),
                      ),
                    if (extra > 0)
                      Positioned(
                        left: shown.length * 26.0,
                        child: Container(
                          width: 36,
                          height: 36,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: c.track,
                            shape: BoxShape.circle,
                            border: Border.all(color: c.bg, width: 2),
                          ),
                          child: Text(
                            '+$extra',
                            style: TextStyle(
                              color: c.muted,
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
                  style: TextStyle(
                    color: c.muted,
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
    final c = context.colors;
    return Tooltip(
      message: 'Personas en la sala e invitación',
      child: Material(
        color: c.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: c.line),
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
                  Icon(AppIcons.users, size: 18, color: c.ink),
                  const SizedBox(width: 8),
                  Text(
                    '$count',
                    style: TextStyle(
                      color: c.ink,
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
  required RoomLayout layout,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: context.colors.surface,
    isScrollControlled: true,
    constraints: const BoxConstraints(maxWidth: 520),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) => _MembersSheet(
      layout: layout,
      onKick: (user) {
        Navigator.of(sheetContext).pop();
        onKick(user);
      },
    ),
  );
}

class _MembersSheet extends ConsumerWidget {
  const _MembersSheet({required this.onKick, required this.layout});

  final ValueChanged<User> onKick;
  final RoomLayout layout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
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
            Text(
              'Invita a tu equipo',
              style: TextStyle(
                color: c.ink,
                fontSize: AppType.sizeTitle - 2,
                fontWeight: AppType.weightBold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Comparte el código o el QR para que entren a esta sala.',
              style: TextStyle(color: c.muted, fontSize: AppType.sizeBody),
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
                    icon: AppIcons.qrCode,
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
              style: TextStyle(
                color: c.ink,
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
            // En celular la barra del header no cabe un cuarto botón sin dejar el
            // nombre de la sala ilegible, así que el cambio de tema vive aquí.
            if (layout == RoomLayout.phone) ...[
              const SizedBox(height: 18),
              const ThemeToggleRow(),
            ],
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
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          RoomAvatar(
            name: user.name,
            seed: user.avatarSeed,
            index: index,
            ringColor: c.surface,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              user.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: c.ink,
                fontSize: 15,
                fontWeight: AppType.weightSemiBold,
              ),
            ),
          ),
          if (isHost) ...[
            const SizedBox(width: 8),
            RoomChip(
              label: 'Anfitrión',
              background: c.restSoft,
              foreground: c.restInk,
            ),
          ],
          if (isMe) ...[
            const SizedBox(width: 8),
            RoomChip(
              label: 'Tú',
              background: c.studySoft,
              foreground: c.study,
            ),
          ],
          if (canKick) ...[
            const SizedBox(width: 8),
            RoomIconButton(
              icon: AppIcons.userX,
              tooltip: 'Expulsar a ${user.name}',
              foreground: c.error,
              onPressed: onKick,
            ),
          ],
        ],
      ),
    );
  }
}
