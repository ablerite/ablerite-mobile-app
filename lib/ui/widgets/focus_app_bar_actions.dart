import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../services/currency_service.dart';
import '../../services/financial_service.dart';
import '../../services/navigation_service.dart';
import '../action_center_guide_page.dart';
import '../exploration_guide_page.dart';
import '../focus_finance_guide_page.dart';
import '../home_guide_page.dart';
import '../mbs_guide_page.dart';
import '../self_development_guide_page.dart';

enum FocusHelpGuide {
  finance,
  selfDevelopment,
  actionCenter,
  exploration,
  wellness,
}

class FocusAppBarActions extends StatelessWidget {
  final FocusHelpGuide? guide;

  const FocusAppBarActions({super.key, this.guide});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: focusNavigationModeNotifier,
      builder: (context, isFocusMode, child) {
        if (!isFocusMode && guide == null) return const SizedBox.shrink();
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isFocusMode && guide == FocusHelpGuide.finance)
              PopupMenuButton<String>(
                tooltip: 'Finance shortcuts',
                icon: const Icon(Icons.account_balance_outlined),
                onSelected: requestFocusShortcut,
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'netWorth',
                    child: _ShortcutMenuItem(
                      icon: Icons.account_balance_wallet_outlined,
                      label: 'Net Worth',
                    ),
                  ),
                  PopupMenuItem(
                    value: 'income',
                    child: _ShortcutMenuItem(
                      icon: Icons.monetization_on_outlined,
                      label: 'Income',
                    ),
                  ),
                  PopupMenuItem(
                    value: 'expenses',
                    child: _ShortcutMenuItem(
                      icon: Icons.pie_chart_outline,
                      label: 'Expenses',
                    ),
                  ),
                  PopupMenuItem(
                    value: 'cashSurplus',
                    child: _ShortcutMenuItem(
                      icon: Icons.savings_outlined,
                      label: 'Cash Surplus',
                    ),
                  ),
                ],
              ),
            if (isFocusMode && guide == FocusHelpGuide.wellness)
              PopupMenuButton<String>(
                tooltip: 'Wellness shortcuts',
                icon: const Icon(Icons.self_improvement_outlined),
                onSelected: requestFocusShortcut,
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'metrics',
                    child: _ShortcutMenuItem(
                      icon: Icons.query_stats_rounded,
                      label: 'Metrics',
                    ),
                  ),
                  PopupMenuItem(
                    value: 'mind',
                    child: _ShortcutMenuItem(
                      icon: Icons.self_improvement,
                      label: 'Mind',
                    ),
                  ),
                  PopupMenuItem(
                    value: 'body',
                    child: _ShortcutMenuItem(
                      icon: Icons.fitness_center,
                      label: 'Body',
                    ),
                  ),
                  PopupMenuItem(
                    value: 'spirit',
                    child: _ShortcutMenuItem(
                      icon: Icons.nights_stay_outlined,
                      label: 'Spirit',
                    ),
                  ),
                ],
              ),
            if (isFocusMode && guide == FocusHelpGuide.finance)
              IconButton(
                icon: const Icon(Icons.assessment_outlined),
                tooltip: 'Financial breakdown',
                onPressed: () => _showFinancialBreakdown(context),
              ),
            if (guide != null)
              IconButton(
                icon: const Icon(Icons.menu_book_outlined),
                tooltip: '${_guideName(guide!)} Help Guide',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        _guidePage(guide!, isFocusMode: isFocusMode),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void _showFinancialBreakdown(BuildContext context) {
    final metricsFuture = FinancialService().getFinancialMetrics();
    final currencyFuture = CurrencyService.fetchFromSupabase();
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.assessment_outlined,
              color: Theme.of(dialogContext).colorScheme.primary,
            ),
            const SizedBox(width: 10),
            const Text('Financial Breakdown'),
          ],
        ),
        content: FutureBuilder<(Map<String, double>, String)>(
          future: Future.wait<dynamic>([metricsFuture, currencyFuture]).then(
            (values) => (values[0] as Map<String, double>, values[1] as String),
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const SizedBox(
                height: 160,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError || snapshot.data == null) {
              return const Text(
                'Your financial breakdown could not be loaded. Please try again.',
              );
            }

            final (metrics, currency) = snapshot.data!;
            final formatter = NumberFormat.currency(
              symbol: CurrencyService.getSymbol(currency),
              decimalDigits: 0,
            );
            return SizedBox(
              width: 320,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _FinancialBreakdownRow(
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'Net Worth',
                    value: formatter.format(metrics['net_worth'] ?? 0),
                  ),
                  _FinancialBreakdownRow(
                    icon: Icons.monetization_on_outlined,
                    label: 'Monthly Income',
                    value: formatter.format(metrics['income'] ?? 0),
                  ),
                  _FinancialBreakdownRow(
                    icon: Icons.pie_chart_outline,
                    label: 'Monthly Expenses',
                    value: formatter.format(metrics['budget'] ?? 0),
                  ),
                  _FinancialBreakdownRow(
                    icon: Icons.savings_outlined,
                    label: 'Cash Surplus',
                    value: formatter.format(metrics['cash_surplus'] ?? 0),
                    isLast: true,
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _guideName(FocusHelpGuide guide) => switch (guide) {
    FocusHelpGuide.finance => 'Finance',
    FocusHelpGuide.selfDevelopment => 'Media',
    FocusHelpGuide.actionCenter => 'Action Center',
    FocusHelpGuide.exploration => 'Exploration',
    FocusHelpGuide.wellness => 'Wellness',
  };

  Widget _guidePage(FocusHelpGuide guide, {required bool isFocusMode}) =>
      switch (guide) {
        FocusHelpGuide.finance =>
          isFocusMode ? const FocusFinanceGuidePage() : const HomeGuidePage(),
        FocusHelpGuide.selfDevelopment => const SelfDevelopmentGuidePage(),
        FocusHelpGuide.actionCenter => const ActionCenterGuidePage(),
        FocusHelpGuide.exploration => const ExplorationGuidePage(),
        FocusHelpGuide.wellness => const MBSGuidePage(),
      };
}

class _ShortcutMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ShortcutMenuItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [Icon(icon, size: 20), const SizedBox(width: 12), Text(label)],
    );
  }
}

