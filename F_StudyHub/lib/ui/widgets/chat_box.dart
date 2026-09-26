import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_icons.dart';

import '../../core/theme.dart';
import '../../data/models/message_model.dart';
import '../../logic/chat_provider.dart';
import '../../logic/room_provider.dart';
import '../room/room_widgets.dart';
import 'avatar_picker.dart';

/// Chat de la sala. Necesita alto acotado: la lista hace scroll por dentro.
class ChatBox extends ConsumerStatefulWidget {
  const ChatBox({super.key, this.showTitle = true});

  /// Sin título cuando una pestaña ya dice "Chat".
  final bool showTitle;

  @override
  ConsumerState<ChatBox> createState() => _ChatBoxState();
}

class _ChatBoxState extends ConsumerState<ChatBox> {
  final _messageController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final ScrollController _scrollController = ScrollController();

  int _lastMessageCount = 0;

  /// Mensaje con el selector de reacciones abierto (uno a la vez).
  String? _pickerMessageId;

  late final ChatNotifier _chat;

  @override
  void initState() {
    super.initState();
    _chat = ref.read(chatProvider.notifier);
  }

  @override
  void dispose() {
    _chat.notifyTyping(false);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send() {
    if (!_formKey.currentState!.validate()) return;
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    ref.read(chatProvider.notifier).sendMessage(text);
    _messageController.clear();
  }

  void _togglePicker(Message message, {required bool isLast}) {
    final opening = _pickerMessageId != message.id;
    setState(() => _pickerMessageId = opening ? message.id : null);
    if (opening && isLast) {
      Future<void>.delayed(const Duration(milliseconds: 220), () {
        if (mounted) _scrollToBottom();
      });
    }
  }

  void _react(Message message, String emoji) {
    HapticFeedback.selectionClick();
    _chat.toggleReaction(message.id, emoji);
    if (_pickerMessageId != null) setState(() => _pickerMessageId = null);
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    // Solo se observa lo que se dibuja: los no leídos y errores no la reconstruyen.
    final messages = ref.watch(chatProvider.select((s) => s.messages));
    final isLoadingHistory = ref.watch(
      chatProvider.select((s) => s.isLoadingHistory),
    );
    final localUserId = ref.watch(
      roomProvider.select((s) => s.localUser?.id ?? ''),
    );
    // La lista de personas solo cambia al entrar, salir o cambiar un avatar, así
    // que observarla entera no reconstruye el chat en cada mensaje.
    final users = ref.watch(roomProvider.select((s) => s.users));
    final avatars = <String, ({String? seed, int index})>{
      for (var i = 0; i < users.length; i++)
        users[i].id: (seed: users[i].avatarSeed, index: i),
    };
    // Un texto estable en vez del mapa: no reconstruye por cambios ajenos.
    final typingKey = ref.watch(
      chatProvider.select((s) => s.typingUsers.values.join('\u0000')),
    );
    final typingNames = typingKey.isEmpty
        ? const <String>[]
        : typingKey.split('\u0000');

    if (messages.length > _lastMessageCount) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }
    _lastMessageCount = messages.length;

    ref.listen<ChatState>(chatProvider, (previous, next) {
      if (next.error != null && next.error != previous?.error) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(next.error!)));
          ref.read(chatProvider.notifier).clearError();
        });
      }
    });

    final messagesArea = isLoadingHistory
        ? Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: c.study,
              ),
            ),
          )
        : messages.isEmpty
        ? const _EmptyChat()
        : ListView.builder(
            controller: _scrollController,
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final message = messages[index];
              final avatar = avatars[message.senderId];
              final previous = index == 0 ? null : messages[index - 1];
              return _MessageItem(
                key: ValueKey(message.id),
                message: message,
                localUserId: localUserId,
                avatarSeed: avatar?.seed,
                avatarIndex: avatar?.index ?? 0,
                // Una racha por persona: avatar y nombre solo en el primero.
                showHeader: previous == null || previous.senderId != message.senderId,
                pickerOpen: _pickerMessageId == message.id,
                onTapBubble: () => _togglePicker(
                  message,
                  isLast: index == messages.length - 1,
                ),
                onReact: (emoji) => _react(message, emoji),
                onTapOwnAvatar: () => showAvatarPicker(context),
              );
            },
          );

    return LayoutBuilder(
      builder: (context, constraints) {
        // Con muy poco alto (celular horizontal) todo el panel hace scroll.
        final bool tight =
            constraints.hasBoundedHeight && constraints.maxHeight < 320;
        final column = Column(
          mainAxisSize: tight ? MainAxisSize.min : MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.showTitle) ...[
              Row(
                children: [
                  Icon(AppIcons.messageSquare, size: 20, color: c.study),
                  SizedBox(width: 10),
                  Text(
                    'Chat',
                    style: TextStyle(
                      color: c.ink,
                      fontSize: AppType.sizeTitle - 2,
                      fontWeight: AppType.weightBold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            tight
                ? SizedBox(height: 220, child: messagesArea)
                : Expanded(child: messagesArea),
            _TypingIndicator(names: typingNames),
            const SizedBox(height: 12),
            Form(
              key: _formKey,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _messageController,
                      textCapitalization: TextCapitalization.sentences,
                      style: TextStyle(color: c.ink, fontSize: 15),
                      maxLength: 1000,
                      maxLengthEnforcement: MaxLengthEnforcement.enforced,
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: 'Escribe un mensaje',
                        hintStyle: TextStyle(color: c.muted),
                        filled: true,
                        fillColor: c.surface,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        border: _fieldBorder(c.line),
                        enabledBorder: _fieldBorder(c.line),
                        focusedBorder: _fieldBorder(c.study, width: 1.5),
                        errorBorder: _fieldBorder(c.error),
                        focusedErrorBorder: _fieldBorder(
                          c.error,
                          width: 1.5,
                        ),
                      ),
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                          ? 'Escribe algo antes de enviar'
                          : null,
                      onChanged: (value) =>
                          _chat.notifyTyping(value.trim().isNotEmpty),
                      onFieldSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  RoomIconButton(
                    size: 52,
                    iconSize: 20,
                    icon: AppIcons.send,
                    tooltip: 'Enviar',
                    foreground: c.onAccent,
                    background: c.study,
                    bordered: false,
                    onPressed: _send,
                  ),
                ],
              ),
            ),
          ],
        );
        return tight ? SingleChildScrollView(child: column) : column;
      },
    );
  }

  OutlineInputBorder _fieldBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}

