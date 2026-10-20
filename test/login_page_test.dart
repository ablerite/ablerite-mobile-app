import 'package:ableritemobile/ui/login_page.dart';
import 'package:ableritemobile/services/auth_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  setUpAll(() async {
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      anonKey: 'test-anon-key',
      authOptions: const FlutterAuthClientOptions(
        localStorage: EmptyLocalStorage(),
        detectSessionInUri: false,
        pkceAsyncStorage: _MemoryAsyncStorage(),
      ),
    );
  });

  testWidgets('Google auth is displayed directly below Apple on iOS', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    try {
      await tester.pumpWidget(const MaterialApp(home: LoginPage()));
      await tester.pump();

      final appleButton = find.byType(SignInWithAppleButton);
      final googleButton = find.byKey(const Key('google-sign-in-button'));

      expect(appleButton, findsOneWidget);
      expect(googleButton, findsOneWidget);
      expect(find.text('Sign in with Google'), findsOneWidget);
      expect(
        tester.getTopLeft(googleButton).dy,
        greaterThan(tester.getTopLeft(appleButton).dy),
      );
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('Google auth is available for account creation', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    try {
      await tester.pumpWidget(
        const MaterialApp(home: LoginPage(initialSignUp: true)),
      );
      await tester.pump();

      expect(find.text('Sign up with Google'), findsOneWidget);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('authentication offers a way to replay onboarding', (
    tester,
  ) async {
    var explored = false;

    await tester.pumpWidget(
      MaterialApp(home: LoginPage(onExploreAblerite: () => explored = true)),
    );
    await tester.pump();

    final exploreButton = find.byKey(const Key('explore-ablerite-button'));
    final forgotPassword = find.text('Forgot password?');

    await tester.ensureVisible(exploreButton);
    await tester.pump();

    expect(
      tester.getCenter(exploreButton).dx,
      lessThan(tester.getCenter(forgotPassword).dx),
    );
    expect(
      (tester.getCenter(exploreButton).dy - tester.getCenter(forgotPassword).dy)
          .abs(),
      lessThan(2),
    );

    await tester.tap(exploreButton);

    expect(find.text('Explore Ablerite'), findsOneWidget);
    expect(explored, isTrue);
  });

  testWidgets('offline email login shows the custom connectivity message', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: LoginPage(authService: _OfflineAuthService())),
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'person@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'password123',
    );

    await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
    await tester.pump();

    expect(
      find.text('Connect to Wi-Fi or a cellular network to log in.'),
      findsOneWidget,
    );
    expect(find.textContaining('AuthRetryableFetchException'), findsNothing);
  });
}

class _OfflineAuthService extends AuthService {
  @override
  Future<AuthResponse> signInWithEmailPassword({
    required String email,
    required String password,
  }) {
    throw AuthRetryableFetchException(
      message: 'SocketException: Failed host lookup',
    );
  }
}

class _MemoryAsyncStorage extends GotrueAsyncStorage {
  const _MemoryAsyncStorage();

  static final Map<String, String> _values = {};

  @override
  Future<String?> getItem({required String key}) async => _values[key];

  @override
  Future<void> removeItem({required String key}) async {
    _values.remove(key);
  }

  @override
  Future<void> setItem({required String key, required String value}) async {
    _values[key] = value;
  }
}
