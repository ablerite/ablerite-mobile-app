import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'widgets/ablerite_loading_indicator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/subscription_service.dart';
import 'widgets/tablet_layout.dart';

class OnboardingPage extends StatefulWidget {
  final VoidCallback onComplete;
  final VoidCallback onSkip;

  const OnboardingPage({
    super.key,
    required this.onComplete,
    required this.onSkip,
  });

  static const String storageKey = 'pre_auth_onboarding_complete_v2';
  static const String progressStorageKey = 'pre_auth_onboarding_progress_v2';
  static const String painPointStorageKey = 'pre_auth_onboarding_pain_point_v2';

  static Future<bool> isComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(storageKey) ?? false;
  }

  static Future<void> markComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(storageKey, true);
  }

  static Future<void> restart() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(storageKey, false);
    await prefs.remove(progressStorageKey);
    await prefs.remove(painPointStorageKey);
  }

  static Future<void> saveProgress(int pageIndex) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(progressStorageKey, pageIndex);
  }

  static Future<void> savePainPoint(String painPoint) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(painPointStorageKey, painPoint);
  }

  static Future<void> clearProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(progressStorageKey);
    await prefs.remove(painPointStorageKey);
  }

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  PageController? _pageController;
  String? _selectedPainPoint;
  int _pageIndex = 0;
  bool _progressLoaded = false;
  bool _isSaving = false;

  static const List<_PainPoint> _painPoints = [
    _PainPoint(
      title: 'Health',
      icon: Icons.favorite_border,
      summary:
          'Use guided lessons, habits, and simple action steps to build a healthier rhythm without overwhelm.',
    ),
    _PainPoint(
      title: 'Wealth',
      icon: Icons.account_balance_wallet_outlined,
      summary:
          'We will point you toward wealth media, money goals, and small tasks so the pressure becomes a plan.',
    ),
    _PainPoint(
      title: 'Relationships',
      icon: Icons.groups_2_outlined,
      summary:
          'Use relationship courses, expectations, and reflection tools to improve the way you connect.',
    ),
    _PainPoint(
      title: 'Stress',
      icon: Icons.spa_outlined,
      summary:
          'Use calming media, focus mode, and short task lists to reduce overload one practical step at a time.',
    ),
    _PainPoint(
      title: 'Anxiety',
      icon: Icons.psychology_alt_outlined,
      summary:
          'Use supportive learning, grounding actions, and visible goals to create more steadiness and control.',
    ),
    _PainPoint(
      title: 'Manifestation',
      icon: Icons.auto_awesome_outlined,
      summary:
          'Use visualization, affirmations, and aligned action steps to turn intention into momentum.',
    ),
  ];

  _PainPoint get _activePainPoint {
    return _painPoints.firstWhere(
      (point) => point.title == _selectedPainPoint,
      orElse: () => _painPoints.first,
    );
  }

  @override
  void initState() {
    super.initState();
    unawaited(_loadProgress());
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPage = (prefs.getInt(OnboardingPage.progressStorageKey) ?? 0)
        .clamp(0, 7);
    final savedPainPoint = prefs.getString(OnboardingPage.painPointStorageKey);
    final validPainPoint = _painPoints.any(
      (point) => point.title == savedPainPoint,
    );
    if (!mounted) return;
    setState(() {
      _pageIndex = savedPage;
      _selectedPainPoint = validPainPoint ? savedPainPoint : null;
      _pageController = PageController(initialPage: savedPage);
      _progressLoaded = true;
    });
  }

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  void _goToPage(int index) {
    _pageController!.animateToPage(
      index,
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _finish({required bool skipped}) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    await OnboardingPage.markComplete();
    await OnboardingPage.clearProgress();
    if (!mounted) return;
    if (skipped) {
      widget.onSkip();
    } else {
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_progressLoaded) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(child: AbleriteLoadingIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: _PageDots(currentIndex: _pageIndex, total: 8),
                      ),
                      if (_pageIndex > 0)
                        TextButton(
                          onPressed: () => _goToPage(_pageIndex - 1),
                          child: const Text('Back'),
                        ),
                      TextButton(
                        onPressed: _isSaving
                            ? null
                            : () => _finish(skipped: true),
                        child: const Text('Skip'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView(
                    controller: _pageController!,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (index) {
                      setState(() => _pageIndex = index);
                      unawaited(OnboardingPage.saveProgress(index));
                    },
                    children: [
                      _OnboardingScreen(
                        isActive: _pageIndex == 0,
                        spaciousLayout: true,
                        staggerEntrance: true,
                        hero: _HolisticGrowthHero(isActive: _pageIndex == 0),
                        title: 'Grow every part of your life',
                        body:
                            'Ablerite is a holistic self-growth and development suite that brings your mind, wellbeing, relationships, purpose, and money into one calm space.',
                        buttonLabel: 'Discover Ablerite',
                        onPressed: () => _goToPage(1),
                        child: _HolisticOverview(isActive: _pageIndex == 0),
                      ),
                      _OnboardingScreen(
                        isActive: _pageIndex == 1,
                        hero: _GrowthToolsHero(isActive: _pageIndex == 1),
                        title: 'Train your mind.\nShape your direction.',
                        body:
                            'Use practical tools to strengthen how you think, picture your future, and turn intention into grounded action.',
                        buttonLabel: 'Next',
                        onPressed: () => _goToPage(2),
                        child: const _GrowthToolList(),
                      ),
                      _OnboardingScreen(
                        isActive: _pageIndex == 2,
                        hero: _DianaAssistantAnimation(
                          isActive: _pageIndex == 2,
                        ),
                        title: 'Meet Diana Life Assistant',
                        body:
                            'Your personal AI assistant uses context from your goals, tasks, and habits to help you plan, reflect, get unstuck, and stay accountable.',
                        buttonLabel: 'Continue',
                        onPressed: () => _goToPage(3),
                        child: const _CompactFeatureList(
                          features: [
                            _OnboardingFeatureData(
                              icon: Icons.route_outlined,
                              title: 'Turn goals into a plan',
                              body: 'Break an outcome into clear next steps.',
                            ),
                            _OnboardingFeatureData(
                              icon: Icons.forum_outlined,
                              title: 'Think it through with Diana',
                              body:
                                  'Get relevant support instead of generic replies.',
                            ),
                            _OnboardingFeatureData(
                              icon: Icons.fact_check_outlined,
                              title: 'Stay accountable',
                              body:
                                  'Check in, reflect, and keep moving toward what matters.',
                            ),
                          ],
                        ),
                      ),
                      _OnboardingScreen(
                        isActive: _pageIndex == 3,
                        imageAsset:
                            'assets/images/onboarding/pain_points_wide.png',
                        imageFit: BoxFit.contain,
                        imageAspectRatio: 16 / 9,
                        title: 'What do you want to solve?',
                        body:
                            'Choose the pressure point you want Ablerite to help with first.',
                        buttonLabel: 'Continue',
                        onPressed: _selectedPainPoint == null
                            ? null
                            : () => _goToPage(4),
                        child: _PainPointGrid(
                          painPoints: _painPoints,
                          selectedPainPoint: _selectedPainPoint,
                          onSelected: (point) {
                            setState(() => _selectedPainPoint = point.title);
                            unawaited(
                              OnboardingPage.savePainPoint(point.title),
                            );
                          },
                        ),
                      ),
                      _OnboardingScreen(
                        isActive: _pageIndex == 4,
                        spaciousLayout: true,
                        imageAsset:
                            'assets/images/onboarding/free_media_wide.png',
                        imageFit: BoxFit.contain,
                        imageAspectRatio: 16 / 9,
                        title: 'Start with free guidance',
                        body: _activePainPoint.summary,
                        buttonLabel: 'Next',
                        onPressed: () => _goToPage(5),
                        child: const _CompactFeatureList(
                          features: [
                            _OnboardingFeatureData(
                              icon: Icons.headphones_outlined,
                              title: 'Listen and learn',
                              body: 'Use free media to understand the problem.',
                            ),
                            _OnboardingFeatureData(
                              icon: Icons.auto_stories_outlined,
                              title: 'Build perspective',
                              body:
                                  'See the challenge clearly and choose what to try next.',
                            ),
                            _OnboardingFeatureData(
                              icon: Icons.repeat_rounded,
                              title: 'Practice what helps',
                              body:
                                  'Turn useful ideas into a small habit you can repeat.',
                            ),
                          ],
                        ),
                      ),
                      _OnboardingScreen(
                        isActive: _pageIndex == 5,
                        spaciousLayout: true,
                        imageAsset:
                            'assets/images/onboarding/picture_your_future_wide.png',
                        imageFit: BoxFit.cover,
                        imageAspectRatio: 16 / 9,
                        title: 'Picture what you want',
                        body:
                            'Give yourself permission to define the life, feeling, or outcome you want to create.',
                        buttonLabel: 'Next',
                        onPressed: () => _goToPage(6),
                        child: const _CompactFeatureList(
                          features: [
                            _OnboardingFeatureData(
                              icon: Icons.visibility_outlined,
                              title: 'Imagine the outcome',
                              body:
                                  'Picture what success would look and feel like.',
                            ),
                            _OnboardingFeatureData(
                              icon: Icons.favorite_border_rounded,
                              title: 'Make it meaningful',
                              body:
                                  'Connect the goal to what genuinely matters to you.',
                            ),
                            _OnboardingFeatureData(
                              icon: Icons.auto_awesome_outlined,
                              title: 'Set your intention',
                              body:
                                  'Choose the direction you want your life to move in.',
                            ),
                          ],
                        ),
                      ),
                      _OnboardingScreen(
                        isActive: _pageIndex == 6,
                        spaciousLayout: true,
                        imageAsset:
                            'assets/images/onboarding/meditate_on_goals_wide_v2.png',
                        imageFit: BoxFit.cover,
                        imageAspectRatio: 16 / 9,
                        title: 'Meditate on your desires',
                        body:
                            'Use meditation, visualization, and affirmations to align your thoughts with the direction you want to take.',
                        buttonLabel: 'Next',
                        onPressed: () => _goToPage(7),
                        child: const _CompactFeatureList(
                          features: [
                            _OnboardingFeatureData(
                              icon: Icons.self_improvement_outlined,
                              title: 'Quiet the noise',
                              body:
                                  'Create space to focus on what you truly want.',
                            ),
                            _OnboardingFeatureData(
                              icon: Icons.remove_red_eye_outlined,
                              title: 'See it clearly',
                              body:
                                  'Visualize your desired outcome with intention.',
                            ),
                            _OnboardingFeatureData(
                              icon: Icons.wb_sunny_outlined,
                              title: 'Return to it',
                              body:
                                  'Use affirmations and reflection to keep it present.',
                            ),
                          ],
                        ),
                      ),
                      _OnboardingScreen(
                        isActive: _pageIndex == 7,
                        spaciousLayout: true,
                        imageAsset:
                            'assets/images/onboarding/action_tools_wide.png',
                        imageFit: BoxFit.contain,
                        imageAspectRatio: 16 / 9,
                        title: 'Turn insight into action',
                        body:
                            'Set goals, break them into tasks, and use the tools daily so progress becomes visible.',
                        buttonLabel: 'Create Your Account',
                        isLoading: _isSaving,
                        onPressed: () => _finish(skipped: false),
                        child: const _CompactFeatureList(
                          features: [
                            _OnboardingFeatureData(
                              icon: Icons.flag_outlined,
                              title: 'Create a goal',
                              body: 'Make the outcome specific and trackable.',
                            ),
                            _OnboardingFeatureData(
                              icon: Icons.task_alt_outlined,
                              title: 'Do the next step',
                              body: 'Use tasks, focus, boards, and reminders.',
                            ),
                            _OnboardingFeatureData(
                              icon: Icons.insights_outlined,
                              title: 'See your momentum',
                              body:
                                  'Review your progress and adjust without losing direction.',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class InitialOfferPage extends StatefulWidget {
  final String userId;
  final VoidCallback onComplete;
  final Future<void> Function(BuildContext context, String userId)? showOffer;

  const InitialOfferPage({
    super.key,
    required this.userId,
    required this.onComplete,
    this.showOffer,
  });

  static String storageKey(String userId) => 'initial_offer_complete_$userId';

  static Future<bool> isComplete(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(storageKey(userId)) ?? false;
  }

  static Future<void> markComplete(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(storageKey(userId), true);
  }

  @override
  State<InitialOfferPage> createState() => _InitialOfferPageState();
}

class _InitialOfferPageState extends State<InitialOfferPage> {
  bool _showCompletionAnimation = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runOfferFlow());
  }

  Future<void> _runOfferFlow() async {
    final customOffer = widget.showOffer;
    if (customOffer != null) {
      await customOffer(context, widget.userId);
    } else {
      await SubscriptionService().logInUser(widget.userId);
      if (!mounted) return;
      await SubscriptionService().showSubscriptionPaywall(context: context);
    }
    if (!mounted) return;
    await InitialOfferPage.markComplete(widget.userId);
    if (!mounted) return;
    setState(() => _showCompletionAnimation = true);
    await Future<void>.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Image.asset(
                    'assets/ablerite_logo_rounded.png',
                    width: 112,
                    height: 112,
                  ),
                ),
                const SizedBox(height: 28),
                const AbleriteLoadingIndicator(),
                const SizedBox(height: 18),
                Text(
                  'Preparing your account options…',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface.withAlpha(165),
                  ),
                ),
              ],
            ),
          ),
          if (_showCompletionAnimation)
            const Positioned.fill(child: _OnboardingCompletionAnimation()),
        ],
      ),
    );
  }
}

