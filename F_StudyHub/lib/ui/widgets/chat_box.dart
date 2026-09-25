import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_icons.dart';

import '../../core/theme.dart';
import '../../data/models/message_model.dart';
import '../../logic/chat_provider.dart';
import '../../logic/room_provider.dart';
import '../room/room_widgets.dart';

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

  @override
  void dispose() {
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
    // Solo se observa lo que se dibuja: los no leídos y errores no la reconstruyen.
    final messages = ref.watch(chatProvider.select((s) => s.messages));
    final isLoadingHistory = ref.watch(
      chatProvider.select((s) => s.isLoadingHistory),
    );
    final localUserId = ref.watch(
      roomProvider.select((s) => s.localUser?.id ?? ''),
    );

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
        ? const Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: kRoomStudy,
              ),
            ),
          )
        : messages.isEmpty
        ? const _EmptyChat()
        : ListView.builder(
            controller: _scrollController,
            itemCount: messages.length,
            itemBuilder: (context, index) => _MessageBubble(
              message: messages[index],
              isOwn: messages[index].isOwn(localUserId),
            ),
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
              const Row(
                children: [
                  Icon(AppIcons.messageSquare, size: 20, color: kRoomStudy),
                  SizedBox(width: 10),
                  Text(
                    'Chat',
                    style: TextStyle(
                      color: kRoomInk,
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
                      style: const TextStyle(color: kRoomInk, fontSize: 15),
                      maxLength: 1000,
                      maxLengthEnforcement: MaxLengthEnforcement.enforced,
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: 'Escribe un mensaje',
                        hintStyle: const TextStyle(color: kRoomMuted),
                        filled: true,
                        fillColor: kRoomSurface,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        border: _fieldBorder(kRoomLine),
                        enabledBorder: _fieldBorder(kRoomLine),
                        focusedBorder: _fieldBorder(kRoomStudy, width: 1.5),
                        errorBorder: _fieldBorder(kRoomError),
                        focusedErrorBorder: _fieldBorder(
                          kRoomError,
                          width: 1.5,
                        ),
                      ),
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                          ? 'Escribe algo antes de enviar'
                          : null,
                      onFieldSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  RoomIconButton(
                    size: 52,
                    iconSize: 20,
                    icon: AppIcons.send,
                    tooltip: 'Enviar',
                    foreground: Colors.white,
                    background: kRoomStudy,
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
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.messageSquare, size: 28, color: kRoomDisabled),
            SizedBox(height: 12),
            Text(
              'Aún no hay mensajes. Saluda al equipo o comparte un enlace.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: kRoomMuted,
                fontSize: AppType.sizeBody,
                height: 1.4,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Los mensajes se borran al salir de la sala.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: kRoomMuted,
                fontSize: AppType.sizeCaption,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.isOwn});

  final Message message;
  final bool isOwn;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isOwn ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
        constraints: const BoxConstraints(maxWidth: 320),
        decoration: BoxDecoration(
          color: isOwn ? kRoomStudy : kRoomTrack,
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
            if (!isOwn)
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  message.senderName,
                  style: const TextStyle(
                    color: kRoomMuted,
                    fontWeight: AppType.weightSemiBold,
                    fontSize: AppType.sizeCaption,
                  ),
                ),
              ),
            Text(
              message.text,
              style: TextStyle(
                color: isOwn ? Colors.white : kRoomInk,
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
                  color: isOwn ? const Color(0xB3FFFFFF) : kRoomMuted,
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
