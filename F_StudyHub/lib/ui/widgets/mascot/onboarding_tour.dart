import 'package:flutter/material.dart';
import '../../../core/app_icons.dart';

import '../../../core/theme.dart';
import '../../../logic/onboarding_provider.dart';
import '../../room/room_widgets.dart';
import 'mascot_bubble.dart';

/// Ilustración pequeña que acompaña a cada paso de la guía.
enum _Preview { welcome, join, modes, controls, tasks, chat, invite }

class _Step {
  const _Step({
    required this.title,
    required this.message,
    required this.preview,
  });

  final String title;
  final String message;
  final _Preview preview;
}

const _welcome = _Step(
  title: 'Estudia solo o en equipo',
  message:
      'StudyHub reúne en una sala un reloj Pomodoro compartido, una lista '
      'de tareas y un chat. Todo se sincroniza al instante.',
  preview: _Preview.welcome,
);

const _join = _Step(
  title: 'Crea una sala o únete a una',
  message:
      'Crea una sala con un nombre y comparte su código de 6 caracteres. '
      'Para entrar a la de alguien más, escribe su código o escanea el QR.',
  preview: _Preview.join,
);

const _modes = _Step(
  title: 'Elige cómo trabajar',
  message:
      'Estudio, descanso corto (5 min) o descanso largo (15 min). Elige el '
      'modo y la duración, y pulsa Iniciar: el reloj corre igual para todos.',
  preview: _Preview.modes,
);

const _controls = _Step(
  title: 'Los descansos llegan solos',
  message:
      'Al terminar el estudio se prepara un descanso, en pausa hasta que '
      'pulses Iniciar. Cada 4 rondas toca uno largo. Con la flecha '
      'Siguiente pasas a la otra fase antes de tiempo.',
  preview: _Preview.controls,
);

const _tasks = _Step(
  title: 'Anota lo que quieres lograr',
  message:
      'Toca el cuadro para marcar una tarea como hecha. Toca su texto o su '
      'estado para cambiarlo, editarla o borrarla. Si hay más personas, '
      'todos ven los cambios al momento.',
  preview: _Preview.tasks,
);

const _chat = _Step(
  title: 'Chat, solo si lo necesitas',
  message:
      'Habla con tu equipo sin salir de la sala. ¿Estudias solo? Oculta el '
      'chat con el botón de arriba y el reloj y las tareas ocupan todo el '
      'espacio.',
  preview: _Preview.chat,
);

const _invite = _Step(
  title: 'Invita a más personas',
  message:
      'Comparte el código o el QR de la sala. Toca los avatares para ver '
      'quién está conectado; el anfitrión también puede expulsar a alguien.',
  preview: _Preview.invite,
);

/// Desde el inicio se explica qué es la app; dentro de la sala, cómo usarla.
List<_Step> _stepsFor({required bool inRoom}) => inRoom
    ? const [_modes, _controls, _tasks, _chat, _invite]
    : const [_welcome, _join, _modes, _controls, _tasks, _chat];

/// Abre la guía. [inRoom] adapta los pasos: fuera de la sala presenta la app;
/// dentro, explica el reloj, las tareas, el chat y cómo invitar.
Future<void> showOnboardingTour(
  BuildContext context,
  OnboardingNotifier notifier, {
  bool inRoom = false,
}) async {
  final isWide = MediaQuery.sizeOf(context).width >= 600;
  notifier.markOpened();
  final view = _OnboardingTourView(steps: _stepsFor(inRoom: inRoom));

  if (isWide) {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => Dialog(
        backgroundColor: kRoomSurface,
        insetPadding: const EdgeInsets.all(24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: view,
        ),
      ),
    );
  } else {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: kRoomSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(child: view),
    );
  }

  // Al cerrar (terminar o saltar) se marca como vista.
  await notifier.complete();
}

class _OnboardingTourView extends StatefulWidget {
  const _OnboardingTourView({required this.steps});

  final List<_Step> steps;

  @override
  State<_OnboardingTourView> createState() => _OnboardingTourViewState();
}

class _OnboardingTourViewState extends State<_OnboardingTourView> {
  int _index = 0;

  bool get _isFirst => _index == 0;
  bool get _isLast => _index == widget.steps.length - 1;

