import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/subscription_service.dart';
import 'access_tier_badge.dart';

export 'access_tier_badge.dart' show AccessTier;

class FeatureCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final double? height;
  final Widget? iconBadge;
  final AccessTier? accessTier;
  final ValueListenable<bool>? proStatusListenable;

  const FeatureCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    this.height,
    this.iconBadge,
    this.accessTier,
    this.proStatusListenable,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 96),
        child: Container(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).dividerColor.withAlpha(20),
            ),
          ),
          child: Row(
            children: [
              _buildLeadingIcon(context),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle!,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withAlpha(150),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Theme.of(context).colorScheme.primary,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeadingIcon(BuildContext context) {
    final iconWidget =
        iconBadge ??
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withAlpha((0.15 * 255).toInt()),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 28),
        );
    final tier = accessTier;
    if (tier == null) return iconWidget;

    return ValueListenableBuilder<bool>(
      valueListenable: proStatusListenable ?? SubscriptionService().proStatus,
      builder: (context, isPro, child) {
        final tierLabel = tier == AccessTier.free ? 'Free' : 'Pro';
        return SizedBox(
          width: 58,
          height: 58,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(child: Center(child: child!)),
              if (!isPro)
                Positioned(
                  top: 2,
                  right: -3,
                  child: Semantics(
                    label: '$tierLabel access',
                    child: AccessTierBadge(tier: tier, onIcon: true),
                  ),
                ),
            ],
          ),
        );
      },
      child: iconWidget,
    );
  }
}

class SuiteFeatureIcon extends StatelessWidget {
  final IconData primaryIcon;
  final IconData secondaryIcon;
  final Color baseColor;
  final Color accentColor;

  const SuiteFeatureIcon({
    super.key,
    required this.primaryIcon,
    required this.secondaryIcon,
    required this.baseColor,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 58,
      height: 58,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [baseColor, accentColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: baseColor.withAlpha(50),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Icon(primaryIcon, color: Colors.white, size: 30),
            ),
          ),
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                shape: BoxShape.circle,
                border: Border.all(color: accentColor.withAlpha(120)),
              ),
              child: Center(
                child: Icon(secondaryIcon, color: accentColor, size: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
