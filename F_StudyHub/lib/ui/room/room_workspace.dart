import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme.dart';
import '../../data/models/user_model.dart';
import '../../logic/chat_provider.dart';
import '../widgets/chat_box.dart';
import '../widgets/pomodoro_timer.dart';
import '../widgets/task_list.dart';
import 'room_header.dart';
import 'room_widgets.dart';

enum _Section { focus, tasks, chat }

/// Sala de estudio: reloj, tareas y chat, con distribución según el ancho.
///
/// - Laptop: tres columnas (reloj, tareas, chat).
/// - Tablet: reloj a la izquierda; tareas y chat en pestañas a la derecha.
/// - Celular: una sección a la vez con navegación inferior y mini reloj.
///
/// El chat se puede ocultar (útil si se estudia solo); se recuerda.
class RoomWorkspace extends ConsumerStatefulWidget {
  const RoomWorkspace({
    super.key,
    required this.onLeave,
    required this.onHelp,
    required this.onKick,
  });

  final VoidCallback onLeave;
  final VoidCallback onHelp;
  final ValueChanged<User> onKick;

  @override
  ConsumerState<RoomWorkspace> createState() => _RoomWorkspaceState();
}

class _RoomWorkspaceState extends ConsumerState<RoomWorkspace> {
  static const _chatHiddenKey = 'chat_hidden';

  bool _chatHidden = false;
  _Section _section = _Section.focus;
  bool? _lastChatVisible;

  @override
  void initState() {
    super.initState();
    _loadChatHidden();
  }