class _OnboardingScreen extends StatelessWidget {
  final String? imageAsset;
  final BoxFit imageFit;
  final double? imageAspectRatio;
  final Widget? hero;
  final String title;
  final String body;
  final Widget child;
  final String buttonLabel;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isActive;
  final bool spaciousLayout;
  final bool staggerEntrance;

  const _OnboardingScreen({
    this.imageAsset,
    this.imageFit = BoxFit.cover,
    this.imageAspectRatio,
    this.hero,
    required this.title,
    required this.body,
    required this.child,
    required this.buttonLabel,
    required this.onPressed,
    this.isLoading = false,
    this.isActive = false,
    this.spaciousLayout = false,
    this.staggerEntrance = false,
  }) : assert(imageAsset != null || hero != null);

  Widget _stagger(Widget child, int delayMilliseconds) {
    if (!staggerEntrance) return child;
    return _StaggeredEntrance(
      isActive: isActive,
      delay: Duration(milliseconds: delayMilliseconds),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isTabletLayout(context)) return _buildTablet(context);

    final colorScheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final isShort = constraints.maxHeight < 680;
        final defaultImageHeight = spaciousLayout
            ? (constraints.maxHeight * 0.30).clamp(168.0, 246.0)
            : (constraints.maxHeight * 0.23).clamp(128.0, 196.0);
        final imageHeight = imageAspectRatio == null
            ? defaultImageHeight
            : ((constraints.maxWidth - 48) / imageAspectRatio!).clamp(
                128.0,
                spaciousLayout ? 246.0 : 196.0,
              );
        final bottomPadding = MediaQuery.paddingOf(context).bottom;

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          child: Column(
            key: ValueKey(imageAsset),
            children: [
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(24, isShort ? 0 : 4, 24, 4),
                  child: LayoutBuilder(
                    builder: (context, contentConstraints) {
                      return Align(
                        alignment: Alignment.topCenter,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.topCenter,
                          child: SizedBox(
                            width: contentConstraints.maxWidth,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _AnimatedHeroEntrance(
                                  isActive: isActive,
                                  child: Container(
                                    height: imageHeight,
                                    clipBehavior: Clip.antiAlias,
                                    decoration: BoxDecoration(
                                      color: colorScheme.surfaceContainerHighest
                                          .withAlpha(80),
                                      borderRadius: BorderRadius.circular(26),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withAlpha(22),
                                          blurRadius: 24,
                                          offset: const Offset(0, 12),
                                        ),
                                      ],
                                    ),
                                    child:
                                        hero ??
                                        Image.asset(
                                          imageAsset!,
                                          fit: imageFit,
                                          alignment: Alignment.center,
                                        ),
                                  ),
                                ),
                                SizedBox(height: isShort ? 12 : 16),
                                _stagger(
                                  Text(
                                    title,
                                    style: GoogleFonts.outfit(
                                      fontSize: isShort ? 24 : 28,
                                      fontWeight: FontWeight.w800,
                                      color: colorScheme.onSurface,
                                      height: 1.02,
                                    ),
                                  ),
                                  110,
                                ),
                                const SizedBox(height: 8),
                                _stagger(
                                  Text(
                                    body,
                                    style: GoogleFonts.outfit(
                                      fontSize: isShort ? 14 : 15,
                                      height: 1.26,
                                      color: colorScheme.onSurface.withAlpha(
                                        170,
                                      ),
                                    ),
                                  ),
                                  210,
                                ),
                                SizedBox(height: isShort ? 12 : 16),
                                child,
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(24, 10, 24, 16 + bottomPadding),
                child: _stagger(
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: onPressed,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: AbleriteLoadingIndicator(strokeWidth: 2),
                            )
                          : Text(buttonLabel),
                    ),
                  ),
                  640,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTablet(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final landscape = isTabletLandscape(context);
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    Widget heroPanel(double height) {
      return _AnimatedHeroEntrance(
        isActive: isActive,
        child: Container(
          height: height,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withAlpha(80),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(22),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child:
              hero ??
              Padding(
                padding: const EdgeInsets.all(12),
                child: Image.asset(
                  imageAsset!,
                  fit: imageFit,
                  alignment: Alignment.center,
                ),
              ),
        ),
      );
    }

    Widget copyAndFeatures() {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _stagger(
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: landscape ? 32 : 34,
                fontWeight: FontWeight.w800,
                color: colorScheme.onSurface,
                height: 1.05,
              ),
            ),
            110,
          ),
          const SizedBox(height: 12),
          _stagger(
            Text(
              body,
              style: GoogleFonts.outfit(
                fontSize: 17,
                height: 1.4,
                color: colorScheme.onSurface.withAlpha(180),
              ),
            ),
            210,
          ),
          const SizedBox(height: 20),
          child,
        ],
      );
    }

