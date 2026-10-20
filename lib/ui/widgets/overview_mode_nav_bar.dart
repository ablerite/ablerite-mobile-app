import 'package:flutter/material.dart';

/// The classic five-area navigation used while Settings is transitioning from
/// Power Focus back to Overview. Its geometry mirrors MainScaffold's bar so
/// the shell does not disappear during the mode handoff.
class OverviewModeNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const OverviewModeNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Row(
        children: [
          _button(context, 0, Icons.dashboard_outlined, 'Overview'),
          _button(context, 1, Icons.psychology_alt, 'Media'),
          _centerButton(context),
          _button(context, 3, Icons.explore, 'Explore'),
          _button(context, 4, Icons.favorite, 'Wellness'),
        ],
      ),
    );
  }

  Widget _button(BuildContext context, int index, IconData icon, String label) {
    final selected = selectedIndex == index;
    final scheme = Theme.of(context).colorScheme;
    final color = selected ? scheme.primary : scheme.onSurface.withAlpha(120);
    return Expanded(
      child: Center(
        child: Semantics(
          label: label,
          button: true,
          selected: selected,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onTap(index),
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

  Widget _centerButton(BuildContext context) {
    const index = 2;
    final selected = selectedIndex == index;
    final scheme = Theme.of(context).colorScheme;
    final inactive = scheme.onSurface.withAlpha(120);
    return Expanded(
      child: Center(
        child: Semantics(
          label: 'Action Center',
          button: true,
          selected: selected,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onTap(index),
            child: SizedBox(
              width: 60,
              height: 60,
              child: Center(
                child: Container(
                  width: selected ? 46 : 42,
                  height: selected ? 46 : 42,
                  decoration: BoxDecoration(
                    color: selected ? scheme.primary : inactive.withAlpha(18),
                    shape: BoxShape.circle,
                    border: selected
                        ? null
                        : Border.all(color: inactive.withAlpha(70)),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: scheme.primary.withAlpha(70),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    Icons.center_focus_strong,
                    color: selected ? scheme.onPrimary : inactive,
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