class _EmptyChat extends StatelessWidget {
  const _EmptyChat();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.messageSquare, size: 28, color: c.disabled),
            SizedBox(height: 12),
            Text(
              'Aún no hay mensajes. Saluda al equipo o comparte un enlace.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: c.muted,
                fontSize: AppType.sizeBody,
                height: 1.4,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Toca un mensaje para reaccionar. Se borran al salir de la sala.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: c.muted,
                fontSize: AppType.sizeCaption,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Un mensaje con su selector de reacciones (al tocarlo) y las reacciones que
/// ya tiene debajo.
class _MessageItem extends StatelessWidget {
  const _MessageItem({
    super.key,
    required this.message,
    required this.localUserId,
    required this.avatarSeed,
    required this.avatarIndex,
    required this.showHeader,
    required this.pickerOpen,
    required this.onTapBubble,
    required this.onReact,
    required this.onTapOwnAvatar,
  });

  final Message message;
  final String localUserId;
  final String? avatarSeed;
  final int avatarIndex;
  final bool showHeader;
  final bool pickerOpen;
  final VoidCallback onTapBubble;
  final ValueChanged<String> onReact;
  final VoidCallback onTapOwnAvatar;

  @override
  Widget build(BuildContext context) {
    final isOwn = message.isOwn(localUserId);
    final align = isOwn ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    // Una sola reacción por usuario y mensaje: se toma el primer emoji permitido
    // que lo tenga, por si llegara alguno repetido de un servidor antiguo.
    String? mine;
    for (final emoji in kReactionEmojis) {
      if (message.reactions[emoji]?.contains(localUserId) ?? false) {
        mine = emoji;
        break;
      }
    }

    // El avatar va fuera del GestureDetector de la burbuja: si no, el tap
    // abriría el selector de reacciones en lugar del de avatares.
    final avatar = showHeader
        ? _MessageAvatar(
            name: message.senderName,
            seed: avatarSeed,
            index: avatarIndex,
            onTap: isOwn ? onTapOwnAvatar : null,
          )
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (avatar != null && !isOwn) ...[
            avatar,
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: align,
              children: [
                Semantics(
                  button: true,
                  hint: 'Toca para reaccionar',
                  child: GestureDetector(
                    onTap: onTapBubble,
                    behavior: HitTestBehavior.opaque,
                    child: _MessageBubble(
                      message: message,
                      isOwn: isOwn,
                      showLabel: showHeader,
                    ),
                  ),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  alignment: isOwn ? Alignment.topRight : Alignment.topLeft,
                  child: pickerOpen
                      ? Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: _ReactionPicker(
                            active: mine,
                            onPick: onReact,
                          ),
                        )
                      : const SizedBox(width: double.infinity),
                ),
                if (message.reactions.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: _ReactionChips(
                      reactions: message.reactions,
                      localUserId: localUserId,
                      alignEnd: isOwn,
                      onTap: onReact,
                    ),
                  ),
              ],
            ),
          ),
          if (avatar != null && isOwn) ...[
            const SizedBox(width: 8),
            avatar,
          ],
        ],
      ),
    );
  }
}

