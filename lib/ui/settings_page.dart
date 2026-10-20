import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/currency_service.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../services/navigation_service.dart';
import '../services/subscription_service.dart';
import 'legal_pages.dart';
import 'pro_status_page.dart';
import 'widgets/auto_walkthrough.dart';
import 'widgets/ambient_focus_overlay.dart';
import 'widgets/focus_mode_nav_bar.dart';
import 'widgets/overview_mode_nav_bar.dart';
import 'widgets/spotlight_walkthrough.dart';

class SettingsPage extends StatefulWidget {
  final bool focusMode;
  final VoidCallback? onOpenAi;
  final Future<bool> Function(BuildContext context)? onOpenApps;
  final VoidCallback? onOpenCalendar;

  const SettingsPage({
    super.key,
    this.focusMode = false,
    this.onOpenAi,
    this.onOpenApps,
    this.onOpenCalendar,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  static const String _shareText =
      "Hey i'm reaching my goals with Ablerite join me on the journey to success.\n\nhttps://www.ablerite.com";
  static const List<AppThemeChoice> _themeDisplayOrder = [
    AppThemeChoice.lake,
    AppThemeChoice.slate,
    AppThemeChoice.white,
    AppThemeChoice.black,
  ];

  String _selectedCurrency = 'USD';
  String _fullName = '';
  PreferredHomeTarget? _pendingHomeTarget;
  late bool _displayFocusMode;
  bool _hidHostBottomNavigation = false;
  final GlobalKey _profileKey = GlobalKey();
  final GlobalKey _membershipKey = GlobalKey();
  final GlobalKey _textSizeKey = GlobalKey();
  final GlobalKey _darkModeKey = GlobalKey();
  final GlobalKey _homeScreenKey = GlobalKey();
  final GlobalKey _inviteKey = GlobalKey();
  final GlobalKey _currencyKey = GlobalKey();
  final GlobalKey _appInfoKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _displayFocusMode = widget.focusMode;
    _loadCurrency();
    _loadUserName();
  }

  @override
  void dispose() {
    if (_hidHostBottomNavigation &&
        _pendingHomeTarget != PreferredHomeTarget.focus) {
      bottomNavVisibleNotifier.value = true;
    }
    super.dispose();
  }

  Future<void> _loadUserName() async {
    final user = Supabase.instance.client.auth.currentUser;
    setState(() {
      _fullName = user?.userMetadata?['full_name'] ?? '';
    });
  }

  Future<void> _saveFullName() async {
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(data: {'full_name': _fullName}),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Name saved!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving name: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showEditNameDialog() {
    final controller = TextEditingController(text: _fullName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          'Edit Name',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          decoration: InputDecoration(
            hintText: 'Enter your full name',
            hintStyle: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withAlpha(120),
            ),
            filled: true,
            fillColor: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withAlpha(50),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
          onChanged: (value) => _fullName = value,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _saveFullName();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          'Log Out',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        content: Text(
          'Are you sure you want to log out?',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withAlpha(180),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await Supabase.instance.client.auth.signOut();
              if (!mounted) return;
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadCurrency() async {
    final currency = await CurrencyService.fetchFromSupabase();
    if (mounted) {
      setState(() => _selectedCurrency = currency);
    }
  }

  IconData _themeIcon(AppThemeChoice choice) {
    switch (choice) {
      case AppThemeChoice.white:
        return Icons.light_mode;
      case AppThemeChoice.black:
        return Icons.dark_mode;
      case AppThemeChoice.lake:
        return Icons.landscape_outlined;
      case AppThemeChoice.slate:
        return Icons.layers_outlined;
    }
  }

  String _themeDescription(AppThemeChoice choice) {
    switch (choice) {
      case AppThemeChoice.white:
        return 'Clean bright white Ablerite theme.';
      case AppThemeChoice.black:
        return 'Layered black and grey Ablerite theme.';
      case AppThemeChoice.lake:
        return 'Forest green, deep teal, aqua, stone, and mist.';
      case AppThemeChoice.slate:
        return 'Near-black slate with muted blue, teal, and mauve accents.';
    }
  }

  void _showThemeDialog(SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: Text(
            'Theme',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: _themeDisplayOrder.map((choice) {
                  final isSelected = settings.themeChoice == choice;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      _themeIcon(choice),
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: Text(
                      choice.label,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    subtitle: Text(
                      _themeDescription(choice),
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withAlpha(150),
                      ),
                    ),
                    trailing: Icon(
                      isSelected
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(
                              context,
                            ).colorScheme.onSurface.withAlpha(90),
                    ),
                    onTap: () async {
                      await settings.setThemeChoice(choice);
                      setDialogState(() {});
                    },
                  );
                }).toList(),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close', style: TextStyle(color: Colors.grey)),
            ),
          ],
        );
      },
    );
  }

