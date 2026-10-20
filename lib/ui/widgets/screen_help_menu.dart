import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'tablet_layout.dart';

Future<void> showScreenHelpMenu({
  required BuildContext context,
  required String screenName,
  required VoidCallback onOpenGuide,
  required VoidCallback onStartWalkthrough,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close help menu',
    barrierColor: Colors.black.withAlpha(105),
    transitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (dialogContext, _, _) {
      final isTablet = isTabletLayout(dialogContext);
      void select(VoidCallback action) {
        Navigator.of(dialogContext, rootNavigator: true).pop();
        Future<void>.delayed(const Duration(milliseconds: 180), action);
      }

      return SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                child: Material(
                  color: const Color(0xFF101820).withAlpha(210),
                  child: Container(
                    width: isTablet
                        ? tabletPopupWidth(
                            dialogContext,
                            portrait: 520,
                            landscape: 600,
                          )
                        : 330,
                    padding: EdgeInsets.all(isTablet ? 24 : 18),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withAlpha(45)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$screenName help',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: isTablet ? 25 : 21,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Choose how you want to explore this screen.',
                          style: GoogleFonts.outfit(
                            color: Colors.white.withAlpha(155),
                            fontSize: isTablet ? 15 : 12,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _HelpOption(
                          icon: Icons.menu_book_outlined,
                          title: 'Help Guide',
                          subtitle: 'Open the detailed $screenName guide',
                          onTap: () => select(onOpenGuide),
                        ),
                        const SizedBox(height: 10),
                        _HelpOption(
                          icon: Icons.tour_outlined,
                          title: 'Walkthrough',
                          subtitle: 'Show the guided tour on this screen',
                          onTap: () => select(onStartWalkthrough),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
    transitionBuilder: (_, animation, _, child) => FadeTransition(
      opacity: animation,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.96, end: 1).animate(animation),
        child: child,
      ),
    ),
  );
}

class _HelpOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _HelpOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withAlpha(18),
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: Colors.white.withAlpha(30)),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white.withAlpha(225), size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        color: Colors.white.withAlpha(140),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.white.withAlpha(110),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