/// Avatar junto a la burbuja. El propio es el atajo al selector de macetas.
class _MessageAvatar extends StatelessWidget {
  const _MessageAvatar({
    required this.name,
    required this.seed,
    required this.index,
    this.onTap,
  });

  final String name;
  final String? seed;
  final int index;
  final VoidCallback? onTap;

  static const double size = 36;

  @override
  Widget build(BuildContext context) {
    final avatar = RoomAvatar(
      name: name,
      seed: seed,
      index: index,
      size: size,
    );
    if (onTap == null) return avatar;

    return Semantics(
      button: true,
      label: 'Cambiar tu avatar',
      excludeSemantics: true,
      child: Tooltip(
        message: 'Cambiar tu avatar',
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: avatar,
        ),
      ),
    );
  }
}

/// Fila con los emojis de aliento disponibles. Solo uno puede estar activo.
class _ReactionPicker extends StatelessWidget {
  const _ReactionPicker({required this.active, required this.onPick});

  final String? active;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.line),
        boxShadow: [
          BoxShadow(color: c.shadow, blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final emoji in kReactionEmojis)
            _EmojiButton(
              emoji: emoji,
              active: emoji == active,
              onTap: () => onPick(emoji),
            ),
        ],
      ),
    );
  }
}

class _EmojiButton extends StatelessWidget {
  const _EmojiButton({
    required this.emoji,
    required this.active,
    required this.onTap,
  });

  final String emoji;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      selected: active,
      label: active ? 'Quitar reacción $emoji' : 'Reaccionar con $emoji',
      excludeSemantics: true,
      child: Material(
        color: active ? c.studySoft : Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 22, height: 1)),
            ),
          ),
        ),
      ),
    );
  }
}

/// Reacciones ya puestas: un chip por emoji con su cuenta. Tocarlo suma o quita
/// la reacción propia.
class _ReactionChips extends StatelessWidget {
  const _ReactionChips({
    required this.reactions,
    required this.localUserId,
    required this.alignEnd,
    required this.onTap,
  });

  final Map<String, List<String>> reactions;
  final String localUserId;
  final bool alignEnd;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    // Siempre en el mismo orden, sin importar quién reaccionó primero.
    final emojis = [
      for (final e in kReactionEmojis)
        if (reactions.containsKey(e)) e,
    ];
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      alignment: alignEnd ? WrapAlignment.end : WrapAlignment.start,
      children: [
        for (final emoji in emojis)
          _ReactionChip(
            emoji: emoji,
            count: reactions[emoji]!.length,
            mine: reactions[emoji]!.contains(localUserId),
            onTap: () => onTap(emoji),
          ),
      ],
    );
  }
}

