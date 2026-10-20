import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../services/navigation_service.dart';
import '../services/subscription_service.dart';
import '../services/system_ui_service.dart';
import 'affirmations_page.dart';
import 'calendar_page.dart';
import 'cash_surplus_page.dart';
import 'chat_page.dart';
import 'financial_detail_page.dart';
import 'goals_page.dart';
import 'home_page.dart';
import 'action_center_page.dart';
import 'hubs/exploration_hub.dart';
import 'hubs/mbs_hub.dart';
import 'hubs/coach_hub.dart';
import 'insights_page.dart';
import 'journal_page.dart';
import 'learn_page.dart';
import 'manifestation_page.dart';
import 'mbs_overview_page.dart';
import 'mbs_pages.dart';
import 'notebooks_page.dart';
import 'settings_page.dart';
import 'todo_page.dart';
import 'train_page.dart';
import 'visualization_page.dart';
import 'widgets/ablerite_loading_indicator.dart';
import 'widgets/ambient_focus_overlay.dart';
import 'widgets/focus_mode_nav_bar.dart';
import 'widgets/spotlight_walkthrough.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold>
    with WidgetsBindingObserver {
  int _selectedIndex = 0;
  late PageController _pageController;
  final Map<int, GlobalKey> _navItemKeys = {
    0: GlobalKey(),
    1: GlobalKey(),
    2: GlobalKey(),
    3: GlobalKey(),
    4: GlobalKey(),
  };

  bool _isChangingPage = false;
  bool _didResolveInitialHome = false;
  bool _isInitialFocusActive = true;
  bool _focusNavigationActive = false;
  bool _isShortcutPreparing = false;
  bool _focusSettingsOpen = false;
  int _shortcutLaunchGeneration = 0;

  final Map<int, GlobalKey<NavigatorState>> _navigatorKeys = {
    0: GlobalKey<NavigatorState>(),
    1: GlobalKey<NavigatorState>(),
    2: GlobalKey<NavigatorState>(),
    3: GlobalKey<NavigatorState>(),
    4: GlobalKey<NavigatorState>(),
  };
  final Map<int, int> _routeDepths = {0: 1, 1: 1, 2: 1, 3: 1, 4: 1};
  late final Map<int, _TabRouteObserver> _routeObservers;
  double _pageOpacity = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _routeObservers = {
      for (final index in _navigatorKeys.keys)
        index: _TabRouteObserver(
          onDepthChanged: (depth) => _onNavigatorDepthChanged(index, depth),
        ),
    };
    _pageController = PageController(initialPage: _selectedIndex);
    pageViewSwipeNotifier.addListener(_onPageViewSwipeChanged);
    bottomNavVisibleNotifier.addListener(_onBottomNavChanged);
    focusShortcutRequestNotifier.addListener(_onFocusShortcutRequested);
    preferredHomeRequestNotifier.addListener(_onPreferredHomeRequested);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resolveInitialHome();
    });
  }

  Future<void> _resolveInitialHome() async {
    if (!mounted || _didResolveInitialHome) return;
    _didResolveInitialHome = true;
    final settings = context.read<SettingsProvider>();
    await settings.loaded;
    if (!mounted) return;
    if (settings.homeScreenChoice != HomeScreenChoice.focus) {
      setState(() => _isInitialFocusActive = false);
      return;
    }
    if (!SubscriptionService().isPro) {
      await settings.setHomeScreenChoice(HomeScreenChoice.overview);
      if (mounted) setState(() => _isInitialFocusActive = false);
      return;
    }

    _setFocusNavigationActive(true);
    final shortcut = await Navigator.of(context, rootNavigator: true)
        .push<FocusAppShortcut>(
          PageRouteBuilder<FocusAppShortcut>(
            opaque: true,
            // Preferences are resolved before the first frame, so Focus can
            // become the initial home without fading through Overview.
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
            pageBuilder: (context, animation, secondaryAnimation) =>
                const AmbientFocusOverlay(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) =>
                    FadeTransition(
                      opacity: CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeIn,
                      ),
                      child: child,
                    ),
          ),
        );

    if (mounted) {
      setState(() => _isInitialFocusActive = false);
      if (shortcut != null) {
        await _openFocusShortcut(
          shortcut,
          returnToFocus: true,
          instantLaunch: true,
        );
      } else {
        _setFocusNavigationActive(false);
      }
    }
  }

  void _onFocusShortcutRequested() {
    final request = focusShortcutRequestNotifier.value;
    if (request == null) return;
    focusShortcutRequestNotifier.value = null;
    final shortcut = FocusAppShortcut.values
        .where((candidate) => candidate.name == request.shortcutName)
        .firstOrNull;
    if (shortcut != null) {
      _openRequestedShortcut(shortcut, request);
    } else {
      request.markReady();
    }
  }

  Future<void> _openRequestedShortcut(
    FocusAppShortcut shortcut,
    FocusShortcutRequest request,
  ) async {
    try {
      await _openFocusShortcut(
        shortcut,
        returnToFocus: _focusNavigationActive,
        instantLaunch: true,
      );
    } finally {
      request.markReady();
    }
  }

  void _onPreferredHomeRequested() {
    final target = preferredHomeRequestNotifier.value;
    if (target == null) return;
    preferredHomeRequestNotifier.value = null;

    switch (target) {
      case PreferredHomeTarget.overview:
        _openOverviewHome();
        break;
      case PreferredHomeTarget.focus:
        _openFocusMode(instant: true);
        break;
    }
  }

  Future<void> _openFocusMode({
    bool instant = false,
    bool showOptionsOnOpen = false,
  }) async {
    _shortcutLaunchGeneration++;
    _setFocusNavigationActive(true);
    // Settings hides the classic host bar while changing shells. Restore it
    // only after Focus navigation is active so classic navigation never
    // flashes during the route transition.
    if (!bottomNavVisibleNotifier.value) {
      bottomNavVisibleNotifier.value = true;
    }
    final shortcut = await Navigator.of(context, rootNavigator: true)
        .push<FocusAppShortcut>(
          PageRouteBuilder<FocusAppShortcut>(
            opaque: true,
            transitionDuration: instant
                ? Duration.zero
                : const Duration(milliseconds: 450),
            reverseTransitionDuration: Duration.zero,
            pageBuilder: (context, animation, secondaryAnimation) =>
                AmbientFocusOverlay(showOptionsOnOpen: showOptionsOnOpen),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) =>
                    FadeTransition(
                      opacity: CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeIn,
                      ),
                      child: child,
                    ),
          ),
        );

    if (!mounted) return;
    if (shortcut != null) {
      await _openFocusShortcut(
        shortcut,
        returnToFocus: true,
        instantLaunch: true,
      );
    } else {
      _setFocusNavigationActive(false);
    }
  }

  Future<bool> _openFocusAppDrawer() async {
    return _openAppDrawerForMode(returnToFocus: true);
  }

  void _openFocusOptionsFromDrawer() {
    _openFocusMode(instant: true, showOptionsOnOpen: true);
  }

  Future<bool> _openFocusAppDrawerOverSettings(
    BuildContext settingsContext,
  ) async {
    return _openAppDrawerForMode(
      returnToFocus: true,
      hostContext: settingsContext,
    );
  }

  Future<bool> _openAppDrawerForMode({
    required bool returnToFocus,
    BuildContext? hostContext,
  }) async {
    var didLaunch = false;
    final shortcut = await showFocusShortcutDrawer(
      hostContext ?? context,
      onOpenOptions: _openFocusOptionsFromDrawer,
      onOpenSettings: _openFocusSettings,
      onLaunchShortcut: (shortcut) async {
        didLaunch = await _openFocusShortcut(
          shortcut,
          returnToFocus: returnToFocus,
          instantLaunch: true,
        );
      },
    );
    if (mounted && shortcut != null) {
      didLaunch = await _openFocusShortcut(
        shortcut,
        returnToFocus: returnToFocus,
        instantLaunch: true,
      );
    }
    return didLaunch;
  }

  Future<void> _openFocusSettings() async {
    if (_focusSettingsOpen) return;
    _focusSettingsOpen = true;
    // Settings belongs to the Focus shell, not to whichever app happens to be
    // active. Present it above MainScaffold so the persistent Focus nav cannot
    // push duplicate settings routes into a tab navigator or keep receiving
    // taps during the transition.
    PreferredHomeTarget? target;
    try {
      target = await Navigator.of(context, rootNavigator: true)
          .push<PreferredHomeTarget>(
            PageRouteBuilder<PreferredHomeTarget>(
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
              pageBuilder: (_, _, _) => SettingsPage(
                focusMode: true,
                onOpenAi: () => _openFocusShortcut(
                  FocusAppShortcut.coaching,
                  returnToFocus: true,
                  instantLaunch: true,
                ),
                onOpenApps: _openFocusAppDrawerOverSettings,
                onOpenCalendar: () => _openFocusShortcut(
                  FocusAppShortcut.calendar,
                  returnToFocus: true,
                  instantLaunch: true,
                ),
              ),
            ),
          );
    } finally {
      _focusSettingsOpen = false;
    }
    if (!mounted || target == null) return;
    switch (target) {
      case PreferredHomeTarget.overview:
        await _openOverviewHome();
        break;
      case PreferredHomeTarget.focus:
        await _openFocusMode(instant: true);
        break;
    }
  }

  Future<void> _openOverviewHome() {
    _setFocusNavigationActive(false);
    _shortcutLaunchGeneration++;
    return _onItemTapped(0);
  }

  Future<bool> _openFocusShortcut(
    FocusAppShortcut shortcut, {
    required bool returnToFocus,
    bool instantLaunch = false,
  }) async {
    if (shortcut == FocusAppShortcut.settings) {
      await _openFocusSettings();
      return true;
    }
    final launchGeneration = ++_shortcutLaunchGeneration;
    final tabIndex = switch (shortcut) {
      FocusAppShortcut.netWorth ||
      FocusAppShortcut.income ||
      FocusAppShortcut.expenses ||
      FocusAppShortcut.cashSurplus => 0,
      FocusAppShortcut.brainTraining ||
      FocusAppShortcut.knowledge ||
      FocusAppShortcut.criticalLearning ||
      FocusAppShortcut.insights => 1,
      FocusAppShortcut.goals ||
      FocusAppShortcut.tasks ||
      FocusAppShortcut.affirmations ||
      FocusAppShortcut.coaching ||
      FocusAppShortcut.calendar => 2,
      FocusAppShortcut.visualization ||
      FocusAppShortcut.manifestation ||
      FocusAppShortcut.notebooks ||
      FocusAppShortcut.journals => 3,
      FocusAppShortcut.metrics ||
      FocusAppShortcut.mind ||
      FocusAppShortcut.body ||
      FocusAppShortcut.spirit => 4,
      FocusAppShortcut.settings => 0,
    };

    // Resolve access before touching the tab stack. Otherwise a Pro shortcut
    // briefly exposes its section home while the entitlement dialog loads.
    if (_requiresPro(shortcut)) {
      final allowed = await SubscriptionService().showPaywallIfNeeded(
        context: context,
      );
      if (!allowed || !mounted) return false;
    }

    _setFocusNavigationActive(returnToFocus);

    final destination = switch (shortcut) {
      FocusAppShortcut.netWorth => FinancialDetailPage(
        title: 'Net Worth',
        section: 'assets',
        color: Theme.of(context).colorScheme.primary,
      ),
      FocusAppShortcut.income => FinancialDetailPage(
        title: 'Income',
        section: 'income',
        color: Theme.of(context).colorScheme.primary,
      ),
      FocusAppShortcut.expenses => FinancialDetailPage(
        title: 'Expenses',
        section: 'expenses',
        color: Theme.of(context).colorScheme.primary,
      ),
      FocusAppShortcut.cashSurplus => const CashSurplusPage(),
      FocusAppShortcut.brainTraining => const TrainPage(),
      FocusAppShortcut.knowledge => const LearnPage(),
      FocusAppShortcut.criticalLearning => const LearnPage(
        initialView: 'criticalHome',
      ),
      FocusAppShortcut.insights => const InsightsPage(),
      FocusAppShortcut.goals => const GoalsPage(),
      FocusAppShortcut.tasks => const TodoPage(),
      FocusAppShortcut.affirmations => const AffirmationsPage(),
      FocusAppShortcut.coaching => const ChatPage(),
      FocusAppShortcut.calendar => const CalendarPage(),
      FocusAppShortcut.visualization => const VisualizationPage(),
      FocusAppShortcut.manifestation => const ManifestationPage(),
      FocusAppShortcut.notebooks => const NotebooksPage(),
      FocusAppShortcut.journals => const JournalPage(),
      FocusAppShortcut.metrics => const MBSOverviewPage(),
      FocusAppShortcut.mind => MBSPage(
        title: 'Mind Practice',
        section: 'meditation_logs',
        color: Theme.of(context).colorScheme.primary,
        icon: Icons.self_improvement,
      ),
      FocusAppShortcut.body => MBSPage(
        title: 'Body Training',
        section: 'body_logs',
        color: Theme.of(context).colorScheme.primary,
        icon: Icons.fitness_center,
      ),
      FocusAppShortcut.spirit => MBSPage(
        title: 'Spirit Development',
        section: 'spirit_logs',
        color: Theme.of(context).colorScheme.primary,
        icon: Icons.nights_stay_outlined,
      ),
      FocusAppShortcut.settings => const SettingsPage(focusMode: true),
    };

    final route = PageRouteBuilder<void>(
      transitionDuration: instantLaunch
          ? Duration.zero
          : const Duration(milliseconds: 420),
      reverseTransitionDuration: returnToFocus
          ? Duration.zero
          : const Duration(milliseconds: 260),
      pageBuilder: (context, animation, secondaryAnimation) => destination,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final eased = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: eased,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.055, 0.025),
              end: Offset.zero,
            ).animate(eased),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.985, end: 1).animate(eased),
              child: child,
            ),
          ),
        );
      },
    );

    // If the destination tab is already mounted, put the app route on its
    // navigator before revealing that tab. This makes the shortcut genuinely
    // direct instead of rendering the section home for an intermediate frame.
    var nestedNavigator = _navigatorKeys[tabIndex]!.currentState;
    Future<void> routeCompletion;
    if (nestedNavigator != null) {
      nestedNavigator.popUntil((candidate) => candidate.isFirst);
      routeCompletion = nestedNavigator.push(route);
      _showPreparedShortcutTab(tabIndex);
    } else {
      // PageView creates distant tabs lazily. Cover that one-frame mount while
      // the navigator attaches, then reveal it with the app already on top.
      if (mounted) setState(() => _isShortcutPreparing = true);
      _prepareShortcutTab(tabIndex);
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return false;
      nestedNavigator = _navigatorKeys[tabIndex]!.currentState;
      routeCompletion = nestedNavigator != null
          ? nestedNavigator.push(route)
          : Navigator.of(context, rootNavigator: true).push(route);
      await WidgetsBinding.instance.endOfFrame;
      if (mounted) setState(() => _isShortcutPreparing = false);
    }

    if (returnToFocus) {
      routeCompletion.then((_) {
        if (mounted && launchGeneration == _shortcutLaunchGeneration) {
          _openFocusMode(instant: true);
        }
      });
    }
    return true;
  }

  void _prepareShortcutTab(int index) {
    if (index == _selectedIndex) {
      _navigatorKeys[index]!.currentState?.popUntil((route) => route.isFirst);
      return;
    }

    _navigatorKeys[_selectedIndex]!.currentState?.popUntil(
      (route) => route.isFirst,
    );
    _isChangingPage = true;
    _pageController.jumpToPage(index);
    setState(() => _selectedIndex = index);
    _isChangingPage = false;
  }

  void _showPreparedShortcutTab(int index) {
    if (index == _selectedIndex) return;

    _navigatorKeys[_selectedIndex]!.currentState?.popUntil(
      (route) => route.isFirst,
    );
    _isChangingPage = true;
    _pageController.jumpToPage(index);
    setState(() => _selectedIndex = index);
    _isChangingPage = false;
  }

  bool _requiresPro(FocusAppShortcut shortcut) {
    return switch (shortcut) {
      FocusAppShortcut.goals ||
      FocusAppShortcut.tasks ||
      FocusAppShortcut.affirmations ||
      FocusAppShortcut.coaching ||
      FocusAppShortcut.calendar ||
      FocusAppShortcut.manifestation ||
      FocusAppShortcut.notebooks ||
      FocusAppShortcut.journals ||
      FocusAppShortcut.metrics ||
      FocusAppShortcut.mind ||
      FocusAppShortcut.body ||
      FocusAppShortcut.spirit => true,
      FocusAppShortcut.settings => false,
      _ => false,
    };
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    pageViewSwipeNotifier.removeListener(_onPageViewSwipeChanged);
    bottomNavVisibleNotifier.removeListener(_onBottomNavChanged);
    focusShortcutRequestNotifier.removeListener(_onFocusShortcutRequested);
    preferredHomeRequestNotifier.removeListener(_onPreferredHomeRequested);
    focusNavigationModeNotifier.value = false;
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Android restores the system navigation bar on resume; hide it again.
      SystemUiService.reapply();
    }
  }

  void _onPageViewSwipeChanged() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  void _onBottomNavChanged() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  void _onBottomNavTapped(int index) {
    // Bottom navigation always means "open this section home", regardless of
    // whether the current app was launched from Focus or Overview.
    _setFocusNavigationActive(false);
    _shortcutLaunchGeneration++;
    _onItemTapped(index);
  }

  void _setFocusNavigationActive(bool active) {
    if (active) {
      SpotlightWalkthrough.dismissAll();
    }
    final changed = _focusNavigationActive != active;
    _focusNavigationActive = active;
    focusNavigationModeNotifier.value = active;
    if (changed && mounted) setState(() {});
  }

  Future<void> _onItemTapped(int index) async {
    if (index == _selectedIndex) {
      // Pop to first route if tapping the active tab
      _navigatorKeys[index]!.currentState!.popUntil((route) => route.isFirst);
    } else {
      // Reset the current tab's navigator to its root before switching away
      _navigatorKeys[_selectedIndex]!.currentState?.popUntil(
        (route) => route.isFirst,
      );

      _isChangingPage = true;
      setState(() {
        _pageOpacity = 0;
      });

      await Future<void>.delayed(const Duration(milliseconds: 70));
      if (!mounted) return;

      _pageController.jumpToPage(index);
      setState(() {
        _selectedIndex = index;
        _pageOpacity = 1;
      });
      _isChangingPage = false;
    }
  }

  Future<void> _onPageChanged(int index) async {
    if (_isChangingPage) {
      setState(() {
        _selectedIndex = index;
      });
      return;
    }

    _navigatorKeys[_selectedIndex]!.currentState?.popUntil(
      (route) => route.isFirst,
    );
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<bool> _onWillPop() async {
    final isFirstRouteInCurrentTab = !await _navigatorKeys[_selectedIndex]!
        .currentState!
        .maybePop();
    if (isFirstRouteInCurrentTab) {
      // If on the first route of the tab, let the app exit or go to home tab?
      // Standard Android behavior: if not on home tab, go to home tab.
      if (_selectedIndex != 0) {
        _onItemTapped(0);
        return false;
      }
    }
    // Let system handle back (exit app)
    return isFirstRouteInCurrentTab;
  }

  bool get _canSwipeBetweenTabs {
    return !_focusNavigationActive &&
        pageViewSwipeNotifier.value &&
        (_routeDepths[_selectedIndex] ?? 1) <= 1;
  }

  void _onNavigatorDepthChanged(int index, int depth) {
    if (_routeDepths[index] == depth) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _routeDepths[index] = depth;
      });
    });
  }

  Widget _buildNavigator(int index, Widget child) {
    return _KeepAliveWrapper(
      child: Navigator(
        key: _navigatorKeys[index],
        observers: [_routeObservers[index]!],
        onGenerateRoute: (routeSettings) {
          return MaterialPageRoute(builder: (context) => child);
        },
      ),
    );
  }

  List<SpotlightStep> get _navigationWalkthroughSteps {
    return [
      SpotlightStep(
        targetKey: _navItemKeys[0]!,
        title: 'Home',
        body:
            'Your main dashboard showing a high-level summary of your finances, primary goal, and key actions.',
        badgeAsset: 'assets/guide_images/free_badge.png',
      ),
      SpotlightStep(
        targetKey: _navItemKeys[1]!,
        title: 'Media',
        body:
            'Explore brain training games, personal growth courses, and daily perspective shifts.',
        badgeAsset: 'assets/guide_images/free_badge.png',
      ),
      SpotlightStep(
        targetKey: _navItemKeys[2]!,
        title: 'Action Center',
        body:
            'Your workspace for goals, task boards, daily affirmations, and AI text coaching.',
        badgeAsset: 'assets/guide_images/pro_badge.png',
      ),
      SpotlightStep(
        targetKey: _navItemKeys[3]!,
        title: 'Exploration',
        body:
            'A space for vision boards, manifestation tracking, notebooks, and personal journals.',
        badgeAsset: 'assets/guide_images/pro_badge.png',
      ),
      SpotlightStep(
        targetKey: _navItemKeys[4]!,
        title: 'Wellness',
        body:
            'Track holistic wellbeing across Mind, Body, and Spirit practices.',
        badgeAsset: 'assets/guide_images/pro_badge.png',
      ),
    ];
  }

  Widget _buildNavButton({
    required int index,
    required String label,
    IconData? icon,
    Color? selectedColor,
  }) {
    final isSelected = _selectedIndex == index;
    final colorScheme = Theme.of(context).colorScheme;
    final color = isSelected
        ? selectedColor ?? colorScheme.primary
        : colorScheme.onSurface.withAlpha(120);

    return Expanded(
      child: Center(
        child: Semantics(
          label: label,
          button: true,
          selected: isSelected,
          child: GestureDetector(
            key: _navItemKeys[index],
            behavior: HitTestBehavior.opaque,
            onTap: () => _onBottomNavTapped(index),
            child: SizedBox(
              width: 56,
              height: 56,
              child: Center(child: Icon(icon, color: color, size: 26)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCenterNavButton() {
    final isSelected = _selectedIndex == 2;
    final colorScheme = Theme.of(context).colorScheme;
    final inactiveColor = colorScheme.onSurface.withAlpha(120);

    return Expanded(
      child: Center(
        child: Semantics(
          label: 'Action Center',
          button: true,
          selected: isSelected,
          child: GestureDetector(
            key: _navItemKeys[2],
            behavior: HitTestBehavior.opaque,
            onTap: () => _onBottomNavTapped(2),
            child: SizedBox(
              width: 60,
              height: 60,
              child: Center(
                child: Container(
                  width: isSelected ? 46 : 42,
                  height: isSelected ? 46 : 42,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colorScheme.primary
                        : inactiveColor.withAlpha(18),
                    shape: BoxShape.circle,
                    border: isSelected
                        ? null
                        : Border.all(color: inactiveColor.withAlpha(70)),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: colorScheme.primary.withAlpha(70),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    Icons.center_focus_strong,
                    color: isSelected ? colorScheme.onPrimary : inactiveColor,
                    size: isSelected ? 30 : 28,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFocusBottomNavigation() {
    return FocusModeNavBar(
      onOpenAi: () => _openFocusShortcut(
        FocusAppShortcut.coaching,
        returnToFocus: true,
        instantLaunch: true,
      ),
      onOpenApps: _openFocusAppDrawer,
      onOpenFocus: _openFocusMode,
      onOpenCalendar: () => _openFocusShortcut(
        FocusAppShortcut.calendar,
        returnToFocus: true,
        instantLaunch: true,
      ),
      onOpenSettings: _openFocusSettings,
    );
  }

  Widget _buildTabletNavigationRail() {
    if (_focusNavigationActive) {
      return FocusModeNavRail(
        onOpenAi: () => _openFocusShortcut(
          FocusAppShortcut.coaching,
          returnToFocus: true,
          instantLaunch: true,
        ),
        onOpenApps: _openFocusAppDrawer,
        onOpenFocus: _openFocusMode,
        onOpenCalendar: () => _openFocusShortcut(
          FocusAppShortcut.calendar,
          returnToFocus: true,
          instantLaunch: true,
        ),
        onOpenSettings: _openFocusSettings,
        focusSelected: true,
      );
    }

    final colorScheme = Theme.of(context).colorScheme;
    return SafeArea(
      right: false,
      child: NavigationRail(
        minWidth: 92,
        groupAlignment: 0,
        labelType: NavigationRailLabelType.all,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        selectedIndex: _selectedIndex,
        selectedIconTheme: IconThemeData(color: colorScheme.primary, size: 28),
        selectedLabelTextStyle: TextStyle(
          color: colorScheme.primary,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
        unselectedIconTheme: IconThemeData(
          color: colorScheme.onSurface.withAlpha(135),
          size: 25,
        ),
        unselectedLabelTextStyle: TextStyle(
          color: colorScheme.onSurface.withAlpha(150),
          fontSize: 10,
        ),
        onDestinationSelected: _onBottomNavTapped,
        destinations: [
          NavigationRailDestination(
            icon: KeyedSubtree(
              key: _navItemKeys[0],
              child: const Icon(Icons.dashboard_outlined),
            ),
            selectedIcon: const Icon(Icons.dashboard),
            label: const Text('Overview'),
          ),
          NavigationRailDestination(
            icon: KeyedSubtree(
              key: _navItemKeys[1],
              child: const Icon(Icons.psychology_alt_outlined),
            ),
            selectedIcon: const Icon(Icons.psychology_alt),
            label: const Text('Develop'),
          ),
          NavigationRailDestination(
            icon: KeyedSubtree(
              key: _navItemKeys[2],
              child: const Icon(Icons.center_focus_strong_outlined),
            ),
            selectedIcon: const Icon(Icons.center_focus_strong),
            label: const Text('Action'),
          ),
          NavigationRailDestination(
            icon: KeyedSubtree(
              key: _navItemKeys[3],
              child: const Icon(Icons.explore_outlined),
            ),
            selectedIcon: const Icon(Icons.explore),
            label: const Text('Explore'),
          ),
          NavigationRailDestination(
            icon: KeyedSubtree(
              key: _navItemKeys[4],
              child: const Icon(Icons.favorite_outline),
            ),
            selectedIcon: const Icon(Icons.favorite),
            label: const Text('Wellness'),
          ),
        ],
      ),
    );
  }

  Widget _buildTabPage(int index) {
    final autoStartWalkthrough =
        _selectedIndex == index &&
        !_isInitialFocusActive &&
        !_focusNavigationActive;

    return switch (index) {
      0 => _buildNavigator(
        0,
        HomePage(
          navigationWalkthroughSteps: _navigationWalkthroughSteps,
          autoStartWalkthrough: autoStartWalkthrough,
        ),
      ),
      1 => _buildNavigator(
        1,
        ActionCenterPage(autoStartWalkthrough: autoStartWalkthrough),
      ),
      2 => _buildNavigator(
        2,
        CoachHub(autoStartWalkthrough: autoStartWalkthrough),
      ),
      3 => _buildNavigator(
        3,
        ExplorationHub(autoStartWalkthrough: autoStartWalkthrough),
      ),
      4 => _buildNavigator(
        4,
        MBSHub(autoStartWalkthrough: autoStartWalkthrough),
      ),
      _ => const SizedBox.shrink(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    if (settings.homeScreenChoice == HomeScreenChoice.focus &&
        !_didResolveInitialHome) {
      // Keep the classic shell out of the first frame while the initial Focus
      // route is being installed.
      return const ColoredBox(color: Colors.black);
    }
    final isTablet = MediaQuery.sizeOf(context).shortestSide >= 600;
    final pageContent = Stack(
      children: [
        AnimatedOpacity(
          opacity: _pageOpacity,
          duration: const Duration(milliseconds: 90),
          curve: Curves.easeOut,
          child: PageView(
            controller: _pageController,
            physics: _canSwipeBetweenTabs
                ? const ClampingScrollPhysics()
                : const NeverScrollableScrollPhysics(),
            onPageChanged: _onPageChanged,
            children: List.generate(5, _buildTabPage),
          ),
        ),
        if (_isShortcutPreparing)
          Positioned.fill(
            child: ColoredBox(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: const Center(child: AbleriteLoadingIndicator(size: 42)),
            ),
          ),
      ],
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final bool shouldPop = await _onWillPop();
        if (shouldPop) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: isTablet
            ? Row(
                children: [
                  _buildTabletNavigationRail(),
                  VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: Theme.of(context).dividerColor.withAlpha(45),
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1120),
                        child: SizedBox.expand(child: pageContent),
                      ),
                    ),
                  ),
                ],
              )
            : pageContent,
        bottomNavigationBar: isTablet
            ? null
            : !bottomNavVisibleNotifier.value
            ? null
            : _focusNavigationActive
            ? _buildFocusBottomNavigation()
            : SafeArea(
                top: false,
                child: Container(
                  height: 72,
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: Row(
                    children: [
                      _buildNavButton(
                        index: 0,
                        label: 'Overview',
                        icon: Icons.dashboard_outlined,
                      ),
                      _buildNavButton(
                        index: 1,
                        icon: Icons.psychology_alt,
                        label: 'Media',
                      ),
                      _buildCenterNavButton(),
                      _buildNavButton(
                        index: 3,
                        icon: Icons.explore,
                        label: 'Explore',
                      ),
                      _buildNavButton(
                        index: 4,
                        icon: Icons.favorite,
                        label: 'Wellness',
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

class _KeepAliveWrapper extends StatefulWidget {
  final Widget child;
  const _KeepAliveWrapper({required this.child});

  @override
  State<_KeepAliveWrapper> createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<_KeepAliveWrapper>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

class _TabRouteObserver extends NavigatorObserver {
  final ValueChanged<int> onDepthChanged;
  int _depth = 0;

  _TabRouteObserver({required this.onDepthChanged});

  void _notify() {
    onDepthChanged(_depth < 1 ? 1 : _depth);
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _depth = previousRoute == null ? 1 : (_depth < 1 ? 2 : _depth + 1);
    _notify();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _depth = (_depth - 1).clamp(1, 1000);
    _notify();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    _depth = (_depth - 1).clamp(1, 1000);
    _notify();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null && oldRoute == null) {
      _depth++;
    } else if (newRoute == null && oldRoute != null) {
      _depth--;
    }
    _notify();
  }
}
