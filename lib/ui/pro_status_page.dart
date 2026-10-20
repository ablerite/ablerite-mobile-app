import 'dart:async';

import 'package:flutter/material.dart';
import 'widgets/ablerite_loading_indicator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../services/subscription_service.dart';

class ProStatusPage extends StatefulWidget {
  final Future<void> Function()? deleteAccount;

  const ProStatusPage({super.key, this.deleteAccount});

  @override
  State<ProStatusPage> createState() => _ProStatusPageState();
}

class _ProStatusPageState extends State<ProStatusPage> {
  bool _isRestoring = false;
  bool _isDeletingAccount = false;

  Future<void> _openSubscriptionManagement() async {
    final outcome = await SubscriptionService().manageSubscription();
    if (!mounted) return;
    switch (outcome) {
      case SubscriptionManagementOutcome.openedStore:
        return;
      case SubscriptionManagementOutcome.unavailable:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Subscription management is unavailable. Try restoring purchases, then try again.',
            ),
          ),
        );
    }
  }

  Future<void> _handleRestore() async {
    setState(() => _isRestoring = true);
    try {
      await SubscriptionService().restorePurchases();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Purchases restored successfully!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to restore: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isRestoring = false);
    }
  }

  Future<void> _showDeleteAccountConfirmation() async {
    if (_isDeletingAccount) return;

    final shouldContinue = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        scrollable: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
        icon: const Icon(Icons.warning_amber_rounded, color: Colors.red),
        title: Text(
          'Delete Account?',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        content: Text(
          'This permanently deletes your Ablerite account and all data '
          'associated with it. This cannot be undone.\n\n'
          'Deleting your account does not cancel an active App Store or '
          'Google Play subscription. Manage your subscription first if '
          'you want to stop future renewals.',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withAlpha(190),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (shouldContinue != true || !mounted) return;

    final dialogDismissed = Completer<void>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _DeleteAccountConfirmationDialog(
        onDisposed: () {
          if (!dialogDismissed.isCompleted) dialogDismissed.complete();
        },
      ),
    );
    if (confirmed != true || !mounted) return;

    // showDialog completes when Navigator.pop is called, before its reverse
    // animation has removed the overlay. Wait for the dialog's actual disposal
    // before signOut replaces the authenticated widget tree.
    await dialogDismissed.future;
    if (!mounted) return;

    setState(() => _isDeletingAccount = true);
    try {
      await (widget.deleteAccount ?? AuthService().deleteAccount)();
      // AuthGate responds to the signed-out event and returns to login.
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is AuthException
                ? error.message
                : 'Account deletion could not be completed. Please try again.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isDeletingAccount = false);
    }
  }

  void _showDowngradeInfo() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Switching to Free Tier',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'By downgrading to the Free tier, you will lose access to:',
              style: GoogleFonts.outfit(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            _buildLossItem('Advanced Goal Management'),
            _buildLossItem('Unlimited AI Coaching Conversations'),
            _buildLossItem('Exclusive Daily Insights & Wisdom'),
            _buildLossItem('Custom Affirmation Generation'),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _openSubscriptionManagement();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Manage & Downgrade',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Keep My Pro Status',
                  style: GoogleFonts.outfit(color: const Color(0xFF10B981)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLossItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          const Icon(Icons.close, color: Colors.red, size: 16),
          const SizedBox(width: 12),
          Text(text, style: GoogleFonts.outfit(fontSize: 14)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPro = SubscriptionService().isPro;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Account Options',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Status Header
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF10B981),
                    const Color(0xFF10B981).withAlpha(150),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withAlpha(60),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(
                    CupertinoIcons.star_fill,
                    color: Colors.white,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isPro ? 'Ablerite Pro Active' : 'Free Account',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isPro
                        ? 'Thank you for being a Pro member!'
                        : 'Manage your account or explore Pro plans',
                    style: GoogleFonts.outfit(
                      color: Colors.white.withAlpha(200),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Management Section
            if (isPro) ...[
              _buildActionCard(
                title: 'Plan Details',
                subtitle: SubscriptionService().activePlanDescription,
                icon: CupertinoIcons.info_circle,
                onTap: null, // Static info card
                trailing: const SizedBox.shrink(),
              ),
              const SizedBox(height: 16),
              _buildActionCard(
                title: 'Manage Subscription',
                subtitle: 'Open billing and membership options',
                icon: CupertinoIcons.creditcard,
                onTap: () async {
                  await _openSubscriptionManagement();
                  if (mounted) setState(() {});
                },
              ),
              const SizedBox(height: 16),
              _buildActionCard(
                title: 'Restore Purchases',
                subtitle: 'Recover your Pro status',
                icon: CupertinoIcons.refresh,
                onTap: _isRestoring ? null : _handleRestore,
                trailing: _isRestoring
                    ? const AbleriteLoadingIndicator()
                    : null,
              ),
              const SizedBox(height: 16),
              _buildActionCard(
                title: 'Switch to Free Tier',
                subtitle: 'Cancel subscription and return to free',
                icon: CupertinoIcons.arrow_2_circlepath,
                onTap: _showDowngradeInfo,
              ),
            ] else ...[
              _buildActionCard(
                title: 'View Pro Plans',
                subtitle: 'Unlock all features today',
                icon: CupertinoIcons.sparkles,
                onTap: () async {
                  await SubscriptionService().showPaywallIfNeeded(
                    context: context,
                  );
                  if (mounted) setState(() {});
                },
              ),
              const SizedBox(height: 16),
              _buildActionCard(
                title: 'Restore Purchases',
                subtitle: 'Already a Pro member?',
                icon: CupertinoIcons.refresh,
                onTap: _isRestoring ? null : _handleRestore,
                trailing: _isRestoring
                    ? const AbleriteLoadingIndicator()
                    : null,
              ),
            ],
            const SizedBox(height: 16),
            _buildActionCard(
              title: 'Delete Account',
              subtitle: _isDeletingAccount
                  ? 'Permanently deleting your account...'
                  : 'Permanently delete your account and data',
              icon: CupertinoIcons.delete,
              color: Colors.red,
              onTap: _isDeletingAccount ? null : _showDeleteAccountConfirmation,
              trailing: _isDeletingAccount
                  ? const SizedBox.square(
                      dimension: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.red,
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback? onTap,
    Widget? trailing,
    Color? color,
  }) {
    final iconColor = color ?? const Color(0xFF10B981);
    return Material(
      color: Theme.of(context).colorScheme.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).dividerColor.withAlpha(20)),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: iconColor),
        title: Text(
          title,
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: color),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey),
        ),
        trailing: trailing ?? const Icon(Icons.chevron_right, size: 20),
      ),
    );
  }
}

class _DeleteAccountConfirmationDialog extends StatefulWidget {
  final VoidCallback onDisposed;

  const _DeleteAccountConfirmationDialog({required this.onDisposed});

  @override
  State<_DeleteAccountConfirmationDialog> createState() =>
      _DeleteAccountConfirmationDialogState();
}

class _DeleteAccountConfirmationDialogState
    extends State<_DeleteAccountConfirmationDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    widget.onDisposed();
    super.dispose();
  }

  void _confirm() {
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      title: Text(
        'Confirm Account Deletion',
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Type DELETE to permanently delete your account.'),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            autocorrect: false,
            enableSuggestions: false,
            decoration: const InputDecoration(
              labelText: 'Confirmation',
              hintText: 'DELETE',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) {
              if (_controller.text.trim() == 'DELETE') _confirm();
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _controller.text.trim() == 'DELETE' ? _confirm : null,
          style: FilledButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text('Delete Account'),
        ),
      ],
    );
  }
}