class _ReactionChip extends StatelessWidget {
  const _ReactionChip({
    required this.emoji,
    required this.count,
    required this.mine,
    required this.onTap,
  });

  final String emoji;
  final int count;
  final bool mine;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final label = count == 1 ? '1 reacción' : '$count reacciones';
    return Semantics(
      button: true,
      selected: mine,
      label: '$emoji, $label${mine ? ', incluida la tuya' : ''}',
      excludeSemantics: true,
      child: Material(
        color: mine ? c.studySoft : c.track,
        shape: StadiumBorder(
          side: BorderSide(color: mine ? c.study : c.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 32, minWidth: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 15, height: 1)),
                  const SizedBox(width: 5),
                  Text(
                    '$count',
                    style: TextStyle(
                      color: mine ? c.study : c.muted,
                      fontSize: AppType.sizeCaption,
                      fontWeight: AppType.weightSemiBold,
                      fontFamily: kFontFamilyMono,
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

/// "Ana está escribiendo…" con tres puntos animados. Se pliega a alto 0 cuando
/// nadie escribe.
class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator({required this.names});

  final List<String> names;

  static String label(List<String> names) {
    if (names.length == 1) return '${names[0]} está escribiendo';
    if (names.length == 2) return '${names[0]} y ${names[1]} están escribiendo';
    return 'Varios están escribiendo';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AnimatedSize(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topLeft,
      child: names.isEmpty
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.only(top: 6, left: 4),
              child: Semantics(
                liveRegion: true,
                label: label(names),
                excludeSemantics: true,
                child: Row(
                  children: [
                    _TypingDots(color: c.muted),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        label(names),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppType.secondaryItalic(
                          context: context,
                          size: AppType.sizeCaption,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots({required this.color});

  final Color color;

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );
  bool _reduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_reduceMotion) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 3; i++)
              Padding(
                padding: EdgeInsets.only(right: i < 2 ? 3 : 0),
                child: Opacity(
                  opacity: _reduceMotion ? 0.7 : _dotOpacity(i),
                  child: Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: widget.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  /// Cada punto sube y baja con un desfase de un tercio del ciclo.
  double _dotOpacity(int index) {
    final phase = (_controller.value - index / 3) % 1.0;
    final wave = phase < 0.5 ? phase * 2 : (1 - phase) * 2;
    return 0.3 + 0.7 * wave;
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isOwn,
    required this.showLabel,
  });

  final Message message;
  final bool isOwn;

  /// Con los mensajes agrupados, el nombre ("Tú" o el de quien envía) solo
  /// aparece en el primero de la racha.
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Align(
      alignment: isOwn ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
        constraints: const BoxConstraints(maxWidth: 320),
        decoration: BoxDecoration(
          color: isOwn ? c.study : c.track,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isOwn ? 16 : 4),
            bottomRight: Radius.circular(isOwn ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showLabel)
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  isOwn ? 'Tú' : message.senderName,
                  style: TextStyle(
                    // Sobre el verde de la burbuja propia el muted no contrasta.
                    color: isOwn
                        ? c.onAccent.withValues(alpha: 0.75)
                        : c.muted,
                    fontWeight: AppType.weightSemiBold,
                    fontSize: AppType.sizeCaption,
                  ),
                ),
              ),
            Text(
              message.text,
              style: TextStyle(
                color: isOwn ? c.onAccent : c.ink,
                fontSize: AppType.sizeBody,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 3),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                _formatHour(message.timestamp),
                style: TextStyle(
                  color: isOwn ? c.onAccent.withValues(alpha: 0.7) : c.muted,
                  fontSize: AppType.sizeMicro,
                  fontFamily: kFontFamilyMono,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatHour(DateTime date) {
    final String hour = date.hour.toString().padLeft(2, '0');
    final String minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
