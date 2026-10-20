import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SpotlightStep {
  final GlobalKey targetKey;
  final String title;
  final String body;
  final String? badgeAsset;

  const SpotlightStep({
    required this.targetKey,
    required this.title,
    required this.body,
    this.badgeAsset,
  });

  SpotlightStep copyWith({String? badgeAsset}) => SpotlightStep(
    targetKey: targetKey,
    title: title,
    body: body,
    badgeAsset: badgeAsset ?? this.badgeAsset,
  );
}

class SpotlightWalkthrough {
  static final Set<OverlayEntry> _activeEntries = <OverlayEntry>{};

  static void dismissAll() {
    final entries = List<OverlayEntry>.of(_activeEntries);
    _activeEntries.clear();
    for (final entry in entries) {
      if (entry.mounted) entry.remove();
    }
  }

  static Future<void> show(
    BuildContext context, {
    required List<SpotlightStep> steps,
    String? badgeAsset,
    bool translucent = false,
    bool scrollTargetsIntoView = true,
  }) async {
    if (steps.isEmpty) return;

    dismissAll();

    final overlay = Overlay.of(context, rootOverlay: true);
    late OverlayEntry entry;

    void close() {
      _activeEntries.remove(entry);
      if (entry.mounted) entry.remove();
    }

    entry = OverlayEntry(
      builder: (context) {
        return _SpotlightWalkthroughOverlay(
          steps: badgeAsset == null
              ? steps
              : steps
                    .map(
                      (step) => step.badgeAsset == null
                          ? step.copyWith(badgeAsset: badgeAsset)
                          : step,
                    )
                    .toList(),
          onClose: close,
          translucent: translucent,
          scrollTargetsIntoView: scrollTargetsIntoView,
        );
      },
    );

    _activeEntries.add(entry);
    overlay.insert(entry);
  }
}

class _SpotlightWalkthroughOverlay extends StatefulWidget {
  final List<SpotlightStep> steps;
  final VoidCallback onClose;
  final bool translucent;
  final bool scrollTargetsIntoView;

  const _SpotlightWalkthroughOverlay({
    required this.steps,
    required this.onClose,
    required this.translucent,
    required this.scrollTargetsIntoView,
  });

  @override
  State<_SpotlightWalkthroughOverlay> createState() =>
      _SpotlightWalkthroughOverlayState();
}

