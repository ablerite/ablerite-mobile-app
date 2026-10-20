import 'package:flutter/services.dart';

/// Tracks the Android system UI (status/nav bar) mode currently intended by
/// the app, so [reapply] can correctly restore it on app resume regardless
/// of whether a fullscreen page (Affirmations, Ambient Focus) is active.
///
/// The app runs in [SystemUiMode.immersiveSticky]: bars are hidden, and an
/// edge swipe reveals them as a translucent overlay on top of the content
/// (no relayout) that Android fades back out on its own after a moment of
/// inactivity — the native "true fullscreen" behavior, not something this
/// app needs to manage by hand.
class SystemUiService {
  SystemUiService._();

  static SystemUiMode _currentMode = SystemUiMode.immersiveSticky;
  static List<SystemUiOverlay> _currentOverlays = const [];
  static const SystemUiOverlayStyle _edgeToEdgeStyle = SystemUiOverlayStyle(
    statusBarColor: Color(0x00000000),
    systemNavigationBarColor: Color(0x00000000),
    systemNavigationBarDividerColor: Color(0x00000000),
    systemStatusBarContrastEnforced: false,
    systemNavigationBarContrastEnforced: false,
  );

  static Future<void> apply(
    SystemUiMode mode, {
    List<SystemUiOverlay> overlays = const [],
  }) {
    _currentMode = mode;
    _currentOverlays = overlays;
    SystemChrome.setSystemUIOverlayStyle(_edgeToEdgeStyle);
    return SystemChrome.setEnabledSystemUIMode(mode, overlays: overlays);
  }

  /// Re-applies whichever mode was last set via [apply] — e.g. on app
  /// resume — without changing what that mode is (so a resume during an
  /// active fullscreen session restores fullscreen, not the app default).
  static Future<void> reapply() {
    SystemChrome.setSystemUIOverlayStyle(_edgeToEdgeStyle);
    return SystemChrome.setEnabledSystemUIMode(
      _currentMode,
      overlays: _currentOverlays,
    );
  }
}
