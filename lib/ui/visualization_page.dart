import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'widgets/focus_app_bar_actions.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../services/subscription_service.dart';
import 'focus_vision_page.dart';
import 'vision_page.dart';
import 'widgets/hub_intro_panel.dart';
import 'widgets/tablet_layout.dart';

class VisualizationPage extends StatelessWidget {
  const VisualizationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChoice = context.watch<SettingsProvider>().themeChoice;
    final usePastelGreens =
        themeChoice == AppThemeChoice.lake ||
        themeChoice == AppThemeChoice.white;
    final suiteBase = usePastelGreens
        ? const Color(0xFF74C69D)
        : const Color(0xFF0F766E);
    final suiteAccent = usePastelGreens
        ? const Color(0xFFB7E4C7)
        : const Color(0xFF8B5CF6);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: const FocusAwareBackButton(),
        title: FocusAwareAppBarTitle(
          child: Text(
            'Visualization',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
        ),
        actions: const [FocusAppBarActions(guide: FocusHelpGuide.exploration)],
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = MediaQuery.sizeOf(context).height < 760;
            final landscapeTablet = isTabletLandscape(context);
            final visionBoardsCard = _VisualizationOptionCard(
              icon: CupertinoIcons.eye,
              title: 'Vision Boards',
              subtitle:
                  'Build and review visual anchors for the future you are creating.',
              bannerAsset: 'assets/images/visualization/visionboards.png',
              color: suiteBase,
              onTap: () async {
                if (await SubscriptionService().showPaywallIfNeeded(
                  context: context,
                )) {
                  if (context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const VisionPage(),
                      ),
                    );
                  }
                }
              },
            );
            final focusVisionCard = _VisualizationOptionCard(
              icon: Icons.center_focus_strong,
              title: 'Focus Vision',
              subtitle:
                  'A focused visualization app for future-state practice and mental rehearsal.',
              bannerAsset: 'assets/images/visualization/focusvision.png',
              color: suiteAccent,
              bannerScale: 1.08,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FocusVisionPage(),
                  ),
                );
              },
            );

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16, compact ? 4 : 8, 16, 12),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 16,
                ),
                child: IntrinsicHeight(
                  child: landscapeTablet
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              flex: 5,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(child: visionBoardsCard),
                                  const SizedBox(height: hubFeatureCardGap),
                                  Expanded(child: focusVisionCard),
                                ],
                              ),
                            ),
                            const SizedBox(width: hubFeatureCardGap),
                            Expanded(
                              flex: 4,
                              child: Align(
                                alignment: Alignment.topCenter,
                                child: HubLandscapeInfoPanel(
                                  icon: Icons.visibility_outlined,
                                  title: 'Make the future easier to see',
                                  body:
                                      'Visualization turns an abstract intention into something your mind can revisit. Use a broad board for the life you are building, then use Focus Vision to rehearse one clear outcome or state.',
                                  highlights: const [
                                    'Vision Boards hold the wider direction.',
                                    'Focus Vision rehearses the next believable scene.',
                                  ],
                                  accentColor: suiteBase,
                                ),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(child: visionBoardsCard),
                            const SizedBox(height: hubFeatureCardGap),
                            Expanded(child: focusVisionCard),
                          ],
                        ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _VisualizationOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String bannerAsset;
  final Color color;
  final double bannerScale;
  final VoidCallback onTap;

  const _VisualizationOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.bannerAsset,
    required this.color,
    this.bannerScale = 1,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withAlpha(46)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: AspectRatio(
                  aspectRatio: isTabletLandscape(context) ? 16 / 6.5 : 16 / 9,
                  child: ClipRect(
                    child: Transform.scale(
                      scale: bannerScale,
                      alignment: isTabletLandscape(context)
                          ? Alignment.topCenter
                          : Alignment.center,
                      child: Image.asset(
                        bannerAsset,
                        fit: BoxFit.cover,
                        alignment: isTabletLandscape(context)
                            ? Alignment.topCenter
                            : Alignment.center,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: color.withAlpha(24),
                            child: Icon(icon, color: color, size: 36),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            color: colorScheme.onSurface.withAlpha(110),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: colorScheme.onSurface.withAlpha(150),
                          height: 1.28,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
