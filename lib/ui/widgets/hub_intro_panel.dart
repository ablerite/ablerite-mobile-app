import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/navigation_service.dart';
import '../settings_page.dart';
import 'auto_walkthrough.dart';
import 'screen_help_menu.dart';
import 'spotlight_walkthrough.dart';
import 'tablet_layout.dart';

const double hubFeatureCardGap = 12;

class HubLandscapeInfoPanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final List<String> highlights;
  final Color? accentColor;

  const HubLandscapeInfoPanel({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    required this.highlights,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = accentColor ?? colorScheme.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withAlpha(62),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withAlpha(52)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accent.withAlpha(22), colorScheme.surface.withAlpha(235)],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: accent.withAlpha(28),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accent, size: 26),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 24,
              height: 1.08,
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            body,
            style: GoogleFonts.outfit(
              fontSize: 14,
              height: 1.45,
              color: colorScheme.onSurface.withAlpha(175),
            ),
          ),
          const SizedBox(height: 20),
          for (final highlight in highlights) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Icon(
                    Icons.check_circle_outline,
                    color: accent,
                    size: 17,
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    highlight,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface.withAlpha(190),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

double hubFeatureCardHeightFor(BoxConstraints constraints) {
  const heroBaseHeight = 226.0;
  const cardCount = 4;
  const bottomPadding = 12.0;
  final availableHeight =
      constraints.maxHeight -
      heroBaseHeight -
      (hubFeatureCardGap * (cardCount - 1)) -
      bottomPadding;
  return (availableHeight / cardCount).clamp(104.0, 144.0);
}

class HubHeroSection extends StatelessWidget {
  final String title;
  final String tagline;
  final String infoBody;
  final String imageAsset;
  final String darkImageAsset;
  final String? slateImageAsset;
  final List<SpotlightStep> walkthroughSteps;
  final Widget child;
  final double childHeight;
  final bool autoStartWalkthrough;
  final String? walkthroughId;
  final String? walkthroughBadgeAsset;
  final Widget? headerAction;
  final VoidCallback? onOpenGuide;
  final Key? helpButtonKey;

  const HubHeroSection({
    super.key,
    required this.title,
    required this.tagline,
    required this.infoBody,
    required this.imageAsset,
    required this.darkImageAsset,
    this.slateImageAsset,
    this.walkthroughSteps = const [],
    required this.child,
    this.childHeight = 96,
    this.autoStartWalkthrough = false,
    this.walkthroughId,
    this.walkthroughBadgeAsset,
    this.headerAction,
    this.onOpenGuide,
    this.helpButtonKey,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final settings = context.watch<SettingsProvider>();
    final toolbarColor = settings.themeChoice == AppThemeChoice.slate
        ? Colors.white
        : colorScheme.primary;
    final heroImageAsset = settings.themeChoice == AppThemeChoice.slate
        ? (slateImageAsset ?? darkImageAsset)
        : Theme.of(context).brightness == Brightness.dark
        ? darkImageAsset
        : imageAsset;
    if (autoStartWalkthrough && walkthroughId != null) {
      AutoWalkthrough.maybeShowOnce(
        context,
        id: walkthroughId!,
        steps: walkthroughSteps,
        badgeAsset: walkthroughBadgeAsset,
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: SizedBox(
        height: 204 + childHeight,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: 0,
              left: -16,
              right: -16,
              height: 278,
              child: ShaderMask(
                shaderCallback: (bounds) {
                  return LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withAlpha(220),
                      Colors.white,
                      Colors.white,
                      Colors.white.withAlpha(0),
                    ],
                    stops: const [0.0, 0.32, 0.82, 1.0],
                  ).createShader(bounds);
                },
                blendMode: BlendMode.dstIn,
                child: Image.asset(
                  heroImageAsset,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                ),
              ),
            ),
            Positioned(
              // Match the standard AppBar geometry used by Financial
              // Overview. Hub pages sit inside 16px body padding, so extend
              // the toolbar back to the screen edges and use 48px action
              // slots throughout.
              top: -4,
              left: -16,
              right: -16,
              child: Row(
                children: [
                  const SizedBox(
                    width: 84,
                    child: Padding(
                      padding: EdgeInsets.only(left: 16),
                      child: _HubClock(),
                    ),
                  ),
                  const Spacer(),
                  if (headerAction != null)
                    IconButtonTheme(
                      data: IconButtonThemeData(
                        style: ButtonStyle(
                          minimumSize: const WidgetStatePropertyAll(
                            Size(48, 48),
                          ),
                          fixedSize: const WidgetStatePropertyAll(Size(48, 48)),
                          padding: const WidgetStatePropertyAll(
                            EdgeInsets.all(8),
                          ),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                      child: headerAction!,
                    ),
                  IconButton(
                    key: helpButtonKey,
                    icon: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: colorScheme.surface.withAlpha(220),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: toolbarColor.withAlpha(210),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(70),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        CupertinoIcons.question,
                        color: toolbarColor,
                        size: 14,
                      ),
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 48,
                      height: 48,
                    ),
                    tooltip: '$title help',
                    onPressed: () {
                      if (onOpenGuide == null) {
                        _showInfoSheet(context);
                        return;
                      }

                      showScreenHelpMenu(
                        context: context,
                        screenName: title,
                        onOpenGuide: onOpenGuide!,
                        onStartWalkthrough: () => SpotlightWalkthrough.show(
                          context,
                          steps: walkthroughSteps,
                          badgeAsset: walkthroughBadgeAsset,
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings),
                    color: toolbarColor,
                    tooltip: 'Settings',
                    constraints: const BoxConstraints.tightFor(
                      width: 48,
                      height: 48,
                    ),
                    padding: const EdgeInsets.all(8),
                    onPressed: () async {
                      final target = await Navigator.push<PreferredHomeTarget>(
                        context,
                        PageRouteBuilder<PreferredHomeTarget>(
                          transitionDuration: Duration.zero,
                          reverseTransitionDuration: Duration.zero,
                          pageBuilder: (_, _, _) => const SettingsPage(),
                        ),
                      );
                      if (target != null) requestPreferredHome(target);
                    },
                  ),
                ],
              ),
            ),
            Positioned(
              top: 52,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 88,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Text(
                  tagline,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    color: colorScheme.onSurface.withAlpha(150),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 204,
              child: SizedBox(height: childHeight, child: child),
            ),
          ],
        ),
      ),
    );
  }

  void _showInfoSheet(BuildContext context) {
    final isTablet = isTabletLayout(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;

        final content = SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withAlpha(24),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        CupertinoIcons.info_circle,
                        color: colorScheme.primary,
                        size: 21,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  infoBody,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    height: 1.45,
                    color: colorScheme.onSurface.withAlpha(190),
                  ),
                ),
              ],
            ),
          ),
        );
        if (!isTablet) return content;
        return Align(
          alignment: Alignment.bottomCenter,
          child: SizedBox(
            width: tabletPopupWidth(context, portrait: 640, landscape: 760),
            child: content,
          ),
        );
      },
    );
  }
}

class _HubClock extends StatefulWidget {
  const _HubClock();

  @override
  State<_HubClock> createState() => _HubClockState();
}

class _HubClockState extends State<_HubClock> {
  DateTime _now = DateTime.now();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      DateFormat('h:mm a').format(_now),
      maxLines: 1,
      style: GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurface.withAlpha(180),
      ),
    );
  }
}