  Future<void> _loadChatHidden() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _chatHidden = prefs.getBool(_chatHiddenKey) ?? false);
  }

  Future<void> _toggleChat() async {
    setState(() {
      _chatHidden = !_chatHidden;
      if (_chatHidden && _section == _Section.chat) _section = _Section.tasks;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_chatHiddenKey, _chatHidden);
  }

  /// Avisa al chat si está a la vista (limpia los no leídos).
  void _syncChatVisible(bool visible) {
    if (_lastChatVisible == visible) return;
    _lastChatVisible = visible;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(chatProvider.notifier).setChatVisible(visible);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: kRoomBg,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final layout = RoomLayout.of(constraints.maxWidth);

          // Coherencia entre layouts: el foco no es una pestaña en tablet.
          final section =
              (layout == RoomLayout.tablet && _section == _Section.focus)
              ? _Section.tasks
              : (_chatHidden && _section == _Section.chat)
              ? _Section.tasks
              : _section;

          final bool chatVisible =
              !_chatHidden &&
              (layout == RoomLayout.wide || section == _Section.chat);
          _syncChatVisible(chatVisible);

          return Column(
            children: [
              RoomHeader(
                layout: layout,
                chatHidden: _chatHidden,
                onLeave: widget.onLeave,
                onHelp: widget.onHelp,
                onToggleChat: _toggleChat,
                onKick: widget.onKick,
              ),
              Expanded(
                child: switch (layout) {
                  RoomLayout.wide => _buildWide(),
                  RoomLayout.tablet => _buildTablet(section),
                  RoomLayout.phone => _buildPhone(section),
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildWide() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Sin chat, reloj y tareas se reparten el ancho por igual (50/50).
          if (_chatHidden)
            const Expanded(child: RoomCard(child: PomodoroTimer()))
          else
            const SizedBox(width: 440, child: RoomCard(child: PomodoroTimer())),
          const SizedBox(width: 20),
          const Expanded(child: RoomCard(child: TaskList())),
          if (!_chatHidden) ...[
            const SizedBox(width: 20),
            const SizedBox(width: 360, child: RoomCard(child: ChatBox())),
          ],
        ],
      ),
    );
  }

  Widget _buildTablet(_Section section) {
    final bool showChat = !_chatHidden && section == _Section.chat;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(
            width: 340,
            child: RoomCard(
              padding: EdgeInsets.all(20),
              child: PomodoroTimer(),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: RoomCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!_chatHidden) ...[
                    _PanelTabs(
                      chatSelected: showChat,
                      onSelect: (chat) => setState(
                        () => _section = chat ? _Section.chat : _Section.tasks,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Expanded(
                    child: IndexedStack(
                      index: showChat ? 1 : 0,
                      children: [
                        TaskList(showTitle: _chatHidden),
                        if (!_chatHidden) const ChatBox(showTitle: false),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhone(_Section section) {
    final tabs = <_Section>[
      _Section.focus,
      _Section.tasks,
      if (!_chatHidden) _Section.chat,
    ];
    final int index = tabs.indexOf(section).clamp(0, tabs.length - 1);

    // Con poco alto (celular horizontal) se omite para dejar espacio al contenido.
    final bool showMini = MediaQuery.sizeOf(context).height >= 480;

    Widget withMiniTimer(Widget child) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        children: [
          if (showMini) ...[
            MiniTimerBar(
              onOpen: () => setState(() => _section = _Section.focus),
            ),
            const SizedBox(height: 12),
          ],
          Expanded(
            child: RoomCard(padding: const EdgeInsets.all(16), child: child),
          ),
        ],
      ),
    );

    return Column(
      children: [
        Expanded(
          child: IndexedStack(
            index: index,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: PomodoroTimer(showTitle: false),
              ),
              withMiniTimer(const TaskList()),
              if (!_chatHidden) withMiniTimer(const ChatBox()),
            ],
          ),
        ),
        _BottomNav(
          tabs: tabs,
          current: tabs[index],
          onSelect: (s) => setState(() => _section = s),
        ),
      ],
    );
  }
}

/// Pestañas Tareas / Chat de la tablet.
class _PanelTabs extends ConsumerWidget {
  const _PanelTabs({required this.chatSelected, required this.onSelect});

  final bool chatSelected;
  final ValueChanged<bool> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(chatProvider.select((s) => s.unreadCount));
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: kRoomTrack,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _tab(
              icon: LucideIcons.listChecks,
              label: 'Tareas',
              selected: !chatSelected,
              onTap: () => onSelect(false),
            ),
          ),
          Expanded(
            child: _tab(
              icon: LucideIcons.messageSquare,
              label: 'Chat',
              selected: chatSelected,
              badge: unread,
              onTap: () => onSelect(true),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tab({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
    int badge = 0,
  }) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 44,
            decoration: BoxDecoration(
              color: selected ? kRoomSurface : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              boxShadow: selected
                  ? const [
                      BoxShadow(
                        color: Color(0x1A1C2321),
                        blurRadius: 2,
                        offset: Offset(0, 1),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: selected ? kRoomInk : kRoomMuted),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: selected ? kRoomInk : kRoomMuted,
                    fontWeight: AppType.weightSemiBold,
                    fontSize: AppType.sizeBody,
                  ),
                ),
                if (badge > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    constraints: const BoxConstraints(minWidth: 20),
                    height: 20,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: kRoomStudy,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$badge',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: AppType.weightBold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Navegación inferior del celular: Foco · Tareas · Chat.
class _BottomNav extends ConsumerWidget {
  const _BottomNav({
    required this.tabs,
    required this.current,
    required this.onSelect,
  });

  final List<_Section> tabs;
  final _Section current;
  final ValueChanged<_Section> onSelect;

  static const _meta = {
    _Section.focus: (LucideIcons.timer, 'Foco'),
    _Section.tasks: (LucideIcons.listChecks, 'Tareas'),
    _Section.chat: (LucideIcons.messageSquare, 'Chat'),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(chatProvider.select((s) => s.unreadCount)) > 0;
    return Container(
      decoration: const BoxDecoration(
        color: kRoomSurface,
        border: Border(top: BorderSide(color: kRoomLine)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              for (final s in tabs)
                Expanded(
                  child: _item(
                    s,
                    selected: s == current,
                    dot: s == _Section.chat && unread && current != s,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(_Section s, {required bool selected, required bool dot}) {
    final (icon, label) = _meta[s]!;
    final color = selected ? kRoomStudy : kRoomMuted;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: () => onSelect(s),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, size: 22, color: color),
                if (dot)
                  Positioned(
                    top: -2,
                    right: -4,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: kRoomError,
                        shape: BoxShape.circle,
                        border: Border.all(color: kRoomSurface, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: AppType.sizeCaption,
                fontWeight: AppType.weightSemiBold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
