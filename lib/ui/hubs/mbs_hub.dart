import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/settings_provider.dart';
import '../calendar_page.dart';
import '../chat_page.dart';
import '../mbs_pages.dart';
import '../mbs_overview_page.dart';
import '../mbs_guide_page.dart';
import '../widgets/feature_card.dart';
import '../widgets/hub_intro_panel.dart';
import '../widgets/spotlight_walkthrough.dart';
import '../../services/subscription_service.dart';
import '../../services/notification_service.dart';

class MBSHub extends StatefulWidget {
  final bool autoStartWalkthrough;

  const MBSHub({super.key, this.autoStartWalkthrough = false});

  @override
  State<MBSHub> createState() => _MBSHubState();
}

class _MBSHubState extends State<MBSHub> {
  @override
  void initState() {
    super.initState();
    _reconcileWellnessReminders();
  }

  Future<void> _reconcileWellnessReminders() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await NotificationService().reconcileWellnessReminders(userId);
    } catch (e) {
      debugPrint('Could not restore Wellness reminders: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final overviewKey = GlobalKey();
    final textCoachingKey = GlobalKey();
    final calendarKey = GlobalKey();
    final guideKey = GlobalKey();
    final mindKey = GlobalKey();
    final bodyKey = GlobalKey();
    final spiritKey = GlobalKey();
    final themeChoice = context.watch<SettingsProvider>().themeChoice;
    final toolbarColor = themeChoice == AppThemeChoice.slate
        ? Colors.white
        : Theme.of(context).colorScheme.primary;
    final usePastelGreens =
        themeChoice == AppThemeChoice.lake ||
        themeChoice == AppThemeChoice.white;
    final suiteBase = usePastelGreens
        ? const Color(0xFF57CC99)
        : const Color(0xFF0EA5E9);
    final suiteAccent = usePastelGreens
        ? const Color(0xFFC7F9CC)
        : const Color(0xFF10B981);

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
                          title: 'Wellness',
                          tagline: 'Mind, Body, Spirit.',
                          infoBody:
                              'The Wellness section is dedicated to your holistic well-being. Regular practice across Mind, Body, and Spirit ensures balanced growth and a deeper connection to your wellbeing.',
                          imageAsset: 'assets/hub_headers/mbs.png',
                          darkImageAsset: 'assets/hub_headers/mbs_dark.png',
                          slateImageAsset: 'assets/hub_headers/mbs_slate.png',
                          childHeight: cardHeight,
                          autoStartWalkthrough: widget.autoStartWalkthrough,
                          walkthroughId: 'mbs',
                          walkthroughBadgeAsset:
                              'assets/guide_images/pro_badge.png',
                          helpButtonKey: guideKey,
                          onOpenGuide: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MBSGuidePage(),
                              ),
                            );
                          },
                          walkthroughSteps: [
                            SpotlightStep(
                              targetKey: overviewKey,
                              title: 'Metrics',
                              body:
                                  'See your holistic wellbeing activity across mind, body, and spirit in one place.',
                            ),
                            SpotlightStep(
                              targetKey: mindKey,
                              title: 'Mind Practice',
                              body:
                                  'Use this for meditation, mindfulness, and mental clarity practices.',
                            ),
                            SpotlightStep(
                              targetKey: bodyKey,
                              title: 'Body Training',
                              body:
                                  'Track physical fitness, body care, and health-related practice.',
                            ),
                            SpotlightStep(
                              targetKey: spiritKey,
                              title: 'Spirit Development',
                              body:
                                  'Log practices that build meaning, peace, connection, and inner alignment.',
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
                              title: 'Wellness Guide',
                              body:
                                  'Read the guide to Mind, Body, and Spirit, and why logging by hand keeps you focused and balanced.',
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
                            key: overviewKey,
                            height: cardHeight,
                            accessTier: AccessTier.pro,
                            title: 'Metrics',
                            subtitle: 'Track your holistic activities log',
                            icon: Icons.query_stats_rounded,
                            color: suiteBase,
                            iconBadge: SuiteFeatureIcon(
                              primaryIcon: Icons.query_stats_rounded,
                              secondaryIcon: Icons.all_inclusive,
                              baseColor: suiteBase,
                              accentColor: suiteAccent,
                            ),
                            onTap: () async {
                              if (await SubscriptionService()
                                  .showPaywallIfNeeded(context: context)) {
                                if (context.mounted) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const MBSOverviewPage(),
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: hubFeatureCardGap),
                        FeatureCard(
                          key: mindKey,
                          height: cardHeight,
                          accessTier: AccessTier.pro,
                          title: 'Mind Practice',
                          subtitle: 'Meditation and mindfulness',
                          icon: Icons.self_improvement,
                          color: suiteBase,
                          iconBadge: SuiteFeatureIcon(
                            primaryIcon: Icons.self_improvement,
                            secondaryIcon: Icons.spa,
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
                                    builder: (context) => MBSPage(
                                      title: 'Mind Practice',
                                      section: 'meditation_logs',
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      icon: Icons.self_improvement,
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                        ),
                        const SizedBox(height: hubFeatureCardGap),
                        FeatureCard(
                          key: bodyKey,
                          height: cardHeight,
                          accessTier: AccessTier.pro,
                          title: 'Body Training',
                          subtitle: 'Physical fitness and health',
                          icon: CupertinoIcons.heart,
                          color: suiteBase,
                          iconBadge: SuiteFeatureIcon(
                            primaryIcon: CupertinoIcons.heart,
                            secondaryIcon: Icons.fitness_center,
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
                                    builder: (context) => MBSPage(
                                      title: 'Body Training',
                                      section: 'body_logs',
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      icon: CupertinoIcons.heart,
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                        ),
                        const SizedBox(height: hubFeatureCardGap),
                        FeatureCard(
                          key: spiritKey,
                          height: cardHeight,
                          accessTier: AccessTier.pro,
                          title: 'Spirit Development',
                          subtitle: 'Internal growth and peace',
                          icon: CupertinoIcons.sparkles,
                          color: suiteBase,
                          iconBadge: SuiteFeatureIcon(
                            primaryIcon: CupertinoIcons.sparkles,
                            secondaryIcon: Icons.nights_stay,
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
                                    builder: (context) => MBSPage(
                                      title: 'Spirit Development',
                                      section: 'spirit_logs',
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      icon: CupertinoIcons.sparkles,
                                    ),
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
