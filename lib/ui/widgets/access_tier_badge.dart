import 'package:flutter/material.dart';

enum AccessTier { free, pro }

/// A deliberately quiet access label for app-list cards.
class AccessTierBadge extends StatelessWidget {
  const AccessTierBadge({
    super.key,
    required this.tier,
    this.prominent = false,
    this.onIcon = false,
  });

  final AccessTier tier;
  final bool prominent;
  final bool onIcon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final foreground = switch (tier) {
      AccessTier.free => scheme.primary,
      AccessTier.pro =>
        isDark ? const Color(0xFFFFD166) : const Color(0xFF8B6508),
    };
    final label = switch (tier) {
      AccessTier.free => 'Free',
      AccessTier.pro => 'Pro',
    };

    return ExcludeSemantics(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: prominent ? 9 : 4,
          vertical: prominent ? 4 : 1,
        ),
        decoration: BoxDecoration(
          color: onIcon
              ? scheme.surface.withAlpha(245)
              : foreground.withAlpha(isDark ? 28 : 18),
          borderRadius: BorderRadius.circular(prominent ? 8 : 5),
          border: Border.all(
            color: foreground.withAlpha(onIcon ? 105 : (isDark ? 80 : 58)),
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          style: TextStyle(
            color: foreground,
            fontSize: prominent ? 11 : 8,
            height: 1.15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
        ),
      ),
    );
  }
}
