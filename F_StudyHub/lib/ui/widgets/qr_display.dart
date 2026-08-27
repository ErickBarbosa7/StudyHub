import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/theme.dart';

class QrDisplaySheet extends StatelessWidget {
  const QrDisplaySheet({super.key, required this.roomId});

  final String roomId;

  static void show(BuildContext context, String roomId) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: kColorPaper,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (_) => QrDisplaySheet(roomId: roomId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 32, 32, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: kColorSageSoft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.qr_code_rounded,
                    color: kColorDeepSage,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Código de sala',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: kColorInk,
                          fontWeight: AppType.weightSemiBold,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: kColorTintedShadow,
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: QrImageView(
                  data: roomId,
                  version: QrVersions.auto,
                  size: 200,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.circle,
                    color: kColorDeepSage,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.circle,
                    color: kColorInk,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: kColorSageSoft,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  roomId,
                  style: const TextStyle(
                    color: kColorInk,
                    fontWeight: AppType.weightBold,
                    fontSize: AppType.sizeBodyLarge,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Comparte este código o esta imagen con tu equipo para que se unan a la sala.',
              textAlign: TextAlign.center,
              style: AppType.secondaryItalic(
                size: AppType.sizeCaption,
                color: kColorTextSecondary,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: roomId));
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Código $roomId copiado al portapapeles')),
                  );
                },
                icon: const Icon(Icons.copy_rounded, size: 20),
                label: const Text('Copiar código'),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: kColorTextSecondary,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Entendido'),
            ),
          ],
        ),
      ),
    );
  }
}
