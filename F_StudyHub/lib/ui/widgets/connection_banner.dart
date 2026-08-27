import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../logic/socket_provider.dart';

class ConnectionBanner extends ConsumerWidget {
  const ConnectionBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(socketStateProvider);

    if (state.isConnecting) {
      return _Banner(
        color: kColorSageSoft,
        child: Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: kColorDeepSage,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Conectando al servidor…',
                style: TextStyle(color: kColorInk),
              ),
            ),
          ],
        ),
      );
    }

    if (state.error != null) {
      return _Banner(
        color: kColorErrorBorder,
        child: Row(
          children: [
            const Icon(Icons.cloud_off_rounded, color: kColorError, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                state.error!,
                style: const TextStyle(
                  color: kColorInk,
                  fontSize: AppType.sizeCaption,
                ),
              ),
            ),
            TextButton(
              onPressed: () => ref.read(socketStateProvider.notifier).connect(),
              style: TextButton.styleFrom(
                foregroundColor: kColorDeepSage,
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              child: const Text('Reintentar'),
            ),
            IconButton(
              onPressed: () =>
                  ref.read(socketStateProvider.notifier).clearError(),
              icon: const Icon(Icons.close_rounded, size: 18),
              color: kColorTextSecondary,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.color, required this.child});

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}
