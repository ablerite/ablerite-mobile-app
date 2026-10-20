import 'package:flutter/material.dart';

class FocusModeNavBar extends StatelessWidget {
  final VoidCallback onOpenAi;
  final VoidCallback onOpenApps;
  final VoidCallback onOpenFocus;
  final VoidCallback onOpenCalendar;
  final VoidCallback onOpenSettings;
  final bool focusSelected;
  final Color? backgroundColor;
  final Color? iconColor;
  final Key? appsKey;
  final Key? focusKey;
  final Key? settingsKey;
  final IconData homeIcon;
  final String homeLabel;

  const FocusModeNavBar({
    super.key,
    required this.onOpenAi,
    required this.onOpenApps,
    required this.onOpenFocus,
    required this.onOpenCalendar,
    required this.onOpenSettings,
    this.focusSelected = false,
    this.backgroundColor,
    this.iconColor,
    this.appsKey,
    this.focusKey,
    this.settingsKey,
    this.homeIcon = Icons.center_focus_strong,
    this.homeLabel = 'Focus Home',
  });

  @override
  Widget build(BuildContext context) {
    final foreground =
        iconColor ?? Theme.of(context).colorScheme.onSurface.withAlpha(190);
    final selected = Theme.of(context).colorScheme.primary;
    final background =
        backgroundColor ?? Theme.of(context).scaffoldBackgroundColor;

    // Paint behind the iPhone home indicator as part of the same bar. Keeping
    // SafeArea outside this background left a visible strip/cut-off on iOS.
    return ColoredBox(
      color: background,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 72,
          child: Row(
            children: [
              _FocusNavButton(
                icon: Icons.auto_awesome,
                label: 'AI Coaching',
                color: foreground,
                onTap: onOpenAi,
              ),
              _FocusNavButton(
                icon: Icons.calendar_month_outlined,
                label: 'Calendar',
                color: foreground,
                onTap: onOpenCalendar,
              ),
              _FocusCenterNavButton(
                key: focusKey,
                icon: homeIcon,
                label: homeLabel,
                inactiveColor: foreground,
                selectedColor: selected,
                selected: focusSelected,
                onTap: onOpenFocus,
              ),
              _FocusNavButton(
                key: appsKey,
                icon: Icons.apps_rounded,
                label: 'App shortcuts',
                color: foreground,
                onTap: onOpenApps,
              ),
              _FocusNavButton(
                key: settingsKey,
                icon: Icons.settings_outlined,
                label: 'Settings',
                color: foreground,
                onTap: onOpenSettings,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tablet counterpart to [FocusModeNavBar]. Phones retain the established
/// bottom navigation while wide screens use persistent, thumb-accessible
/// navigation at the leading edge.
class FocusModeNavRail extends StatelessWidget {
  final VoidCallback onOpenAi;
  final VoidCallback onOpenApps;
  final VoidCallback onOpenFocus;
  final VoidCallback onOpenCalendar;
  final VoidCallback onOpenSettings;
  final bool focusSelected;
  final Color? backgroundColor;
  final Color? iconColor;
  final Key? appsKey;
  final Key? focusKey;
  final Key? settingsKey;

  const FocusModeNavRail({
    super.key,
    required this.onOpenAi,
    required this.onOpenApps,
    required this.onOpenFocus,
    required this.onOpenCalendar,
    required this.onOpenSettings,
    this.focusSelected = false,
    this.backgroundColor,
    this.iconColor,
    this.appsKey,
    this.focusKey,
    this.settingsKey,
  });

  @override
  Widget build(BuildContext context) {
    final foreground =
        iconColor ?? Theme.of(context).colorScheme.onSurface.withAlpha(190);
    final selected = Theme.of(context).colorScheme.primary;
    final background =
        backgroundColor ?? Theme.of(context).scaffoldBackgroundColor;

    return Material(
      color: background,
      child: SafeArea(
        right: false,
        child: NavigationRail(
          minWidth: 92,
          groupAlignment: 0,
          backgroundColor: Colors.transparent,
          labelType: NavigationRailLabelType.all,
          selectedIndex: focusSelected ? 2 : null,
          selectedIconTheme: IconThemeData(color: selected, size: 28),
          unselectedIconTheme: IconThemeData(color: foreground, size: 25),
          selectedLabelTextStyle: TextStyle(
            color: selected,
            fontWeight: FontWeight.w700,
            fontSize: 11,
          ),
          unselectedLabelTextStyle: TextStyle(
            color: foreground.withAlpha(190),
            fontSize: 10,
          ),
          onDestinationSelected: (index) {
            switch (index) {
              case 0:
                onOpenAi();
              case 1:
                onOpenCalendar();
              case 2:
                onOpenFocus();
              case 3:
                onOpenApps();
              case 4:
                onOpenSettings();
            }
          },
          destinations: [
            const NavigationRailDestination(
              icon: Icon(Icons.auto_awesome),
              label: Text('Assistant'),
            ),
            const NavigationRailDestination(
              icon: Icon(Icons.calendar_month_outlined),
              label: Text('Calendar'),
            ),
            NavigationRailDestination(
              icon: KeyedSubtree(
                key: focusKey,
                child: const Icon(Icons.center_focus_strong),
              ),
              label: const Text('Focus'),
            ),
            NavigationRailDestination(
              icon: KeyedSubtree(
                key: appsKey,
                child: const Icon(Icons.apps_rounded),
              ),
              label: const Text('Apps'),
            ),
            NavigationRailDestination(
              icon: KeyedSubtree(
                key: settingsKey,
                child: const Icon(Icons.settings_outlined),
              ),
              label: const Text('Settings'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FocusNavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _FocusNavButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Semantics(
          button: true,
          label: label,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
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
}

class _FocusCenterNavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color inactiveColor;
  final Color selectedColor;
  final bool selected;
  final VoidCallback onTap;

  const _FocusCenterNavButton({
    super.key,
    required this.icon,
    required this.label,
    required this.inactiveColor,
    required this.selectedColor,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Semantics(
          label: label,
          button: true,
          selected: selected,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: SizedBox(
              width: 60,
              height: 60,
              child: Center(
                child: Container(
                  width: selected ? 46 : 42,
                  height: selected ? 46 : 42,
                  decoration: BoxDecoration(
                    color: selected
                        ? selectedColor
                        : inactiveColor.withAlpha(18),
                    shape: BoxShape.circle,
                    border: selected
                        ? null
                        : Border.all(color: inactiveColor.withAlpha(70)),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: selectedColor.withAlpha(70),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    icon,
                    color: selected
                        ? Theme.of(context).colorScheme.onPrimary
                        : inactiveColor,
                    size: selected ? 30 : 28,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
