import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../calendar_page.dart';
import '../chat_page.dart';
import '../exploration_guide_page.dart';
import '../journal_page.dart';
import '../manifestation_page.dart';
import '../notebooks_page.dart';
import '../visualization_page.dart';
import '../widgets/feature_card.dart';
import '../widgets/hub_intro_panel.dart';
import '../widgets/spotlight_walkthrough.dart';
import '../../services/subscription_service.dart';

class ExplorationHub extends StatelessWidget {
  final bool autoStartWalkthrough;

  const ExplorationHub({super.key, this.autoStartWalkthrough = false});

  @override
  Widget build(BuildContext context) {
    final visualizationKey = GlobalKey();
    final manifestationKey = GlobalKey();
    final notebooksKey = GlobalKey();
    final journalsKey = GlobalKey();
    final textCoachingKey = GlobalKey();
    final calendarKey = GlobalKey();
    final guideKey = GlobalKey();
    final themeChoice = context.watch<SettingsProvider>().themeChoice;
    final toolbarColor = themeChoice == AppThemeChoice.slate
        ? Colors.white
        : Theme.of(context).colorScheme.primary;
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
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final cardHeight = hubFeatureCardHeightFor(constraints);
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        HubHeroSection(
                          title: 'Exploration',
                          tagline: 'Imagine, discover and reflect',
                          infoBody:
                              'Explore your visions, shape manifestation work, and capture ideas in notebooks. Use journals for reflection and gratitude. Uncover your true potential through continuous self-discovery.',
                          imageAsset: 'assets/hub_headers/exploration.png',
                          darkImageAsset:
                              'assets/hub_headers/exploration_dark.png',
                          slateImageAsset:
                              'assets/hub_headers/exploration_slate.png',
                          childHeight: cardHeight,
                          autoStartWalkthrough: autoStartWalkthrough,
                          walkthroughId: 'exploration',
                          walkthroughBadgeAsset:
                              'assets/guide_images/pro_badge.png',
                          helpButtonKey: guideKey,
                          onOpenGuide: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ExplorationGuidePage(),
                              ),
                            );
                          },
                          walkthroughSteps: [
                            SpotlightStep(
                              targetKey: visualizationKey,
                              title: 'Visualization',
                              body:
                                  'Open visual tools for vision boards and focused future-state practice.',
                            ),
                            SpotlightStep(
                              targetKey: manifestationKey,
                              title: 'Manifestation',
                              body:
                                  'Set intentions, track outcomes, and practice cosmic ordering work.',
                            ),
                            SpotlightStep(
                              targetKey: notebooksKey,
                              title: 'Notebooks',
                              body:
                                  'Use notebooks to capture ideas, plans, research, and personal notes.',
                            ),
                            SpotlightStep(
                              targetKey: journalsKey,
                              title: 'Journals',
                              body:
                                  'Reflect on your days, record gratitude, and notice patterns over time.',
                            ),
                            SpotlightStep(
                              targetKey: textCoachingKey,
                              title: 'Text Coaching',
                              body:
                                  'The sparkles icon is a Pro shortcut to coaching for reflection, planning, and accountability.',
                            ),
                            SpotlightStep(
                              targetKey: calendarKey,
                              title: 'Calendar',
                              body:
                                  'The calendar icon is a Pro shortcut to every dated goal and task, grouped by day.',
                            ),
                            SpotlightStep(
                              targetKey: guideKey,
                              title: 'Exploration Guide',
                              body:
                                  'Read the guide to Visualization, Manifestation, Notebooks, and Journals.',
                            ),
                          ],
                          headerAction: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                key: textCoachingKey,
                                icon: const Icon(Icons.auto_awesome),
                                color: toolbarColor,
                                tooltip: 'Text Coaching',
                                onPressed: () async {
                                  if (await SubscriptionService()
                                      .showPaywallIfNeeded(context: context)) {
                                    if (context.mounted) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const ChatPage(),
                                        ),
                                      );
                                    }
                                  }
                                },
                              ),
                              IconButton(
                                key: calendarKey,
                                icon: const Icon(Icons.calendar_month_outlined),
                                color: toolbarColor,
                                tooltip: 'Calendar',
                                onPressed: () async {
                                  if (await SubscriptionService()
                                      .showPaywallIfNeeded(context: context)) {
                                    if (context.mounted) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const CalendarPage(),
                                        ),
                                      );
                                    }
                                  }
                                },
                              ),
                            ],
                          ),
                          child: FeatureCard(
                            key: visualizationKey,
                            height: cardHeight,
                            accessTier: AccessTier.pro,
                            title: 'Visualization',
                            subtitle: 'Vision Board and Focus Vision',
                            icon: CupertinoIcons.eye,
                            color: suiteBase,
                            iconBadge: SuiteFeatureIcon(
                              primaryIcon: CupertinoIcons.eye,
                              secondaryIcon: Icons.center_focus_strong,
                              baseColor: suiteBase,
                              accentColor: suiteAccent,
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const VisualizationPage(),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: hubFeatureCardGap),
                        FeatureCard(
                          key: manifestationKey,
                          height: cardHeight,
                          accessTier: AccessTier.pro,
                          title: 'Manifestation',
                          subtitle: 'Expectations and cosmic ordering',
                          icon: Icons.rocket_launch_outlined,
                          color: suiteBase,
                          iconBadge: SuiteFeatureIcon(
                            primaryIcon: Icons.rocket_launch_outlined,
                            secondaryIcon: Icons.public,
                            baseColor: suiteBase,
                            accentColor: suiteAccent,
                          ),
                          onTap: () async {
                            if (await SubscriptionService().showPaywallIfNeeded(
                              context: context,
                            )) {
                              if (context.mounted) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const ManifestationPage(),
                                  ),
                                );
                              }
                            }
                          },
                        ),
                        const SizedBox(height: hubFeatureCardGap),
                        FeatureCard(
                          key: notebooksKey,
                          height: cardHeight,
                          accessTier: AccessTier.pro,
                          title: 'Notebooks',
                          subtitle: 'Capture ideas in notebooks',
                          icon: CupertinoIcons.folder,
                          color: suiteBase,
                          iconBadge: SuiteFeatureIcon(
                            primaryIcon: CupertinoIcons.folder,
                            secondaryIcon: Icons.edit_note,
                            baseColor: suiteBase,
                            accentColor: suiteAccent,
                          ),
                          onTap: () async {
                            if (await SubscriptionService().showPaywallIfNeeded(
                              context: context,
                            )) {
                              if (context.mounted) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const NotebooksPage(),
                                  ),
                                );
                              }
                            }
                          },
                        ),
                        const SizedBox(height: hubFeatureCardGap),
                        FeatureCard(
                          key: journalsKey,
                          height: cardHeight,
                          accessTier: AccessTier.pro,
                          title: 'Journals',
                          subtitle: 'Reflection and gratitude',
                          icon: CupertinoIcons.book,
                          color: suiteBase,
                          iconBadge: SuiteFeatureIcon(
                            primaryIcon: CupertinoIcons.book,
                            secondaryIcon: Icons.favorite,
                            baseColor: suiteBase,
                            accentColor: suiteAccent,
                          ),
                          onTap: () async {
                            if (await SubscriptionService().showPaywallIfNeeded(
                              context: context,
                            )) {
                              if (context.mounted) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const JournalPage(),
                                  ),
                                );
                              }
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
