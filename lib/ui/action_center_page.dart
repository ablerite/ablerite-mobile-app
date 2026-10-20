import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import 'learn_page.dart';
import 'self_development_guide_page.dart';
import 'train_page.dart';
import 'insights_page.dart';
import 'calendar_page.dart';
import 'chat_page.dart';
import '../services/subscription_service.dart';
import 'widgets/feature_card.dart';
import 'widgets/hub_intro_panel.dart';
import 'widgets/spotlight_walkthrough.dart';
import 'widgets/tablet_layout.dart';

class ActionCenterPage extends StatelessWidget {
  final bool autoStartWalkthrough;

  const ActionCenterPage({super.key, this.autoStartWalkthrough = false});

  @override
  Widget build(BuildContext context) {
    final brainTrainingKey = GlobalKey();
    final knowledgeKey = GlobalKey();
    final selfHelpKey = GlobalKey();
    final insightsKey = GlobalKey();
    final guideKey = GlobalKey();
    final textCoachingShortcutKey = GlobalKey();
    final calendarKey = GlobalKey();
    final themeChoice = context.watch<SettingsProvider>().themeChoice;
    final toolbarColor = themeChoice == AppThemeChoice.slate
        ? Colors.white
        : Theme.of(context).colorScheme.primary;
    final usePastelGreens =
        themeChoice == AppThemeChoice.lake ||
        themeChoice == AppThemeChoice.white;
    final suiteBase = usePastelGreens
        ? const Color(0xFF52B788)
        : const Color(0xFF4F46E5);
    final suiteAccent = usePastelGreens
        ? const Color(0xFF95D5B2)
        : const Color(0xFF06B6D4);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final cardHeight = hubFeatureCardHeightFor(constraints);
            final isTablet = isTabletLayout(context);
            return SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isTablet ? 1040 : double.infinity,
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 28 : 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        HubHeroSection(
                          title: 'Media',
                          tagline: 'Learn for free, train and explore.',
                          infoBody:
                              'Your Media space brings together focus training, knowledge, critical learning, and key insights for practical growth.',
                          imageAsset: 'assets/hub_headers/self_development.png',
                          darkImageAsset:
                              'assets/hub_headers/self_development_dark.png',
                          slateImageAsset:
                              'assets/hub_headers/self_development_slate.png',
                          childHeight: cardHeight,
                          autoStartWalkthrough: autoStartWalkthrough,
                          walkthroughId: 'self-development',
                          walkthroughBadgeAsset:
                              'assets/guide_images/free_badge.png',
                          helpButtonKey: guideKey,
                          onOpenGuide: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const SelfDevelopmentGuidePage(),
                              ),
                            );
                          },
                          walkthroughSteps: [
                            SpotlightStep(
                              targetKey: brainTrainingKey,
                              title: 'Brain Training',
                              body:
                                  'Use this to practise focus, memory, and mental sharpness through short training games.',
                            ),
                            SpotlightStep(
                              targetKey: knowledgeKey,
                              title: 'Knowledge',
                              body:
                                  'Explore articles, media, and guides on goals, habits, mindset, and personal development.',
                            ),
                            SpotlightStep(
                              targetKey: selfHelpKey,
                              title: 'Critical Learning',
                              body:
                                  'Access specialized audio and video modules focused on core personal growth topics.',
                            ),
                            SpotlightStep(
                              targetKey: insightsKey,
                              title: 'Key Insights',
                              body:
                                  'Visit this for concise prompts and perspective shifts when you need a quick reset.',
                            ),
                            SpotlightStep(
                              targetKey: textCoachingShortcutKey,
                              title: 'Text Coaching',
                              body:
                                  'The sparkles icon is a Pro shortcut to coaching for reflection, planning, and accountability.',
                              badgeAsset: 'assets/guide_images/pro_badge.png',
                            ),
                            SpotlightStep(
                              targetKey: calendarKey,
                              title: 'Calendar',
                              body:
                                  'The calendar icon is a Pro shortcut to every dated goal and task, grouped by day.',
                              badgeAsset: 'assets/guide_images/pro_badge.png',
                            ),
                            SpotlightStep(
                              targetKey: guideKey,
                              title: 'Media Guide',
                              body:
                                  'Read the guide to Brain Training, Knowledge, Critical Learning, Key Insights, and the Pro shortcuts.',
                            ),
                          ],
                          headerAction: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                key: textCoachingShortcutKey,
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
                            key: brainTrainingKey,
                            height: cardHeight,
                            accessTier: AccessTier.free,
                            title: 'Brain Training',
                            subtitle: 'Train your mental focus',
                            icon: Icons.psychology,
                            color: suiteBase,
                            iconBadge: SuiteFeatureIcon(
                              primaryIcon: Icons.psychology_alt,
                              secondaryIcon: Icons.bolt,
                              baseColor: suiteBase,
                              accentColor: suiteAccent,
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const TrainPage(),
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: hubFeatureCardGap),

                        // Knowledge Card
                        FeatureCard(
                          key: knowledgeKey,
                          height: cardHeight,
                          accessTier: AccessTier.free,
                          title: 'Knowledge',
                          subtitle: 'Master your self',
                          icon: Icons.school,
                          color: suiteBase,
                          iconBadge: SuiteFeatureIcon(
                            primaryIcon: Icons.school,
                            secondaryIcon: Icons.trending_up,
                            baseColor: suiteBase,
                            accentColor: suiteAccent,
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LearnPage(),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: hubFeatureCardGap),

                        // Critical Learning Card
                        FeatureCard(
                          key: selfHelpKey,
                          height: cardHeight,
                          accessTier: AccessTier.free,
                          title: 'Critical Learning',
                          subtitle: 'Goals, habits & mindset',
                          icon: Icons.adjust,
                          color: suiteBase,
                          iconBadge: SuiteFeatureIcon(
                            primaryIcon: Icons.adjust,
                            secondaryIcon: Icons.school,
                            baseColor: suiteBase,
                            accentColor: suiteAccent,
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LearnPage(
                                  initialView: 'criticalHome',
                                ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: hubFeatureCardGap),

                        // Key Insights Card
                        FeatureCard(
                          key: insightsKey,
                          height: cardHeight,
                          accessTier: AccessTier.free,
                          title: 'Key Insights',
                          subtitle: 'Inspirational quotes for all life areas',
                          icon: CupertinoIcons.lightbulb_fill,
                          color: suiteBase,
                          iconBadge: SuiteFeatureIcon(
                            primaryIcon: CupertinoIcons.lightbulb_fill,
                            secondaryIcon: Icons.auto_awesome,
                            baseColor: suiteBase,
                            accentColor: suiteAccent,
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const InsightsPage(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
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
