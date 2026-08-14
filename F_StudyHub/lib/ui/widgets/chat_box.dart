import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../data/models/message_model.dart';
import '../../logic/chat_provider.dart';
import '../../logic/room_provider.dart';

class ChatBox extends ConsumerStatefulWidget {
  const ChatBox({super.key});

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

  void _autoScroll() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  void _send() {
    if (!_formKey.currentState!.validate()) return;

    ref.read(chatProvider.notifier).sendMessage(_messageController.text);
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatProvider).messages;
    final localUserId = ref.watch(roomProvider).localUser?.id ?? '';

    if (messages.length != _lastMessageCount) {
      _lastMessageCount = messages.length;
      _autoScroll();
    }

    final double padding = MediaQuery.sizeOf(context).width < 600 ? 16 : 24;

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: kColorSurfaceWhite,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: kColorTintedShadow,
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: kColorTealSoft,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.forum_rounded,
                  color: kColorTeal,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Chat',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: kColorOffBlack,
                    fontWeight: AppType.weightSemiBold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: kColorSurfaceSoft,
                borderRadius: BorderRadius.circular(24),
              ),
              child: messages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 40,
                            color: kColorTeal,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Todavía no hay mensajes.\n¡Inicia la conversación!',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: kColorTextSecondary,
                                  height: 1.4,
                                ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      itemCount: messages.length,
                      itemBuilder: (context, index) => _MessageBubble(
                        message: messages[index],
                        isOwn: messages[index].isOwn(localUserId),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),

          Form(
            key: _formKey,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _messageController,
                    textCapitalization: TextCapitalization.sentences,
                    style: const TextStyle(color: kColorOffBlack),
                    decoration: InputDecoration(
                      labelText: 'Escribe un mensaje',
                      hintText: 'ej. ¿Vamos por el capítulo 3?',
                      labelStyle: const TextStyle(color: kColorTextSecondary),
                      hintStyle: TextStyle(
                        color: kColorTextSecondary.withValues(alpha: 0.5),
                      ),
                      filled: true,
                      fillColor: kColorSurfaceSoft,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 18,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(
                          color: kColorTeal,
                          width: 1.5,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(
                          color: kColorErrorBorder,
                          width: 1.5,
                        ),
                      ),
                    ),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                        ? 'Requerido'
                        : null,
                    onFieldSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 56,
                  width: 56,
                  child: ElevatedButton(
                    onPressed: _send,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      backgroundColor: kColorDarkGreen,
                      foregroundColor: kColorCream,
                      elevation: 0,
                    ),
                    child: const Icon(Icons.send_rounded, size: 24),
                  ),
                ),
              ],
            ),
          ),
        ],
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
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: isOwn ? kColorDarkGreen : kColorTealSoft,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(isOwn ? 20 : 4),
            topRight: Radius.circular(isOwn ? 4 : 20),
            bottomLeft: const Radius.circular(20),
            bottomRight: const Radius.circular(20),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isOwn)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  message.senderName,
                  style: const TextStyle(
                    color: kColorTeal,
                    fontWeight: AppType.weightBold,
                    fontSize: AppType.sizeCaption,
                  ),
                ),
              ),
            Text(
              message.text,
              style: TextStyle(
                color: isOwn ? kColorCream : kColorOffBlack,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 2),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                _formatHour(message.timestamp),
                style: TextStyle(
                  color: isOwn
                      ? kColorCream.withValues(alpha: 0.7)
                      : kColorTextSecondary,
                  fontSize: AppType.sizeMicro,
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
