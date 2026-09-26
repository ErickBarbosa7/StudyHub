import 'package:flutter/material.dart';
import '../../core/theme.dart';

void showCustomNotification(
  BuildContext context, {
  required String title,
  required IconData icon,
  Color? iconColor,
}) {
  final c = context.colors;
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: c.snackBg,
      content: Row(
        children: [
          Icon(icon, color: iconColor ?? c.study, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: c.snackText,
                fontWeight: AppType.weightSemiBold,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
      duration: const Duration(seconds: 3),
    ),
  );
}
