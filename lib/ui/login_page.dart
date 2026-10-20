import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'widgets/ablerite_loading_indicator.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import 'app_messenger.dart';
import 'auth_error_message.dart';

class LoginPage extends StatefulWidget {
  final bool initialSignUp;
  final VoidCallback? onExploreAblerite;
  final AuthService? authService;

  const LoginPage({
    super.key,
    this.initialSignUp = false,
    this.onExploreAblerite,
    this.authService,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  static const String _passwordResetRedirect =
      'com.senrama.ablerite://reset-password';

  late final AuthService _authService;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  late bool _isSignUp;
  bool _isPasswordResetMode = false;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
    _isSignUp = widget.initialSignUp;
  }

  void _showAuthError(Object error, {required String fallback}) {
    if (!mounted) return;
    showAppSnackBar(
      SnackBar(
        content: Text(authErrorMessage(error, fallback: fallback)),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _signInWithApple() async {
    setState(() => _isLoading = true);

    try {
      await _authService.signInWithApple();
      // AuthGate observes the new Supabase session and handles navigation.
    } on SignInWithAppleAuthorizationException catch (error) {
      if (!mounted || error.code == AuthorizationErrorCode.canceled) return;
      _showAuthError(
        error,
        fallback: 'Could not sign in with Apple. Please try again.',
      );
    } on AuthException catch (error) {
      _showAuthError(
        error,
        fallback: 'Could not sign in with Apple. Please try again.',
      );
    } catch (error) {
      _showAuthError(
        error,
        fallback: 'Could not sign in with Apple. Please try again.',
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      await _authService.signInWithGoogle();
      // Supabase restores the session from the auth-callback deep link.
      // AuthGate observes that session and handles navigation.
    } on AuthException catch (error) {
      _showAuthError(
        error,
        fallback: 'Could not sign in with Google. Please try again.',
      );
    } catch (error) {
      _showAuthError(
        error,
        fallback: 'Could not sign in with Google. Please try again.',
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _googleSignInButton(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: 50,
      child: OutlinedButton(
        key: const Key('google-sign-in-button'),
        onPressed: _isLoading ? null : _signInWithGoogle,
        style: OutlinedButton.styleFrom(
          backgroundColor: isDark
              ? const Color(0xFF131314)
              : const Color(0xFFFFFFFF),
          foregroundColor: isDark
              ? const Color(0xFFE3E3E3)
              : const Color(0xFF1F1F1F),
          disabledBackgroundColor: isDark
              ? const Color(0xFF131314)
              : const Color(0xFFFFFFFF),
          disabledForegroundColor: isDark
              ? const Color(0xFFE3E3E3)
              : const Color(0xFF1F1F1F),
          side: BorderSide(
            color: isDark ? const Color(0xFF8E918F) : const Color(0xFF747775),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/google_g_logo.png',
              width: 20,
              height: 20,
              semanticLabel: 'Google',
            ),
            const SizedBox(width: 12),
            Text(
              _isSignUp ? 'Sign up with Google' : 'Sign in with Google',
              style: const TextStyle(
                fontSize: 14,
                height: 20 / 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendPasswordResetEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      showAppSnackBar(
        const SnackBar(
          content: Text('Enter a valid email address.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _authService.sendPasswordResetEmail(
        email: email,
        redirectTo: _passwordResetRedirect,
      );
      if (!mounted) return;
      showAppSnackBar(
        const SnackBar(
          content: Text('Password reset email sent. Check your inbox.'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
      setState(() => _isPasswordResetMode = false);
    } on AuthException catch (error) {
      _showAuthError(error, fallback: 'Could not send reset email.');
    } catch (error) {
      _showAuthError(error, fallback: 'Could not send reset email.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submit() async {
    if (_isPasswordResetMode) {
      await _sendPasswordResetEmail();
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      if (_isSignUp) {
        await _authService.signUpWithEmailPassword(
          email: email,
          password: password,
        );
        await _authService.signOut();
        if (mounted) {
          setState(() {
            _isSignUp = false;
            _passwordController.clear();
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Account created! Please check your email to confirm.',
              ),
              backgroundColor: Color(0xFF10B981),
            ),
          );
        }
      } else {
        await _authService.signInWithEmailPassword(
          email: email,
          password: password,
        );
        // No need to navigate manually; AuthGate handles it.
      }
    } on AuthException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              authErrorMessage(
                error,
                fallback:
                    'Could not complete authentication. Please try again.',
              ),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              authErrorMessage(
                error,
                fallback:
                    'Could not complete authentication. Please try again.',
              ),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.sizeOf(context).shortestSide >= 600;
    final isNativeMobile =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.android);
    final form = Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Image.asset('assets/ablerite_logo_rounded.png', height: 100),
          const SizedBox(height: 24),
          Text(
            _isPasswordResetMode
                ? 'Reset Password'
                : _isSignUp
                ? 'Create Account'
                : 'Welcome Back',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isPasswordResetMode
                ? 'Enter your email and we will send a reset link.'
                : _isSignUp
                ? 'Sign up to start using Ablerite'
                : 'Sign in to continue to Ablerite',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
            ),
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _emailController,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              return null;
            },
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            decoration: InputDecoration(
              labelText: 'Email',
              prefixIcon: const Icon(Icons.email_outlined, color: Colors.grey),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context).dividerColor.withAlpha(40),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          if (!_isPasswordResetMode) ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your password';
                }
                if (_isSignUp && value.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
              obscureText: true,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outlined, color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).dividerColor.withAlpha(40),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: AbleriteLoadingIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      _isPasswordResetMode
                          ? 'Send Reset Link'
                          : _isSignUp
                          ? 'Sign Up'
                          : 'Login',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          if (isNativeMobile && !_isPasswordResetMode) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: Divider(color: Theme.of(context).dividerColor)),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('or', style: TextStyle(color: Colors.grey)),
                ),
                Expanded(child: Divider(color: Theme.of(context).dividerColor)),
              ],
            ),
            const SizedBox(height: 16),
            if (defaultTargetPlatform == TargetPlatform.iOS) ...[
              SizedBox(
                height: 50,
                child: SignInWithAppleButton(
                  onPressed: _isLoading ? null : _signInWithApple,
                  borderRadius: const BorderRadius.all(Radius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
            ],
            _googleSignInButton(context),
          ],
          const SizedBox(height: 16),
          if (!_isPasswordResetMode) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: widget.onExploreAblerite == null
                        ? const SizedBox.shrink()
                        : TextButton(
                            key: const Key('explore-ablerite-button'),
                            onPressed: _isLoading
                                ? null
                                : widget.onExploreAblerite,
                            child: const Text('Explore Ablerite'),
                          ),
                  ),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: _isSignUp
                        ? const SizedBox.shrink()
                        : TextButton(
                            onPressed: _isLoading
                                ? null
                                : () {
                                    setState(() => _isPasswordResetMode = true);
                                  },
                            child: Text(
                              'Forgot password?',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
          ],
          TextButton(
            onPressed: () {
              setState(() {
                if (_isPasswordResetMode) {
                  _isPasswordResetMode = false;
                } else {
                  _isSignUp = !_isSignUp;
                }
              });
            },
            child: Text(
              _isPasswordResetMode
                  ? 'Back to Login'
                  : _isSignUp
                  ? 'Already have an account? Login'
                  : "Don't have an account? Sign Up",
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: isTablet
              ? ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Container(
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: Theme.of(context).dividerColor.withAlpha(45),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(18),
                          blurRadius: 36,
                          offset: const Offset(0, 16),
                        ),
                      ],
                    ),
                    child: form,
                  ),
                )
              : form,
        ),
      ),
    );
  }
}
