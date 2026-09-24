import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';

import '../../core/theme.dart';
import '../../data/services/sound_service.dart';
import '../../logic/onboarding_provider.dart';
import '../../logic/room_provider.dart';
import '../../logic/socket_provider.dart';
import '../../ui/widgets/connection_banner.dart';
import '../../ui/widgets/mascot/onboarding_tour.dart';
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
      final restored = await ref
          .read(roomProvider.notifier)
          .restoreSavedSession();
      if (restored && mounted) {
        Navigator.of(context).pushNamed(CreateRoomScreen.routeName);
      }
    });
  }

  void _showHowItWorks() {
    showOnboardingTour(context, ref.read(onboardingProvider.notifier));
  }

  @override
  Widget build(BuildContext context) {
    final roomState = ref.watch(roomProvider);

    ref.listen<RoomState>(roomProvider, (previous, next) {
      if (next.error != null && next.error != previous?.error) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(next.error!)));
          ref.read(roomProvider.notifier).clearError();
        });
      }
    });

    return Scaffold(
      backgroundColor: kColorPaper,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: Column(
        children: [
          const ConnectionBanner(),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
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
                        'Estudia y concéntrate\nen equipo',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: kColorInk,
                              fontWeight: AppType.weightSemiBold,
                              height: 1.2,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Una app para estudiar a distancia. Crea una sala con tus amigos, anoten sus tareas y usen el temporizador para no distraerse.',
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
                                  Navigator.of(
                                    context,
                                  ).pushNamed(CreateRoomScreen.routeName);
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
                      if (roomState.room != null) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.of(
                                context,
                              ).pushNamed(CreateRoomScreen.routeName);
                            },
                            icon: const Icon(Icons.arrow_back_rounded),
                            label: const Text('Volver a la sala'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: kColorDeepSage,
                              side: const BorderSide(
                                color: kColorSage,
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                          ),
                        ),
                      ],
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
          ),
        ],
      ),
    );
  }
}
