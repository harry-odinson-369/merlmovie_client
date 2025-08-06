import 'package:flutter/material.dart';

class FadeSwitchOnBool extends StatefulWidget {
  final bool showSecond;
  final Widget first;
  final Widget second;
  const FadeSwitchOnBool({
    super.key,
    required this.showSecond,
    required this.first,
    required this.second,
  });

  @override
  State<FadeSwitchOnBool> createState() => _FadeSwitchOnBoolState();
}

class _FadeSwitchOnBoolState extends State<FadeSwitchOnBool> {
  double _opacity = 1.0;
  bool _showFirstWidget = true;
  bool _transitioning = false;

  @override
  void didUpdateWidget(covariant FadeSwitchOnBool oldWidget) {
    super.didUpdateWidget(oldWidget);

    // When boolean changes, trigger transition
    if (oldWidget.showSecond != widget.showSecond) {
      _startTransition();
    }
  }

  void _startTransition() async {
    if (_transitioning) return;
    _transitioning = true;

    // Step 1: Fade out current
    setState(() {
      _opacity = 0.0;
    });

    await Future.delayed(const Duration(milliseconds: 300));

    // Step 2: Switch widget
    setState(() {
      _showFirstWidget = !widget.showSecond;
    });

    // Step 3: Fade in new widget
    setState(() {
      _opacity = 1.0;
    });

    await Future.delayed(const Duration(milliseconds: 300));
    _transitioning = false;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _opacity,
      duration: const Duration(milliseconds: 300),
      child: _showFirstWidget ? widget.first : widget.second,
    );
  }
}