class _SpotlightWalkthroughOverlayState
    extends State<_SpotlightWalkthroughOverlay> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _scrollToCurrentTarget();
  }

  SpotlightStep get _step => widget.steps[_index];

  Rect? _targetRect() {
    final context = _step.targetKey.currentContext;
    if (context == null) return null;

    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return null;

    final offset = renderObject.localToGlobal(Offset.zero);
    return offset & renderObject.size;
  }

  void _scrollToCurrentTarget() {
    if (!widget.scrollTargetsIntoView) return;
    final targetKey = _step.targetKey;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || targetKey != _step.targetKey) return;
      final targetContext = targetKey.currentContext;
      if (targetContext == null) return;

      // Most walkthrough targets are already visible. Centering every target
      // caused the Financial Overview cards to jump underneath a spotlight
      // that was still painted at their old position.
      final renderObject = targetContext.findRenderObject();
      if (renderObject is RenderBox && renderObject.hasSize) {
        final targetRect =
            renderObject.localToGlobal(Offset.zero) & renderObject.size;
        final mediaQuery = MediaQuery.of(context);
        final visibleLeft = mediaQuery.padding.left;
        final visibleTop = mediaQuery.padding.top;
        final visibleRight = mediaQuery.size.width - mediaQuery.padding.right;
        final visibleBottom =
            mediaQuery.size.height - mediaQuery.padding.bottom;
        if (targetRect.left >= visibleLeft &&
            targetRect.top >= visibleTop &&
            targetRect.right <= visibleRight &&
            targetRect.bottom <= visibleBottom) {
          if (mounted) setState(() {});
          return;
        }
      }

      final scrollable = Scrollable.maybeOf(targetContext);
      void repaintWhileScrolling() {
        if (mounted && targetKey == _step.targetKey) setState(() {});
      }

      scrollable?.position.addListener(repaintWhileScrolling);
      try {
        await Scrollable.ensureVisible(
          targetContext,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          alignment: 0.5,
        );
      } finally {
        scrollable?.position.removeListener(repaintWhileScrolling);
      }
      if (mounted) setState(() {});
    });
  }

  void _moveTo(int index) {
    if (index < 0 || index >= widget.steps.length) return;
    setState(() => _index = index);
    _scrollToCurrentTarget();
  }

  @override
  Widget build(BuildContext context) {
    final targetRect = _targetRect();
    final screenSize = MediaQuery.of(context).size;
    final safePadding = MediaQuery.of(context).padding;

    double cardTop;
    if (targetRect != null) {
      final isBottomHalf = targetRect.center.dy > screenSize.height * 0.5;
      if (isBottomHalf) {
        cardTop = (targetRect.top - 210).clamp(
          safePadding.top + 16,
          screenSize.height - 240,
        );
      } else {
        cardTop = (targetRect.bottom + 20).clamp(
          safePadding.top + 16,
          screenSize.height - 240,
        );
      }
    } else {
      cardTop = safePadding.top + 80;
    }

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _SpotlightPainter(
                targetRect: targetRect,
                overlayColor: Colors.black.withAlpha(
                  widget.translucent ? 145 : 185,
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {},
            ),
          ),
          Positioned(
            top: cardTop.toDouble(),
            left: 20,
            right: 20,
            child: _WalkthroughCard(
              step: _step,
              currentStep: _index + 1,
              totalSteps: widget.steps.length,
              onBack: _index == 0 ? null : () => _moveTo(_index - 1),
              onNext: _index == widget.steps.length - 1
                  ? widget.onClose
                  : () => _moveTo(_index + 1),
              onClose: widget.onClose,
              translucent: widget.translucent,
            ),
          ),
        ],
      ),
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  final Rect? targetRect;
  final Color overlayColor;

  const _SpotlightPainter({
    required this.targetRect,
    required this.overlayColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final overlayPath = Path()..addRect(Offset.zero & size);
    final target = targetRect;

    if (target != null) {
      final spotlight = RRect.fromRectAndRadius(
        target.inflate(12),
        const Radius.circular(22),
      );
      overlayPath.addRRect(spotlight);
      overlayPath.fillType = PathFillType.evenOdd;
    }

    canvas.drawPath(overlayPath, Paint()..color = overlayColor);

    if (target != null) {
      final borderPaint = Paint()
        ..color = Colors.white.withAlpha(220)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawRRect(
        RRect.fromRectAndRadius(target.inflate(12), const Radius.circular(22)),
        borderPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter oldDelegate) {
    return oldDelegate.targetRect != targetRect ||
        oldDelegate.overlayColor != overlayColor;
  }
}

class _WalkthroughCard extends StatelessWidget {
  final SpotlightStep step;
  final int currentStep;
  final int totalSteps;
  final VoidCallback? onBack;
  final VoidCallback onNext;
  final VoidCallback onClose;
  final bool translucent;

  const _WalkthroughCard({
    required this.step,
    required this.currentStep,
    required this.totalSteps,
    required this.onBack,
    required this.onNext,
    required this.onClose,
    required this.translucent,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final card = Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: translucent
            ? colorScheme.surface.withAlpha(190)
            : colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).dividerColor.withAlpha(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(55),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          step.title,
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        if (step.badgeAsset != null) ...[
                          const SizedBox(width: 6),
                          Image.asset(
                            step.badgeAsset!,
                            width: 44,
                            height: 21,
                            fit: BoxFit.contain,
                            semanticLabel: 'Feature access badge',
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close),
                color: colorScheme.onSurface.withAlpha(150),
                tooltip: 'Close walkthrough',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 40,
                  height: 40,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            step.body,
            style: GoogleFonts.outfit(
              fontSize: 14,
              height: 1.4,
              color: colorScheme.onSurface.withAlpha(180),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Text(
                '$currentStep of $totalSteps',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: colorScheme.onSurface.withAlpha(130),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              TextButton(onPressed: onBack, child: const Text('Back')),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: onNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                ),
                child: Text(currentStep == totalSteps ? 'Done' : 'Next'),
              ),
            ],
          ),
        ],
      ),
    );

    if (!translucent) return card;
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: card,
      ),
    );
  }
}
