import 'dart:math';

import 'package:flutter/material.dart';

enum HalfCircleBounceDirection { left, right }

class HalfCircleBounce extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final void Function()? onTap;
  final HalfCircleBounceDirection? direction;
  const HalfCircleBounce({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.onTap,
    this.direction = HalfCircleBounceDirection.right,
  });

  @override
  State<HalfCircleBounce> createState() => _HalfCircleBounceState();
}

class _HalfCircleBounceState extends State<HalfCircleBounce>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotation;

  @override
  void initState() {
    super.initState();
    bool isRight = widget.direction == HalfCircleBounceDirection.right;
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _rotation = Tween<double>(
      begin: 0,
      end: isRight ? pi / 2 : -pi / 2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        await _controller.forward();
        _controller.reverse();
        widget.onTap?.call();
      },
      splashColor: Colors.transparent,
      splashFactory: NoSplash.splashFactory,
      child: AnimatedBuilder(
        animation: _rotation,
        builder: (context, child) {
          return Transform.rotate(angle: _rotation.value, child: child);
        },
        child: widget.child,
      ),
    );
  }
}
