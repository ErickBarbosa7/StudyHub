import 'package:flutter/material.dart';

import '../../core/theme.dart';

class HelpIcon extends StatelessWidget {
  const HelpIcon({
    super.key,
    required this.title,
    required this.description,
    this.compact = false,
  });

  final String title;
  final String description;
  final bool compact;

  void _showHelp(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: kColorPaper,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (sheetContext) => SafeArea(
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
                      Icons.help_outline_rounded,
                      color: kColorDeepSage,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(
                            color: kColorInk,
                            fontWeight: AppType.weightSemiBold,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                description,
                style: AppType.secondaryItalic(
                  color: kColorInk,
                  size: AppType.sizeBodyMedium,
                ),
              ),
              const SizedBox(height: 28),
              TextButton(
                onPressed: () => Navigator.of(sheetContext).pop(),
                style: TextButton.styleFrom(
                  foregroundColor: kColorDeepSage,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Entendido',
                  style: TextStyle(fontWeight: AppType.weightSemiBold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double size = compact ? 18 : 20;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _showHelp(context),
      child: Container(
        width: size + 8,
        height: size + 8,
        decoration: BoxDecoration(
          color: kColorSageSoft,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.help_outline_rounded,
          size: size,
          color: kColorTextSecondary,
        ),
      ),
      ),
    );
  }
}
