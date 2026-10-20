import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static const String socialAuthRedirect =
      'com.senrama.ablerite://auth-callback';

  final SupabaseClient _supabase = Supabase.instance.client;

  // Stream to listen to auth state changes
  Stream<AuthState> get onAuthStateChange => _supabase.auth.onAuthStateChange;

  // Get current session
  Session? get currentSession => _supabase.auth.currentSession;

  // Sign in with email and password
  Future<AuthResponse> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // Sign up with email and password
  Future<AuthResponse> signUpWithEmailPassword({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signUp(email: email, password: password);
  }

  Future<AuthResponse> signInWithApple() async {
    final rawNonce = _supabase.auth.generateRawNonce();
    final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: const [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: hashedNonce,
    );

    final idToken = credential.identityToken;
    if (idToken == null) {
      throw const AuthException(
        'Apple did not return an identity token. Please try again.',
      );
    }

    final response = await _supabase.auth.signInWithIdToken(
      provider: OAuthProvider.apple,
      idToken: idToken,
      nonce: rawNonce,
    );

    // Apple supplies the name only on the first authorization, so persist it
    // immediately for subsequent sessions.
    final givenName = credential.givenName?.trim();
    final familyName = credential.familyName?.trim();
    final fullName = [
      if (givenName != null && givenName.isNotEmpty) givenName,
      if (familyName != null && familyName.isNotEmpty) familyName,
    ].join(' ');

    if (fullName.isNotEmpty) {
      await _supabase.auth.updateUser(
        UserAttributes(
          data: {
            'full_name': fullName,
            if (givenName != null && givenName.isNotEmpty)
              'given_name': givenName,
            if (familyName != null && familyName.isNotEmpty)
              'family_name': familyName,
          },
        ),
      );
    }

    return response;
  }

  Future<void> signInWithGoogle() async {
    final launched = await _supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: socialAuthRedirect,
      authScreenLaunchMode: LaunchMode.externalApplication,
    );

    if (!launched) {
      throw const AuthException(
        'Could not open Google sign-in. Please try again.',
      );
    }
  }

  Future<void> sendPasswordResetEmail({
    required String email,
    required String redirectTo,
  }) async {
    await _supabase.auth.resetPasswordForEmail(email, redirectTo: redirectTo);
  }

  Future<void> updatePassword(String password) async {
    await _supabase.auth.updateUser(UserAttributes(password: password));
  }

  /// Permanently deletes the signed-in user's account and server-side data.
  ///
  /// The privileged deletion runs in an authenticated Edge Function so the
  /// service-role key is never exposed to the app.
  Future<void> deleteAccount() async {
    if (_supabase.auth.currentSession == null) {
      throw const AuthException(
        'Your session has expired. Please sign in again to delete your account.',
      );
    }

    final response = await _supabase.functions.invoke(
      'delete-account',
      body: const {'confirmation': 'DELETE'},
    );

    final data = response.data;
    if (response.status != 200 || data is! Map || data['deleted'] != true) {
      final message = data is Map && data['error'] is String
          ? data['error'] as String
          : 'Account deletion could not be completed. Please try again.';
      throw AuthException(message);
    }

    // The server has removed the Auth user and revoked refresh sessions.
    // Clear the persisted local JWT immediately instead of waiting for expiry.
    await _supabase.auth.signOut(scope: SignOutScope.local);
  }

  // Sign out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}
