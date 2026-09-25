import "../widgets/custom_snackbar.dart";
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme.dart';
import '../../data/models/user_model.dart';
import '../../logic/onboarding_provider.dart';
import '../../logic/pomodoro_provider.dart';
import '../../logic/room_provider.dart';
import '../../logic/task_provider.dart';
import '../../data/services/sound_service.dart';
import '../widgets/connection_banner.dart';
import '../room/room_workspace.dart';
import '../widgets/mascot/onboarding_tour.dart';
import '../widgets/qr_scanner.dart';

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
      // Sesión terminada por conexión perdida: volver al inicio.
      if (next.sessionEnded && !(previous?.sessionEnded ?? false)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                next.error ??
                    'Se perdió la conexión. Tu sesión se cerró.',
              ),
            ),
          );
          Navigator.of(context).popUntil((route) => route.isFirst);
          ref.read(roomProvider.notifier).clearSessionEnded();
        });
        return;
      }

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
            icon: LucideIcons.listPlus,
            iconColor: kRoomStudy,
          );
          ref.read(taskProvider.notifier).consumeNewTask();
        });
      }
    });

    ref.listen<PomodoroState>(pomodoroProvider, (previous, next) {
      if (next.isFinished && !(previous?.isFinished ?? false)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final breakEnded = next.finishedMode != null &&
              next.finishedMode != kModeFocus;
          showCustomNotification(
            context,
            title: breakEnded
                ? 'Descanso terminado. ¡De vuelta al estudio!'
                : '¡Tiempo completado! Tu descanso está listo.',
            icon: breakEnded ? LucideIcons.bookOpen : LucideIcons.coffee,
            iconColor: breakEnded ? kRoomStudy : kRoomBreak,
          );
        });
      }
      
      // También avisa si la flecha cambió de fase con el reloj corriendo.
      final phaseChangedWhileRunning =
          next.isRunning && previous != null && previous.mode != next.mode;
      if ((next.isRunning && !(previous?.isRunning ?? false)) ||
          phaseChangedWhileRunning) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          showCustomNotification(
            context,
            title: next.isBreak
                ? 'Descanso iniciado. ¡Relájate!'
                : 'Pomodoro iniciado. ¡A concentrarse!',
            icon: next.isBreak ? LucideIcons.coffee : LucideIcons.timer,
            iconColor: next.isBreak ? kRoomBreak : kRoomStudy,
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
        backgroundColor: inRoom ? kRoomBg : kColorPaper,
        appBar: inRoom
            ? null
            : AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: kColorInk),
          title: const Text(''),
          actions: [
            TextButton.icon(
              onPressed: () => showOnboardingTour(
                context,
                ref.read(onboardingProvider.notifier),
              ),
              icon: const Icon(LucideIcons.circleHelp, size: 20),
              label: const Text('¿Cómo funciona?'),
              style: TextButton.styleFrom(
                foregroundColor: kColorTextSecondary,
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          ],
        ),
        body: SafeArea(
          top: inRoom,
          bottom: false,
          child: Column(
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
                  border: Border.all(color: kColorBorder),
                  borderRadius: BorderRadius.circular(24),
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
                        icon: LucideIcons.user,
                        maxLength: _maxUserNameLength,
                      ),

                      const SizedBox(height: 24),
                      if (_mode == _FormMode.create)
                        // --- CAMPO: NOMBRE DE SALA ---
                        _buildOrganicTextField(
                          controller: _roomNameController,
                          label: 'Nombre de la sala',
                          hint: 'ej. Sesión de Física',
                          icon: LucideIcons.doorOpen,
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
                              LucideIcons.scanQrCode,
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
                                      ? LucideIcons.plus
                                      : LucideIcons.logIn,
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
              ? LucideIcons.info
              : LucideIcons.lightbulb,
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
    return RoomWorkspace(
      onLeave: _leaveRoom,
      onKick: _showKickDialog,
      onHelp: () => showOnboardingTour(
        context,
        ref.read(onboardingProvider.notifier),
        inRoom: true,
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
