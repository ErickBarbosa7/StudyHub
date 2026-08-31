import "../widgets/custom_snackbar.dart";
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';

import '../../core/theme.dart';
import '../../data/models/user_model.dart';
import '../../logic/chat_provider.dart';
import '../../logic/pomodoro_provider.dart';
import '../../logic/room_provider.dart';
import '../../logic/task_provider.dart';
import '../../data/services/sound_service.dart';
import '../widgets/chat_box.dart';
import '../widgets/connection_banner.dart';
import '../widgets/pomodoro_timer.dart';
import '../widgets/folder_tabs.dart';
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

  // --- LÍMITES DE CARACTERES PARA PRODUCCIÓN ---
  static const int _maxUserNameLength = 15;
  static const int _maxRoomNameLength = 20;

  late final List<TextEditingController> _codeControllers;
  late final List<FocusNode> _codeFocusNodes;
  bool _showCodeError = false;

  @override
  void initState() {
    super.initState();
    _codeControllers = List.generate(
      _codeLength,
      (_) => TextEditingController(),
    );
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
    _roomCodeController.text = _codeControllers
        .map((c) => c.text)
        .join()
        .toUpperCase();
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
      _fillCode(value);
      return;
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
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace) {
      if (_codeControllers[index].text.isEmpty && index > 0) {
        _codeControllers[index - 1].clear();
        _codeFocusNodes[index - 1].requestFocus();
        _syncCodeController();
      }
      return;
    }

    final isPaste =
        event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.keyV &&
        (HardwareKeyboard.instance.isControlPressed ||
            HardwareKeyboard.instance.isMetaPressed);
    if (isPaste) {
      _handleCodePaste();
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
      final isNotFound =
          error != null && error.toLowerCase().contains('código no válido');
      if (isNotFound) {
        _showNotFoundSheet();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error ??
                  (_mode == _FormMode.create
                      ? 'No se pudo crear la sala. Intenta de nuevo.'
                      : 'Código no válido. Verifica que esté bien escrito e intenta de nuevo.'),
            ),
          ),
        );
      }
      ref.read(roomProvider.notifier).clearError();
    }
  }

  void _showNotFoundSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: kColorPaper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(32, 32, 32, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.asset('assets/Lottie/404.json', height: 180, repeat: true),
            const SizedBox(height: 20),
            const Text(
              'Código no válido',
              style: TextStyle(
                fontSize: AppType.sizeTitle,
                fontWeight: AppType.weightSemiBold,
                color: kColorInk,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No se encontró una sala con ese código. Verifica que esté bien escrito e intenta de nuevo.',
              textAlign: TextAlign.center,
              style: AppType.secondaryItalic(
                size: AppType.sizeBodyMedium,
                color: kColorTextSecondary,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Reintentar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showKickDialog(User user) {
    showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: kColorPaper,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          '¿Expulsar a ${user.name}?',
          style: const TextStyle(
            color: kColorInk,
            fontWeight: AppType.weightSemiBold,
          ),
        ),
        content: Text(
          '${user.name} será removido de la sala. Podrá volver a unirse con el mismo código.',
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
              'Expulsar',
              style: TextStyle(fontWeight: AppType.weightSemiBold),
            ),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        ref.read(roomProvider.notifier).kickUser(user.id);
      }
    });
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
          'Puedes volver a entrar con el código. Pero ojo: si eres el último en irte, la sala desaparecerá.',
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
      if (next.error != null &&
          next.error != previous?.error &&
          !next.isCreating) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final isNotFound = next.error!.toLowerCase().contains(
            'código no válido',
          );
          if (isNotFound) {
            _showNotFoundSheet();
          } else {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(next.error!)));
          }
          ref.read(roomProvider.notifier).clearError();
        });
      }
    });

    ref.listen<TaskState>(taskProvider, (previous, next) {
      if (next.newTaskCount > 0 &&
          next.newTaskCount != previous?.newTaskCount) {
        ref.read(soundProvider.notifier).playTaskNotificationSound();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final creatorName = next.lastAddedTaskCreatorName;
          final titlePrefix = creatorName != null ? '$creatorName agregó una tarea:' : 'Nueva tarea:';
          showCustomNotification(
            context,
            title: '$titlePrefix ${next.lastAddedTaskTitle ?? 'Agregada'}',
            icon: Icons.add_task_rounded,
            iconColor: kColorGold,
          );
          ref.read(taskProvider.notifier).consumeNewTask();
        });
      }
    });

    ref.listen<PomodoroState>(pomodoroProvider, (previous, next) {
      if (next.isFinished && !(previous?.isFinished ?? false)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          showCustomNotification(
            context,
            title: '¡Tiempo completado! Tómate un descanso.',
            icon: Icons.alarm_on_rounded,
          );
        });
      }
      
      if (next.isRunning && !(previous?.isRunning ?? false)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          showCustomNotification(
            context,
            title: 'Pomodoro iniciado. ¡A concentrarse!',
            icon: Icons.timer_rounded,
            iconColor: kColorDeepSage,
          );
        });
      }
    });

    return PopScope(
      canPop: !inRoom,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || !inRoom) return;
        _leaveRoom();
      },
      child: Scaffold(
        backgroundColor: kColorPaper,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: kColorInk),
          title: const Text(''),
          actions: [],
        ),
        body: Column(
          children: [
            const ConnectionBanner(),
            Expanded(
              child: inRoom
                  ? _buildWorkspace(roomState)
                  : _buildCreateForm(roomState),
            ),
          ],
        ),
      ),
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

                      // --- CAMPO: NOMBRE DE USUARIO ---
                      _buildOrganicTextField(
                        controller: _userNameController,
                        label: 'Tu nombre',
                        hint: 'ej. Ana',
                        icon: Icons.person_outline_rounded,
                        maxLength: _maxUserNameLength,
                      ),

                      const SizedBox(height: 24),
                      if (_mode == _FormMode.create)
                        // --- CAMPO: NOMBRE DE SALA ---
                        _buildOrganicTextField(
                          controller: _roomNameController,
                          label: 'Nombre de la sala',
                          hint: 'ej. Sesión de Física',
                          icon: Icons.meeting_room_rounded,
                          textCapitalization: TextCapitalization.sentences,
                          keyboardType: TextInputType.text,
                          maxLength: _maxRoomNameLength,
                        )
                      else ...[
                        _buildCodeInputFields(),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final scannedCode = await QrScannerSheet.show(
                                context,
                              );
                              if (scannedCode != null && mounted) {
                                _fillCode(scannedCode);
                              }
                            },
                            icon: const Icon(
                              Icons.qr_code_scanner_rounded,
                              size: 22,
                            ),
                            label: const Text(
                              'Escanear QR para unirse',
                              style: TextStyle(
                                fontSize: AppType.sizeBodyMedium,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 16,
                              ),
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
                                color:
                                    _showCodeError &&
                                        _codeControllers[index].text.isEmpty
                                    ? kColorErrorBorder
                                    : kColorBorder,
                                width: 1.5,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color:
                                    _showCodeError &&
                                        _codeControllers[index].text.isEmpty
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
          isCreate
              ? Icons.info_outline_rounded
              : Icons.lightbulb_outline_rounded,
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
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
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
      ),
    );
  }

  Widget _buildWorkspace(RoomState roomState) {
    final bool compact = MediaQuery.sizeOf(context).width < 600;
    final bool isWide = MediaQuery.sizeOf(context).width >= 800;
    return Column(
      children: [
        _buildUsersHeader(roomState),
        
        Expanded(
          child: DefaultTabController(
            length: 2,
            child: Stack(
              children: [
                // Unified Content Container
                Positioned.fill(
                  top: 56, // Height of the tabs
                  child: Container(
                    decoration: BoxDecoration(
                      color: kColorCard,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(0), // flush with the tabs
                        bottom: Radius.circular(0),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: kColorTintedShadow,
                          blurRadius: 24,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TabBarView(
                      children: [
                        _StudyTabContent(
                          isWide: isWide,
                          compact: compact,
                        ),
                      Builder(
                        builder: (context) {
                          final bottomInset = MediaQuery.of(context).viewInsets.bottom;
                          final padding = EdgeInsets.fromLTRB(
                            compact ? 16 : 24,
                            compact ? 16 : 24,
                            compact ? 16 : 24,
                            bottomInset > 0 ? 8 : (compact ? 16 : 24),
                          );

                          final hasTasks = ref.watch(
                            taskProvider.select((s) => s.tasks.isNotEmpty),
                          );

                          if (isWide && hasTasks) {
                            return Padding(
                              padding: padding,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Expanded(
                                    flex: 7,
                                    child: ChatBox(),
                                  ),
                                  Container(
                                    width: 1,
                                    margin: const EdgeInsets.symmetric(horizontal: 24),
                                    color: kColorBorder,
                                  ),
                                  const Expanded(
                                    flex: 3,
                                    child: _AllTasksSidePanel(),
                                  ),
                                ],
                              ),
                            );
                          }

                          return Padding(
                            padding: padding,
                            child: const ChatBox(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                ), // Closes Positioned.fill(child: Container)
                // Tabs paint ON TOP of the container to cover the shadow seam!
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 56,
                  child: Builder(
                    builder: (context) {
                      final tabController = DefaultTabController.of(context);
                      return AnimatedBuilder(
                        animation: tabController,
                        builder: (context, child) {
                          return FolderTabs(
                            currentIndex: tabController.index,
                            firstTab: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [Icon(Icons.alarm_rounded), SizedBox(width: 8), Text('Estudio')],
                            ),
                            secondTab: const _ChatTabBadge(),
                            onChanged: (index) {
                              tabController.animateTo(index);
                            },
                          );
                        },
                      );
                    },
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
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 16,
        vertical: compact ? 8 : 10,
      ),
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
          Text(
            'Código:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: kColorTextSecondary,
              fontWeight: AppType.weightSemiBold,
            ),
          ),
          SizedBox(width: compact ? 6 : 8),
          Text(
            roomId,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: kColorInk,
              fontWeight: AppType.weightBold,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(width: compact ? 12 : 16),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
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
                size: compact ? 16 : 18,
                color: kColorTextSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQrBtn(String roomId) {
    final bool compact = MediaQuery.sizeOf(context).width < 600;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => QrDisplaySheet.show(context, roomId),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: kColorSageSoft,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.qr_code_2_rounded,
            size: compact ? 22 : 26,
            color: kColorDeepSage,
          ),
        ),
      ),
    );
  }

  Widget _buildUsersHeader(RoomState roomState) {
    final room = roomState.room;
    final bool compact = MediaQuery.sizeOf(context).width < 600;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        compact ? 16 : 24,
        compact ? 6 : 8,
        compact ? 16 : 24,
        compact ? 24 : 32,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (room != null) ...[
            Text(
              room.name,
              style: const TextStyle(
                fontSize: 32, // Large and prominent
                fontWeight: AppType.weightBold,
                color: kColorInk,
                letterSpacing: -0.5,
                height: 1.1,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: compact ? 12 : 16),
          ],
          Row(
            children: [
              if (room != null) _buildRoomCodePill(room.roomId),
              if (room != null) SizedBox(width: compact ? 8 : 12),
              if (room != null) _buildQrBtn(room.roomId),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: kColorSageSoft,
                  borderRadius: BorderRadius.circular(12), // matched QR radius
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.people_rounded,
                      size: compact ? 22 : 26, // matched QR size
                      color: kColorDeepSage,
                    ),
                    SizedBox(width: compact ? 6 : 8),
                    Text(
                      '${roomState.users.length}',
                      style: TextStyle(
                        color: kColorDeepSage,
                        fontWeight: AppType.weightBold,
                        fontSize: compact ? 16 : 18,
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
                separatorBuilder: (context, index) =>
                    SizedBox(width: compact ? 8 : 10),
                itemBuilder: (context, index) {
                  final user = roomState.users[index];
                  final bool isHost = room?.hostId == user.id;
                  final bool isLocal = roomState.localUser?.id == user.id;
                  final bool canKick =
                      !isHost &&
                      !isLocal &&
                      room?.hostId == roomState.localUser?.id;

                  return GestureDetector(
                    onLongPress: canKick ? () => _showKickDialog(user) : null,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: compact ? 14 : 18,
                        vertical: compact ? 8 : 10,
                      ),
                      decoration: BoxDecoration(
                        color: isHost ? kColorGoldSoft : kColorSageSoft,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isHost ? kColorGold : kColorDeepSage,
                            ),
                          ),
                          SizedBox(width: compact ? 8 : 10),
                          Text(
                            user.name,
                            style: TextStyle(
                              color: kColorInk,
                              fontWeight: AppType.weightSemiBold,
                              fontSize: compact
                                  ? AppType.sizeBody
                                  : AppType.sizeBodyMedium,
                            ),
                          ),
                          if (isHost) ...[
                            SizedBox(width: compact ? 4 : 6),
                            Icon(
                              Icons.workspace_premium_rounded,
                              size: 14,
                              color: kColorGold,
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  // --- WIDGET ACTUALIZADO ---
  Widget _buildOrganicTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextCapitalization textCapitalization = TextCapitalization.sentences,
    TextInputType? keyboardType,
    int? maxLength,
  }) {
    return TextFormField(
      controller: controller,
      textCapitalization: textCapitalization,

      // Bloqueo de entrada
      maxLength: maxLength,
      maxLengthEnforcement: maxLength != null
          ? MaxLengthEnforcement.enforced
          : null,

      autofillHints: keyboardType == TextInputType.visiblePassword
          ? const [AutofillHints.oneTimeCode]
          : null,
      style: const TextStyle(color: kColorInk),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,

        // Ocultar el contador "0/20" para mantener el diseño limpio
        counterText: '',

        labelStyle: const TextStyle(color: kColorTextSecondary),
        hintStyle: TextStyle(color: kColorTextSecondary.withValues(alpha: 0.5)),
        prefixIcon: Icon(icon, color: kColorDeepSage),
        filled: true,
        fillColor: kColorPaper,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 20,
        ),
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
      validator: (value) {
        final text = value?.trim() ?? '';
        if (text.isEmpty) return 'Por favor, completa este campo.';
        if (maxLength != null && text.length > maxLength) {
          return 'Uy, el texto es demasiado largo.';
        }
        return null;
      },
    );
  }
}

class _ChatTabBadge extends ConsumerStatefulWidget {
  const _ChatTabBadge();

  @override
  ConsumerState<_ChatTabBadge> createState() => _ChatTabBadgeState();
}

class _ChatTabBadgeState extends ConsumerState<_ChatTabBadge> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = DefaultTabController.of(context);
    controller.removeListener(_onTabChange);
    controller.addListener(_onTabChange);
  }

  @override
  void dispose() {
    DefaultTabController.of(context).removeListener(_onTabChange);
    super.dispose();
  }

  void _onTabChange() {
    if (!mounted) return;
    ref
        .read(chatProvider.notifier)
        .setChatVisible(DefaultTabController.of(context).index == 1);
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = ref.watch(chatProvider.select((s) => s.unreadCount));
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.forum_rounded),
            SizedBox(width: 8),
            Text('Chat de equipo'),
          ],
        ),
        if (unreadCount > 0)
          Positioned(
            top: -2,
            right: -8,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: kColorError,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
}

class _AllTasksSidePanel extends ConsumerWidget {
  const _AllTasksSidePanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(taskProvider.select((s) => s.tasks));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tareas',
          style: TextStyle(
            fontSize: AppType.sizeTitle,
            fontWeight: AppType.weightBold,
            color: kColorInk,
          ),
        ),
        const SizedBox(height: 16),
        if (tasks.isEmpty)
          const Text(
            'No hay tareas creadas.',
            style: TextStyle(color: kColorTextSecondary),
          )
        else
          Expanded(
            child: ListView.separated(
              itemCount: tasks.length,
              separatorBuilder: (context, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final task = tasks[index];
                final isDone = task.stateCode == 'COMPLETED';
                final isInProgress = task.stateCode == 'IN_PROGRESS';

                final baseColor = isDone
                    ? kColorTextSecondary
                    : (isInProgress ? kColorDeepSage : kColorInk);
                final bgColor = isDone
                    ? kColorPaper
                    : (isInProgress ? kColorSageSoft : Colors.transparent);
                final borderColor = isDone
                    ? kColorBorder
                    : (isInProgress ? kColorDeepSage : kColorBorder);
                final icon = isDone
                    ? Icons.check_circle_rounded
                    : (isInProgress ? Icons.play_circle_outline_rounded : Icons.radio_button_unchecked_rounded);

                // Colores vivos SOLO para la etiqueta del estado
                final pillColor = isDone
                    ? kColorStateDone
                    : (isInProgress ? kColorStateInProgress : kColorStatePending);

                return MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Material(
                    color: Colors.transparent,
                    clipBehavior: Clip.antiAlias,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      onTap: () {
                        DefaultTabController.of(context).animateTo(0);
                      },
                      hoverColor: baseColor.withValues(alpha: 0.1),
                      splashColor: baseColor.withValues(alpha: 0.2),
                      highlightColor: baseColor.withValues(alpha: 0.1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: borderColor, width: isInProgress ? 1.5 : 1.0),
                          borderRadius: BorderRadius.circular(16),
                          color: bgColor,
                        ),
                        child: Row(
                          children: [
                            Icon(icon, color: baseColor, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                task.title,
                                style: TextStyle(
                                  fontWeight: isDone ? AppType.weightMedium : AppType.weightSemiBold,
                                  color: baseColor,
                                  decoration: isDone ? TextDecoration.lineThrough : null,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: pillColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                task.stateLabel,
                                style: TextStyle(
                                  fontSize: AppType.sizeCaption,
                                  fontWeight: AppType.weightSemiBold,
                                  color: pillColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}





class _StudyTabContent extends StatefulWidget {
  const _StudyTabContent({required this.isWide, required this.compact});
  final bool isWide;
  final bool compact;

  @override
  State<_StudyTabContent> createState() => _StudyTabContentState();
}

class _StudyTabContentState extends State<_StudyTabContent> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (widget.isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 1,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: const PomodoroTimer(),
            ),
          ),
          Expanded(
            flex: 1,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: const TaskList(),
            ),
          ),
        ],
      );
    } else {
      return SingleChildScrollView(
        padding: EdgeInsets.all(widget.compact ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: const [
            PomodoroTimer(),
            SizedBox(height: 16),
            TaskList(),
          ],
        ),
      );
    }
  }
}
