// Simple service to control PageView swipe and bottom nav visibility from child pages
// Avoids circular imports between main_scaffold and mini app pages

import 'dart:async';

import 'package:flutter/foundation.dart';

final ValueNotifier<bool> pageViewSwipeNotifier = ValueNotifier(true);
final ValueNotifier<bool> bottomNavVisibleNotifier = ValueNotifier(true);

// True while a sub-app is being presented from the Power Focus shell. App
// landing pages use this to avoid showing a back button that misleadingly
// points at a section home which is not part of the Focus navigation model.
final ValueNotifier<bool> focusNavigationModeNotifier = ValueNotifier(false);

// Individual app screens publish shortcut requests here. MainScaffold owns the
// tab navigators and consumes the request so switching apps always resets the
// correct stack and retains subscription checks.
class FocusShortcutRequest {
  final String shortcutName;
  final Completer<void> _ready = Completer<void>();

  FocusShortcutRequest(this.shortcutName);

  Future<void> get ready => _ready.future;

  void markReady() {
    if (!_ready.isCompleted) _ready.complete();
  }
}

final ValueNotifier<FocusShortcutRequest?> focusShortcutRequestNotifier =
    ValueNotifier(null);

Future<void> requestFocusShortcut(String shortcutName) {
  final request = FocusShortcutRequest(shortcutName);
  focusShortcutRequestNotifier.value = request;
  return request.ready;
}

enum PreferredHomeTarget { overview, focus }

// Sub-app screens publish their preferred-home request here. MainScaffold
// owns both the nested tab navigators and Focus overlay, so it can return to
// either home cleanly from any depth in the app.
final ValueNotifier<PreferredHomeTarget?> preferredHomeRequestNotifier =
    ValueNotifier(null);

void requestPreferredHome(PreferredHomeTarget target) {
  preferredHomeRequestNotifier.value = target;
}

// Active hub tracking
final ValueNotifier<int?> activeHubNotifier = ValueNotifier<int?>(null);

// Tab switching flag - set true when switching tabs so initial route pushes don't affect counter
final ValueNotifier<bool> tabSwitchingNotifier = ValueNotifier(false);

int _navDepth = 0;

void pushPage() {
  _navDepth++;
  if (_navDepth > 0) {
    pageViewSwipeNotifier.value = false;
  }
}

void popPage() {
  _navDepth--;
  if (_navDepth <= 0) {
    _navDepth = 0;
    pageViewSwipeNotifier.value = true;
  }
}

void resetNavDepth() {
  _navDepth = 0;
  pageViewSwipeNotifier.value = true;
}

void setActiveHub(int index) {
  final previousHub = activeHubNotifier.value;
  activeHubNotifier.value = index;

  if (previousHub != null && previousHub != index) {
    // Switching tabs - reset nav depth since old hub's pages won't call popPage
    resetNavDepth();
  }
}

void notifyTabSwitching() {
  tabSwitchingNotifier.value = true;
}

void notifyTabSwitchComplete() {
  tabSwitchingNotifier.value = false;
}

void setPageViewSwipeEnabled(bool enabled) {
  pageViewSwipeNotifier.value = enabled;
}

bool getPageViewSwipeEnabled() => pageViewSwipeNotifier.value;

void setBottomNavVisible(bool visible) {
  bottomNavVisibleNotifier.value = visible;
}
