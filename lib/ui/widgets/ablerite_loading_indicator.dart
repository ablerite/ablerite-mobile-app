import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A calm, lightweight progress cue used throughout the app. The dot travels
/// forward while gently bouncing, so it remains clear at both small and
/// full-page sizes without the visual weight of a spinner.
class AbleriteLoadingIndicator extends StatefulWidget {
  final double size;
  final Color? color;

  /// Retained for backwards-compatible call sites.
  final double strokeWidth;

  const AbleriteLoadingIndicator({
    super.key,
    this.size = 40,
    this.color,
    this.strokeWidth = 2,
  });

  @override
  State<AbleriteLoadingIndicator> createState() =>
      _AbleriteLoadingIndicatorState();
}

class _AbleriteLoadingIndicatorState extends State<AbleriteLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1350),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.primary;
    return Semantics(
      label: 'Loading',
      child: SizedBox.square(
        dimension: widget.size,
        child: AnimatedBuilder(
          animation: _controller,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withAlpha(55),
                  blurRadius: widget.size * 0.16,
                  offset: Offset(0, widget.size * 0.07),
                ),
              ],
            ),
            child: SizedBox.square(dimension: widget.size * 0.3),
          ),
          builder: (context, child) {
            final progress = _controller.value;
            final bounce = math.sin(progress * math.pi * 2);
            return Center(
              child: Transform.translate(
                offset: Offset(
                  (progress - 0.5) * widget.size * 0.34,
                  -bounce * widget.size * 0.14,
                ),
                child: Transform.scale(
                  scale: 0.9 + ((bounce + 1) * 0.05),
                  child: child,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
