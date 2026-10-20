import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'home_guide_page.dart';
import 'settings_page.dart';
import 'widgets/financial_card.dart';
import '../services/financial_service.dart';
import '../services/currency_service.dart';
import '../services/navigation_service.dart';
import '../services/subscription_service.dart';
import 'financial_detail_page.dart';
import 'cash_surplus_page.dart';
import 'widgets/auto_walkthrough.dart';
import 'widgets/access_tier_badge.dart';
import 'widgets/desktop_app_dialog.dart';
import 'widgets/spotlight_walkthrough.dart';
import 'widgets/screen_help_menu.dart';

class HomePage extends StatefulWidget {
  final List<SpotlightStep> navigationWalkthroughSteps;
  final bool autoStartWalkthrough;

  const HomePage({
    super.key,
    this.navigationWalkthroughSteps = const [],
    this.autoStartWalkthrough = false,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FinancialService _financialService = FinancialService();
  final GlobalKey _assetsKey = GlobalKey();
  final GlobalKey _incomeKey = GlobalKey();
  final GlobalKey _expensesKey = GlobalKey();
  final GlobalKey _cashSurplusKey = GlobalKey();
  final GlobalKey _desktopAppKey = GlobalKey();
  final GlobalKey _helpKey = GlobalKey();
  final GlobalKey _settingsKey = GlobalKey();
  late Future<Map<String, double>> _metricsFuture;
  String _currencySymbol = '\$';
  late Timer _clockTimer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadData();
    // The Android status bar is hidden in fullscreen mode, so this stands
    // in for the system clock.
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _metricsFuture = _financialService.getFinancialMetrics();
    });
    await _loadCurrency();
  }

  Future<void> _loadCurrency() async {
    final currency = await CurrencyService.fetchFromSupabase();
    if (mounted) {
      setState(() {
        _currencySymbol = CurrencyService.getSymbol(currency);
      });
    }
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      symbol: _currencySymbol,
      decimalDigits: 0,
    );
    return formatter.format(amount.round());
  }

  Future<void> _openFinancePage(Widget page) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
    if (mounted) await _loadData();
  }

  void _showHomeWalkthrough() {
    SpotlightWalkthrough.show(context, steps: _walkthroughSteps);
  }

  List<SpotlightStep> get _walkthroughSteps {
    return [
      SpotlightStep(
        targetKey: _desktopAppKey,
        title: 'Pro Desktop App',
        body:
            'Learn about the companion desktop app, copy download links, or manage Pro access.',
        badgeAsset: 'assets/guide_images/pro_badge.png',
      ),
      SpotlightStep(
        targetKey: _helpKey,
        title: 'Help & Guides',
        body:
            'Open user guides or restart interactive walkthroughs anytime from this menu.',
        badgeAsset: null,
      ),
      SpotlightStep(
        targetKey: _settingsKey,
        title: 'Settings',
        body:
            'Customize your theme, text scale, currency symbol, and account preferences.',
      ),
      SpotlightStep(
        targetKey: _assetsKey,
        title: 'Assets',
        body:
            'Track your assets and view total net worth after subtracting liabilities.',
        badgeAsset: 'assets/guide_images/free_badge.png',
      ),
      SpotlightStep(
        targetKey: _incomeKey,
        title: 'Income',
        body: 'Monitor regular income streams and track revenue milestones.',
        badgeAsset: 'assets/guide_images/free_badge.png',
      ),
      SpotlightStep(
        targetKey: _expensesKey,
        title: 'Expenses',
        body:
            'Track fixed bills and variable spending to maintain a healthy budget.',
        badgeAsset: 'assets/guide_images/free_badge.png',
      ),
      SpotlightStep(
        targetKey: _cashSurplusKey,
        title: 'Cash Surplus',
        body:
            'View unallocated monthly funds remaining after expenses to plan investments or savings.',
        badgeAsset: 'assets/guide_images/free_badge.png',
      ),
      ...widget.navigationWalkthroughSteps,
    ];
  }

  void _maybeAutoStartWalkthrough() {
    if (!widget.autoStartWalkthrough) return;
    AutoWalkthrough.maybeShowOnce(
      context,
      id: 'home',
      steps: _walkthroughSteps,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _maybeAutoStartWalkthrough();
  }

  @override
  void didUpdateWidget(covariant HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.autoStartWalkthrough != oldWidget.autoStartWalkthrough) {
      _maybeAutoStartWalkthrough();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final String greetingName =
        user?.userMetadata?['full_name']?.split(' ').first ?? 'Creator';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leadingWidth: 84,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Center(
            child: Text(
              DateFormat('h:mm a').format(_now),
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface.withAlpha(180),
              ),
            ),
          ),
        ),
        actions: [
          IconButton(
            key: _desktopAppKey,
            icon: Icon(
              Icons.desktop_windows_outlined,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            tooltip: 'Pro Desktop App',
            onPressed: () => DesktopAppDialog.show(context),
          ),
          IconButton(
            key: _helpKey,
            icon: Icon(
              Icons.help_outline,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            tooltip: 'Financial Overview help',
            onPressed: () => showScreenHelpMenu(
              context: context,
              screenName: 'Financial Overview',
              onOpenGuide: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HomeGuidePage(),
                  ),
                );
              },
              onStartWalkthrough: _showHomeWalkthrough,
            ),
          ),
          IconButton(
            key: _settingsKey,
            icon: Icon(
              Icons.settings,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            tooltip: 'Settings',
            onPressed: () async {
              final target = await Navigator.push<PreferredHomeTarget>(
                context,
                PageRouteBuilder<PreferredHomeTarget>(
                  transitionDuration: Duration.zero,
                  reverseTransitionDuration: Duration.zero,
                  pageBuilder: (_, _, _) => const SettingsPage(),
                ),
              );
              if (!mounted) return;
              if (target != null) {
                // Apply a layout change immediately. Waiting for the financial
                // refresh here could delay or prevent Power Focus from opening.
                requestPreferredHome(target);
              }
              if (target != PreferredHomeTarget.focus) {
                await _loadData();
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isTablet = constraints.maxWidth >= 700;
            // Route and system-bar transitions can briefly report a zero-height
            // viewport. Never pass a negative minimum height to ConstrainedBox.
            final contentHeight = (constraints.maxHeight - 48)
                .clamp(0.0, double.infinity)
                .toDouble();
            const headerAndTitleHeight = 86.0;
            const cardGaps = 18.0;
            final financialCardHeight =
                ((contentHeight - headerAndTitleHeight - cardGaps) / 4)
                    .clamp(72.0, 150.0)
                    .toDouble();

            return RefreshIndicator(
              onRefresh: _loadData,
              color: const Color(0xFF10B981),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24.0),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: contentHeight),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Ablerite',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const Spacer(),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Welcome back,',
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withAlpha(150),
                                ),
                              ),
                              Text(
                                '$greetingName.',
                                style: GoogleFonts.outfit(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Text(
                            'Financial Overview',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const Spacer(),
                          ValueListenableBuilder<bool>(
                            valueListenable: SubscriptionService().proStatus,
                            builder: (context, isPro, child) => isPro
                                ? const SizedBox.shrink()
                                : Semantics(
                                    label: 'Financial Overview, Free access',
                                    child: const AccessTierBadge(
                                      tier: AccessTier.free,
                                      prominent: true,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      FutureBuilder<Map<String, double>>(
                        future: _metricsFuture,
                        builder: (context, snapshot) {
                          final metrics =
                              snapshot.data ??
                              {
                                'net_worth': 0.0,
                                'income': 0.0,
                                'budget': 0.0,
                                'cash_surplus': 0.0,
                              };

                          final cards = <Widget>[
                            FinancialCard(
                              key: _assetsKey,
                              title: 'Net Worth',
                              value: _formatCurrency(metrics['net_worth']!),
                              icon: Icons.account_balance_wallet,
                              color: Theme.of(context).colorScheme.primary,
                              height: financialCardHeight,
                              onTap: () {
                                _openFinancePage(
                                  FinancialDetailPage(
                                    title: 'Net Worth',
                                    section: 'assets',
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                );
                              },
                            ),
                            FinancialCard(
                              key: _incomeKey,
                              title: 'Monthly Income',
                              value: _formatCurrency(metrics['income']!),
                              icon: Icons.monetization_on,
                              color: Theme.of(context).colorScheme.primary,
                              height: financialCardHeight,
                              onTap: () {
                                _openFinancePage(
                                  FinancialDetailPage(
                                    title: 'Income',
                                    section: 'income',
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                );
                              },
                            ),
                            FinancialCard(
                              key: _expensesKey,
                              title: 'Monthly Expenses',
                              value: _formatCurrency(metrics['budget']!),
                              icon: Icons.pie_chart,
                              color: Theme.of(context).colorScheme.primary,
                              height: financialCardHeight,
                              onTap: () {
                                _openFinancePage(
                                  FinancialDetailPage(
                                    title: 'Expenses',
                                    section: 'expenses',
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                );
                              },
                            ),
                            FinancialCard(
                              key: _cashSurplusKey,
                              title: 'Cash Surplus',
                              value: _formatCurrency(
                                metrics['cash_surplus'] ?? 0.0,
                              ),
                              icon: Icons.savings,
                              color: Theme.of(context).colorScheme.primary,
                              height: financialCardHeight,
                              onTap: () {
                                _openFinancePage(const CashSurplusPage());
                              },
                            ),
                          ];

                          if (isTablet) {
                            return GridView.count(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 2.35,
                              children: cards,
                            );
                          }

                          return Column(
                            children: [
                              for (
                                var index = 0;
                                index < cards.length;
                                index++
                              ) ...[
                                cards[index],
                                if (index != cards.length - 1)
                                  const SizedBox(height: 6),
                              ],
                            ],
                          );
                        },
                      ),
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
