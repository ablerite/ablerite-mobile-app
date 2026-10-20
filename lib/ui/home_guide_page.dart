import 'package:flutter/material.dart';
import 'widgets/guide_page.dart';

class HomeGuidePage extends StatelessWidget {
  const HomeGuidePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const GuidePage(
      appBarTitle: 'Home Guide',
      heroHeadline:
          'A practical guide to your dashboard and the numbers that matter daily.',
      sections: [
        GuideSectionData(
          icon: Icons.dashboard_outlined,
          title: 'What this page is for',
          body:
              'Home is your dashboard — a quick, honest snapshot of your financial picture the moment you open the app, plus fast access to the tools you reach for most often. Nothing here requires digging; the goal is that a glance tells you where you stand.\n\nEverything below is either a number you should see daily or a shortcut you will use often enough to justify living on the home screen.',
          imageAsset: 'assets/guide_images/home_overview.png',
        ),
        GuideSectionData(
          icon: Icons.account_balance_wallet_outlined,
          title: 'Net Worth (Assets)',
          body:
              'What you own after liabilities are accounted for. Tap it to manage individual assets and see how they add up. Net worth moves slowly, so check it for direction over weeks, not for daily change.\n\nThis is the long-range number — the one that tells you whether your overall position is improving, not just whether this month was good.',
          imageAsset: 'assets/guide_images/home_networth.png',
        ),
        GuideSectionData(
          icon: Icons.trending_up,
          title: 'Monthly Income',
          body:
              'The money coming in each month. Tap it to add or update income sources as they change. Keeping this current matters more than it seems — every other financial calculation on this page depends on it being accurate.\n\nUpdate it the moment an income source changes, not at the end of the month from memory.',
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
        GuideSectionData(
          icon: Icons.wb_twilight_outlined,
          title: 'Focus Mode',
          body:
              'A calm, distraction-free full-screen space with ambient sound and a focus timer. Use it when you need to protect a block of time from your phone, not just from other apps.\n\nFocus Mode works best when you decide what you are focusing on before you open it, not once you are already inside.',
        ),
        GuideSectionData(
          icon: Icons.desktop_windows_outlined,
          title: 'Pro Desktop App',
          body:
              'Details on the Pro desktop app, so your data and habits stay in sync across devices rather than living only on your phone. Useful the moment you want to work from a bigger screen without losing anything you have already logged here.',
          headingBadgeAsset: 'assets/guide_images/pro_badge.png',
        ),
        GuideSectionData(
          icon: Icons.settings_outlined,
          title: 'Settings',
          body:
              'Appearance, preferences, account, currency, and app options all live here. It is worth a visit early on to set your currency and theme correctly, rather than discovering the defaults were wrong months in.\n\nThe help icon next to Settings restarts the guided walkthrough any time you want a quick reminder of what each button does.',
        ),
      ],
    );
  }
}
