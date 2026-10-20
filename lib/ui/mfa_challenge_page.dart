import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_messenger.dart';
import 'widgets/ablerite_loading_indicator.dart';

class MfaChallengePage extends StatefulWidget {
  const MfaChallengePage({super.key});

  @override
  State<MfaChallengePage> createState() => _MfaChallengePageState();
}

class _MfaChallengePageState extends State<MfaChallengePage> {
  final _codeController = TextEditingController();
  String? _factorId;
  String? _error;
  bool _loadingFactor = true;
  bool _submitting = false;
  bool _useRecoveryCode = false;

  SupabaseClient get _client => Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _loadFactor();
  }

  Future<void> _loadFactor() async {
    try {
      final factors = await _client.auth.mfa.listFactors();
      if (!mounted) return;
      if (factors.totp.isEmpty) {
        setState(() {
          _error =
              'No verified authenticator was found. Sign out and contact support if this continues.';
          _loadingFactor = false;
        });
        return;
      }
      setState(() {
        _factorId = factors.totp.first.id;
        _loadingFactor = false;
      });
    } on AuthException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _loadingFactor = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load your authenticator. Please try again.';
        _loadingFactor = false;
      });
    }
  }

  Future<void> _verifyAuthenticator() async {
    final code = _codeController.text.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(code) || _factorId == null) {
      setState(
        () => _error = 'Enter the six-digit code from your authenticator app.',
      );
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await _client.auth.mfa.challengeAndVerify(
        factorId: _factorId!,
        code: code,
      );
      _codeController.clear();
      // Verification refreshes the session and AuthGate advances automatically.
    } on AuthException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'That code could not be verified. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _functionError(FunctionException error) {
    final details = error.details;
    if (details is Map && details['error'] is String) {
      return details['error'] as String;
    }
    return 'That recovery code could not be used.';
  }

  Future<void> _recoverMfa() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() => _error = 'Enter one of your saved recovery codes.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await _client.functions.invoke(
        'mfa-recovery',
        body: {'action': 'recover', 'code': code},
      );
      await _client.auth.signOut(scope: SignOutScope.local);
      showAppSnackBar(
        const SnackBar(
          content: Text(
            'Recovery code accepted. Sign in again, then set up a new authenticator from the desktop app.',
          ),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    } on FunctionException catch (error) {
      if (mounted) setState(() => _error = _functionError(error));
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'That recovery code could not be used.');
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _switchMode() {
    setState(() {
      _useRecoveryCode = !_useRecoveryCode;
      _codeController.clear();
      _error = null;
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTablet = MediaQuery.sizeOf(context).shortestSide >= 600;

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Image.asset('assets/ablerite_logo_rounded.png', height: 90),
        const SizedBox(height: 24),
        Icon(
          _useRecoveryCode ? Icons.key_rounded : Icons.security_rounded,
          size: 42,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 16),
        Text(
          'Security verification',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _useRecoveryCode
              ? 'Use one of the recovery codes you saved when enabling MFA.'
              : 'Enter the six-digit code from your authenticator app.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: theme.colorScheme.onSurface.withAlpha(160),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 28),
        TextField(
          controller: _codeController,
          enabled: !_submitting && !_loadingFactor,
          autofocus: true,
          keyboardType: _useRecoveryCode
              ? TextInputType.text
              : TextInputType.number,
          textCapitalization: _useRecoveryCode
              ? TextCapitalization.characters
              : TextCapitalization.none,
          inputFormatters: _useRecoveryCode
              ? [LengthLimitingTextInputFormatter(40)]
              : [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
          textAlign: TextAlign.center,
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontFamily: 'monospace',
            fontSize: 18,
            letterSpacing: _useRecoveryCode ? 0.8 : 6,
          ),
          decoration: InputDecoration(
            hintText: _useRecoveryCode ? 'ABLR-XXXX-XXXX-XXXX-XXXX' : '000000',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onSubmitted: (_) =>
              _useRecoveryCode ? _recoverMfa() : _verifyAuthenticator(),
        ),
        if (_error != null) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              _error!,
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
        const SizedBox(height: 20),
        SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: _submitting || _loadingFactor
                ? null
                : _useRecoveryCode
                ? _recoverMfa
                : _verifyAuthenticator,
            child: _submitting || _loadingFactor
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: AbleriteLoadingIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    _useRecoveryCode
                        ? 'Use recovery code'
                        : 'Verify and continue',
                  ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: _submitting ? null : _switchMode,
          icon: Icon(
            _useRecoveryCode ? Icons.arrow_back_rounded : Icons.key_rounded,
            size: 18,
          ),
          label: Text(
            _useRecoveryCode
                ? 'Back to authenticator code'
                : 'Lost your authenticator? Use a recovery code',
          ),
        ),
        TextButton.icon(
          onPressed: _submitting ? null : () => _client.auth.signOut(),
          icon: const Icon(Icons.logout_rounded, size: 18),
          label: const Text('Sign out'),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: isTablet
                  ? Container(
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: theme.dividerColor.withAlpha(45),
                        ),
                      ),
                      child: content,
                    )
                  : content,
            ),
          ),
        ),
      ),
    );
  }
}
