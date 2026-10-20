import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract interface class AppReviewRequester {
  Future<bool> isAvailable();

  Future<void> requestReview();
}

class StoreKitReviewRequester implements AppReviewRequester {
  StoreKitReviewRequester({InAppReview? inAppReview})
    : _inAppReview = inAppReview ?? InAppReview.instance;

  final InAppReview _inAppReview;

  @override
  Future<bool> isAvailable() => _inAppReview.isAvailable();

  @override
  Future<void> requestReview() => _inAppReview.requestReview();
}

/// Requests one App Store review prompt for the 1.0.2 review campaign.
///
/// The first signed-in session establishes eligibility. The second signed-in
/// session requests the native prompt, after a short delay, and a successful
/// request is persisted so later sessions do not request it again.
class AppReviewService {
  AppReviewService({
    required this.campaignId,
    AppReviewRequester? requester,
    Future<SharedPreferences> Function()? preferencesFactory,
    bool Function()? isSupportedPlatform,
    this.promptDelay = const Duration(seconds: 3),
  }) : _requester = requester ?? StoreKitReviewRequester(),
       _preferencesFactory =
           preferencesFactory ?? SharedPreferences.getInstance,
       _isSupportedPlatform = isSupportedPlatform ?? _isIos;

  static final AppReviewService instance = AppReviewService(
    campaignId: '1.0.2',
  );

  final String campaignId;
  final AppReviewRequester _requester;
  final Future<SharedPreferences> Function() _preferencesFactory;
  final bool Function() _isSupportedPlatform;
  final Duration promptDelay;

  bool _handledThisAppSession = false;

  String get _sessionCountKey => 'app_review.$campaignId.eligible_sessions';
  String get _requestedKey => 'app_review.$campaignId.requested';

  static bool _isIos() =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  /// Returns true only when the native review request was dispatched.
  Future<bool> registerEligibleSessionAndMaybeRequest() async {
    if (_handledThisAppSession || !_isSupportedPlatform()) return false;
    _handledThisAppSession = true;

    final preferences = await _preferencesFactory();
    if (preferences.getBool(_requestedKey) ?? false) return false;

    final eligibleSessions = (preferences.getInt(_sessionCountKey) ?? 0) + 1;
    await preferences.setInt(_sessionCountKey, eligibleSessions);
    if (eligibleSessions < 2) return false;

    if (promptDelay > Duration.zero) {
      await Future<void>.delayed(promptDelay);
    }

    try {
      if (!await _requester.isAvailable()) return false;
      await _requester.requestReview();
      await preferences.setBool(_requestedKey, true);
      return true;
    } catch (error, stackTrace) {
      debugPrint('App Store review request failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return false;
    }
  }
}
