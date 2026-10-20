import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/fcm_service.dart';
import '../services/subscription_service.dart';
import 'widgets/loading_screen.dart';
import 'login_page.dart';
import 'main_scaffold.dart';
import 'onboarding_page.dart';
import 'reset_password_page.dart';
import 'mfa_challenge_page.dart';
import 'widgets/auto_walkthrough.dart';
import 'widgets/app_review_prompt.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  String? _lastSessionUserId;
  bool _launchStateLoaded = false;
  bool _preAuthOnboardingComplete = false;
  bool _showSignUp = false;
  final Set<String> _completedInitialOfferUserIds = {};
  final Map<String, Future<bool>> _initialOfferChecks = {};
  late final StreamSubscription<AuthState> _authSubscription;
  String? _subscriptionUserId;
  Future<void> _subscriptionSync = Future<void>.value();

  @override
  void initState() {
    super.initState();
    unawaited(_loadLaunchState());
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen(
      (data) {
        final session = data.session;
        if (session != null) {
          FcmService().registerToken(session.user.id);
        } else {
          FcmService().deleteToken();
        }
        unawaited(_syncSubscriptionUser(session?.user.id));
      },
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('Supabase auth state network error: $error');
      },
    );
    unawaited(
      _syncSubscriptionUser(
        Supabase.instance.client.auth.currentSession?.user.id,
      ),
    );
  }

  Future<void> _loadLaunchState() async {
    final complete = await OnboardingPage.isComplete();
    if (!mounted) return;
    setState(() {
      _preAuthOnboardingComplete = complete;
      _launchStateLoaded = true;
    });
  }

  void _completePreAuthOnboarding({required bool showSignUp}) {
    setState(() {
      _preAuthOnboardingComplete = true;
      _showSignUp = showSignUp;
    });
  }

  Future<void> _replayPreAuthOnboarding() async {
    await OnboardingPage.restart();
    if (!mounted) return;
    setState(() {
      _preAuthOnboardingComplete = false;
      _showSignUp = false;
    });
  }

  Future<bool> _initialOfferComplete(String userId) {
    return _initialOfferChecks.putIfAbsent(
      userId,
      () => InitialOfferPage.isComplete(userId),
    );
  }

  Widget _postAuthDestination(String userId) {
    if (_completedInitialOfferUserIds.contains(userId)) {
      return _animatedDestination(
        'main:$userId',
        const AppReviewPrompt(child: MainScaffold()),
      );
    }
    return FutureBuilder<bool>(
      future: _initialOfferComplete(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _animatedDestination(
            'offer-loading:$userId',
            const LoadingScreen(),
          );
        }
        if (snapshot.data!) {
          return _animatedDestination(
            'main:$userId',
            const AppReviewPrompt(child: MainScaffold()),
          );
        }
        return _animatedDestination(
          'initial-offer:$userId',
          InitialOfferPage(
            userId: userId,
            onComplete: () {
              setState(() {
                _completedInitialOfferUserIds.add(userId);
                _initialOfferChecks[userId] = Future<bool>.value(true);
              });
            },
          ),
        );
      },
    );
  }

  Future<void> _syncSubscriptionUser(String? userId) async {
    if (_subscriptionUserId == userId) return _subscriptionSync;
    final previousUserId = _subscriptionUserId;
    _subscriptionUserId = userId;
    _subscriptionSync = _subscriptionSync.then((_) async {
      if (previousUserId != null && previousUserId != userId) {
        await SubscriptionService().logOutUser();
      }
      if (userId != null) {
        await SubscriptionService().logInUser(userId);
      }
    });
    return _subscriptionSync;
  }

  Widget _animatedDestination(String destinationKey, Widget child) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 520),
      reverseDuration: const Duration(milliseconds: 320),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        final slide = Tween<Offset>(
          begin: const Offset(0, 0.025),
          end: Offset.zero,
        ).animate(animation);
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: slide, child: child),
        );
      },
      child: KeyedSubtree(key: ValueKey(destinationKey), child: child),
    );
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_launchStateLoaded) {
      return _animatedDestination('launch-loading', const LoadingScreen());
    }
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      initialData: AuthState(
        AuthChangeEvent.initialSession,
        Supabase.instance.client.auth.currentSession,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _animatedDestination('loading', const LoadingScreen());
        }

        final session = snapshot.hasData ? snapshot.data!.session : null;
        final event = snapshot.hasData ? snapshot.data!.event : null;

        if (event == AuthChangeEvent.passwordRecovery) {
          return _animatedDestination(
            'password-recovery',
            const ResetPasswordPage(),
          );
        }

        if (session != null) {
          final userId = session.user.id;
          if (event == AuthChangeEvent.signedIn &&
              _lastSessionUserId != userId) {
            _lastSessionUserId = userId;
            AutoWalkthrough.resetForLogin();
          } else {
            _lastSessionUserId = userId;
          }
          final assurance = Supabase.instance.client.auth.mfa
              .getAuthenticatorAssuranceLevel();
          if (assurance.currentLevel == AuthenticatorAssuranceLevels.aal1 &&
              assurance.nextLevel == AuthenticatorAssuranceLevels.aal2) {
            return _animatedDestination(
              'mfa:$userId',
              const MfaChallengePage(),
            );
          }
          return _postAuthDestination(userId);
        } else {
          if (_lastSessionUserId != null) {
            _showSignUp = false;
          }
          _lastSessionUserId = null;
          AutoWalkthrough.disableUntilNextLogin();
          if (!_preAuthOnboardingComplete) {
            return _animatedDestination(
              'pre-auth-onboarding',
              OnboardingPage(
                onComplete: () => _completePreAuthOnboarding(showSignUp: true),
                onSkip: () => _completePreAuthOnboarding(showSignUp: false),
              ),
            );
          }
          return _animatedDestination(
            _showSignUp ? 'signup' : 'login',
            LoginPage(
              initialSignUp: _showSignUp,
              onExploreAblerite: () => unawaited(_replayPreAuthOnboarding()),
            ),
          );
        }
      },
    );
  }
}
