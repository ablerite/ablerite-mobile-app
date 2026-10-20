import 'package:flutter/material.dart';

import '../../services/navigation_service.dart';
import 'spotlight_walkthrough.dart';

class AutoWalkthrough {
  static int _session = 0;
  static bool _isArmed = false;
  static final Set<String> _shownIds = {};

  static void resetForLogin() {
    _session++;
    _isArmed = true;
    _shownIds.clear();
  }

  static void disableUntilNextLogin() {
    _isArmed = false;
    _shownIds.clear();
  }

  static void maybeShowOnce(
    BuildContext context, {
    required String id,
    required List<SpotlightStep> steps,
    String? badgeAsset,
    Duration delay = const Duration(milliseconds: 450),
  }) {
    if (!_isArmed) return;
    if (focusNavigationModeNotifier.value) return;
    if (steps.isEmpty) return;
    final scopedId = '$_session:$id';
    if (_shownIds.contains(scopedId)) return;
    _shownIds.add(scopedId);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future<void>.delayed(delay);
      if (!context.mounted) return;
      if (focusNavigationModeNotifier.value) {
        // Focus mode intentionally suppresses automatic walkthroughs. Allow
        // this walkthrough to be scheduled again after returning to Overview.
        _shownIds.remove(scopedId);
        return;
      }
      SpotlightWalkthrough.show(context, steps: steps, badgeAsset: badgeAsset);
    });
  }
}
