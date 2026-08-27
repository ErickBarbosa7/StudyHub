import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../logic/room_provider.dart';
import '../widgets/chat_box.dart';
import '../widgets/pomodoro_timer.dart';
import '../widgets/qr_display.dart';
import '../widgets/qr_scanner.dart';
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

  static const int _codeLength = 6;
  late final List<TextEditingController> _codeControllers;
  late final List<FocusNode> _codeFocusNodes;
  bool _showCodeError = false;

  @override
  void initState() {
    super.initState();
    _codeControllers = List.generate(_codeLength, (_) => TextEditingController());
    _codeFocusNodes = List.generate(_codeLength, (_) => FocusNode());
  }

  @override
  void dispose() {
    _roomNameController.dispose();
    _roomCodeController.dispose();
    _userNameController.dispose();
    for (final c in _codeControllers) {
      c.dispose();
    }
    for (final n in _codeFocusNodes) {
      n.dispose();
    }
    super.dispose();
  }

  void _syncCodeController() {
    _roomCodeController.text = _codeControllers.map((c) => c.text).join().toUpperCase();
  }

  void _fillCode(String code) {
    final upper = code.toUpperCase();
    for (int i = 0; i < _codeLength; i++) {
      _codeControllers[i].text = i < upper.length ? upper[i] : '';
    }
    _syncCodeController();
    if (upper.length >= _codeLength) {
      _codeFocusNodes[_codeLength - 1].requestFocus();
    } else if (upper.isNotEmpty) {
      _codeFocusNodes[upper.length.clamp(0, _codeLength - 1)].requestFocus();
    }
    setState(() => _showCodeError = false);
  }

  void _clearCode() {
    for (final c in _codeControllers) {
      c.clear();
    }
    _syncCodeController();
  }

  void _onCodeChanged(int index, String value) {
    if (value.length > 1) {
      _codeControllers[index].text = value.characters.last;
      _codeControllers[index].selection = TextSelection.fromPosition(
        TextPosition(offset: 1),
      );
    }

    final char = _codeControllers[index].text.toUpperCase();
    if (_codeControllers[index].text != char && char.isNotEmpty) {
      _codeControllers[index].text = char;
      _codeControllers[index].selection = TextSelection.fromPosition(
        TextPosition(offset: char.length),
      );
    }

    _syncCodeController();

    if (char.isNotEmpty && index < _codeLength - 1) {
      _codeFocusNodes[index + 1].requestFocus();
    }

    setState(() => _showCodeError = false);
  }

  void _onCodeKeyEvent(int index, KeyEvent event) {
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.backspace) {
      if (_codeControllers[index].text.isEmpty && index > 0) {
        _codeControllers[index - 1].clear();
        _codeFocusNodes[index - 1].requestFocus();
        _syncCodeController();
      }
    }
  }

  Future<void> _handleCodePaste() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text?.trim().toUpperCase() ?? '';
      final alphanumeric = text.replaceAll(RegExp(r'[^A-Z0-9]'), '');
      if (alphanumeric.length == _codeLength) {
        _fillCode(alphanumeric);
      }
    } catch (_) {}
  }

  Future<void> _submit() async {
    if (_mode == _FormMode.join) {
      final code = _codeControllers.map((c) => c.text).join();
      if (code.length < _codeLength) {
        setState(() => _showCodeError = true);
        return;
      }
    }

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
      final error = ref.read(roomProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error ??
                (_mode == _FormMode.create
                    ? 'No se pudo crear la sala. Intenta de nuevo.'
                    : 'No se encontró la sala con ese código. Verifica el código e intenta de nuevo.'),
          ),
        ),
      );
      ref.read(roomProvider.notifier).clearError();
    }
  }

  void _leaveRoom() {
    showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: kColorPaper,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          '¿Salir de la sala?',
          style: TextStyle(
            color: kColorInk,
            fontWeight: AppType.weightSemiBold,
          ),
        ),
        content: Text(
          'Si sales, perderás el acceso a esta sala. Puedes volver a unirte con el mismo código.',
          style: AppType.secondaryItalic(color: kColorInk),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            style: TextButton.styleFrom(foregroundColor: kColorTextSecondary),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: kColorError),
            child: const Text(
              'Salir',
              style: TextStyle(fontWeight: AppType.weightSemiBold),
            ),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        ref.read(roomProvider.notifier).leaveRoom();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final roomState = ref.watch(roomProvider);
    final bool inRoom = roomState.room != null;

    ref.listen<RoomState>(roomProvider, (previous, next) {
      if (next.error != null && next.error != previous?.error && !next.isCreating) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(next.error!)),
          );
          ref.read(roomProvider.notifier).clearError();
        });
      }
    });

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
                      fontSize: AppType.sizeHero,
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
                      const SizedBox(height: 8),
                      _buildModeHelpText(),
                      const SizedBox(height: 20),
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
                      else ...[
                        _buildCodeInputFields(),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final scannedCode = await QrScannerSheet.show(context);
                              if (scannedCode != null && mounted) {
                                _fillCode(scannedCode);
                              }
                            },
                            icon: const Icon(Icons.qr_code_scanner_rounded, size: 22),
                            label: const Text(
                              'Escanear QR para unirse',
                              style: TextStyle(
                                fontSize: AppType.sizeBodyMedium,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildCodeInputFields() {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final bool compact = screenWidth < 400;
    final double boxWidth = compact ? 38 : 46;
    final double boxHeight = boxWidth * 1.2;
    final double gap = compact ? 8 : 10;
    final double fontSize = compact ? 16 : 20;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Código de la sala',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: _showCodeError ? kColorError : kColorTextSecondary,
                fontWeight: AppType.weightSemiBold,
                fontSize: AppType.sizeCaption,
              ),
        ),
        SizedBox(height: boxWidth < 40 ? 8 : 12),
        SizedBox(
          width: screenWidth - 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_codeLength, (index) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (index > 0) SizedBox(width: gap),
                  SizedBox(
                  width: boxWidth,
                  height: boxHeight,
                  child: KeyboardListener(
                    focusNode: FocusNode(),
                    onKeyEvent: (event) => _onCodeKeyEvent(index, event),
                    child: GestureDetector(
                      onTap: _handleCodePaste,
                      child: TextField(
                        controller: _codeControllers[index],
                        focusNode: _codeFocusNodes[index],
                        textAlign: TextAlign.center,
                        textCapitalization: TextCapitalization.characters,
                        keyboardType: TextInputType.visiblePassword,
                        maxLength: 1,
                        style: TextStyle(
                          fontFamily: kFontFamilyMono,
                          fontWeight: AppType.weightSemiBold,
                          fontSize: fontSize,
                          color: kColorInk,
                        ),
                        cursorColor: kColorDeepSage,
                        decoration: InputDecoration(
                          counterText: '',
                          contentPadding: EdgeInsets.zero,
                          filled: true,
                          fillColor: kColorPaper,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: _showCodeError && _codeControllers[index].text.isEmpty
                                  ? kColorErrorBorder
                                  : kColorBorder,
                              width: 1.5,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: _showCodeError && _codeControllers[index].text.isEmpty
                                  ? kColorErrorBorder
                                  : kColorBorder,
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: kColorDeepSage,
                              width: 2,
                            ),
                          ),
                        ),
                        onChanged: (value) => _onCodeChanged(index, value),
                        onTap: () {
                          _codeControllers[index].selection = TextSelection(
                            baseOffset: 0,
                            extentOffset: _codeControllers[index].text.length,
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            );
          }),
          ),
        ),
        if (_showCodeError) ...[
          const SizedBox(height: 8),
          Text(
            'Ingresa los 6 caracteres del código',
            style: TextStyle(
              color: kColorError,
              fontSize: AppType.sizeCaption,
              fontWeight: AppType.weightMedium,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildModeHelpText() {
    final bool isCreate = _mode == _FormMode.create;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          isCreate ? Icons.info_outline_rounded : Icons.lightbulb_outline_rounded,
          size: 16,
          color: kColorTextSecondary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            isCreate
                ? 'Genera un código único que podrás compartir para invitar a tu equipo.'
                : 'Ingresa el código que te compartió tu compañero para entrar a su sala de estudio.',
            style: AppType.secondaryItalic(
              size: AppType.sizeCaption,
              color: kColorTextSecondary,
            ),
          ),
        ),
      ],
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
              _clearCode();
            }),
          ),
          const SizedBox(width: 4),
          _modePill(
            label: 'Unirte',
            selected: _mode == _FormMode.join,
            onTap: () => setState(() {
              _mode = _FormMode.join;
              _roomNameController.clear();
              _showCodeError = false;
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

  Widget _buildWorkspace(RoomState roomState) {
    final bool compact = MediaQuery.sizeOf(context).width < 600;
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
                      SingleChildScrollView(
                        padding: EdgeInsets.all(compact ? 16 : 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: const [
                            PomodoroTimer(),
                            SizedBox(height: 32),
                            TaskList(),
                          ],
                        ),
                      ),
                      Builder(
                        builder: (context) {
                          final bottomInset = MediaQuery.of(context).viewInsets.bottom;
                          return Padding(
                            padding: EdgeInsets.fromLTRB(compact ? 16 : 24, compact ? 16 : 24, compact ? 16 : 24, bottomInset > 0 ? 8 : (compact ? 16 : 24)),
                            child: const ChatBox(),
                          );
                        },
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
    final bool compact = MediaQuery.sizeOf(context).width < 600;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 14, vertical: compact ? 6 : 8),
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
          Icon(Icons.key_rounded, size: compact ? 16 : 18, color: kColorGold),
          SizedBox(width: compact ? 6 : 8),
          Text(
            roomId,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: kColorInk,
                  fontWeight: AppType.weightBold,
                  letterSpacing: 1.2,
                ),
          ),
          SizedBox(width: compact ? 6 : 8),
          GestureDetector(
            onTap: () => QrDisplaySheet.show(context, roomId),
            child: Icon(
              Icons.qr_code_rounded,
              size: compact ? 18 : 22,
              color: kColorDeepSage,
            ),
          ),
          SizedBox(width: compact ? 6 : 8),
          GestureDetector(
            onTap: () async {
              await Clipboard.setData(ClipboardData(text: roomId));
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Código $roomId copiado al portapapeles'),
                ),
              );
            },
            child: Icon(
              Icons.copy_rounded,
              size: compact ? 14 : 16,
              color: kColorTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersHeader(RoomState roomState) {
    final room = roomState.room;
    final bool compact = MediaQuery.sizeOf(context).width < 600;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(compact ? 16 : 24, compact ? 6 : 8, compact ? 16 : 24, compact ? 8 : 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (room != null) _buildRoomCodePill(room.roomId),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 12, vertical: compact ? 4 : 6),
                decoration: BoxDecoration(
                  color: kColorSageSoft,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.people_rounded, size: compact ? 14 : 16, color: kColorDeepSage),
                    SizedBox(width: compact ? 4 : 6),
                    Text(
                      '${roomState.users.length}',
                      style: TextStyle(
                        color: kColorInk,
                        fontWeight: AppType.weightSemiBold,
                        fontSize: compact ? AppType.sizeCaption : AppType.sizeBody,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 8 : 12),
          if (roomState.users.isEmpty)
            Text(
              'Esperando a que tu equipo se una...',
              style: AppType.secondaryItalic(size: AppType.sizeCaption),
            )
          else
            SizedBox(
              height: compact ? 40 : 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: roomState.users.length,
                separatorBuilder: (context, index) => SizedBox(width: compact ? 8 : 10),
                itemBuilder: (context, index) {
                  final user = roomState.users[index];
                  return Container(
                    padding: EdgeInsets.symmetric(horizontal: compact ? 14 : 18, vertical: compact ? 8 : 10),
                    decoration: BoxDecoration(
                      color: kColorSageSoft,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: kColorDeepSage,
                          ),
                        ),
                        SizedBox(width: compact ? 8 : 10),
                        Text(
                          user.name,
                          style: TextStyle(
                            color: kColorInk,
                            fontWeight: AppType.weightSemiBold,
                            fontSize: compact ? AppType.sizeBody : AppType.sizeBodyMedium,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

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
