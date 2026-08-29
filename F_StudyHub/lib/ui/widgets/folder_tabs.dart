import 'package:flutter/material.dart';
import '../../core/theme.dart';

class FolderTabs extends StatelessWidget {
  final int currentIndex;
  final Widget firstTab;
  final Widget secondTab;
  final ValueChanged<int> onChanged;

  const FolderTabs({
    super.key,
    required this.currentIndex,
    required this.firstTab,
    required this.secondTab,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _TabButton(
            isSelected: currentIndex == 0,
            isLeft: true,
            onTap: () => onChanged(0),
            child: firstTab,
          ),
        ),
        Expanded(
          child: _TabButton(
            isSelected: currentIndex == 1,
            isLeft: false,
            onTap: () => onChanged(1),
            child: secondTab,
          ),
        ),
      ],
    );
  }
}

class _TabButton extends StatelessWidget {
  final Widget child;
  final bool isSelected;
  final bool isLeft;
  final VoidCallback onTap;

  const _TabButton({
    required this.child,
    required this.isSelected,
    required this.isLeft,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = isSelected
        ? BorderRadius.only(
            topLeft: isLeft ? Radius.zero : const Radius.circular(24),
            topRight: !isLeft ? Radius.zero : const Radius.circular(24),
          )
        : const BorderRadius.vertical(top: Radius.circular(24)); // Always rounded on top if inactive

    return Material(
      color: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      borderRadius: borderRadius,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        hoverColor: kColorCard.withValues(alpha: 0.5),
        splashColor: kColorCard.withValues(alpha: 0.3),
        highlightColor: kColorCard.withValues(alpha: 0.2),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: isSelected ? kColorCard : Colors.transparent,
            borderRadius: borderRadius,
          ),
          child: Center(
            child: IconTheme(
              data: IconThemeData(
                color: isSelected ? kColorInk : kColorTextSecondary.withValues(alpha: 0.6),
              ),
              child: DefaultTextStyle(
                style: TextStyle(
                  color: isSelected ? kColorInk : kColorTextSecondary.withValues(alpha: 0.6),
                  fontWeight: isSelected ? AppType.weightBold : AppType.weightMedium,
                  fontSize: AppType.sizeBody,
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
