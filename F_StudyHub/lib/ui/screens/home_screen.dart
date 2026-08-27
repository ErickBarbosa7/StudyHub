import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';

import '../../core/theme.dart';
import '../../data/services/sound_service.dart';
import '../../logic/room_provider.dart';
import '../../logic/socket_provider.dart';
import 'create_room_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      ref.read(socketServiceProvider).connect();
      final restored =
          await ref.read(roomProvider.notifier).restoreSavedSession();
      if (restored && mounted) {
        Navigator.of(context).pushNamed(CreateRoomScreen.routeName);
      }
    });
  }

  void _showHowItWorks() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: kColorPaper,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => const _HowItWorksModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final roomState = ref.watch(roomProvider);

    ref.listen<RoomState>(roomProvider, (previous, next) {
      if (next.error != null && next.error != previous?.error) {
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
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [kColorSage, kColorDeepSage],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds),
                  child: const Text(
                    'StudyHub',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: AppType.sizeGiant,
                      fontWeight: AppType.weightBold,
                      letterSpacing: -1,
                      height: 1.1,
                      color: kColorInk,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Lottie.asset(
                  'assets/Lottie/STUDENT.json',
                  height: 240,
                  repeat: true,
                ),
                const SizedBox(height: 32),
                Text(
                  'Estudia en equipo,\na tu ritmo',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: kColorInk,
                        fontWeight: AppType.weightSemiBold,
                        height: 1.2,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Crea una sala o únete con un código.',
                  textAlign: TextAlign.center,
                  style: AppType.secondaryItalic(),
                ),

                const SizedBox(height: 48),

                if (roomState.isRestoring) ...[
                  const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: kColorDeepSage,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Restaurando tu sesión anterior...',
                    textAlign: TextAlign.center,
                    style: AppType.secondaryItalic(
                      color: kColorTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: roomState.isRestoring
                        ? null
                        : () {
                            ref.read(soundProvider.notifier).unlock();
                            Navigator.of(context).pushNamed(
                              CreateRoomScreen.routeName,
                            );
                          },
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Crear o unirse a una sala'),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: _showHowItWorks,
                  icon: const Icon(Icons.help_outline_rounded, size: 20),
                  label: const Text('¿Cómo funciona?'),
                  style: TextButton.styleFrom(
                    foregroundColor: kColorTextSecondary,
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

class _HowItWorksModal extends StatelessWidget {
  const _HowItWorksModal();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(32, 32, 32, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Tu espacio de enfoque',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: kColorInk,
                    fontWeight: AppType.weightSemiBold,
                  ),
            ),
            const SizedBox(height: 32),

            const _HelpFeature(
              icon: Icons.meeting_room_rounded,
              title: 'Salas Privadas',
              subtitle: 'Comparte un código y reúne a tu equipo.',
            ),
            const _HelpFeature(
              icon: Icons.checklist_rounded,
              title: 'Tareas Sincronizadas',
              subtitle: 'Una lista única que se actualiza al instante.',
            ),
            const _HelpFeature(
              icon: Icons.timer_rounded,
              title: 'Reloj Pomodoro',
              subtitle: 'Un solo temporizador para concentrarse juntos.',
            ),

            const SizedBox(height: 32),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: kColorInk,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: const Text('Entendido', style: TextStyle(fontWeight: AppType.weightSemiBold)),
            ),
          ],
        ),
      ),
    );
  }
}

class _HelpFeature extends StatelessWidget {
  const _HelpFeature({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kColorSageSoft,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: kColorDeepSage, size: 28),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: kColorInk,
                        fontWeight: AppType.weightSemiBold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppType.secondaryItalic(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
