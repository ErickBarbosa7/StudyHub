import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../core/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../data/services/sound_service.dart';
import '../../logic/onboarding_provider.dart';
import '../../logic/room_provider.dart';
import '../../logic/socket_provider.dart';
import '../../ui/widgets/connection_banner.dart';
import '../../ui/widgets/landing_hero.dart';
import '../../ui/widgets/mascot/onboarding_tour.dart';
import '../../ui/widgets/theme_toggle.dart';
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
      // En pantallas anchas el inicio ya muestra la sala restaurada.
      if (restored &&
          mounted &&
          MediaQuery.sizeOf(context).width < kLandingBreakpoint) {
        Navigator.of(context).pushNamed(CreateRoomScreen.routeName);
      }
    });
  }

  void _showHowItWorks() {
    showOnboardingTour(context, ref.read(onboardingProvider.notifier));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    // Laptop: el inicio es directamente el formulario, sin clic intermedio.
    if (MediaQuery.sizeOf(context).width >= kLandingBreakpoint) {
      return const CreateRoomScreen(landing: true);
    }

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
      backgroundColor: c.brand,
      body: SafeArea(
        child: Column(
          children: [
            const ConnectionBanner(),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final bool roomy = constraints.maxHeight >= 660;
                        final double width = constraints.maxWidth;

                        final header = Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Align(
                              alignment: Alignment.centerRight,
                              // Tema junto a la ayuda: son los dos controles de la
                              // app fuera de la sala, arriba a la derecha.
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const ThemeTogglePillButton(),
                                  const SizedBox(width: 4),
                                  IconButton(
                                    onPressed: _showHowItWorks,
                                    tooltip: '¿Cómo funciona?',
                                    icon: const Icon(
                                      AppIcons.circleHelp,
                                      color: kLandingSoft,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            LandingWordmark(maxWidth: width),
                            SizedBox(
                              height: math.max(
                                10,
                                LandingWordmark.sizeFor(width) * 0.16,
                              ),
                            ),
                            LandingTagline(width: width),
                            const SizedBox(height: 20),
                            const LandingFeatures(),
                          ],
                        );

                        final actions = Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (roomState.isRestoring) ...[
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'Restaurando tu sesión anterior...',
                                    style: TextStyle(color: kLandingSoft),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                            ],
                            SizedBox(
                              height: 56,
                              child: ElevatedButton.icon(
                                onPressed: roomState.isRestoring
                                    ? null
                                    : () {
                                        ref
                                            .read(soundProvider.notifier)
                                            .unlock();
                                        Navigator.of(
                                          context,
                                        ).pushNamed(CreateRoomScreen.routeName);
                                      },
                                icon: const Icon(AppIcons.plus),
                                label: const Text('Crear o unirse a una sala'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: c.brand,
                                  disabledBackgroundColor: const Color(
                                    0x80FFFFFF,
                                  ),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ),
                            if (roomState.room != null) ...[
                              const SizedBox(height: 12),
                              SizedBox(
                                height: 56,
                                child: OutlinedButton.icon(
                                  onPressed: () => Navigator.of(
                                    context,
                                  ).pushNamed(CreateRoomScreen.routeName),
                                  icon: const Icon(AppIcons.arrowLeft),
                                  label: const Text('Volver a la sala'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: const BorderSide(
                                      color: Color(0x80FFFFFF),
                                      width: 1.5,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        );

                        if (!roomy) {
                          // Pantalla baja: todo en una columna con scroll.
                          return SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                header,
                                const SizedBox(height: 28),
                                actions,
                              ],
                            ),
                          );
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            header,
                            // La animación usa el alto que sobre.
                            Expanded(
                              child: LayoutBuilder(
                                builder: (context, box) {
                                  if (box.maxHeight < 170) {
                                    return const SizedBox.shrink();
                                  }
                                  return Center(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 20,
                                      ),
                                      child: LandingIllustration(
                                        height: math.min(
                                          box.maxHeight - 40,
                                          width / LandingIllustration.aspect,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            actions,
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
