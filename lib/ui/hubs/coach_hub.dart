import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../action_center_guide_page.dart';
import '../calendar_page.dart';
import '../chat_page.dart';
import '../goals_page.dart';
import '../todo_page.dart';
import '../affirmations_page.dart';
import '../widgets/feature_card.dart';
import '../widgets/hub_intro_panel.dart';
import '../widgets/spotlight_walkthrough.dart';
import '../../services/subscription_service.dart';

class CoachHub extends StatelessWidget {
  final bool autoStartWalkthrough;

  const CoachHub({super.key, this.autoStartWalkthrough = false});

  @override
  Widget build(BuildContext context) {
    final goalsKey = GlobalKey();
    final taskListsKey = GlobalKey();
    final affirmationsKey = GlobalKey();
    final textCoachingKey = GlobalKey();
    final textCoachingShortcutKey = GlobalKey();
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
        : const Color(0xFF0D9488);
    final suiteAccent = usePastelGreens
        ? const Color(0xFFB7E4C7)
        : const Color(0xFF6366F1);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final cardHeight = hubFeatureCardHeightFor(constraints);
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    HubHeroSection(
                      title: 'Action Center',
                      tagline: 'Reach your potential',
                      infoBody:
                          'Use this space to define your goals, turn them into task lists, and stay accountable through coaching conversations and daily affirmation practice.',
                      imageAsset: 'assets/hub_headers/action_center.png',
                      darkImageAsset:
                          'assets/hub_headers/action_center_dark.png',
                      slateImageAsset:
                          'assets/hub_headers/action_center_slate.png',
                      childHeight: cardHeight,
                      autoStartWalkthrough: autoStartWalkthrough,
                      walkthroughId: 'action-center',
                      walkthroughBadgeAsset:
                          'assets/guide_images/pro_badge.png',
                      helpButtonKey: guideKey,
                      onOpenGuide: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ActionCenterGuidePage(),
                          ),
                        );
                      },
                      walkthroughSteps: [
                        SpotlightStep(
                          targetKey: goalsKey,
                          title: 'Goals',
                          body:
                              'Start here to define what you are working toward and track progress over time.',
                        ),
                        SpotlightStep(
                          targetKey: taskListsKey,
                          title: 'Task Lists',
                          body:
                              'Break goals into practical tasks and manage the next actions that move you forward.',
                        ),
                        SpotlightStep(
                          targetKey: affirmationsKey,
                          title: 'Affirmations',
                          body:
                              'Use affirmation sessions to reinforce identity, intention, and consistency.',
                        ),
                        SpotlightStep(
                          targetKey: textCoachingShortcutKey,
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
                          title: 'Action Center Guide',
                          body:
                              'Read the guide to Goals, Task Lists, Affirmations, Text Coaching, and the Calendar.',
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
                                      builder: (context) => const ChatPage(),
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
                        key: goalsKey,
                        height: cardHeight,
                        accessTier: AccessTier.pro,
                        title: 'Goals',
                        subtitle: 'Manage and achieve your goals',
                        icon: Icons.adjust,
                        color: suiteBase,
                        iconBadge: SuiteFeatureIcon(
                          primaryIcon: Icons.adjust,
                          secondaryIcon: Icons.flag,
                          baseColor: suiteBase,
                          accentColor: suiteAccent,
                        ),
                        onTap: () async {
                          if (await SubscriptionService().showPaywallIfNeeded(
                            context: context,
                          )) {
                            if (context.mounted) {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const GoalsPage(),
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ),

                    const SizedBox(height: hubFeatureCardGap),

                    FeatureCard(
                      key: taskListsKey,
                      height: cardHeight,
                      accessTier: AccessTier.pro,
                      title: 'Task Lists',
                      subtitle: 'View and manage your tasks',
                      icon: Icons.task_alt,
                      color: suiteBase,
                      iconBadge: SuiteFeatureIcon(
                        primaryIcon: Icons.task_alt,
                        secondaryIcon: Icons.timeline,
                        baseColor: suiteBase,
                        accentColor: suiteAccent,
                      ),
                      onTap: () async {
                        if (await SubscriptionService().showPaywallIfNeeded(
                          context: context,
                        )) {
                          if (context.mounted) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const TodoPage(),
                              ),
                            );
                          }
                        }
                      },
                    ),

                    const SizedBox(height: hubFeatureCardGap),

                    FeatureCard(
                      key: affirmationsKey,
                      height: cardHeight,
                      accessTier: AccessTier.pro,
                      title: 'Affirmations',
                      subtitle: 'Daily guided sessions',
                      icon: Icons.format_quote_rounded,
                      color: suiteBase,
                      iconBadge: SuiteFeatureIcon(
                        primaryIcon: Icons.format_quote_rounded,
                        secondaryIcon: Icons.repeat,
                        baseColor: suiteBase,
                        accentColor: suiteAccent,
                      ),
                      onTap: () async {
                        if (await SubscriptionService().showPaywallIfNeeded(
                          context: context,
                        )) {
                          if (context.mounted) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const AffirmationsPage(),
                              ),
                            );
                          }
                        }
                      },
                    ),

                    const SizedBox(height: hubFeatureCardGap),

                    FeatureCard(
                      key: textCoachingKey,
                      height: cardHeight,
                      accessTier: AccessTier.pro,
                      title: 'Text Coaching',
                      subtitle: 'Deep conversations and guidance',
                      icon: Icons.auto_awesome,
                      color: suiteBase,
                      iconBadge: SuiteFeatureIcon(
                        primaryIcon: Icons.auto_awesome,
                        secondaryIcon: Icons.psychology,
                        baseColor: suiteBase,
                        accentColor: suiteAccent,
                      ),
                      onTap: () async {
                        if (await SubscriptionService().showPaywallIfNeeded(
                          context: context,
                        )) {
                          if (context.mounted) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const ChatPage(),
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
            );
          },
        ),
      ),
    );
  }
}