    final pageContent = landscape
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: heroPanel(420)),
              const SizedBox(width: 40),
              Expanded(child: SingleChildScrollView(child: copyAndFeatures())),
            ],
          )
        : SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                heroPanel(hero != null ? 400 : (spaciousLayout ? 380 : 350)),
                const SizedBox(height: 28),
                copyAndFeatures(),
              ],
            ),
          );

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      child: Column(
        key: ValueKey(imageAsset),
        children: [
          Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                landscape ? 36 : 40,
                8,
                landscape ? 36 : 40,
                8,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: landscape ? 1120 : 760),
                  child: pageContent,
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(40, 12, 40, 18 + bottomPadding),
            child: Center(
              child: _stagger(
                SizedBox(
                  width: landscape ? 440 : 520,
                  child: FilledButton(
                    onPressed: onPressed,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: AbleriteLoadingIndicator(strokeWidth: 2),
                          )
                        : Text(buttonLabel),
                  ),
                ),
                640,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedHeroEntrance extends StatefulWidget {
  final bool isActive;
  final Widget child;

  const _AnimatedHeroEntrance({required this.isActive, required this.child});

  @override
  State<_AnimatedHeroEntrance> createState() => _AnimatedHeroEntranceState();
}

class _AnimatedHeroEntranceState extends State<_AnimatedHeroEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _curve;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 560),
    );
    _curve = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    if (widget.isActive) _controller.forward();
  }

  @override
  void didUpdateWidget(covariant _AnimatedHeroEntrance oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: ScaleTransition(
        scale: Tween(begin: 0.92, end: 1.0).animate(_curve),
        child: widget.child,
      ),
    );
  }
}

