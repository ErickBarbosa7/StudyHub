import 'package:flutter/material.dart';
import '../../core/app_icons.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/theme.dart';

class QrDisplaySheet extends StatelessWidget {
  const QrDisplaySheet({super.key, required this.roomId});

  final String roomId;

  static void show(BuildContext context, String roomId) {
    final c = context.colors;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: c.bg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (_) => QrDisplaySheet(roomId: roomId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
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
                    color: c.studySoft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    AppIcons.qrCode,
                    color: c.study,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Código de sala',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: c.ink,
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
                  border: Border.all(color: c.line),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: QrImageView(
                  data: roomId,
                  version: QrVersions.auto,
                  size: 200,
                  backgroundColor: Colors.white,
                  eyeStyle: QrEyeStyle(
                    eyeShape: QrEyeShape.circle,
                    color: c.study,
                  ),
                  dataModuleStyle: QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.circle,
                    color: c.ink,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: c.studySoft,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  roomId,
                  style: TextStyle(
                    color: c.ink,
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
              style: AppType.secondaryItalic(context: context,
                size: AppType.sizeCaption,
                color: c.muted,
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
                icon: const Icon(AppIcons.copy, size: 20),
                label: const Text('Copiar código'),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: c.muted,
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
