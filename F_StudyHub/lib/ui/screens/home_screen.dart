import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';

import '../../core/theme.dart';
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
      // Inicializa la conexión en segundo plano sin bloquear la UI
      ref.read(socketServiceProvider).connect();
      // Si quedó una sala abierta (F5), vuelve a ella automáticamente
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
      backgroundColor: kColorCream,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => const _HowItWorksModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kColorBackground, // Reforzando el fondo orgánico
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
                    colors: [kColorDarkGreen, kColorSoftGreen],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds),
                  child: const Text(
                    'StudyHub',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                      height: 1.1,
                      color: kColorOffBlack,
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
                        color: kColorOffBlack,
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
                
                const SizedBox(height: 48), // Mucho espacio en blanco (Organic Minimal)
                
                SizedBox(
                  width: double.infinity,
                  height: 56, // Botón más amplio y táctil
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pushNamed(
                      CreateRoomScreen.routeName,
                    ),
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

/// Extraemos el Modal a su propio Widget para mantener el código limpio
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
                    color: kColorOffBlack,
                    fontWeight: AppType.weightSemiBold,
                  ),
            ),
            const SizedBox(height: 32),
            
            // Textos más cortos, scaneables y directos
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
                foregroundColor: kColorOffBlack,
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

/// Componente visual simplificado, sin "Cards" rígidas
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
              color: kColorOlive.withValues(alpha: 0.3), // Fondo muy suave
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: kColorDarkGreen, size: 28),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: kColorOffBlack,
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