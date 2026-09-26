import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_icons.dart';
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

  static const _chatWidth = 360.0;
  static const _railWidth = 56.0;

  bool _chatHidden = false;

  /// Falso hasta aplicar la preferencia guardada: así un chat plegado no se
  /// anima al abrir la sala.
  bool _animateChat = false;
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _animateChat = true);
    });
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
      color: context.colors.bg,
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
    final bool animate =
        _animateChat && !MediaQuery.disableAnimationsOf(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(width: 440, child: RoomCard(child: PomodoroTimer())),
          const SizedBox(width: 20),
          const Expanded(child: RoomCard(child: TaskList())),
          const SizedBox(width: 20),
          _buildChatColumn(animate),
        ],
      ),
    );
  }

  /// Columna del chat en laptop: abierta (tarjeta) o plegada (riel). El chat
  /// sigue montado al plegarlo para no perder el borrador ni el scroll.
  Widget _buildChatColumn(bool animate) {
    final bool hidden = _chatHidden;
    final duration = animate
        ? const Duration(milliseconds: 220)
        : Duration.zero;
    final c = context.colors;
    final radius = BorderRadius.circular(20);

    return AnimatedContainer(
      duration: duration,
      curve: Curves.easeOutCubic,
      width: hidden ? _railWidth : _chatWidth,
      // El borde, el radio y el fondo los lleva el contenedor y no la tarjeta de
      // dentro: lo que exceda el ancho lo recorta el ClipRRect, así que una
      // tarjeta con borde propio perdía el de la derecha en cuanto empezaba a
      // encogerse y dejaba un corte sin línea.
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.line),
        borderRadius: radius,
      ),
      child: Material(
        // Solo como lienzo del InkWell del riel; el fondo ya está arriba.
        type: MaterialType.transparency,
        child: ClipRRect(
          borderRadius: radius,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Ancho fijo: el chat no se vuelve a maquetar mientras se encoge,
              // solo se recorta y se desvanece.
              OverflowBox(
                alignment: Alignment.centerLeft,
                minWidth: _chatWidth,
                maxWidth: _chatWidth,
                child: ExcludeFocus(
                  excluding: hidden,
                  child: ExcludeSemantics(
                    excluding: hidden,
                    child: IgnorePointer(
                      ignoring: hidden,
                      // El TickerMode va DENTRO del AnimatedOpacity: fuera, al
                      // plegar silenciaba el ticker del propio desvanecido, la
                      // opacidad se quedaba en 1 y el chat asomaba en el riel.
                      child: AnimatedOpacity(
                        duration: duration,
                        opacity: hidden ? 0 : 1,
                        child: TickerMode(
                          enabled: !hidden,
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: ChatBox(onCollapse: _toggleChat),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              IgnorePointer(
                ignoring: !hidden,
                child: ExcludeSemantics(
                  excluding: !hidden,
                  child: AnimatedOpacity(
                    duration: duration,
                    opacity: hidden ? 1 : 0,
                    child: _ChatRail(onExpand: _toggleChat),
                  ),
                ),
              ),
            ],
          ),
        ),
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
                      onHideChat: _toggleChat,
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
          // Las secciones fuera de vista conservan su estado (texto escrito,
          // scroll) pero sin animar: TickerMode las deja en pausa.
          child: IndexedStack(
            index: index,
            children: [
              TickerMode(
                enabled: index == 0,
                child: const Padding(
                  padding: EdgeInsets.fromLTRB(16, 4, 16, 16),
                  child: PomodoroTimer(showTitle: false),
                ),
              ),
              TickerMode(
                enabled: index == 1,
                child: withMiniTimer(const TaskList()),
              ),
              if (!_chatHidden)
                TickerMode(
                  enabled: index == 2,
                  child: withMiniTimer(
                    ChatBox(
                      onCollapse: _toggleChat,
                      collapseIcon: AppIcons.x,
                    ),
                  ),
                ),
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
  const _PanelTabs({
    required this.chatSelected,
    required this.onSelect,
    required this.onHideChat,
  });

  final bool chatSelected;
  final ValueChanged<bool> onSelect;

  /// Cierra el chat (quita su pestaña); solo se ofrece estando en el chat.
  final VoidCallback onHideChat;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final unread = ref.watch(chatProvider.select((s) => s.unreadCount));
    final tabs = Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: c.track,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _tab(
              c: c,
              icon: AppIcons.listChecks,
              label: 'Tareas',
              selected: !chatSelected,
              onTap: () => onSelect(false),
            ),
          ),
          Expanded(
            child: _tab(
              c: c,
              icon: AppIcons.messageSquare,
              label: 'Chat',
              selected: chatSelected,
              badge: unread,
              onTap: () => onSelect(true),
            ),
          ),
        ],
      ),
    );

    return Row(
      children: [
        Expanded(child: tabs),
        if (chatSelected) ...[
          const SizedBox(width: 8),
          RoomIconButton(
            icon: AppIcons.x,
            tooltip: 'Ocultar chat',
            foreground: c.muted,
            onPressed: onHideChat,
          ),
        ],
      ],
    );
  }

  Widget _tab({
    required AppColors c,
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
              color: selected ? c.surface : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: c.shadow,
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: selected ? c.ink : c.muted),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: selected ? c.ink : c.muted,
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
                      color: c.study,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$badge',
                      style: TextStyle(
                        color: c.onAccent,
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
    _Section.focus: (AppIcons.timer, 'Foco'),
    _Section.tasks: (AppIcons.listChecks, 'Tareas'),
    _Section.chat: (AppIcons.messageSquare, 'Chat'),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final unread = ref.watch(chatProvider.select((s) => s.unreadCount > 0));
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.line)),
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
                    c,
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

  Widget _item(AppColors c, _Section s, {required bool selected, required bool dot}) {
    final (icon, label) = _meta[s]!;
    final color = selected ? c.study : c.muted;
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
                        color: c.error,
                        shape: BoxShape.circle,
                        border: Border.all(color: c.surface, width: 2),
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

/// Lo que queda del chat en laptop cuando está plegado: un riel con el botón
/// para abrirlo y los mensajes sin leer.
class _ChatRail extends ConsumerWidget {
  const _ChatRail({required this.onExpand});

  final VoidCallback onExpand;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final unread = ref.watch(chatProvider.select((s) => s.unreadCount));
    final label = unread > 0 ? 'Mostrar chat, $unread sin leer' : 'Mostrar chat';

    return Tooltip(
      message: 'Mostrar chat',
      child: Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        // El fondo y el borde los pinta el contenedor que se encoge, así que el
        // riel no lleva tarjeta propia: si la llevara, su borde derecho
        // aparecería fading dentro del de la barra mientras se cierra.
        child: InkWell(
          onTap: onExpand,
          customBorder: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                Icon(AppIcons.panelRightOpen, size: 20, color: c.ink),
                const SizedBox(height: 12),
                if (unread > 0)
                  Container(
                    constraints: const BoxConstraints(minWidth: 24),
                    height: 24,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color: c.study,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Center(
                      widthFactor: 1,
                      child: Text(
                        unread > 99 ? '99+' : '$unread',
                        style: TextStyle(
                          color: c.onAccent,
                          fontSize: 11,
                          fontWeight: AppType.weightBold,
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: RotatedBox(
                        quarterTurns: 3,
                        child: Text(
                          'Chat',
                          style: TextStyle(
                            color: c.muted,
                            fontSize: AppType.sizeBody,
                            fontWeight: AppType.weightSemiBold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
