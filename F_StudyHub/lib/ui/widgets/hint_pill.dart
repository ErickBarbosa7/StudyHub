import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme.dart';

class HintPill extends StatefulWidget {
  const HintPill({
    super.key,
    required this.message,
    required this.icon,
    this.entrance = const Duration(milliseconds: 320),
    this.stay = const Duration(seconds: 4),
    this.gap = const Duration(seconds: 6),
  });

  final String message;
  final IconData icon;
  final Duration entrance;
  final Duration stay;
  final Duration gap;

  @override
  State<HintPill> createState() => _HintPillState();
}

class _HintPillState extends State<HintPill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: widget.entrance)
          ..addStatusListener(_onStatus);
    _slide =
        Tween<Offset>(begin: const Offset(0, 0.35), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _timer?.cancel();
      _timer = Timer(widget.stay, () {
        if (!mounted) return;
        _controller.reverse();
      });
    } else if (status == AnimationStatus.dismissed) {
      _timer?.cancel();
      _timer = Timer(widget.gap, () {
        if (!mounted) return;
        _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _fade,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: kColorSageSoft,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: kColorSage),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, color: kColorDeepSage, size: 18),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  widget.message,
                  style:
                      AppType.secondaryItalic(size: AppType.sizeBodyMedium),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}