class _FinancialBreakdownRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isLast;

  const _FinancialBreakdownRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: colors.outline.withAlpha(35))),
      ),
      child: Row(
        children: [
          Icon(icon, size: 21, color: colors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.outfit(color: colors.onSurfaceVariant),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.outfit(
              color: colors.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// The primary back control for an app landing page.
///
/// Power Focus launches apps directly and deliberately has no section-home
/// layer, so a back arrow there is both unnecessary and misleading. Classic
/// Overview retains the existing Navigator.pop behaviour.
class FocusAwareBackButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const FocusAwareBackButton({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: focusNavigationModeNotifier,
      builder: (context, isFocusMode, child) {
        if (isFocusMode) return const SizedBox.shrink();
        return BackButton(
          onPressed: onPressed ?? () => Navigator.maybePop(context),
        );
      },
    );
  }
}

/// Reclaims the space normally reserved for the landing-page back button.
/// The surrounding AppBar keeps its classic Overview geometry unchanged.
class FocusAwareAppBarTitle extends StatelessWidget {
  final Widget child;
  final double focusOffset;

  const FocusAwareAppBarTitle({
    super.key,
    required this.child,
    this.focusOffset = 56,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: focusNavigationModeNotifier,
      child: child,
      builder: (context, isFocusMode, child) {
        if (!isFocusMode) return child!;
        return Transform.translate(
          offset: Offset(-focusOffset, 0),
          child: child,
        );
      },
    );
  }
}
