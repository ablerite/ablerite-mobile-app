import 'package:flutter/material.dart';

import 'widgets/guide_page.dart';

/// Finance help shown inside Focus mode. It deliberately excludes the Home
/// dashboard introduction and overview screenshot because that screen is not
/// part of the Focus navigation flow.
class FocusFinanceGuidePage extends StatelessWidget {
  const FocusFinanceGuidePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const GuidePage(
      appBarTitle: 'Finance Guide',
      sections: [
        GuideSectionData(
          icon: Icons.account_balance_wallet_outlined,
          title: 'Net Worth (Assets)',
          body:
              'What you own after liabilities are accounted for. Use Net Worth to manage individual assets and see how they add up. Net worth moves slowly, so check it for direction over weeks, not for daily change.\n\nThis is the long-range number — the one that tells you whether your overall position is improving, not just whether this month was good.',
          imageAsset: 'assets/guide_images/home_networth.png',
        ),
        GuideSectionData(
          icon: Icons.trending_up,
          title: 'Monthly Income',
          body:
              'The money coming in each month. Add or update income sources as they change. Keeping this current matters more than it seems — every other financial calculation depends on it being accurate.\n\nUpdate it the moment an income source changes, not at the end of the month from memory.',
          imageAsset: 'assets/guide_images/home_income.png',
        ),
        GuideSectionData(
          icon: Icons.receipt_long_outlined,
          title: 'Monthly Expenses',
          body:
              'Recurring and planned spending, tracked so you can understand your outgoings rather than guess at them. Expenses are the number most people underestimate without tracking, and the one most worth getting right.\n\nReview this regularly — expenses drift upward quietly far more often than they drop.',
          imageAsset: 'assets/guide_images/home_expenses.png',
        ),
        GuideSectionData(
          icon: Icons.savings_outlined,
          title: 'Cash Surplus',
          body:
              'What is left after income and expenses. Use it to allocate spare cash intentionally, rather than letting it disappear into whatever you happen to spend on next. A surplus you have not assigned a purpose to is the easiest money to lose track of.\n\nCheck this before making a discretionary purchase, not after.',
          imageAsset: 'assets/guide_images/home_cashsurplus.png',
        ),
      ],
    );
  }
}