class _StaggeredEntrance extends StatefulWidget {
  final bool isActive;
  final Duration delay;
  final Widget child;

  const _StaggeredEntrance({
    required this.isActive,
    required this.delay,
    required this.child,
  });

  @override
  State<_StaggeredEntrance> createState() => _StaggeredEntranceState();
}

class _StaggeredEntranceState extends State<_StaggeredEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _position;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    final curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _opacity = curve;
    _position = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(curve);
    if (widget.isActive) _scheduleEntrance();
  }

  @override
  void didUpdateWidget(covariant _StaggeredEntrance oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _scheduleEntrance();
    } else if (!widget.isActive && oldWidget.isActive) {
      _timer?.cancel();
      _controller.reset();
    }
  }

  void _scheduleEntrance() {
    _timer?.cancel();
    _controller.reset();
    _timer = Timer(widget.delay, () {
      if (mounted && widget.isActive) _controller.forward();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _position, child: widget.child),
    );
  }
}

class _HolisticGrowthHero extends StatefulWidget {
  final bool isActive;

  const _HolisticGrowthHero({required this.isActive});

  @override
  State<_HolisticGrowthHero> createState() => _HolisticGrowthHeroState();
}

class _HolisticGrowthHeroState extends State<_HolisticGrowthHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  static const orbitItems = [
    ('Mind', Icons.psychology_outlined),
    ('Body', Icons.favorite_border),
    ('Relationships', Icons.groups_2_outlined),
    ('Purpose', Icons.explore_outlined),
    ('Wealth', Icons.account_balance_wallet_outlined),
    ('Growth', Icons.trending_up_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    );
    if (widget.isActive) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant _HolisticGrowthHero oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _controller.repeat();
    } else if (!widget.isActive && oldWidget.isActive) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final progress = _controller.value * orbitItems.length;
        final activeIndex = progress.floor() % orbitItems.length;
        final activePulse = math.sin((progress % 1) * math.pi);
        return LayoutBuilder(
          builder: (context, constraints) {
            const nodeSize = 38.0;
            final availableDiameter = math.min(
              constraints.maxWidth - nodeSize - 24,
              constraints.maxHeight - nodeSize - 24,
            );
            final radius = math.max(44.0, availableDiameter / 2);
            final center = Offset(
              constraints.maxWidth / 2,
              constraints.maxHeight / 2,
            );
            return Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _HolisticNetworkPainter(
                      color: colorScheme.primary,
                      nodeCount: orbitItems.length,
                    ),
                  ),
                ),
                for (final entry in orbitItems.indexed)
                  Positioned(
                    left:
                        center.dx +
                        math.cos(
                              -math.pi / 2 +
                                  (entry.$1 * math.pi * 2 / orbitItems.length),
                            ) *
                            radius -
                        nodeSize / 2,
                    top:
                        center.dy +
                        math.sin(
                              -math.pi / 2 +
                                  (entry.$1 * math.pi * 2 / orbitItems.length),
                            ) *
                            radius -
                        nodeSize / 2,
                    child: Transform.scale(
                      scale: entry.$1 == activeIndex
                          ? 1.05 + (activePulse * 0.12)
                          : 1,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 280),
                        width: nodeSize,
                        height: nodeSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: entry.$1 == activeIndex
                              ? colorScheme.primary
                              : colorScheme.surfaceContainerHighest,
                          border: Border.all(
                            color: entry.$1 == activeIndex
                                ? colorScheme.primary
                                : colorScheme.outline.withAlpha(30),
                          ),
                          boxShadow: entry.$1 == activeIndex
                              ? [
                                  BoxShadow(
                                    color: colorScheme.primary.withAlpha(75),
                                    blurRadius: 16,
                                  ),
                                ]
                              : null,
                        ),
                        child: Icon(
                          entry.$2.$2,
                          size: 18,
                          color: entry.$1 == activeIndex
                              ? colorScheme.onPrimary
                              : colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                Center(
                  child: Transform.scale(
                    scale: 1 + (activePulse * 0.025),
                    child: Container(
                      width: 96,
                      height: 96,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(27),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.primary.withAlpha(45),
                            blurRadius: 30,
                            offset: const Offset(0, 14),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.asset('assets/ablerite_logo_rounded.png'),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _HolisticNetworkPainter extends CustomPainter {
  final Color color;
  final int nodeCount;

  const _HolisticNetworkPainter({required this.color, required this.nodeCount});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const nodeSize = 38.0;
    final radius = math.max(
      44.0,
      math.min(size.width - nodeSize - 24, size.height - nodeSize - 24) / 2,
    );
    final linePaint = Paint()
      ..color = color.withAlpha(30)
      ..strokeWidth = 1.3
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius, linePaint);
    canvas.drawCircle(center, radius * 0.68, linePaint);
    for (var index = 0; index < nodeCount; index++) {
      final angle = -math.pi / 2 + (index * math.pi * 2 / nodeCount);
      final node = Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
      );
      canvas.drawLine(center, node, linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _HolisticNetworkPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.nodeCount != nodeCount;
  }
}

class _LifeAreaChips extends StatelessWidget {
  const _LifeAreaChips();

  static const areas = [
    'Mind',
    'Body',
    'Purpose',
    'Relationships',
    'Wealth',
    'Growth',
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: areas
          .map(
            (area) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check, size: 14, color: colorScheme.primary),
                  const SizedBox(width: 5),
                  Text(
                    area,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _HolisticOverview extends StatelessWidget {
  final bool isActive;

  const _HolisticOverview({required this.isActive});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StaggeredEntrance(
          isActive: isActive,
          delay: const Duration(milliseconds: 330),
          child: const _LifeAreaChips(),
        ),
        const SizedBox(height: 14),
        _StaggeredEntrance(
          isActive: isActive,
          delay: const Duration(milliseconds: 430),
          child: _OverviewCard(
            icon: Icons.all_inclusive_rounded,
            title: 'One connected growth ecosystem',
            body: 'Learn · visualise · plan · act · review',
            colorScheme: colorScheme,
          ),
        ),
        const SizedBox(height: 10),
        _StaggeredEntrance(
          isActive: isActive,
          delay: const Duration(milliseconds: 530),
          child: _OverviewCard(
            icon: Icons.auto_awesome_rounded,
            title: 'Built around your whole life',
            body: 'Turn personal insight into meaningful daily progress.',
            colorScheme: colorScheme,
          ),
        ),
      ],
    );
  }
}

class _OverviewCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final ColorScheme colorScheme;

  const _OverviewCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.primary.withAlpha(18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.primary.withAlpha(28)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: colorScheme.primary.withAlpha(28),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: colorScheme.primary, size: 22),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  body,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: colorScheme.onSurface.withAlpha(155),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GrowthToolsHero extends StatefulWidget {
  final bool isActive;

  const _GrowthToolsHero({required this.isActive});

  @override
  State<_GrowthToolsHero> createState() => _GrowthToolsHeroState();
}

class _GrowthToolsHeroState extends State<_GrowthToolsHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  static const tools = [
    (
      'Brain Training',
      'Strengthen focus, memory, and mental agility.',
      'assets/images/app_banners/braintraining.png',
    ),
    (
      'Visualization',
      'Picture and mentally rehearse your future.',
      'assets/images/visualization/visionboards.png',
    ),
    (
      'Manifestation',
      'Pair a clear intention with aligned action.',
      'assets/images/manifestation/cosmicodering.png',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4800),
    );
    if (widget.isActive) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant _GrowthToolsHero oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _controller.repeat();
    } else if (!widget.isActive && oldWidget.isActive) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keepFacesVisible =
        isTabletLayout(context) && !isTabletLandscape(context);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final activeIndex = (_controller.value * tools.length).floor().clamp(
          0,
          tools.length - 1,
        );
        final tool = tools[activeIndex];
        return Padding(
          padding: const EdgeInsets.all(10),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              fit: StackFit.expand,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 520),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: Tween(begin: 1.04, end: 1.0).animate(animation),
                      child: child,
                    ),
                  ),
                  child: Image.asset(
                    tool.$3,
                    key: ValueKey(activeIndex),
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    alignment: keepFacesVisible
                        ? Alignment.topCenter
                        : Alignment.center,
                  ),
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0xE6071B15)],
                      stops: [0.3, 1],
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 14,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        tool.$1,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 19,
                          height: 1,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        tool.$2,
                        maxLines: 2,
                        style: GoogleFonts.outfit(
                          color: Colors.white.withAlpha(210),
                          fontSize: 12,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  right: 14,
                  top: 14,
                  child: Row(
                    children: List.generate(
                      tools.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 240),
                        width: index == activeIndex ? 22 : 7,
                        height: 7,
                        margin: const EdgeInsets.only(left: 5),
                        decoration: BoxDecoration(
                          color: index == activeIndex
                              ? Colors.white
                              : Colors.white.withAlpha(110),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _GrowthToolList extends StatelessWidget {
  const _GrowthToolList();

  @override
  Widget build(BuildContext context) {
    return const _CompactFeatureList(
      features: [
        _OnboardingFeatureData(
          icon: Icons.psychology_outlined,
          title: 'Brain training',
          body: 'Strengthen focus, memory, and mental agility.',
        ),
        _OnboardingFeatureData(
          icon: Icons.visibility_outlined,
          title: 'Visualization',
          body: 'Picture and mentally rehearse your future.',
        ),
        _OnboardingFeatureData(
          icon: Icons.auto_awesome_outlined,
          title: 'Manifestation',
          body: 'Pair a clear intention with aligned action.',
        ),
      ],
    );
  }
}

class _DianaAssistantAnimation extends StatefulWidget {
  final bool isActive;

  const _DianaAssistantAnimation({required this.isActive});

  @override
  State<_DianaAssistantAnimation> createState() =>
      _DianaAssistantAnimationState();
}

class _DianaAssistantAnimationState extends State<_DianaAssistantAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );
    if (widget.isActive) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant _DianaAssistantAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _controller.repeat();
    } else if (!widget.isActive && oldWidget.isActive) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final angle = _controller.value * math.pi * 2;
        final pulse = 1 + (math.sin(angle * 2) * 0.035);
        final firstBubble = _windowedOpacity(_controller.value, 0.08, 0.42);
        final secondBubble = _windowedOpacity(_controller.value, 0.38, 0.82);
        return LayoutBuilder(
          builder: (context, constraints) {
            final center = Offset(
              constraints.maxWidth / 2,
              constraints.maxHeight / 2,
            );
            final orbitRadius = math.max(
              42.0,
              math.min(constraints.maxWidth, constraints.maxHeight) * 0.32,
            );
            final ringSize = orbitRadius * 1.72;
            final assistantSize = orbitRadius * 1.28;
            const dotSizes = [10.0, 8.0, 12.0];

            return Stack(
              clipBehavior: Clip.hardEdge,
              alignment: Alignment.center,
              children: [
                Positioned(
                  left: 14,
                  bottom: 18,
                  child: _DianaChatBubble(
                    opacity: firstBubble,
                    label: 'Help me make a plan',
                  ),
                ),
                Positioned(
                  right: 12,
                  top: 18,
                  child: _DianaChatBubble(
                    opacity: secondBubble,
                    label: 'Here are 3 next steps',
                    isDiana: true,
                  ),
                ),
                for (var index = 0; index < dotSizes.length; index++)
                  Positioned(
                    left:
                        center.dx +
                        math.cos(angle + (index * math.pi * 2 / 3)) *
                            orbitRadius -
                        dotSizes[index] / 2,
                    top:
                        center.dy +
                        math.sin(angle + (index * math.pi * 2 / 3)) *
                            orbitRadius -
                        dotSizes[index] / 2,
                    child: _OrbitDot(
                      color: index == 0
                          ? colorScheme.tertiary
                          : colorScheme.primary,
                      size: dotSizes[index],
                    ),
                  ),
                Container(
                  width: ringSize,
                  height: ringSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: colorScheme.primary.withAlpha(35),
                    ),
                  ),
                ),
                Transform.scale(
                  scale: pulse,
                  child: Container(
                    width: assistantSize,
                    height: assistantSize,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withAlpha(28),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withAlpha(28),
                          blurRadius: 28,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.face_3,
                      color: colorScheme.primary,
                      size: assistantSize * 0.52,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  double _windowedOpacity(double value, double start, double end) {
    const fade = 0.1;
    if (value < start || value > end) return 0;
    if (value < start + fade) return (value - start) / fade;
    if (value > end - fade) return (end - value) / fade;
    return 1;
  }
}

class _DianaChatBubble extends StatelessWidget {
  final double opacity;
  final String label;
  final bool isDiana;

  const _DianaChatBubble({
    required this.opacity,
    required this.label,
    this.isDiana = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Opacity(
      opacity: opacity.clamp(0, 1),
      child: Transform.translate(
        offset: Offset(0, 8 * (1 - opacity)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 126),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: isDiana
                ? colorScheme.primary.withAlpha(28)
                : colorScheme.surface,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(13),
              topRight: const Radius.circular(13),
              bottomLeft: Radius.circular(isDiana ? 4 : 13),
              bottomRight: Radius.circular(isDiana ? 13 : 4),
            ),
            border: Border.all(color: colorScheme.outline.withAlpha(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(12),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 10,
              height: 1.15,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

class _OrbitDot extends StatelessWidget {
  final Color color;
  final double size;

  const _OrbitDot({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color.withAlpha(90), blurRadius: 10)],
      ),
    );
  }
}

class _OnboardingCompletionAnimation extends StatefulWidget {
  const _OnboardingCompletionAnimation();

  @override
  State<_OnboardingCompletionAnimation> createState() =>
      _OnboardingCompletionAnimationState();
}

class _OnboardingCompletionAnimationState
    extends State<_OnboardingCompletionAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _logoScale;
  late final Animation<double> _copyOpacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1900),
    )..forward();
    _logoScale = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.04, 0.58, curve: Curves.elasticOut),
    );
    _copyOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.42, 0.78, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surface,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final ringProgress = Curves.easeOutCubic.transform(
            (_controller.value / 0.72).clamp(0, 1),
          );
          return Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 1.05,
                      colors: [
                        colorScheme.primary.withAlpha(34),
                        colorScheme.surface,
                      ],
                    ),
                  ),
                ),
              ),
              for (final multiplier in [1.0, 1.32, 1.64])
                Opacity(
                  opacity: ((1 - ringProgress) * 0.42).clamp(0, 1),
                  child: Transform.scale(
                    scale: 0.55 + (ringProgress * multiplier),
                    child: Container(
                      width: 190,
                      height: 190,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colorScheme.primary.withAlpha(70),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ScaleTransition(
                    scale: _logoScale,
                    child: Container(
                      width: 148,
                      height: 148,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(39),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.primary.withAlpha(60),
                            blurRadius: 42,
                            offset: const Offset(0, 18),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(31),
                        child: Image.asset('assets/ablerite_logo_rounded.png'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 42),
                  FadeTransition(
                    opacity: _copyOpacity,
                    child: Column(
                      children: [
                        Text(
                          'You’re ready to manifest.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 30,
                            height: 1.05,
                            fontWeight: FontWeight.w900,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Welcome to Ablerite',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface.withAlpha(155),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PainPoint {
  final String title;
  final IconData icon;
  final String summary;

  const _PainPoint({
    required this.title,
    required this.icon,
    required this.summary,
  });
}

class _PainPointGrid extends StatelessWidget {
  final List<_PainPoint> painPoints;
  final String? selectedPainPoint;
  final ValueChanged<_PainPoint> onSelected;

  const _PainPointGrid({
    required this.painPoints,
    required this.selectedPainPoint,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final rowHeight = (screenHeight * 0.057).clamp(42.0, 52.0);
    final iconSize = (rowHeight * 0.38).clamp(16.0, 20.0);
    final fontSize = (rowHeight * 0.31).clamp(13.0, 16.0);
    final gap = screenHeight < 720 ? 6.0 : 8.0;
    return Column(
      children: painPoints.map((point) {
        final isSelected = selectedPainPoint == point.title;
        return Padding(
          padding: EdgeInsets.only(bottom: gap),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            height: rowHeight,
            child: Material(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.surfaceContainerHighest.withAlpha(170),
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => onSelected(point),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 28,
                        child: Icon(
                          point.icon,
                          size: iconSize,
                          color: isSelected
                              ? colorScheme.onPrimary
                              : colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          point.title,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: fontSize,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? colorScheme.onPrimary
                                : colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _OnboardingFeatureData {
  final IconData icon;
  final String title;
  final String body;

  const _OnboardingFeatureData({
    required this.icon,
    required this.title,
    required this.body,
  });
}

class _CompactFeatureList extends StatelessWidget {
  final List<_OnboardingFeatureData> features;

  const _CompactFeatureList({required this.features});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: features.map((feature) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: colorScheme.outline.withAlpha(35)),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withAlpha(24),
                  shape: BoxShape.circle,
                ),
                child: Icon(feature.icon, color: colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      feature.title,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      feature.body,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        height: 1.25,
                        color: colorScheme.onSurface.withAlpha(150),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _PageDots extends StatelessWidget {
  final int currentIndex;
  final int total;

  const _PageDots({required this.currentIndex, required this.total});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: List.generate(total, (index) {
        final isActive = index == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: isActive ? 32 : 9,
          height: 9,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: isActive
                ? colorScheme.primary
                : colorScheme.outline.withAlpha(70),
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}
