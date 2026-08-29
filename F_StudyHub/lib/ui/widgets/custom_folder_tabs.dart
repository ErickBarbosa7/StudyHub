import 'package:flutter/material.dart';
import '../../core/theme.dart';

class CustomFolderTabs extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onChanged;

  const CustomFolderTabs({
    super.key,
    required this.currentIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _TabButton(
            title: 'Estudio',
            icon: Icons.alarm_rounded,
            isSelected: currentIndex == 0,
            isLeft: true,
            onTap: () => onChanged(0),
          ),
        ),
        Expanded(
          child: _TabButton(
            title: 'Chat de equipo',
            icon: Icons.forum_rounded,
            isSelected: currentIndex == 1,
            isLeft: false,
            onTap: () => onChanged(1),
          ),
        ),
      ],
    );
  }
}

class _TabButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final bool isLeft;
  final VoidCallback onTap;

  const _TabButton({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.isLeft,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = Radius.circular(24);
    final borderRadius = BorderRadius.only(
      topLeft: isLeft ? Radius.zero : radius,
      topRight: !isLeft ? Radius.zero : radius,
    );

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: isSelected ? kColorCard : Colors.transparent,
            borderRadius: borderRadius,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? kColorDeepSage : kColorTextSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? kColorDeepSage : kColorTextSecondary,
                  fontWeight: isSelected ? AppType.weightSemiBold : AppType.weightMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
