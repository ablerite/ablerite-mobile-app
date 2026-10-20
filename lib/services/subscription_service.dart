import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import '../ui/widgets/ablerite_loading_indicator.dart';

enum SubscriptionPaywallOutcome { purchased, cancelled, unavailable }

enum SubscriptionManagementOutcome { openedStore, unavailable }

class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  // Must exactly match the case-sensitive RevenueCat entitlement identifier.
  static const String _defaultEntitlementIdentifier = 'Ablerite Pro';

  bool _isConfigured = false;
  final ValueNotifier<bool> _proStatus = ValueNotifier<bool>(false);
  String? _identifiedUserId;
  String? _activeProductIdentifier;
  bool get isPro => _proStatus.value;
  ValueListenable<bool> get proStatus => _proStatus;
  String get activePlanDescription {
    final product = _activeProductIdentifier?.toLowerCase() ?? '';
    if (product.contains('year') || product.contains('annual')) {
      return 'Ablerite Pro Annual Subscription';
    }
    if (product.contains('month')) {
      return 'Ablerite Pro Monthly Subscription';
    }
    return 'Ablerite Pro Subscription';
  }

  String get _entitlementIdentifier =>
      dotenv.env['REVENUECAT_ENTITLEMENT_ID'] ?? _defaultEntitlementIdentifier;

  String? get _apiKey {
    if (Platform.isAndroid) return dotenv.env['REVENUECAT_ANDROID_API_KEY'];
    if (Platform.isIOS) return dotenv.env['REVENUECAT_IOS_API_KEY'];
    return null;
  }

  Future<void> init() async {
    final apiKey = _apiKey;
    if (apiKey == null || apiKey.trim().isEmpty) {
      debugPrint(
        'RevenueCat is enabled, but no platform API key was found in .env.',
      );
      _isConfigured = false;
      _setIsPro(false);
      return;
    }

    try {
      if (!kReleaseMode) {
        await Purchases.setLogLevel(LogLevel.debug);
      }
      await Purchases.configure(PurchasesConfiguration(apiKey));
      Purchases.addCustomerInfoUpdateListener(_applyCustomerInfo);
      _isConfigured = true;
      await updateCustomerInfo();
    } catch (e, stackTrace) {
      debugPrint('RevenueCat initialization failed: $e');
      debugPrintStack(stackTrace: stackTrace);
      _isConfigured = false;
      _setIsPro(false);
    }
  }

  Future<void> updateCustomerInfo() async {
    if (!_isConfigured) return;
    final customerInfo = await Purchases.getCustomerInfo();
    _applyCustomerInfo(customerInfo);
  }

  /// Shows the RevenueCat Paywall if the user is not Pro.
  /// Returns true if the user is Pro or successfully subscribed.
  Future<bool> showPaywallIfNeeded({BuildContext? context}) async {
    if (isPro) return true;
    if (!_isConfigured) return false;
    if (context == null || !context.mounted) {
      return _presentRevenueCatPaywall();
    }

    return await showDialog<bool>(
          context: context,
          barrierDismissible: true,
          barrierColor: Colors.black.withAlpha(82),
          builder: (_) => BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Center(
              child: _SubscriptionVideoCtaDialog(
                openPaywall: _presentRevenueCatPaywall,
              ),
            ),
          ),
        ) ??
        false;
  }

  /// Shows the RevenueCat Paywall directly, without the video CTA.
  Future<bool> showDirectPaywallIfNeeded() async {
    if (isPro) return true;
    if (!_isConfigured) return false;
    return _presentRevenueCatPaywall();
  }

  /// Presents the current offering during onboarding.
  ///
  /// This is used by onboarding, where users should be able to review and buy
  /// a plan without making the rest of onboarding conditional on a purchase.
  Future<SubscriptionPaywallOutcome> showSubscriptionPaywall({
    BuildContext? context,
  }) async {
    if (!_isConfigured) return SubscriptionPaywallOutcome.unavailable;
    try {
      final result = await RevenueCatUI.presentPaywall(
        displayCloseButton: true,
      );
      if (result == PaywallResult.purchased ||
          result == PaywallResult.restored) {
        await updateCustomerInfo();
        return SubscriptionPaywallOutcome.purchased;
      }
      if (result == PaywallResult.cancelled) {
        return SubscriptionPaywallOutcome.cancelled;
      }
      return SubscriptionPaywallOutcome.unavailable;
    } catch (e, stackTrace) {
      debugPrint('RevenueCat subscription paywall failed: $e');
      debugPrintStack(stackTrace: stackTrace);
      return SubscriptionPaywallOutcome.unavailable;
    }
  }

  Future<bool> _presentRevenueCatPaywall() async {
    try {
      final result = await RevenueCatUI.presentPaywallIfNeeded(
        _entitlementIdentifier,
        displayCloseButton: true,
      );

      if (result == PaywallResult.notPresented) {
        // Never infer access from the paywall UI result. A paywall can fail to
        // present for reasons unrelated to an active subscription, so only
        // RevenueCat's current entitlement state may unlock Pro.
        await updateCustomerInfo();
        return isPro;
      }

      if (result == PaywallResult.purchased ||
          result == PaywallResult.restored) {
        await updateCustomerInfo();
        return isPro;
      }

      return false;
    } catch (e, stackTrace) {
      debugPrint('RevenueCat paywall failed: $e');
      debugPrintStack(stackTrace: stackTrace);
      return false;
    }
  }

  /// Shows the RevenueCat Customer Center for support and purchase recovery.
  Future<void> showCustomerCenter() async {
    if (!_isConfigured) return;
    await RevenueCatUI.presentCustomerCenter(
      onRestoreCompleted: (customerInfo) => _applyCustomerInfo(customerInfo),
    );
  }

  /// Restores previous purchases
  Future<void> restorePurchases() async {
    if (!_isConfigured) return;
    final customerInfo = await Purchases.restorePurchases();
    _applyCustomerInfo(customerInfo);
  }

  /// Opens the store-owned screen where renewal, cancellation, and plan
  /// changes are actually controlled.
  Future<SubscriptionManagementOutcome> manageSubscription() async {
    if (!_isConfigured) return SubscriptionManagementOutcome.unavailable;
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      _applyCustomerInfo(customerInfo);

      final fallbackUrl = Platform.isIOS
          ? 'https://apps.apple.com/account/subscriptions'
          : Platform.isAndroid
          ? 'https://play.google.com/store/account/subscriptions?package=com.senrama.ablerite'
          : null;
      final url = customerInfo.managementURL ?? fallbackUrl;
      if (url == null) return SubscriptionManagementOutcome.unavailable;
      final opened = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
      return opened
          ? SubscriptionManagementOutcome.openedStore
          : SubscriptionManagementOutcome.unavailable;
    } catch (e, stackTrace) {
      debugPrint('Opening subscription management failed: $e');
      debugPrintStack(stackTrace: stackTrace);
      return SubscriptionManagementOutcome.unavailable;
    }
  }

  /// Associates RevenueCat purchases with the stable Supabase user UUID.
  Future<void> logInUser(String userId) async {
    if (!_isConfigured || _identifiedUserId == userId) return;
    try {
      final result = await Purchases.logIn(userId);
      _identifiedUserId = userId;
      _applyCustomerInfo(result.customerInfo);
    } catch (e, stackTrace) {
      debugPrint('RevenueCat user login failed: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  /// Returns RevenueCat to a fresh anonymous customer after app sign-out.
  Future<void> logOutUser() async {
    if (!_isConfigured || _identifiedUserId == null) return;
    try {
      final customerInfo = await Purchases.logOut();
      _identifiedUserId = null;
      _applyCustomerInfo(customerInfo);
    } catch (e, stackTrace) {
      debugPrint('RevenueCat user logout failed: $e');
      debugPrintStack(stackTrace: stackTrace);
      _identifiedUserId = null;
      _setIsPro(false);
    }
  }

  void _applyCustomerInfo(CustomerInfo customerInfo) {
    final activeEntitlement =
        customerInfo.entitlements.active[_entitlementIdentifier];
    _setIsPro(activeEntitlement != null);
    _activeProductIdentifier = activeEntitlement?.productIdentifier;
  }

  void _setIsPro(bool value) {
    if (_proStatus.value != value) {
      _proStatus.value = value;
    }
  }
}

class _SubscriptionVideoCtaDialog extends StatefulWidget {
  const _SubscriptionVideoCtaDialog({required this.openPaywall});

  final Future<bool> Function() openPaywall;

  @override
  State<_SubscriptionVideoCtaDialog> createState() =>
      _SubscriptionVideoCtaDialogState();
}

class _SubscriptionVideoCtaDialogState
    extends State<_SubscriptionVideoCtaDialog> {
  late final VideoPlayerController _controller;
  late final Future<void> _initializeVideo;
  bool _isReady = false;
  bool _isOpeningPaywall = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset(
      'assets/video/subscriptions/subscribe-cta.mp4',
    );
    _controller.addListener(_handleVideoProgress);
    _initializeVideo = _prepareVideo();
  }

  Future<void> _prepareVideo() async {
    await _controller.initialize();
    await _controller.setLooping(false);
    await _controller.setVolume(1);
    if (!mounted) return;
    setState(() => _isReady = true);
    await _controller.play();
  }

  void _handleVideoProgress() {
    if (!_isReady || _isOpeningPaywall || !mounted) return;
    final value = _controller.value;
    final duration = value.duration;
    if (duration == Duration.zero) return;
    final remaining = duration - value.position;
    if (remaining <= const Duration(milliseconds: 350)) {
      _openPaywall();
    }
  }

  Future<void> _openPaywall() async {
    if (_isOpeningPaywall || !mounted) return;
    setState(() => _isOpeningPaywall = true);
    await _controller.pause();

    final hasAccess = await widget.openPaywall();
    if (!mounted) return;
    Navigator.of(context).pop(hasAccess);
  }

  @override
  void dispose() {
    _controller.removeListener(_handleVideoProgress);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenSize = MediaQuery.sizeOf(context);
    final modalHeight = (screenSize.height * 0.80)
        .clamp(620.0, 760.0)
        .toDouble();
    return PopScope(
      canPop: !_isOpeningPaywall,
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          height: modalHeight,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              FutureBuilder<void>(
                future: _initializeVideo,
                builder: (context, snapshot) {
                  if (_isReady) {
                    return FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _controller.value.size.width,
                        height: _controller.value.size.height,
                        child: VideoPlayer(_controller),
                      ),
                    );
                  }
                  return Container(
                    color: colorScheme.primary.withAlpha(24),
                    child: Center(
                      child: AbleriteLoadingIndicator(
                        color: colorScheme.primary,
                      ),
                    ),
                  );
                },
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withAlpha(18),
                        Colors.black.withAlpha(0),
                        Colors.black.withAlpha(150),
                      ],
                      stops: const [0, 0.48, 1],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: IconButton.filledTonal(
                  onPressed: _isOpeningPaywall
                      ? null
                      : () => Navigator.of(context).pop(false),
                  icon: const Icon(Icons.close_rounded),
                  tooltip: 'Close',
                ),
              ),
              if (_isReady &&
                  !_controller.value.isPlaying &&
                  !_isOpeningPaywall)
                Center(
                  child: IconButton.filled(
                    onPressed: () => _controller.play(),
                    icon: const Icon(Icons.play_arrow_rounded),
                    iconSize: 36,
                    tooltip: 'Play',
                  ),
                ),
              Positioned(
                left: 18,
                right: 18,
                bottom: 18,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            colorScheme.surface.withAlpha(165),
                            colorScheme.surface.withAlpha(92),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: Colors.white.withAlpha(118)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(45),
                            blurRadius: 28,
                            offset: const Offset(0, 16),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Unlock Ablerite Pro',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: colorScheme.onSurface,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Level up with goal management, task lists, vision boards and all the tools you need to succeed.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  height: 1.30,
                                  color: colorScheme.onSurface.withAlpha(178),
                                ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: _isOpeningPaywall
                                  ? null
                                  : _openPaywall,
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: _isOpeningPaywall
                                  ? const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        AbleriteLoadingIndicator(
                                          size: 18,
                                          strokeWidth: 2,
                                        ),
                                        SizedBox(width: 10),
                                        Text('Loading subscription options…'),
                                      ],
                                    )
                                  : const Text('Subscribe Now'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (_isOpeningPaywall)
                Positioned.fill(
                  child: AbsorbPointer(
                    child: ColoredBox(color: Colors.black26),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