  void _close() => Navigator.of(context).pop();

  void _next() {
    if (_isLast) {
      _close();
      return;
    }
    setState(() => _index += 1);
  }

  void _back() {
    if (_isFirst) {
      _close();
      return;
    }
    setState(() => _index -= 1);
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.steps[_index];
    final total = widget.steps.length;
    // Cabecera y botones fijos; solo el contenido del paso hace scroll, para
    // que "Siguiente" siempre quede a la vista (pantallas bajas).
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Paso ${_index + 1} de $total',
                  style: const TextStyle(
                    color: kRoomMuted,
                    fontSize: AppType.sizeLabel,
                    fontWeight: AppType.weightSemiBold,
                  ),
                ),
              ),
              RoomIconButton(
                icon: AppIcons.x,
                tooltip: 'Cerrar guía',
                bordered: false,
                background: Colors.transparent,
                onPressed: _close,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Flexible(
            child: SingleChildScrollView(
              child: AnimatedSize(
                duration: const Duration(milliseconds: 200),
                alignment: Alignment.topCenter,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Column(
                    key: ValueKey(_index),
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        height: 132,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: kRoomBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: _PreviewView(step.preview),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        step.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: kRoomInk,
                          fontSize: AppType.sizeTitle,
                          fontWeight: AppType.weightBold,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        step.message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: kRoomMuted,
                          fontSize: AppType.sizeBodyMedium,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(total, (i) {
              final active = i == _index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 22 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: active ? kRoomStudy : kRoomLine,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: _back,
                  style: TextButton.styleFrom(
                    foregroundColor: kRoomMuted,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(_isFirst ? 'Saltar' : 'Atrás'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: _next,
                    style: FilledButton.styleFrom(
                      backgroundColor: kRoomStudy,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(_isLast ? 'Entendido' : 'Siguiente'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Mini vista de la función que explica cada paso, con los mismos colores
/// e iconos que la sala real.
class _PreviewView extends StatelessWidget {
  const _PreviewView(this.preview);

  final _Preview preview;

  @override
  Widget build(BuildContext context) {
    return switch (preview) {
      _Preview.welcome => const ClawdAvatar(height: 100),
      _Preview.join => const Row(
        children: [
          Expanded(
            child: _Tile(
              icon: AppIcons.plus,
              label: 'Crear sala',
              detail: 'Con nombre',
              accent: kRoomStudy,
              soft: kRoomStudySoft,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: _Tile(
              icon: AppIcons.logIn,
              label: 'Unirme',
              detail: 'Con código',
              accent: kRoomLong,
              soft: kRoomLongSoft,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: _Tile(
              icon: AppIcons.scanQrCode,
              label: 'Escanear',
              detail: 'Código QR',
              accent: kRoomBreakInk,
              soft: kRoomBreakSoft,
            ),
          ),
        ],
      ),
      _Preview.modes => const Row(
        children: [
          Expanded(
            child: _Tile(
              icon: AppIcons.bookOpen,
              label: 'Estudio',
              detail: '5 a 180 min',
              accent: kRoomStudy,
              soft: kRoomStudySoft,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: _Tile(
              icon: AppIcons.coffee,
              label: 'Descanso corto',
              detail: '5 min',
              accent: kRoomBreak,
              soft: kRoomBreakSoft,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: _Tile(
              icon: AppIcons.moon,
              label: 'Descanso largo',
              detail: '15 min',
              accent: kRoomLong,
              soft: kRoomLongSoft,
            ),
          ),
        ],
      ),
      _Preview.controls => const _Fit(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Captioned(
              caption: 'Reiniciar',
              child: _MiniSquare(
                icon: AppIcons.rotateCcw,
                foreground: kRoomInk,
                background: kRoomSurface,
                bordered: true,
              ),
            ),
            SizedBox(width: 12),
            _Captioned(caption: 'Iniciar o pausar', child: _MiniPrimary()),
            SizedBox(width: 12),
            _Captioned(
              caption: 'Adelantar',
              child: _MiniSquare(
                icon: AppIcons.skipForward,
                foreground: kRoomStudy,
                background: kRoomStudySoft,
                bordered: false,
              ),
            ),
          ],
        ),
      ),
      _Preview.tasks => const _Fit(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RoomChip(
              label: 'Pendiente',
              background: kRoomTrack,
              foreground: kRoomMuted,
            ),
            _Arrow(),
            RoomChip(
              label: 'En progreso',
              background: kRoomBreakSoft,
              foreground: kRoomBreakInk,
            ),
            _Arrow(),
            RoomChip(
              label: 'Completada',
              background: kRoomStudySoft,
              foreground: kRoomStudy,
            ),
          ],
        ),
      ),
      _Preview.chat => const _Fit(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Captioned(
              caption: 'Chat visible',
              child: _MiniSquare(
                icon: AppIcons.messageSquare,
                foreground: kRoomInk,
                background: kRoomSurface,
                bordered: true,
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 14, left: 12, right: 12),
              child: _Arrow(),
            ),
            _Captioned(
              caption: 'Chat oculto',
              child: _MiniSquare(
                icon: AppIcons.messageSquareOff,
                foreground: kRoomMuted,
                background: kRoomSurface,
                bordered: true,
              ),
            ),
          ],
        ),
      ),
      _Preview.invite => const _Fit(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _MiniCode(),
            SizedBox(width: 10),
            _MiniSquare(
              icon: AppIcons.qrCode,
              foreground: kRoomInk,
              background: kRoomSurface,
              bordered: true,
            ),
            SizedBox(width: 14),
            RoomAvatar(name: 'Ana Lu', index: 0, ringColor: kRoomBg),
            Padding(
              padding: EdgeInsets.only(left: 4),
              child: RoomAvatar(name: 'Marco', index: 1, ringColor: kRoomBg),
            ),
          ],
        ),
      ),
    };
  }
}

/// Reduce la mini vista si no cabe (pantallas angostas o fuentes grandes).
class _Fit extends StatelessWidget {
  const _Fit({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      FittedBox(fit: BoxFit.scaleDown, child: child);
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.label,
    required this.detail,
    required this.accent,
    required this.soft,
  });

  final IconData icon;
  final String label;
  final String detail;
  final Color accent;
  final Color soft;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
      decoration: BoxDecoration(
        color: soft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 22, color: accent),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: const TextStyle(
              color: kRoomInk,
              fontSize: AppType.sizeCaption,
              fontWeight: AppType.weightSemiBold,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            detail,
            textAlign: TextAlign.center,
            maxLines: 1,
            style: TextStyle(
              color: accent,
              fontSize: AppType.sizeCaption,
              fontWeight: AppType.weightSemiBold,
            ),
          ),
        ],
      ),
    );
  }
}

class _Arrow extends StatelessWidget {
  const _Arrow();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(horizontal: 4),
    child: Icon(AppIcons.chevronRight, size: 16, color: kRoomMuted),
  );
}

class _Captioned extends StatelessWidget {
  const _Captioned({required this.caption, required this.child});

  final String caption;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        child,
        const SizedBox(height: 6),
        Text(
          caption,
          style: const TextStyle(
            color: kRoomMuted,
            fontSize: AppType.sizeCaption,
          ),
        ),
      ],
    );
  }
}

class _MiniSquare extends StatelessWidget {
  const _MiniSquare({
    required this.icon,
    required this.foreground,
    required this.background,
    required this.bordered,
  });

  final IconData icon;
  final Color foreground;
  final Color background;
  final bool bordered;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
        border: bordered ? Border.all(color: kRoomLine) : null,
      ),
      child: Icon(icon, size: 20, color: foreground),
    );
  }
}

class _MiniPrimary extends StatelessWidget {
  const _MiniPrimary();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: kRoomStudy,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(AppIcons.play, size: 18, color: Colors.white),
          SizedBox(width: 8),
          Text(
            'Iniciar',
            style: TextStyle(
              color: Colors.white,
              fontWeight: AppType.weightSemiBold,
              fontSize: AppType.sizeBody,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniCode extends StatelessWidget {
  const _MiniCode();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: kRoomSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kRoomLine),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'K7Q2MX',
            style: TextStyle(
              color: kRoomInk,
              fontSize: AppType.sizeBody,
              fontWeight: AppType.weightBold,
              letterSpacing: 1.6,
            ),
          ),
          SizedBox(width: 8),
          Icon(AppIcons.copy, size: 16, color: kRoomMuted),
        ],
      ),
    );
  }
}
