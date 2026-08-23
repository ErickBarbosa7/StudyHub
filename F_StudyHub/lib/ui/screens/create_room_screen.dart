import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../logic/room_provider.dart';
import '../widgets/chat_box.dart';
import '../widgets/pomodoro_timer.dart';
import '../widgets/task_list.dart';

enum _FormMode { create, join }

class CreateRoomScreen extends ConsumerStatefulWidget {
  const CreateRoomScreen({super.key});

  static const String routeName = '/create-room';

  @override
  ConsumerState<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends ConsumerState<CreateRoomScreen> {
  _FormMode _mode = _FormMode.create;

  final _roomNameController = TextEditingController();
  final _roomCodeController = TextEditingController();
  final _userNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _roomNameController.dispose();
    _roomCodeController.dispose();
    _userNameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final userName = _userNameController.text.trim();
    final bool created;

    if (_mode == _FormMode.create) {
      final roomName = _roomNameController.text.trim();
      created = await ref
          .read(roomProvider.notifier)
          .createAndJoinRoom(roomName: roomName, userName: userName);
    } else {
      final roomCode = _roomCodeController.text.trim();
      created = await ref
          .read(roomProvider.notifier)
          .joinRoomByCode(roomCode: roomCode, userName: userName);
    }

    if (!mounted) return;

    if (!created) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _mode == _FormMode.create
                ? 'No se pudo crear la sala'
                : 'No se encontró la sala con ese código',
          ),
        ),
      );
    }
  }

  void _leaveRoom() {
    ref.read(roomProvider.notifier).leaveRoom();
  }

  @override
  Widget build(BuildContext context) {
    final roomState = ref.watch(roomProvider);
    final bool inRoom = roomState.room != null;

    return Scaffold(
      backgroundColor: kColorPaper,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: kColorInk),
        title: inRoom
            ? Text(
                roomState.room!.name,
                style: const TextStyle(
                  color: kColorInk,
                  fontWeight: AppType.weightSemiBold,
                ),
              )
            : const Text(''),
        actions: inRoom
            ? [
                IconButton(
                  onPressed: _leaveRoom,
                  icon: const Icon(Icons.logout_rounded, color: kColorTextSecondary),
                  tooltip: 'Salir de la sala',
                ),
              ]
            : null,
      ),
      body: inRoom ? _buildWorkspace(roomState) : _buildCreateForm(roomState),
    );
  }

  // 1. EL FORMULARIO (se mantiene centrado y estrecho a 420px)
  Widget _buildCreateForm(RoomState roomState) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'StudyHub',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: kColorInk,
                      fontWeight: AppType.weightBold,
                      fontSize: 40,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                'Crea tu sala y coordina a tu equipo en tiempo real.',
                textAlign: TextAlign.center,
                style: AppType.secondaryItalic(),
              ),
              const SizedBox(height: 48),

              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: kColorCard,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: kColorTintedShadow,
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildModeToggle(),
                      const SizedBox(height: 28),
                      _buildOrganicTextField(
                        controller: _userNameController,
                        label: 'Tu nombre',
                        hint: 'ej. Ana',
                        icon: Icons.person_outline_rounded,
                      ),
                      const SizedBox(height: 24),
                      if (_mode == _FormMode.create)
                        _buildOrganicTextField(
                          controller: _roomNameController,
                          label: 'Nombre de la sala',
                          hint: 'ej. Sesión de Física',
                          icon: Icons.meeting_room_rounded,
                          textCapitalization: TextCapitalization.sentences,
                          keyboardType: TextInputType.text,
                        )
                      else
                        _buildOrganicTextField(
                          controller: _roomCodeController,
                          label: 'Código de la sala',
                          hint: 'ej. ABC123',
                          icon: Icons.key_rounded,
                          textCapitalization: TextCapitalization.characters,
                          keyboardType: TextInputType.visiblePassword,
                        ),
                      const SizedBox(height: 40),
                      SizedBox(
                        height: 56,
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: roomState.isCreating ? null : _submit,
                          icon: roomState.isCreating
                              ? const SizedBox.shrink()
                              : Icon(
                                  _mode == _FormMode.create
                                      ? Icons.add_rounded
                                      : Icons.login_rounded,
                                ),
                          label: roomState.isCreating
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: kColorInk,
                                  ),
                                )
                              : Text(
                                  _mode == _FormMode.create
                                      ? 'Crear sala'
                                      : 'Unirse',
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: kColorPaper,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          _modePill(
            label: 'Crear sala',
            selected: _mode == _FormMode.create,
            onTap: () => setState(() {
              _mode = _FormMode.create;
              _roomCodeController.clear();
            }),
          ),
          const SizedBox(width: 4),
          _modePill(
            label: 'Unirte',
            selected: _mode == _FormMode.join,
            onTap: () => setState(() {
              _mode = _FormMode.join;
              _roomNameController.clear();
            }),
          ),
        ],
      ),
    );
  }

  Widget _modePill({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? kColorDeepSage : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? kColorPaper : kColorTextSecondary,
              fontWeight: AppType.weightSemiBold,
              fontSize: AppType.sizeBody,
            ),
          ),
        ),
      ),
    );
  }

  // 2. EL ESPACIO DE TRABAJO (Diseño de Dashboard, sin límite de ancho)
  Widget _buildWorkspace(RoomState roomState) {
    return Column(
      children: [
        _buildUsersHeader(roomState),
        Expanded(
          child: DefaultTabController(
            length: 2,
          child: Column(
            children: [
              const TabBar(
                tabs: [
                  Tab(icon: Icon(Icons.timer_rounded), text: 'Estudio'),
                  Tab(icon: Icon(Icons.chat_bubble_rounded), text: 'Chat'),
                ],
              ),
                Expanded(
                  child: TabBarView(
                    children: [
                      // PESTAÑA 1: Temporizador y Tareas
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: const [
                            PomodoroTimer(),
                            SizedBox(height: 32),
                            TaskList(),
                          ],
                        ),
                      ),
                      // PESTAÑA 2: Chat (con espacio propio para el teclado)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: ChatBox(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRoomCodePill(String roomId) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: kColorCard,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: kColorTintedShadow,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.key_rounded, size: 18, color: kColorGold),
          const SizedBox(width: 8),
          Text(
            'Código de sala',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: kColorTextSecondary,
                  fontWeight: AppType.weightSemiBold,
                ),
          ),
          const SizedBox(width: 8),
          Container(width: 1, height: 18, color: kColorBorder),
          const SizedBox(width: 8),
          Text(
            roomId,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: kColorInk,
                  fontWeight: AppType.weightBold,
                  letterSpacing: 1.2,
                ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () async {
              await Clipboard.setData(ClipboardData(text: roomId));
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Código $roomId copiado'),
                ),
              );
            },
            child: const Icon(
              Icons.copy_rounded,
              size: 18,
              color: kColorTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersHeader(RoomState roomState) {
    final room = roomState.room;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (room != null) ...[
            _buildRoomCodePill(room.roomId),
            const SizedBox(height: 16),
          ],
          Text(
            'Conectados (${roomState.users.length})',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: kColorInk,
                  fontWeight: AppType.weightSemiBold,
                ),
          ),
          const SizedBox(height: 12),
          if (roomState.users.isEmpty)
            Text(
              'Esperando a que tu equipo se una...',
              style: AppType.secondaryItalic(size: AppType.sizeBodyMedium),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 12,
              children: roomState.users.map((user) => Chip(
                backgroundColor: kColorSageSoft,
                side: BorderSide.none,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                avatar: const Icon(Icons.circle, size: 10, color: kColorDeepSage),
                label: Text(
                  user.name,
                  style: const TextStyle(color: kColorInk, fontWeight: AppType.weightSemiBold),
                ),
              )).toList(),
            ),
        ],
      ),
    );
  }

  /// Método auxiliar para mantener limpio el código y reusar el estilo del TextField
  Widget _buildOrganicTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextCapitalization textCapitalization = TextCapitalization.sentences,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      textCapitalization: textCapitalization,
      autofillHints: keyboardType == TextInputType.visiblePassword
          ? const [AutofillHints.oneTimeCode]
          : null,
      style: const TextStyle(color: kColorInk),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: kColorTextSecondary),
        hintStyle: TextStyle(color: kColorTextSecondary.withValues(alpha: 0.5)),
        prefixIcon: Icon(icon, color: kColorDeepSage),
        filled: true,
        fillColor: kColorPaper,
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: kColorDeepSage, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: kColorErrorBorder, width: 1.5),
        ),
      ),
      validator: (value) => (value == null || value.trim().isEmpty) ? 'Requerido' : null,
    );
  }
}