  void _showHomeScreenDialog(SettingsProvider settings) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Choose your app layout'),
        contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _HomeScreenChoiceTile(
              icon: Icons.dashboard_outlined,
              title: 'Overview',
              badgeAsset: 'assets/guide_images/free_badge.png',
              description:
                  'The classic layout with Financial Overview, five section home screens, and standard bottom navigation.',
              selected: settings.homeScreenChoice == HomeScreenChoice.overview,
              onTap: () async {
                Navigator.pop(dialogContext);
                await settings.setHomeScreenChoice(HomeScreenChoice.overview);
                if (!mounted) return;
                if (_hidHostBottomNavigation) {
                  bottomNavVisibleNotifier.value = true;
                  _hidHostBottomNavigation = false;
                }
                setState(() {
                  _pendingHomeTarget = PreferredHomeTarget.overview;
                  _displayFocusMode = false;
                });
              },
            ),
            const SizedBox(height: 10),
            _HomeScreenChoiceTile(
              icon: Icons.wb_twilight_outlined,
              title: 'Power Focus',
              badgeAsset: 'assets/guide_images/pro_badge.png',
              description:
                  'A Pro focus-first layout with a wallpaper home, dedicated Focus navigation, and direct app shortcuts.',
              selected: settings.homeScreenChoice == HomeScreenChoice.focus,
              onTap: () async {
                final allowed = await SubscriptionService().showPaywallIfNeeded(
                  context: dialogContext,
                );
                if (!allowed || !dialogContext.mounted) return;
                Navigator.pop(dialogContext);
                await settings.setHomeScreenChoice(HomeScreenChoice.focus);
                if (!mounted) return;
                if (!widget.focusMode) {
                  bottomNavVisibleNotifier.value = false;
                  _hidHostBottomNavigation = true;
                }
                setState(() {
                  _pendingHomeTarget = PreferredHomeTarget.focus;
                  _displayFocusMode = true;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showTextSizeDialog(SettingsProvider settings) {
    var selectedScale = settings.textScaleFactor;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Text Size'),
          content: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest.withAlpha(90),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'This is how your app text will look.',
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('A', style: TextStyle(fontSize: 12)),
                    Expanded(
                      child: Slider(
                        value: selectedScale,
                        min: 0.8,
                        max: 2.0,
                        divisions: 12,
                        label: '${selectedScale.toStringAsFixed(1)}x',
                        onChanged: (value) {
                          setDialogState(() => selectedScale = value);
                          settings.setTextScaleFactor(value);
                        },
                      ),
                    ),
                    const Text('A', style: TextStyle(fontSize: 22)),
                  ],
                ),
                Text(
                  '${selectedScale.toStringAsFixed(1)}x',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareInvite() async {
    await SharePlus.instance.share(
      ShareParams(
        title: 'Ablerite',
        subject: 'Join me on Ablerite',
        text: _shareText,
      ),
    );
  }

  void _showSettingsWalkthrough() {
    SpotlightWalkthrough.show(context, steps: _walkthroughSteps);
  }

  void _showAppInfoDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Theme.of(dialogContext).colorScheme.surface,
        title: Text(
          'Ablerite Info',
          style: TextStyle(
            color: Theme.of(dialogContext).colorScheme.onSurface,
          ),
        ),
        content: Text(
          'Ablerite is your all-in-one system for managing life, work, and personal growth.\n\nVersion: 1.0.0',
          style: TextStyle(
            color: Theme.of(dialogContext).colorScheme.onSurface.withAlpha(180),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'OK',
              style: TextStyle(
                color: Theme.of(dialogContext).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAppInformationMenu() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Text(
              'App information',
              style: Theme.of(
                sheetContext,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('App info'),
            subtitle: const Text('About Ablerite and the current version'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.pop(sheetContext);
              _showAppInfoDialog();
            },
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Terms of Service'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.pop(sheetContext);
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const TermsOfServicePage(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.pop(sheetContext);
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const PrivacyPolicyPage(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  List<SpotlightStep> get _walkthroughSteps {
    return [
      SpotlightStep(
        targetKey: _profileKey,
        title: 'Profile',
        body:
            'Your account email appears here. Long press your name area to edit the display name used in the app.',
      ),
      SpotlightStep(
        targetKey: _membershipKey,
        title: 'Membership',
        body:
            'Manage your Ablerite Pro membership, restore purchases, or view available plans.',
      ),
      SpotlightStep(
        targetKey: _homeScreenKey,
        title: 'App Layout',
        body:
            'Choose the classic Overview navigation or the Pro Power Focus layout.',
      ),
      SpotlightStep(
        targetKey: _darkModeKey,
        title: 'Theme',
        body:
            'Switch between White, Black, Lake, and Slate colour schemes for the app.',
      ),
      SpotlightStep(
        targetKey: _textSizeKey,
        title: 'Text Size',
        body:
            'Use this slider to make app text smaller or larger across supported screens.',
      ),
      SpotlightStep(
        targetKey: _inviteKey,
        title: 'Invite Friends',
        body: 'Share Ablerite with someone else using your email app.',
      ),
      SpotlightStep(
        targetKey: _currencyKey,
        title: 'Currency',
        body: 'Choose the currency symbol used across your financial pages.',
      ),
      SpotlightStep(
        targetKey: _appInfoKey,
        title: 'App Information',
        body:
            'Open app details, the Terms of Service, or the Privacy Policy from one menu.',
      ),
    ];
  }

  void _maybeAutoStartWalkthrough() {
    AutoWalkthrough.maybeShowOnce(
      context,
      id: 'settings',
      steps: _walkthroughSteps,
    );
  }

  void _leaveFocusSettings(VoidCallback? destination) {
    final selectedTarget = _pendingHomeTarget;
    if (selectedTarget != null) {
      Navigator.of(context).pop(selectedTarget);
      return;
    }
    Navigator.of(context).pop();
    if (destination != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => destination());
    }
  }

  Future<void> _openAppsOverFocusSettings() async {
    final openApps = widget.onOpenApps;
    if (openApps == null) {
      final shortcut = await showFocusShortcutDrawer(context);
      if (shortcut == null || !mounted) return;

      Navigator.of(
        context,
      ).pop(_pendingHomeTarget ?? PreferredHomeTarget.focus);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        requestFocusShortcut(shortcut.name);
      });
      return;
    }

    final launchedApp = await openApps(context);
    if (launchedApp && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _maybeAutoStartWalkthrough();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = Supabase.instance.client.auth.currentUser;
    final email = user?.email ?? 'No email found';
    final overviewPending = _pendingHomeTarget == PreferredHomeTarget.overview;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final heightScale = ((screenHeight - 667) / (932 - 667)).clamp(0.0, 1.0);
    final avatarRadius = 24.0 + (4.0 * heightScale);
    final profileTopSpacing = 2.0 + (4.0 * heightScale);
    final settingsTileDensity = -1.5 + heightScale;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) Navigator.of(context).pop(_pendingHomeTarget);
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: !_displayFocusMode,
          leading: _displayFocusMode
              ? null
              : BackButton(
                  onPressed: () =>
                      Navigator.of(context).pop(_pendingHomeTarget),
                ),
          title: const Text('Settings'),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
          actions: [
            IconButton(
              icon: const Icon(Icons.help_outline),
              tooltip: 'Settings walkthrough',
              onPressed: _showSettingsWalkthrough,
            ),
            IconButton(
              key: _inviteKey,
              icon: const Icon(Icons.person_add_alt_1_outlined),
              tooltip: 'Invite Friends',
              onPressed: _shareInvite,
            ),
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.red),
              tooltip: 'Log out',
              onPressed: _showLogoutConfirmation,
            ),
          ],
        ),
        bottomNavigationBar: _displayFocusMode
            ? FocusModeNavBar(
                homeIcon: overviewPending
                    ? Icons.dashboard_outlined
                    : Icons.center_focus_strong,
                homeLabel: overviewPending ? 'Overview Home' : 'Focus Home',
                onOpenAi: () => _leaveFocusSettings(widget.onOpenAi),
                onOpenApps: _openAppsOverFocusSettings,
                onOpenFocus: () => Navigator.of(
                  context,
                ).pop(_pendingHomeTarget ?? PreferredHomeTarget.focus),
                onOpenCalendar: () =>
                    _leaveFocusSettings(widget.onOpenCalendar),
                onOpenSettings: () {},
              )
            : widget.focusMode
            ? SafeArea(
                top: false,
                child: OverviewModeNavBar(
                  selectedIndex: 0,
                  onTap: (_) =>
                      Navigator.of(context).pop(PreferredHomeTarget.overview),
                ),
              )
            : null,
        body: ListTileTheme(
          data: ListTileTheme.of(context).copyWith(
            visualDensity: VisualDensity(vertical: settingsTileDensity),
          ),
          child: ListView(
            children: [
              SizedBox(height: profileTopSpacing),

              // Avatar with long press to edit name
              KeyedSubtree(
                key: _profileKey,
                child: GestureDetector(
                  onLongPress: _showEditNameDialog,
                  child: Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: avatarRadius,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary.withAlpha(20),
                          child: Text(
                            _fullName.isNotEmpty
                                ? _fullName[0].toUpperCase()
                                : (email.isNotEmpty
                                      ? email[0].toUpperCase()
                                      : '?'),
                            style: TextStyle(
                              fontSize: avatarRadius * 0.8,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _fullName.isNotEmpty
                              ? _fullName
                              : 'Long press to edit name',
                          style: TextStyle(
                            fontSize: 13,
                            color: _fullName.isNotEmpty
                                ? Theme.of(context).colorScheme.onSurface
                                : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 6),
              Center(
                child: Text(
                  email,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Divider(
                color: Theme.of(
                  context,
                ).dividerColor.withAlpha(isDark ? 40 : 80),
              ),

              ListTile(
                key: _membershipKey,
                leading: Icon(
                  Icons.workspace_premium_outlined,
                  color: isDark ? Colors.amberAccent : Colors.amber[800],
                ),
                title: Text(
                  'Account & Membership',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                subtitle: const Text(
                  'Manage your account and plan',
                  style: TextStyle(color: Colors.grey),
                ),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProStatusPage()),
                  );
                },
              ),
              Divider(
                color: Theme.of(
                  context,
                ).dividerColor.withAlpha(isDark ? 40 : 80),
              ),

              Consumer<SettingsProvider>(
                builder: (context, settings, child) {
                  return ListTile(
                    key: _homeScreenKey,
                    leading: Icon(
                      settings.homeScreenChoice == HomeScreenChoice.focus
                          ? Icons.wb_twilight_outlined
                          : Icons.dashboard_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: Text(
                      'App Layout',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    subtitle: Text(
                      '${settings.homeScreenChoice.label} layout selected',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: Colors.grey,
                    ),
                    onTap: () => _showHomeScreenDialog(settings),
                  );
                },
              ),
              Divider(
                color: Theme.of(
                  context,
                ).dividerColor.withAlpha(isDark ? 40 : 80),
              ),
              Consumer<SettingsProvider>(
                builder: (context, settings, child) {
                  return ListTile(
                    key: _darkModeKey,
                    leading: Icon(
                      _themeIcon(settings.themeChoice),
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: Text(
                      'Theme',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    subtitle: Text(
                      '${settings.themeChoice.label} theme',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: Colors.grey,
                    ),
                    onTap: () => _showThemeDialog(settings),
                  );
                },
              ),
              Divider(
                color: Theme.of(
                  context,
                ).dividerColor.withAlpha(isDark ? 40 : 80),
              ),
              Consumer<SettingsProvider>(
                builder: (context, settings, child) {
                  return ListTile(
                    key: _textSizeKey,
                    leading: Icon(
                      Icons.text_fields,
                      color: isDark ? Colors.orangeAccent : Colors.orange[800],
                    ),
                    title: Text(
                      'Text Size',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    subtitle: const Text(
                      'Adjust app text size',
                      style: TextStyle(color: Colors.grey),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${settings.textScaleFactor.toStringAsFixed(1)}x',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right, color: Colors.grey),
                      ],
                    ),
                    onTap: () => _showTextSizeDialog(settings),
                  );
                },
              ),
              Divider(
                color: Theme.of(
                  context,
                ).dividerColor.withAlpha(isDark ? 40 : 80),
              ),
              ListTile(
                key: _currencyKey,
                leading: Icon(
                  Icons.attach_money,
                  color: isDark ? Colors.greenAccent : Colors.green[700],
                ),
                title: Text(
                  'Currency',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                subtitle: Text(
                  '${CurrencyService.currencyNames[_selectedCurrency]} (${CurrencyService.getSymbol(_selectedCurrency)})',
                  style: const TextStyle(color: Colors.grey),
                ),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (dialogContext) => StatefulBuilder(
                      builder: (context, setDialogState) => AlertDialog(
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        title: Text(
                          'Select Currency',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: CurrencyService.currencySymbols.entries.map(
                            (entry) {
                              final code = entry.key;
                              final symbol = entry.value;
                              final name = CurrencyService.currencyNames[code];
                              final isSelected = _selectedCurrency == code;

                              return ListTile(
                                title: Text(
                                  '$name ($symbol)',
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                  ),
                                ),
                                leading: Icon(
                                  isSelected
                                      ? Icons.check_circle
                                      : Icons.circle_outlined,
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.grey,
                                ),
                                onTap: () async {
                                  await CurrencyService.saveToSupabase(code);
                                  setState(() => _selectedCurrency = code);
                                  setDialogState(() {});
                                  if (mounted) {
                                    if (!context.mounted) return;
                                    Navigator.pop(dialogContext);
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Currency changed to $name',
                                        ),
                                        backgroundColor: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                      ),
                                    );
                                  }
                                },
                              );
                            },
                          ).toList(),
                        ),
                      ),
                    ),
                  );
                },
              ),
              Divider(
                color: Theme.of(
                  context,
                ).dividerColor.withAlpha(isDark ? 40 : 80),
              ),
              ListTile(
                key: _appInfoKey,
                leading: Icon(
                  Icons.info_outline,
                  color: isDark ? Colors.cyan : Colors.cyan[800],
                ),
                title: Text(
                  'App information',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                subtitle: const Text(
                  'Info, terms and privacy',
                  style: TextStyle(color: Colors.grey),
                ),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: _showAppInformationMenu,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeScreenChoiceTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? badgeAsset;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  const _HomeScreenChoiceTile({
    required this.icon,
    required this.title,
    this.badgeAsset,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: selected
          ? colorScheme.primary.withAlpha(24)
          : colorScheme.surfaceContainerHighest.withAlpha(90),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        if (badgeAsset != null) ...[
                          const SizedBox(width: 6),
                          Image.asset(
                            badgeAsset!,
                            width: 44,
                            height: 21,
                            fit: BoxFit.contain,
                            semanticLabel: badgeAsset!.contains('free')
                                ? 'Free feature'
                                : 'Pro feature',
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.3,
                        color: colorScheme.onSurface.withAlpha(165),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                selected ? Icons.check_circle : Icons.circle_outlined,
                color: selected
                    ? colorScheme.primary
                    : colorScheme.onSurface.withAlpha(80),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
