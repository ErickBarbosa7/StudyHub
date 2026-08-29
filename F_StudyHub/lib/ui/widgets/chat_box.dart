import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../data/models/message_model.dart';
import '../../logic/chat_provider.dart';
import '../../logic/room_provider.dart';
import 'help_icon.dart';

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
    final chatState = ref.watch(chatProvider);
    final messages = chatState.messages;
    final isLoadingHistory = chatState.isLoadingHistory;
    final localUserId = ref.watch(roomProvider.select((s) => s.localUser?.id ?? ''));

    if (chatState.messages.length > _lastMessageCount) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }
    _lastMessageCount = chatState.messages.length;

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

    final double padding = MediaQuery.sizeOf(context).width < 600 ? 16 : 24;
    final bool compact = MediaQuery.sizeOf(context).width < 600;
    final double bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(
        padding,
        padding,
        padding,
        padding + bottomInset,
      ),
      decoration: const BoxDecoration(color: Colors.transparent),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.forum_rounded,
                color: kColorDeepSage,
                size: compact ? 24 : 28,
              ),
              SizedBox(width: compact ? 12 : 16),
              Expanded(
                child: Text(
                  'Chat',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: kColorInk,
                    fontWeight: AppType.weightSemiBold,
                    fontSize: compact ? AppType.sizeTitle : null,
                  ),
                ),
              ),
              HelpIcon(
                title: 'Chat del equipo',
                description: 'Habla con tu equipo aquí. Todos los mensajes se borran al salir de la sala.',
                compact: compact,
              ),
            ],
          ),
          SizedBox(height: compact ? 16 : 24),

          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: kColorPaper,
                borderRadius: BorderRadius.circular(24),
              ),
              child: isLoadingHistory
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 32,
                            height: 32,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: kColorDeepSage,
                            ),
                          ),
                          SizedBox(height: compact ? 10 : 14),
                          Text(
                            'Cargando historial del chat...',
                            style: AppType.secondaryItalic(
                              size: compact
                                  ? AppType.sizeBody
                                  : AppType.sizeBodyMedium,
                            ),
                          ),
                        ],
                      ),
                    )
                  : messages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: compact ? 32 : 40,
                            color: kColorSage,
                          ),
                          SizedBox(height: compact ? 8 : 12),
                          Text(
                            'Todavía no hay mensajes.\n¡Inicia la conversación!',
                            textAlign: TextAlign.center,
                            style: AppType.secondaryItalic(
                              size: compact
                                  ? AppType.sizeBody
                                  : AppType.sizeBodyMedium,
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
          SizedBox(height: compact ? 12 : 16),

          Form(
            key: _formKey,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _messageController,
                    textCapitalization: TextCapitalization.sentences,
                    style: const TextStyle(color: kColorInk),
                    maxLength: 1000,
                    maxLengthEnforcement: MaxLengthEnforcement.enforced,
                    decoration: InputDecoration(
                      counterText: '',
                      labelText: 'Escribe un mensaje',
                      hintText: 'ej. ¿Listos para estudiar?',
                      labelStyle: const TextStyle(color: kColorTextSecondary),
                      hintStyle: TextStyle(
                        color: kColorTextSecondary.withValues(alpha: 0.5),
                      ),
                      filled: true,
                      fillColor: kColorPaper,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: compact ? 16 : 24,
                        vertical: compact ? 14 : 18,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(
                          color: kColorDeepSage,
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
                        ? '¡Escribe algo antes de enviar!'
                        : null,
                    onFieldSubmitted: (_) => _send(),
                  ),
                ),
                SizedBox(width: compact ? 8 : 12),
                SizedBox(
                  height: compact ? 48 : 56,
                  width: compact ? 48 : 56,
                  child: ElevatedButton(
                    onPressed: _send,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      backgroundColor: kColorDeepSage,
                      foregroundColor: kColorPaper,
                      elevation: 0,
                    ),
                    child: Icon(Icons.send_rounded, size: compact ? 20 : 24),
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
          color: isOwn ? kColorDeepSage : kColorSageSoft,
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
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                isOwn ? 'Tú' : message.senderName,
                style: TextStyle(
                  color: isOwn
                      ? kColorPaper.withValues(alpha: 0.75)
                      : kColorDeepSage,
                  fontWeight: AppType.weightBold,
                  fontSize: AppType.sizeCaption,
                ),
              ),
            ),
            Text(
              message.text,
              style: TextStyle(
                color: isOwn ? kColorPaper : kColorInk,
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
                      ? kColorPaper.withValues(alpha: 0.75)
                      : kColorTextSecondary,
                  fontSize: AppType.sizeMicro,
                  fontFamily: kFontFamilyMono,
                  fontVariations: const [AppType.italicSlant],
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
