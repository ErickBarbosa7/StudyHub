import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../../core/theme.dart';

/// Asset Lottie de Clawd, la mascota guía.
const String kClawdAsset = 'assets/Lottie/claude.json';

/// Avatar animado de Clawd (canvas ancho, por eso se usa FittedBox).
class ClawdAvatar extends StatelessWidget {
  const ClawdAvatar({super.key, required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    const double canvasAspect = 2750 / 1850;
    final double width = height * canvasAspect;
    // Capa de repintado propia y frame rate de la animación (12 fps) en vez
    // de repintar a 60 fps.
    return RepaintBoundary(
      child: SizedBox(
        width: width,
        height: height,
        child: FittedBox(
          fit: BoxFit.contain,
          child: Lottie.asset(
            kClawdAsset,
            repeat: true,
            width: width,
            height: height,
            frameRate: FrameRate.composition,
          ),
        ),
      ),
    );
  }
}

/// Tarjeta con el avatar de Clawd y una burbuja de texto (tip contextual).
class MascotTip extends StatelessWidget {
  const MascotTip({
    super.key,
    required this.message,
    this.title,
    this.actionLabel,
    this.onAction,
    this.compact = false,
  });

  final String message;
  final String? title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final double avatarHeight = compact ? 52 : 84;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: EdgeInsets.all(compact ? 12 : 16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClawdAvatar(height: avatarHeight),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null) ...[
                  Text(
                    title!,
                    style: TextStyle(
                      fontFamily: kFontFamily,
                      fontWeight: AppType.weightSemiBold,
                      fontSize: compact ? AppType.sizeLabel : AppType.sizeBody,
                      color: c.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                Text(
                  message,
                  style: AppType.secondaryItalic(context: context,
                    color: c.ink,
                    size: compact ? AppType.sizeBody : AppType.sizeBodyMedium,
                  ),
                ),
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: onAction,
                      style: TextButton.styleFrom(
                        foregroundColor: c.study,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      child: Text(
                        actionLabel!,
                        style: const TextStyle(
                          fontWeight: AppType.weightSemiBold,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}