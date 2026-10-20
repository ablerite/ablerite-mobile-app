import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/goal.dart';
import '../../providers/settings_provider.dart';
import '../../services/navigation_service.dart';
import '../../services/system_ui_service.dart';
import '../settings_page.dart';
import '../goal_detail_page.dart';
import 'focus_mode_nav_bar.dart';
import 'spotlight_walkthrough.dart';
import 'tablet_layout.dart';

// ---------------------------------------------------------------------------
// Quotes list (sourced from InsightsPage)
// ---------------------------------------------------------------------------
const List<Map<String, String>> _kQuotes = [
  {
    'text': 'Take care of your body. It\'s the only place you have to live.',
    'author': 'Jim Rohn',
  },
  {
    'text': 'The money you earn is a result of the value you create.',
    'author': 'T. Harv Eker',
  },
  {
    'text':
        'The quality of your life depends on the quality of your relationships.',
    'author': 'Tony Robbins',
  },
  {
    'text':
        'Choose a job you love, and you will never have to work a day in your life.',
    'author': 'Confucius',
  },
  {
    'text': 'When you let go of what you are, you become what you might be.',
    'author': 'Lao Tzu',
  },
  {
    'text':
        'The only person you are destined to become is the person you decide to be.',
    'author': 'Ralph Waldo Emerson',
  },
  {'text': 'What you seek is seeking you.', 'author': 'Rumi'},
  {
    'text': 'The mind is everything. What you think you become.',
    'author': 'Buddha',
  },
  {
    'text': 'An investment in knowledge pays the best interest.',
    'author': 'Benjamin Franklin',
  },
  {
    'text':
        'You are not a drop in the ocean. You are the entire ocean in a drop.',
    'author': 'Rumi',
  },
  {
    'text': 'The only way to do great work is to love what you do.',
    'author': 'Steve Jobs',
  },
  {
    'text': 'Peace comes from within. Do not seek it without.',
    'author': 'Buddha',
  },
  {
    'text': 'Opportunities don\'t happen. You create them.',
    'author': 'Chris Grosser',
  },
  {
    'text':
        'Success is not final, failure is not fatal: it is the courage to continue that counts.',
    'author': 'Winston Churchill',
  },
  {
    'text': 'Everything you\'ve ever wanted is on the other side of fear.',
    'author': 'George Addair',
  },
  {
    'text': 'Believe you can and you\'re halfway there.',
    'author': 'Theodore Roosevelt',
  },
  {'text': 'Dream it. Believe it. Achieve it.', 'author': 'Unknown'},
  {
    'text': 'The wound is the place where the Light enters you.',
    'author': 'Rumi',
  },
  {'text': 'Wealth flows in proportion to gratitude.', 'author': 'Unknown'},
  {
    'text':
        'Your time is limited, don\'t waste it living someone else\'s life.',
    'author': 'Steve Jobs',
  },
];

class _FocusWallpaper {
  final String label;
  final String asset;

  const _FocusWallpaper({required this.label, required this.asset});
}

const List<_FocusWallpaper> _kFocusWallpapers = [
  _FocusWallpaper(
    label: 'Mountain Lake',
    asset: 'assets/images/focus_mode/mountain_lake_portrait.webp',
  ),
  _FocusWallpaper(
    label: 'Valley Day',
    asset: 'assets/images/focus_mode/9_16/valley-day_9_16.png',
  ),
  _FocusWallpaper(
    label: 'Bloom',
    asset: 'assets/images/focus_mode/9_16/bloom_9_16.png',
  ),
  _FocusWallpaper(
    label: 'Lilly',
    asset: 'assets/images/focus_mode/9_16/lilly_9_16.png',
  ),
  _FocusWallpaper(
    label: 'Epic Sunrise',
    asset: 'assets/images/focus_mode/9_16/epic-sunrise_9_16.png',
  ),
  _FocusWallpaper(
    label: 'Teal Monument',
    asset: 'assets/images/focus_mode/teal_monument.webp',
  ),
];

enum FocusAppShortcut {
  // Finance apps
  netWorth,
  income,
  expenses,
  cashSurplus,
  // Media apps
  brainTraining,
  knowledge,
  criticalLearning,
  insights,
  // Action Center apps
  goals,
  tasks,
  affirmations,
  coaching,
  calendar,
  // Exploration apps
  visualization,
  manifestation,
  notebooks,
  journals,
  // Wellness apps
  metrics,
  mind,
  body,
  spirit,
  // Drawer action
  settings,
}

class _FocusAppShortcutData {
  final FocusAppShortcut shortcut;
  final String label;
  final IconData icon;

  const _FocusAppShortcutData(this.shortcut, this.label, this.icon);
}

enum _FocusDrawerTheme {
  glass,
  colour,
  solid,
  outline,
  technicolour,
  unite,
  text,
  textDot,
}

const List<_FocusDrawerTheme> _focusDrawerThemeDisplayOrder = [
  _FocusDrawerTheme.glass,
  _FocusDrawerTheme.colour,
  _FocusDrawerTheme.solid,
  _FocusDrawerTheme.outline,
  _FocusDrawerTheme.unite,
  _FocusDrawerTheme.technicolour,
  _FocusDrawerTheme.text,
  _FocusDrawerTheme.textDot,
];

extension _FocusDrawerThemeDetails on _FocusDrawerTheme {
  String get label => switch (this) {
    _FocusDrawerTheme.glass => 'Glass',
    _FocusDrawerTheme.colour => 'Colour',
    _FocusDrawerTheme.outline => 'Solid Colours',
    _FocusDrawerTheme.solid => 'Solid',
    _FocusDrawerTheme.technicolour => 'Technicolour',
    _FocusDrawerTheme.unite => 'Unite',
    _FocusDrawerTheme.text => 'Text',
    _FocusDrawerTheme.textDot => 'Text + Dot',
  };

  String get description => switch (this) {
    _FocusDrawerTheme.glass => 'Translucent circles',
    _FocusDrawerTheme.colour => 'Colour-coded buttons',
    _FocusDrawerTheme.outline => 'Solid colour circles',
    _FocusDrawerTheme.solid => 'High-contrast buttons',
    _FocusDrawerTheme.technicolour => 'One colour per app',
    _FocusDrawerTheme.unite => 'Four-colour designs',
    _FocusDrawerTheme.text => 'Text-only app list',
    _FocusDrawerTheme.textDot => 'Text with colour dots',
  };

  IconData get icon => switch (this) {
    _FocusDrawerTheme.glass => Icons.blur_on_outlined,
    _FocusDrawerTheme.colour => Icons.palette_outlined,
    _FocusDrawerTheme.outline => Icons.color_lens_outlined,
    _FocusDrawerTheme.solid => Icons.contrast_rounded,
    _FocusDrawerTheme.technicolour => Icons.auto_awesome_mosaic_outlined,
    _FocusDrawerTheme.unite => Icons.diversity_3_outlined,
    _FocusDrawerTheme.text => Icons.format_align_left_rounded,
    _FocusDrawerTheme.textDot => Icons.format_list_bulleted_rounded,
  };
}

const List<_FocusAppShortcutData> _kFocusApps = [
  _FocusAppShortcutData(FocusAppShortcut.coaching, 'Chat', Icons.auto_awesome),
  _FocusAppShortcutData(
    FocusAppShortcut.affirmations,
    'Affirmations',
    Icons.format_quote_rounded,
  ),
  _FocusAppShortcutData(FocusAppShortcut.tasks, 'Tasks', Icons.task_alt),
  _FocusAppShortcutData(FocusAppShortcut.goals, 'Goals', Icons.adjust),
  _FocusAppShortcutData(
    FocusAppShortcut.visualization,
    'Visualize',
    Icons.visibility_outlined,
  ),
  _FocusAppShortcutData(
    FocusAppShortcut.manifestation,
    'Manifest',
    Icons.rocket_launch_outlined,
  ),
  _FocusAppShortcutData(
    FocusAppShortcut.notebooks,
    'Notebooks',
    Icons.folder_outlined,
  ),
  _FocusAppShortcutData(
    FocusAppShortcut.journals,
    'Journals',
    Icons.menu_book_outlined,
  ),
  _FocusAppShortcutData(
    FocusAppShortcut.insights,
    'Insights',
    Icons.lightbulb_outline,
  ),
  _FocusAppShortcutData(
    FocusAppShortcut.brainTraining,
    'Brain Train',
    Icons.psychology_alt_outlined,
  ),
  _FocusAppShortcutData(
    FocusAppShortcut.knowledge,
    'Knowledge',
    Icons.school_outlined,
  ),
  _FocusAppShortcutData(
    FocusAppShortcut.criticalLearning,
    'Critical',
    Icons.adjust,
  ),
  _FocusAppShortcutData(
    FocusAppShortcut.netWorth,
    'Net Worth',
    Icons.account_balance_wallet_outlined,
  ),
  _FocusAppShortcutData(
    FocusAppShortcut.income,
    'Income',
    Icons.monetization_on_outlined,
  ),
  _FocusAppShortcutData(
    FocusAppShortcut.expenses,
    'Expenses',
    Icons.pie_chart_outline,
  ),
  _FocusAppShortcutData(
    FocusAppShortcut.cashSurplus,
    'Surplus',
    Icons.savings_outlined,
  ),
  _FocusAppShortcutData(
    FocusAppShortcut.metrics,
    'Metrics',
    Icons.query_stats_rounded,
  ),
  _FocusAppShortcutData(FocusAppShortcut.mind, 'Mind', Icons.self_improvement),
  _FocusAppShortcutData(FocusAppShortcut.body, 'Body', Icons.fitness_center),
  _FocusAppShortcutData(
    FocusAppShortcut.spirit,
    'Spirit',
    Icons.nights_stay_outlined,
  ),
  _FocusAppShortcutData(
    FocusAppShortcut.calendar,
    'Calendar',
    Icons.calendar_month_outlined,
  ),
  _FocusAppShortcutData(
    FocusAppShortcut.settings,
    'Settings',
    Icons.settings_outlined,
  ),
];

class _FocusShortcutFolderData {
  final String label;
  final _FocusAppShortcutData tile;
  final List<_FocusAppShortcutData> apps;

  const _FocusShortcutFolderData({
    required this.label,
    required this.tile,
    required this.apps,
  });
}

const _kFinanceFolder = _FocusShortcutFolderData(
  label: 'Finance',
  tile: _FocusAppShortcutData(
    FocusAppShortcut.netWorth,
    'Finance',
    Icons.account_balance_outlined,
  ),
  apps: [
    _FocusAppShortcutData(
      FocusAppShortcut.netWorth,
      'Net Worth',
      Icons.account_balance_wallet_outlined,
    ),
    _FocusAppShortcutData(
      FocusAppShortcut.income,
      'Income',
      Icons.monetization_on_outlined,
    ),
    _FocusAppShortcutData(
      FocusAppShortcut.expenses,
      'Expenses',
      Icons.pie_chart_outline,
    ),
    _FocusAppShortcutData(
      FocusAppShortcut.cashSurplus,
      'Surplus',
      Icons.savings_outlined,
    ),
  ],
);

const _kMbsFolder = _FocusShortcutFolderData(
  label: 'Wellness',
  tile: _FocusAppShortcutData(
    FocusAppShortcut.metrics,
    'Wellness',
    Icons.self_improvement_outlined,
  ),
  apps: [
    _FocusAppShortcutData(
      FocusAppShortcut.metrics,
      'Metrics',
      Icons.query_stats_rounded,
    ),
    _FocusAppShortcutData(
      FocusAppShortcut.mind,
      'Mind',
      Icons.self_improvement,
    ),
    _FocusAppShortcutData(FocusAppShortcut.body, 'Body', Icons.fitness_center),
    _FocusAppShortcutData(
      FocusAppShortcut.spirit,
      'Spirit',
      Icons.nights_stay_outlined,
    ),
  ],
);

const _kFocusFolders = [_kFinanceFolder, _kMbsFolder];

_FocusShortcutFolderData? _folderForRepresentative(FocusAppShortcut shortcut) {
  for (final folder in _kFocusFolders) {
    if (folder.tile.shortcut == shortcut) return folder;
  }
  return null;
}

bool _isFolderMember(FocusAppShortcut shortcut) {
  return _kFocusFolders.any(
    (folder) => folder.apps.any((app) => app.shortcut == shortcut),
  );
}

const _focusShortcutOrderPreferenceKey = 'focus_shortcut_order';
const _focusDrawerThemePreferenceKey = 'focus_drawer_theme';

_FocusDrawerTheme _drawerThemeFromName(String? name) {
  return _FocusDrawerTheme.values.firstWhere(
    (theme) => theme.name == name,
    orElse: () => _FocusDrawerTheme.colour,
  );
}

Color _shortcutAccent(FocusAppShortcut shortcut) {
  return switch (shortcut) {
    FocusAppShortcut.netWorth ||
    FocusAppShortcut.income ||
    FocusAppShortcut.expenses ||
    FocusAppShortcut.cashSurplus => const Color(0xFF62D6A7),
    FocusAppShortcut.brainTraining ||
    FocusAppShortcut.knowledge ||
    FocusAppShortcut.criticalLearning ||
    FocusAppShortcut.insights => const Color(0xFF78A9FF),
    FocusAppShortcut.goals ||
    FocusAppShortcut.tasks ||
    FocusAppShortcut.affirmations ||
    FocusAppShortcut.coaching => const Color(0xFFC493FF),
    FocusAppShortcut.visualization ||
    FocusAppShortcut.manifestation ||
    FocusAppShortcut.notebooks ||
    FocusAppShortcut.journals => const Color(0xFFFFB86B),
    FocusAppShortcut.metrics ||
    FocusAppShortcut.mind ||
    FocusAppShortcut.body ||
    FocusAppShortcut.spirit ||
    FocusAppShortcut.calendar ||
    FocusAppShortcut.settings => const Color(0xFF62D6A7),
  };
}

/// A deliberately broad spectrum so no two Technicolour shortcuts share an
/// icon colour. Keeping this mapping tied to the shortcut (rather than its
/// position) means reordering apps does not change their identity.
Color _technicolourAccent(FocusAppShortcut shortcut) {
  return switch (shortcut) {
    FocusAppShortcut.netWorth => const Color(0xFF16A34A),
    FocusAppShortcut.income => const Color(0xFF84CC16),
    FocusAppShortcut.expenses => const Color(0xFFF59E0B),
    FocusAppShortcut.cashSurplus => const Color(0xFFEAB308),
    FocusAppShortcut.brainTraining => const Color(0xFF06B6D4),
    FocusAppShortcut.knowledge => const Color(0xFF3B82F6),
    FocusAppShortcut.criticalLearning => const Color(0xFF6366F1),
    FocusAppShortcut.insights => const Color(0xFF8B5CF6),
    FocusAppShortcut.goals => const Color(0xFFD946EF),
    FocusAppShortcut.tasks => const Color(0xFFEC4899),
    FocusAppShortcut.affirmations => const Color(0xFFFB7185),
    FocusAppShortcut.coaching => const Color(0xFFF97316),
    FocusAppShortcut.calendar => const Color(0xFF16A34A),
    FocusAppShortcut.visualization => const Color(0xFF14B8A6),
    FocusAppShortcut.manifestation => const Color(0xFF0EA5E9),
    FocusAppShortcut.notebooks => const Color(0xFF2563EB),
    FocusAppShortcut.journals => const Color(0xFF7C3AED),
    FocusAppShortcut.metrics => const Color(0xFF16A34A),
    FocusAppShortcut.mind => const Color(0xFF16A34A),
    FocusAppShortcut.body => const Color(0xFF16A34A),
    FocusAppShortcut.spirit => const Color(0xFF16A34A),
    FocusAppShortcut.settings => const Color(0xFF16A34A),
  };
}

const List<Color> _uniteColours = [
  Color(0xFFEF4444), // red
  Color(0xFF22C55E), // green
  Color(0xFFFACC15), // yellow
  Color(0xFF3B82F6), // blue
];

int _shortcutIndex(FocusAppShortcut shortcut) =>
    _kFocusApps.indexWhere((item) => item.shortcut == shortcut);

bool _isDefaultBottomRowShortcut(FocusAppShortcut shortcut) =>
    shortcut == FocusAppShortcut.netWorth ||
    shortcut == FocusAppShortcut.metrics ||
    shortcut == FocusAppShortcut.calendar ||
    shortcut == FocusAppShortcut.settings;

Gradient _uniteGradient(FocusAppShortcut shortcut) {
  final index = _shortcutIndex(
    _isDefaultBottomRowShortcut(shortcut)
        ? FocusAppShortcut.netWorth
        : shortcut,
  );
  final colours = List<Color>.generate(
    4,
    (offset) => _uniteColours[(index + offset) % _uniteColours.length],
  );
  return switch (index % 5) {
    0 => LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: colours,
    ),
    1 => LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      stops: const [0, .3, .68, 1],
      colors: colours,
    ),
    2 => SweepGradient(
      startAngle: 0,
      endAngle: 6.283185307,
      colors: [...colours, colours.first],
    ),
    3 => RadialGradient(
      center: const Alignment(-.35, -.35),
      radius: 1.15,
      colors: colours,
    ),
    _ => LinearGradient(
      begin: Alignment.bottomLeft,
      end: Alignment.topRight,
      stops: const [0, .28, .7, 1],
      colors: colours.reversed.toList(),
    ),
  };
}

Future<void> resetFocusShortcutOrder() async {
  final preferences = await SharedPreferences.getInstance();
  await preferences.remove(_focusShortcutOrderPreferenceKey);
}

class _FocusDrawerPreferences {
  final List<_FocusAppShortcutData> items;
  final _FocusDrawerTheme theme;

  const _FocusDrawerPreferences({required this.items, required this.theme});
}

Future<_FocusDrawerPreferences> _loadFocusDrawerPreferences() async {
  final preferences = await SharedPreferences.getInstance();
  final storedNames = preferences.getStringList(
    _focusShortcutOrderPreferenceKey,
  );
  final theme = _drawerThemeFromName(
    preferences.getString(_focusDrawerThemePreferenceKey),
  );
  if (storedNames == null) {
    return _FocusDrawerPreferences(items: List.of(_kFocusApps), theme: theme);
  }

  final byName = {for (final item in _kFocusApps) item.shortcut.name: item};
  final ordered = <_FocusAppShortcutData>[
    for (final name in storedNames)
      if (byName.remove(name) case final item?) item,
    ...byName.values,
  ];
  return _FocusDrawerPreferences(items: ordered, theme: theme);
}

Future<FocusAppShortcut?> showFocusShortcutDrawer(
  BuildContext context, {
  VoidCallback? onOpenOptions,
  VoidCallback? onOpenSettings,
  Future<void> Function(FocusAppShortcut shortcut)? onLaunchShortcut,
  Key? optionsKey,
}) async {
  final preferences = await _loadFocusDrawerPreferences();
  if (!context.mounted) return null;
  return showGeneralDialog<FocusAppShortcut>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: true,
    barrierLabel: 'Close app drawer',
    barrierColor: Colors.black.withAlpha(70),
    transitionDuration: Duration.zero,
    pageBuilder: (dialogContext, _, _) => _FocusShortcutDrawer(
      dialogContext: dialogContext,
      initialItems: preferences.items,
      initialDrawerTheme: preferences.theme,
      onOpenOptions: onOpenOptions,
      onOpenSettings: onOpenSettings,
      onLaunchShortcut: onLaunchShortcut,
      optionsKey: optionsKey,
    ),
    transitionBuilder: (context, animation, _, child) => FadeTransition(
      opacity: animation,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.95, end: 1).animate(animation),
        child: child,
      ),
    ),
  );
}

class _FocusShortcutDrawer extends StatefulWidget {
  final BuildContext dialogContext;
  final List<_FocusAppShortcutData> initialItems;
  final _FocusDrawerTheme initialDrawerTheme;
  final VoidCallback? onOpenOptions;
  final VoidCallback? onOpenSettings;
  final Future<void> Function(FocusAppShortcut shortcut)? onLaunchShortcut;
  final Key? optionsKey;

  const _FocusShortcutDrawer({
    required this.dialogContext,
    required this.initialItems,
    required this.initialDrawerTheme,
    this.onOpenOptions,
    this.onOpenSettings,
    this.onLaunchShortcut,
    this.optionsKey,
  });

  @override
  State<_FocusShortcutDrawer> createState() => _FocusShortcutDrawerState();
}

class _FocusShortcutDrawerState extends State<_FocusShortcutDrawer> {
  late final List<_FocusAppShortcutData> _items = List.of(widget.initialItems);
  FocusAppShortcut? _launchingShortcut;
  _FocusShortcutFolderData? _openFolder;
  late final _FocusDrawerTheme _drawerTheme = widget.initialDrawerTheme;

  Future<void> _saveOrder() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(
      _focusShortcutOrderPreferenceKey,
      _items.map((item) => item.shortcut.name).toList(),
    );
  }

  void _moveShortcut(FocusAppShortcut dragged, FocusAppShortcut target) {
    if (dragged == target) return;
    final oldIndex = _items.indexWhere((item) => item.shortcut == dragged);
    if (oldIndex < 0) return;

    setState(() {
      final item = _items.removeAt(oldIndex);
      final newIndex = _items.indexWhere(
        (candidate) => candidate.shortcut == target,
      );
      _items.insert(newIndex < 0 ? _items.length : newIndex, item);
    });
    _saveOrder();
  }

  List<_FocusAppShortcutData> _itemsInAlphabeticalColumns() {
    final alphabetical = _topLevelItems()
      ..sort(
        (first, second) =>
            first.label.toLowerCase().compareTo(second.label.toLowerCase()),
      );
    final columnLength = (alphabetical.length + 1) ~/ 2;
    return [
      for (var row = 0; row < columnLength; row++) ...[
        alphabetical[row],
        if (row + columnLength < alphabetical.length)
          alphabetical[row + columnLength],
      ],
    ];
  }

  List<_FocusAppShortcutData> _topLevelItems() {
    return [
      for (final item in _items)
        if (_folderForRepresentative(item.shortcut) case final folder?)
          folder.tile
        else if (!_isFolderMember(item.shortcut))
          item,
    ];
  }

  void _openShortcutFolder(_FocusShortcutFolderData folder) {
    if (_launchingShortcut != null) return;
    setState(() => _openFolder = folder);
  }

  void _handleTopLevelTap(_FocusAppShortcutData item) {
    if (item.shortcut == FocusAppShortcut.settings) {
      final openSettings = widget.onOpenSettings;
      Navigator.of(widget.dialogContext, rootNavigator: true).pop();
      if (openSettings != null) Future<void>.microtask(openSettings);
      return;
    }
    final folder = _folderForRepresentative(item.shortcut);
    if (folder != null) {
      _openShortcutFolder(folder);
    } else {
      _launchShortcut(item.shortcut);
    }
  }

  Future<void> _launchShortcut(FocusAppShortcut shortcut) async {
    if (_launchingShortcut != null) return;
    setState(() => _launchingShortcut = shortcut);
    if (!mounted || !widget.dialogContext.mounted) return;
    final launchShortcut = widget.onLaunchShortcut;
    if (launchShortcut == null) {
      Navigator.pop(widget.dialogContext, shortcut);
      return;
    }

    await launchShortcut(shortcut);
    if (mounted && widget.dialogContext.mounted) {
      Navigator.pop(widget.dialogContext);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = isTabletLayout(context);
    const horizontalScreenPadding = 18.0;
    final drawerMaxWidth = isTablet
        ? tabletPopupWidth(context, portrait: 700, landscape: 900)
        : 370.0;
    const drawerHorizontalPadding = 18.0;
    final isListStyle =
        _drawerTheme == _FocusDrawerTheme.text ||
        _drawerTheme == _FocusDrawerTheme.textDot;
    final displayedItems = isListStyle
        ? _itemsInAlphabeticalColumns()
        : _topLevelItems();
    final isLandscapeTablet = isTabletLandscape(context);
    final gridColumns = isTablet
        ? (isListStyle ? 3 : (isLandscapeTablet ? 8 : 4))
        : (isListStyle ? 2 : 4);
    final gridCrossSpacing = isListStyle ? 6.0 : 8.0;
    final gridMainSpacing = isListStyle ? 2.0 : 10.0;
    final gridChildAspectRatio = isTablet ? 0.88 : 0.74;
    const drawerVerticalChrome = 20.0 + 34.0 + 12.0 + 18.0;

    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;
    final drawerWidth =
        screenSize.width - (horizontalScreenPadding * 2) < drawerMaxWidth
        ? screenSize.width - (horizontalScreenPadding * 2)
        : drawerMaxWidth;
    final gridWidth = drawerWidth - (drawerHorizontalPadding * 2);
    final gridTileWidth =
        (gridWidth - (gridCrossSpacing * (gridColumns - 1))) / gridColumns;
    final gridTileHeight = isListStyle
        ? 48.0
        : gridTileWidth / gridChildAspectRatio;
    final gridRows = (displayedItems.length / gridColumns).ceil();
    final gridHeight =
        (gridTileHeight * gridRows) +
        (gridMainSpacing * (gridRows > 0 ? gridRows - 1 : 0));
    final requiredDrawerHeight = drawerVerticalChrome + gridHeight;
    final availableDrawerHeight =
        screenSize.height - mediaQuery.padding.vertical - 24;
    final drawerHeight = requiredDrawerHeight < availableDrawerHeight
        ? requiredDrawerHeight
        : availableDrawerHeight;
    final gridNeedsScrolling =
        requiredDrawerHeight > availableDrawerHeight + 0.5;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Material(
        color: Colors.transparent,
        child: Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.pop(widget.dialogContext),
              child: const SizedBox.expand(),
            ),
            SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                      child: Container(
                        width: drawerWidth,
                        height: drawerHeight,
                        padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(92),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: Colors.white.withAlpha(58)),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Apps',
                                      style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    isListStyle
                                        ? 'Alphabetical'
                                        : 'Hold and drag to reorder',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white.withAlpha(145),
                                      fontSize: 11,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  IconButton(
                                    key: widget.optionsKey,
                                    icon: const Icon(Icons.build_outlined),
                                    color: Colors.white,
                                    iconSize: 18,
                                    tooltip: 'Focus options',
                                    constraints: const BoxConstraints.tightFor(
                                      width: 34,
                                      height: 34,
                                    ),
                                    padding: const EdgeInsets.all(6),
                                    onPressed: () {
                                      final openOptions = widget.onOpenOptions;
                                      Navigator.of(
                                        widget.dialogContext,
                                        rootNavigator: true,
                                      ).pop();
                                      if (openOptions != null) {
                                        Future<void>.microtask(openOptions);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Expanded(
                              child: GridView.builder(
                                padding: EdgeInsets.zero,
                                physics: gridNeedsScrolling
                                    ? const ClampingScrollPhysics()
                                    : const NeverScrollableScrollPhysics(),
                                itemCount: displayedItems.length,
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: gridColumns,
                                      crossAxisSpacing: gridCrossSpacing,
                                      mainAxisSpacing: gridMainSpacing,
                                      mainAxisExtent: isListStyle
                                          ? gridTileHeight
                                          : null,
                                      childAspectRatio: gridChildAspectRatio,
                                    ),
                                itemBuilder: (context, index) {
                                  final item = displayedItems[index];
                                  if (isListStyle) {
                                    final isLaunching =
                                        _launchingShortcut == item.shortcut;
                                    final isLaunchDimmed =
                                        _launchingShortcut != null &&
                                        !isLaunching;
                                    return AnimatedOpacity(
                                      duration: const Duration(
                                        milliseconds: 180,
                                      ),
                                      curve: Curves.easeOut,
                                      opacity: isLaunchDimmed ? 0.16 : 1,
                                      child: AnimatedScale(
                                        duration: const Duration(
                                          milliseconds: 220,
                                        ),
                                        curve: Curves.easeOutBack,
                                        scale: isLaunching ? 1.08 : 1,
                                        child: IgnorePointer(
                                          ignoring: _launchingShortcut != null,
                                          child: _FocusShortcutTile(
                                            item: item,
                                            drawerTheme: _drawerTheme,
                                            highlighted: isLaunching,
                                            onTap: () =>
                                                _handleTopLevelTap(item),
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                  return DragTarget<FocusAppShortcut>(
                                    onAcceptWithDetails: (details) =>
                                        _moveShortcut(
                                          details.data,
                                          item.shortcut,
                                        ),
                                    builder: (context, candidates, rejected) {
                                      final isLaunching =
                                          _launchingShortcut == item.shortcut;
                                      final isLaunchDimmed =
                                          _launchingShortcut != null &&
                                          !isLaunching;
                                      final tile = AnimatedOpacity(
                                        duration: const Duration(
                                          milliseconds: 180,
                                        ),
                                        curve: Curves.easeOut,
                                        opacity: isLaunchDimmed ? 0.16 : 1,
                                        child: AnimatedScale(
                                          duration: const Duration(
                                            milliseconds: 220,
                                          ),
                                          curve: Curves.easeOutBack,
                                          scale: isLaunching ? 1.14 : 1,
                                          child: _FocusShortcutTile(
                                            item: item,
                                            drawerTheme: _drawerTheme,
                                            highlighted:
                                                candidates.isNotEmpty ||
                                                isLaunching,
                                            onTap: () =>
                                                _handleTopLevelTap(item),
                                          ),
                                        ),
                                      );
                                      return LongPressDraggable<
                                        FocusAppShortcut
                                      >(
                                        data: item.shortcut,
                                        maxSimultaneousDrags:
                                            _launchingShortcut == null ? 1 : 0,
                                        delay: const Duration(
                                          milliseconds: 280,
                                        ),
                                        feedback: Material(
                                          color: Colors.transparent,
                                          child: SizedBox(
                                            width: isListStyle ? 164 : 80,
                                            height: isListStyle ? 48 : 98,
                                            child: _FocusShortcutTile(
                                              item: item,
                                              drawerTheme: _drawerTheme,
                                              highlighted: true,
                                            ),
                                          ),
                                        ),
                                        childWhenDragging: Opacity(
                                          opacity: 0.25,
                                          child: tile,
                                        ),
                                        child: IgnorePointer(
                                          ignoring: _launchingShortcut != null,
                                          child: tile,
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (_openFolder case final folder?) ...[
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _openFolder = null),
                  child: Container(color: Colors.black.withAlpha(72)),
                ),
              ),
              SafeArea(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 34),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                        child: Container(
                          width: isTablet ? 520 : 320,
                          padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(150),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withAlpha(70),
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      folder.label,
                                      style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close_rounded),
                                    color: Colors.white.withAlpha(210),
                                    iconSize: 20,
                                    tooltip: 'Close ${folder.label}',
                                    constraints: const BoxConstraints.tightFor(
                                      width: 34,
                                      height: 34,
                                    ),
                                    padding: const EdgeInsets.all(6),
                                    onPressed: () =>
                                        setState(() => _openFolder = null),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  for (final item in folder.apps)
                                    SizedBox(
                                      height: 48,
                                      child: AnimatedOpacity(
                                        duration: const Duration(
                                          milliseconds: 180,
                                        ),
                                        opacity:
                                            _launchingShortcut != null &&
                                                _launchingShortcut !=
                                                    item.shortcut
                                            ? 0.16
                                            : 1,
                                        child: IgnorePointer(
                                          ignoring: _launchingShortcut != null,
                                          child: _FocusShortcutListTile(
                                            item: item,
                                            showDot: true,
                                            highlighted:
                                                _launchingShortcut ==
                                                item.shortcut,
                                            onTap: () =>
                                                _launchShortcut(item.shortcut),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FocusShortcutTile extends StatelessWidget {
  final _FocusAppShortcutData item;
  final _FocusDrawerTheme drawerTheme;
  final bool highlighted;
  final VoidCallback? onTap;

  const _FocusShortcutTile({
    required this.item,
    required this.drawerTheme,
    this.highlighted = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isTextList = drawerTheme == _FocusDrawerTheme.text;
    final isTextDotList = drawerTheme == _FocusDrawerTheme.textDot;
    if (isTextList || isTextDotList) {
      return _FocusShortcutListTile(
        item: item,
        showDot: isTextDotList,
        highlighted: highlighted,
        onTap: onTap,
      );
    }

    final isTechnicolour = drawerTheme == _FocusDrawerTheme.technicolour;
    final isUnite = drawerTheme == _FocusDrawerTheme.unite;
    final isDefaultBottomRow = _isDefaultBottomRowShortcut(item.shortcut);
    final accent = isTechnicolour
        ? _technicolourAccent(item.shortcut)
        : _shortcutAccent(item.shortcut);
    final isSquare =
        drawerTheme == _FocusDrawerTheme.colour ||
        drawerTheme == _FocusDrawerTheme.solid ||
        isTechnicolour ||
        isUnite;
    final buttonColor = switch (drawerTheme) {
      _FocusDrawerTheme.glass =>
        isDefaultBottomRow
            ? accent.withAlpha(highlighted ? 120 : 76)
            : Colors.white.withAlpha(highlighted ? 38 : 24),
      _FocusDrawerTheme.colour => accent.withAlpha(highlighted ? 120 : 76),
      _FocusDrawerTheme.outline => accent.withAlpha(highlighted ? 255 : 225),
      _FocusDrawerTheme.solid => Colors.white.withAlpha(
        highlighted ? 255 : 225,
      ),
      _FocusDrawerTheme.technicolour => accent.withAlpha(
        highlighted ? 255 : 225,
      ),
      _FocusDrawerTheme.unite => Colors.transparent,
      _FocusDrawerTheme.text || _FocusDrawerTheme.textDot => Colors.transparent,
    };
    final borderColor = switch (drawerTheme) {
      _FocusDrawerTheme.glass =>
        isDefaultBottomRow
            ? accent.withAlpha(highlighted ? 255 : 180)
            : Colors.white.withAlpha(highlighted ? 95 : 45),
      _FocusDrawerTheme.colour => accent.withAlpha(highlighted ? 255 : 180),
      _FocusDrawerTheme.outline => accent,
      _FocusDrawerTheme.solid => Colors.white.withAlpha(235),
      _FocusDrawerTheme.technicolour => Colors.white.withAlpha(
        highlighted ? 245 : 175,
      ),
      _FocusDrawerTheme.unite => Colors.white.withAlpha(
        highlighted ? 245 : 185,
      ),
      _FocusDrawerTheme.text || _FocusDrawerTheme.textDot => Colors.transparent,
    };
    final iconColor =
        drawerTheme == _FocusDrawerTheme.solid ||
            drawerTheme == _FocusDrawerTheme.outline
        ? const Color(0xFF17212B)
        : isTechnicolour || isUnite
        ? Colors.white
        : drawerTheme == _FocusDrawerTheme.colour
        ? Colors.white
        : Colors.white.withAlpha(240);
    final tileColor = switch (drawerTheme) {
      _FocusDrawerTheme.colour => accent.withAlpha(highlighted ? 28 : 10),
      _FocusDrawerTheme.outline => accent.withAlpha(highlighted ? 30 : 12),
      _FocusDrawerTheme.solid => Colors.white.withAlpha(highlighted ? 24 : 8),
      _FocusDrawerTheme.technicolour => accent.withAlpha(highlighted ? 38 : 16),
      _FocusDrawerTheme.unite => Colors.white.withAlpha(highlighted ? 26 : 9),
      _FocusDrawerTheme.text || _FocusDrawerTheme.textDot => Colors.transparent,
      _ => highlighted ? Colors.white.withAlpha(22) : Colors.transparent,
    };

    return Semantics(
      button: true,
      label: 'Open ${item.label}. Hold and drag to reorder.',
      child: Material(
        color: tileColor,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: buttonColor,
                  gradient: isUnite ? _uniteGradient(item.shortcut) : null,
                  shape: isSquare ? BoxShape.rectangle : BoxShape.circle,
                  borderRadius: isSquare ? BorderRadius.circular(16) : null,
                  border: Border.all(color: borderColor),
                  boxShadow: (isTechnicolour || isUnite)
                      ? [
                          BoxShadow(
                            color: (isTechnicolour ? accent : Colors.blue)
                                .withAlpha(highlighted ? 125 : 70),
                            blurRadius: highlighted ? 12 : 7,
                            spreadRadius: highlighted ? 1 : 0,
                          ),
                        ]
                      : null,
                ),
                child: Icon(item.icon, color: iconColor, size: 26),
              ),
              const SizedBox(height: 8),
              Text(
                item.label,
                maxLines: 1,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  color: Colors.white.withAlpha(220),
                  fontSize: 11,
                  height: 1,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FocusShortcutListTile extends StatelessWidget {
  final _FocusAppShortcutData item;
  final bool showDot;
  final bool highlighted;
  final VoidCallback? onTap;

  const _FocusShortcutListTile({
    required this.item,
    required this.showDot,
    required this.highlighted,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Open ${item.label}. Hold and drag to reorder.',
      child: Material(
        color: highlighted ? Colors.white.withAlpha(30) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      color: Colors.white.withAlpha(235),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (showDot)
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: _shortcutAccent(item.shortcut),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _shortcutAccent(item.shortcut).withAlpha(105),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Overlay widget
// ---------------------------------------------------------------------------
class AmbientFocusOverlay extends StatefulWidget {
  final bool showOptionsOnOpen;

  const AmbientFocusOverlay({super.key, this.showOptionsOnOpen = false});

  @override
  State<AmbientFocusOverlay> createState() => _AmbientFocusOverlayState();
}

class _AmbientFocusOverlayState extends State<AmbientFocusOverlay>
    with TickerProviderStateMixin {
  static const _wallpaperPreferenceKey = 'ambient_focus_wallpaper';
  static const _customWallpaperPathPreferenceKey =
      'ambient_focus_custom_wallpaper_path';
  static const _wallpaperPreferenceVersionKey =
      'ambient_focus_wallpaper_version';
  static const _wallpaperPreferenceVersion = 3;

  final _optionsKey = GlobalKey();
  final _settingsKey = GlobalKey();
  final _clockKey = GlobalKey();
  final _appDrawerKey = GlobalKey();
  final _insightKey = GlobalKey();
  final _goalKey = GlobalKey();
  final _taskKey = GlobalKey();

  // Clock
  late Timer _clockTimer;
  DateTime _now = DateTime.now();

  // Data
  Goal? _focusGoal;
  String? _nextTask;
  late Map<String, String> _todayQuote;
  int _wallpaperIndex = 0;
  String? _customWallpaperPath;
  _FocusDrawerTheme _drawerTheme = _FocusDrawerTheme.colour;
  bool _isAppDrawerOpen = false;
  FocusAppShortcut? _settingsShortcutToLaunch;
  double _focusSwipeDistance = 0;
  bool _focusSwipeStartedInBody = false;

  // Focus palette cycles through the same themes available in Settings.
  AppThemeChoice _focusTheme = AppThemeChoice.lake;
  static const List<AppThemeChoice> _focusThemeOrder = [
    AppThemeChoice.lake,
    AppThemeChoice.slate,
    AppThemeChoice.white,
    AppThemeChoice.black,
  ];

  // Animations
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();

    // True full screen — hide status bar, home indicator, and nav bar
    SystemUiService.apply(SystemUiMode.immersiveSticky);

    // Pick a daily-stable quote
    final dayOfYear = _now.difference(DateTime(_now.year, 1, 1)).inDays;
    _todayQuote = _kQuotes[dayOfYear % _kQuotes.length];

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _fadeController.forward();

    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });

    _prepareFocusOverlay();
    _loadData();
  }

  Future<void> _prepareFocusOverlay() async {
    await _loadWallpaperPreference();
    await _recoverLostCustomWallpaper();
    if (!mounted || !widget.showOptionsOnOpen) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _showFocusOptions(_FocusPalette.forTheme(_focusTheme));
    });
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    _fadeController.dispose();
    // The app's default mode is already immersiveSticky, but re-apply
    // explicitly in case a stray system UI reveal changed it mid-session.
    SystemUiService.apply(SystemUiMode.immersiveSticky);
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.wait([_loadGoal(), _loadNextTask()]);
  }

  Future<void> _loadWallpaperPreference() async {
    final preferences = await SharedPreferences.getInstance();
    var storedIndex = preferences.getInt(_wallpaperPreferenceKey) ?? 0;
    final storedVersion =
        preferences.getInt(_wallpaperPreferenceVersionKey) ?? 1;
    var customWallpaperPath = preferences.getString(
      _customWallpaperPathPreferenceKey,
    );
    if (customWallpaperPath != null &&
        !File(customWallpaperPath).existsSync()) {
      customWallpaperPath = null;
      await preferences.remove(_customWallpaperPathPreferenceKey);
    }
    if (storedVersion < 2) {
      // The third preset was removed. Keep existing selections aligned with
      // their original wallpaper where possible.
      if (storedIndex == 2) {
        storedIndex = 0;
      } else if (storedIndex > 2) {
        storedIndex--;
      }
    }
    if (storedVersion < 3) {
      // Preserve the selected wallpaper while moving Epic Sunrise and Teal
      // Monument together to the final preset row.
      storedIndex = switch (storedIndex) {
        0 => 0, // Mountain Lake
        1 => 4, // Epic Sunrise
        2 => 5, // Teal Monument
        3 => 1, // Valley Day
        4 => 2, // Bloom
        5 => 3, // Lilly
        _ => 0,
      };
    }
    if (storedVersion < _wallpaperPreferenceVersion) {
      await preferences.setInt(
        _wallpaperPreferenceVersionKey,
        _wallpaperPreferenceVersion,
      );
      await preferences.setInt(_wallpaperPreferenceKey, storedIndex);
    }
    final storedDrawerTheme = _drawerThemeFromName(
      preferences.getString(_focusDrawerThemePreferenceKey),
    );
    if (!mounted) return;
    setState(() {
      _wallpaperIndex = storedIndex
          .clamp(0, _kFocusWallpapers.length - 1)
          .toInt();
      _customWallpaperPath = customWallpaperPath;
      _drawerTheme = storedDrawerTheme;
    });
  }

  Future<void> _selectWallpaper(int index) async {
    if (index == _wallpaperIndex && _customWallpaperPath == null) return;
    setState(() {
      _wallpaperIndex = index;
      _customWallpaperPath = null;
    });
    final preferences = await SharedPreferences.getInstance();
    await preferences.setInt(_wallpaperPreferenceKey, index);
    await preferences.remove(_customWallpaperPathPreferenceKey);
  }

  String get _wallpaperLabel => _customWallpaperPath == null
      ? _kFocusWallpapers[_wallpaperIndex].label
      : 'Your Photo';

  Future<void> _recoverLostCustomWallpaper() async {
    try {
      final response = await ImagePicker().retrieveLostData();
      if (response.isEmpty || response.file == null) return;
      await _saveCustomWallpaper(response.file!);
    } catch (_) {
      // Lost-data recovery is Android-specific and should never block Focus.
    }
  }

  Future<void> _pickCustomWallpaper() async {
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 2160,
        imageQuality: 90,
      );
      if (image == null) return;
      await _saveCustomWallpaper(image);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not use that photo: $error')),
      );
    }
  }

  Future<void> _saveCustomWallpaper(XFile image) async {
    final extension =
        RegExp(
          r'\.(jpe?g|png|webp)$',
          caseSensitive: false,
        ).firstMatch(image.name)?.group(0) ??
        '.jpg';
    final directory = Directory(
      '${(await getApplicationDocumentsDirectory()).path}/focus_wallpapers',
    );
    await directory.create(recursive: true);

    // Each selection gets a new path, preventing Flutter's ImageCache from
    // reusing pixels from a previously chosen file with the same filename.
    final destination = File(
      '${directory.path}/wallpaper_${DateTime.now().microsecondsSinceEpoch}$extension',
    );
    await image.saveTo(destination.path);

    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _customWallpaperPathPreferenceKey,
      destination.path,
    );

    final previousPath = _customWallpaperPath;
    if (!mounted) return;
    setState(() => _customWallpaperPath = destination.path);
    if (previousPath != null && previousPath != destination.path) {
      try {
        await File(previousPath).delete();
      } catch (_) {
        // The old file is no longer referenced, so it can be cleaned up on a
        // later selection without interrupting the newly chosen wallpaper.
      }
    }
  }

  Future<void> _selectDrawerTheme(_FocusDrawerTheme theme) async {
    if (theme == _drawerTheme) return;
    setState(() => _drawerTheme = theme);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_focusDrawerThemePreferenceKey, theme.name);
  }

  Future<void> _showWallpaperPicker(_FocusPalette palette) async {
    final isTablet = isTabletLayout(context);
    final selectedIndex = await showModalBottomSheet<int>(
      context: context,
      useRootNavigator: true,
      backgroundColor: palette.bgColor,
      showDragHandle: true,
      isScrollControlled: true,
      constraints: isTablet
          ? tabletDialogConstraints(
              context,
              portraitWidth: 700,
              landscapeWidth: 880,
              heightFactor: 0.9,
            )
          : null,
      builder: (sheetContext) => FractionallySizedBox(
        // A two-column grid needs room for multiple wallpaper rows plus the
        // action card. Keep it below the status area while avoiding clipped
        // cards on compact phone screens.
        heightFactor: isTablet ? 0.88 : 0.96,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose a focus wallpaper',
                  style: GoogleFonts.outfit(
                    color: palette.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Scrollbar(
                    child: GridView.builder(
                      padding: const EdgeInsets.only(bottom: 8),
                      itemCount: _kFocusWallpapers.length + 1,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.28,
                          ),
                      itemBuilder: (context, index) {
                        final isCustom = index == _kFocusWallpapers.length;
                        if (isCustom) {
                          final customFile = _customWallpaperPath == null
                              ? null
                              : File(_customWallpaperPath!);
                          final selected =
                              customFile != null && customFile.existsSync();
                          return GestureDetector(
                            onTap: () => Navigator.pop(sheetContext, index),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: ColoredBox(
                                    color: palette.tileBg,
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        if (customFile != null)
                                          Image.file(
                                            customFile,
                                            fit: BoxFit.cover,
                                          ),
                                        if (customFile != null)
                                          const DecoratedBox(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                                colors: [
                                                  Colors.transparent,
                                                  Color(0xB8000000),
                                                ],
                                              ),
                                            ),
                                          ),
                                        Center(
                                          child: Icon(
                                            Icons.add_photo_alternate_outlined,
                                            color: customFile == null
                                                ? palette.textPrimary
                                                : Colors.white,
                                            size: 34,
                                          ),
                                        ),
                                        Positioned(
                                          left: 10,
                                          right: 10,
                                          bottom: 9,
                                          child: Text(
                                            customFile == null
                                                ? 'Add your photo'
                                                : 'Change your photo',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.outfit(
                                              color: customFile == null
                                                  ? palette.textPrimary
                                                  : Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        if (selected)
                                          const Positioned(
                                            top: 8,
                                            right: 8,
                                            child: Icon(
                                              Icons.check_circle,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                                IgnorePointer(
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: selected
                                            ? palette.accent
                                            : palette.tileBorder,
                                        width: selected ? 2 : 1,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        final wallpaper = _kFocusWallpapers[index];
                        final selected =
                            _customWallpaperPath == null &&
                            index == _wallpaperIndex;
                        return GestureDetector(
                          onTap: () => Navigator.pop(sheetContext, index),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            foregroundDecoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: selected
                                    ? palette.accent
                                    : palette.tileBorder,
                                width: selected ? 2 : 1,
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.asset(wallpaper.asset, fit: BoxFit.cover),
                                const DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Color(0xB8000000),
                                      ],
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: 10,
                                  right: 10,
                                  bottom: 9,
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          wallpaper.label,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.outfit(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      if (selected)
                                        const Icon(
                                          Icons.check_circle,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (selectedIndex == _kFocusWallpapers.length) {
      await _pickCustomWallpaper();
    } else if (selectedIndex != null) {
      await _selectWallpaper(selectedIndex);
    }
  }

  Future<void> _showThemePicker(_FocusPalette palette) async {
    final isTablet = isTabletLayout(context);
    final selectedTheme = await showModalBottomSheet<AppThemeChoice>(
      context: context,
      useRootNavigator: true,
      backgroundColor: palette.bgColor,
      showDragHandle: true,
      isScrollControlled: true,
      constraints: isTablet
          ? tabletDialogConstraints(
              context,
              portraitWidth: 680,
              landscapeWidth: 820,
              heightFactor: 0.78,
            )
          : null,
      builder: (sheetContext) => FractionallySizedBox(
        heightFactor: isTablet ? 0.72 : 0.54,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose your app theme',
                  style: GoogleFonts.outfit(
                    color: palette.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'This theme is used across Focus and the rest of the app.',
                  style: GoogleFonts.outfit(
                    color: palette.textMuted,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: GridView.builder(
                    padding: EdgeInsets.zero,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _focusThemeOrder.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.42,
                        ),
                    itemBuilder: (context, index) {
                      final theme = _focusThemeOrder[index];
                      final preview = _FocusPalette.forTheme(theme);
                      final selected = theme == _focusTheme;
                      return Material(
                        color: preview.bgColor,
                        borderRadius: BorderRadius.circular(18),
                        child: InkWell(
                          onTap: () => Navigator.pop(sheetContext, theme),
                          borderRadius: BorderRadius.circular(18),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: selected
                                    ? preview.accent
                                    : preview.tileBorder,
                                width: selected ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      _themeIcon(theme),
                                      color: preview.accent,
                                      size: 22,
                                    ),
                                    const Spacer(),
                                    if (selected)
                                      Icon(
                                        Icons.check_circle,
                                        color: preview.accent,
                                        size: 19,
                                      ),
                                  ],
                                ),
                                const Spacer(),
                                Text(
                                  theme.label,
                                  style: GoogleFonts.outfit(
                                    color: preview.textPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    _ThemeSwatch(color: preview.accent),
                                    const SizedBox(width: 6),
                                    _ThemeSwatch(color: preview.tileBg),
                                    const SizedBox(width: 6),
                                    _ThemeSwatch(color: preview.textPrimary),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (selectedTheme == null || selectedTheme == _focusTheme || !mounted) {
      return;
    }
    setState(() => _focusTheme = selectedTheme);
    await context.read<SettingsProvider>().setThemeChoice(selectedTheme);
  }

  Future<void> _showDrawerThemePicker(_FocusPalette palette) async {
    final isTablet = isTabletLayout(context);
    final selectedTheme = await showModalBottomSheet<_FocusDrawerTheme>(
      context: context,
      useRootNavigator: true,
      backgroundColor: palette.bgColor,
      showDragHandle: true,
      isScrollControlled: true,
      constraints: isTablet
          ? tabletDialogConstraints(
              context,
              portraitWidth: 700,
              landscapeWidth: 880,
              heightFactor: 0.84,
            )
          : null,
      builder: (sheetContext) => FractionallySizedBox(
        heightFactor: isTablet ? 0.82 : 0.92,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose an app drawer style',
                  style: GoogleFonts.outfit(
                    color: palette.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Change the shortcut icon and button appearance.',
                  style: GoogleFonts.outfit(
                    color: palette.textMuted,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      const columnCount = 2;
                      final rowCount =
                          (_focusDrawerThemeDisplayOrder.length / columnCount)
                              .ceil();
                      final mainSpacing = constraints.maxHeight < 520
                          ? 4.0
                          : 8.0;
                      final calculatedHeight =
                          (constraints.maxHeight -
                              (mainSpacing * (rowCount - 1))) /
                          rowCount;
                      final cardHeight = calculatedHeight > 1
                          ? calculatedHeight
                          : 1.0;
                      final textScale = MediaQuery.textScalerOf(
                        sheetContext,
                      ).scale(1).clamp(1.0, 2.0).toDouble();
                      final visualScale = (cardHeight / (128 * textScale))
                          .clamp(0.35, 1.0)
                          .toDouble();

                      return GridView.builder(
                        padding: EdgeInsets.zero,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _focusDrawerThemeDisplayOrder.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columnCount,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: mainSpacing,
                          mainAxisExtent: cardHeight,
                        ),
                        itemBuilder: (context, index) {
                          final theme = _focusDrawerThemeDisplayOrder[index];
                          return _FocusDrawerThemeCard(
                            theme: theme,
                            selected: theme == _drawerTheme,
                            palette: palette,
                            visualScale: visualScale,
                            onTap: () => Navigator.pop(sheetContext, theme),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (selectedTheme != null) await _selectDrawerTheme(selectedTheme);
  }

  Future<void> _showFocusOptions(_FocusPalette palette) async {
    await showGeneralDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: true,
      barrierLabel: 'Close focus options',
      barrierColor: Colors.black.withAlpha(110),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (dialogContext, _, _) {
        final isTablet = isTabletLayout(dialogContext);
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Material(
            color: Colors.transparent,
            child: Stack(
              fit: StackFit.expand,
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.pop(dialogContext),
                  child: const SizedBox.expand(),
                ),
                SafeArea(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                          child: Container(
                            width: isTablet
                                ? tabletPopupWidth(
                                    dialogContext,
                                    portrait: 560,
                                    landscape: 640,
                                  )
                                : 340,
                            constraints: isTablet
                                ? BoxConstraints(
                                    maxHeight:
                                        MediaQuery.sizeOf(
                                          dialogContext,
                                        ).height *
                                        0.86,
                                  )
                                : null,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.black.withAlpha(125),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: Colors.white.withAlpha(55),
                              ),
                            ),
                            child: scrollOnTablet(
                              dialogContext,
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Focus options',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Adjust your focus environment',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white.withAlpha(155),
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  _FocusOptionTile(
                                    icon: Icons.wallpaper_outlined,
                                    title: 'Wallpaper',
                                    value: _wallpaperLabel,
                                    onTap: () {
                                      Navigator.pop(dialogContext);
                                      Future<void>.microtask(() {
                                        if (mounted) {
                                          _showWallpaperPicker(palette);
                                        }
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 10),
                                  _FocusOptionTile(
                                    icon: _themeIcon(_focusTheme),
                                    title: 'Theme',
                                    value:
                                        '${_focusTheme.label} · choose theme',
                                    onTap: () {
                                      Navigator.pop(dialogContext);
                                      Future<void>.microtask(() {
                                        if (mounted) _showThemePicker(palette);
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 10),
                                  _FocusOptionTile(
                                    icon: _drawerTheme.icon,
                                    title: 'App drawer style',
                                    value:
                                        '${_drawerTheme.label} · icons and buttons',
                                    onTap: () {
                                      Navigator.pop(dialogContext);
                                      Future<void>.microtask(() {
                                        if (mounted) {
                                          _showDrawerThemePicker(palette);
                                        }
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 10),
                                  _FocusOptionTile(
                                    icon: Icons.restart_alt_rounded,
                                    title: 'Reset app order',
                                    value: 'Restore the default 21-app layout',
                                    onTap: () async {
                                      await resetFocusShortcutOrder();
                                      if (dialogContext.mounted) {
                                        Navigator.pop(dialogContext);
                                      }
                                    },
                                  ),
                                  const SizedBox(height: 10),
                                  _FocusOptionTile(
                                    icon: Icons.help_outline,
                                    title: 'Walkthrough',
                                    value: 'Tour the Focus Mode controls',
                                    onTap: () {
                                      Navigator.pop(dialogContext);
                                      Future<void>.microtask(() {
                                        if (mounted) _showFocusWalkthrough();
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 10),
                                  _FocusOptionTile(
                                    icon: Icons.dashboard_outlined,
                                    title: 'Exit Focus',
                                    value: 'Return to Overview',
                                    isExit: true,
                                    onTap: () {
                                      Navigator.pop(dialogContext);
                                      Future<void>.microtask(() {
                                        if (mounted) {
                                          Navigator.of(
                                            context,
                                            rootNavigator: true,
                                          ).pop();
                                        }
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, _, child) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.96, end: 1).animate(animation),
          child: child,
        ),
      ),
    );
  }

  Future<FocusAppShortcut?> _chooseAppFromDrawer({
    BuildContext? hostContext,
  }) async {
    if (_isAppDrawerOpen) return null;
    _isAppDrawerOpen = true;
    try {
      return await showFocusShortcutDrawer(
        hostContext ?? context,
        optionsKey: _optionsKey,
        onOpenSettings: _openFocusSettings,
        onOpenOptions: () {
          if (mounted) {
            _showFocusOptions(_FocusPalette.forTheme(_focusTheme));
          }
        },
      );
    } finally {
      _isAppDrawerOpen = false;
    }
  }

  Future<void> _showAppDrawer() async {
    final shortcut = await _chooseAppFromDrawer();
    if (shortcut != null && mounted) {
      Navigator.of(context, rootNavigator: true).pop(shortcut);
    }
  }

  Future<bool> _showAppDrawerOverSettings(BuildContext settingsContext) async {
    final shortcut = await _chooseAppFromDrawer(hostContext: settingsContext);
    if (shortcut == null || !mounted) return false;
    _settingsShortcutToLaunch = shortcut;
    return true;
  }

  Future<void> _openFocusSettings() async {
    final target = await Navigator.of(context, rootNavigator: true)
        .push<PreferredHomeTarget>(
          PageRouteBuilder<PreferredHomeTarget>(
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
            pageBuilder: (_, _, _) => SettingsPage(
              focusMode: true,
              onOpenAi: () => Navigator.of(
                context,
                rootNavigator: true,
              ).pop(FocusAppShortcut.coaching),
              onOpenApps: _showAppDrawerOverSettings,
              onOpenCalendar: () => Navigator.of(
                context,
                rootNavigator: true,
              ).pop(FocusAppShortcut.calendar),
            ),
          ),
        );
    if (!mounted) return;
    final shortcut = _settingsShortcutToLaunch;
    _settingsShortcutToLaunch = null;
    if (shortcut != null) {
      Navigator.of(context, rootNavigator: true).pop(shortcut);
      return;
    }
    if (target == PreferredHomeTarget.overview) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  void _handleFocusSwipeStart(DragStartDetails details) {
    _focusSwipeDistance = 0;
    final mediaQuery = MediaQuery.of(context);
    final isPhoneLayout = mediaQuery.size.shortestSide < 600;
    final bottomNavigationTop =
        mediaQuery.size.height - mediaQuery.padding.bottom - 72;
    _focusSwipeStartedInBody =
        !isPhoneLayout || details.globalPosition.dy < bottomNavigationTop;
  }

  void _handleFocusSwipeUpdate(DragUpdateDetails details) {
    if (!_focusSwipeStartedInBody) return;
    _focusSwipeDistance += details.primaryDelta ?? 0;
  }

  void _handleFocusSwipeEnd(DragEndDetails details) {
    if (!_focusSwipeStartedInBody) {
      _focusSwipeDistance = 0;
      return;
    }
    final upwardVelocity = (details.primaryVelocity ?? 0) < -450;
    final upwardDistance = _focusSwipeDistance < -64;
    _focusSwipeDistance = 0;
    _focusSwipeStartedInBody = false;
    if (upwardVelocity || upwardDistance) {
      _showAppDrawer();
    }
  }

  void _showFocusWalkthrough() {
    SpotlightWalkthrough.show(
      context,
      translucent: true,
      scrollTargetsIntoView: false,
      steps: [
        SpotlightStep(
          targetKey: _settingsKey,
          title: 'Settings',
          body:
              'Open app settings to manage your account, preferences, theme, and navigation mode.',
        ),
        SpotlightStep(
          targetKey: _clockKey,
          title: 'Focus Clock',
          body:
              'Keep time visible without distracting notifications or widgets.',
        ),
        SpotlightStep(
          targetKey: _appDrawerKey,
          title: 'Apps and Focus Options',
          body:
              'Access all 21 app modules organized into Finance, Wellness, and Productivity. Use the wrench for Focus tools and the gear icon for Settings.',
        ),
        SpotlightStep(
          targetKey: _insightKey,
          title: 'Daily Insight',
          body:
              'Use the daily thought as a calm prompt for your focus session.',
        ),
        SpotlightStep(
          targetKey: _goalKey,
          title: 'Focus Goal',
          body: 'Keep your primary goal visible while you work.',
        ),
        SpotlightStep(
          targetKey: _taskKey,
          title: 'Next Quick Task',
          body: 'See the next practical action waiting for your attention.',
        ),
      ],
    );
  }

  Future<void> _loadGoal() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;
      final client = Supabase.instance.client;
      final primaryGoal = await client
          .from('items')
          .select()
          .eq('user_id', userId)
          .eq('section', 'activeGoals')
          .eq('is_primary', true)
          .neq('status', 'deleted')
          .neq('status', 'trashed')
          .or('archived.is.null,archived.eq.false')
          .order('order_index', ascending: true, nullsFirst: false)
          .order('created_at', ascending: true)
          .limit(1)
          .maybeSingle();

      final fallbackGoal =
          primaryGoal ??
          await client
              .from('items')
              .select()
              .eq('user_id', userId)
              .eq('section', 'activeGoals')
              .neq('status', 'deleted')
              .neq('status', 'trashed')
              .or('archived.is.null,archived.eq.false')
              .order('order_index', ascending: true, nullsFirst: false)
              .order('created_at', ascending: true)
              .limit(1)
              .maybeSingle();

      if (mounted && fallbackGoal != null) {
        setState(() => _focusGoal = Goal.fromJson(fallbackGoal));
      }
    } catch (_) {}
  }

  void _openFocusGoal() {
    final goal = _focusGoal;
    if (goal == null) {
      Navigator.of(context, rootNavigator: true).pop(FocusAppShortcut.goals);
      return;
    }
    Navigator.of(
      context,
      rootNavigator: true,
    ).push(MaterialPageRoute<void>(builder: (_) => GoalDetailPage(goal: goal)));
  }

  Future<void> _loadNextTask() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      // Tasks are stored as embedded JSON inside the task_boards row
      final boardRes = await Supabase.instance.client
          .from('task_boards')
          .select()
          .eq('user_id', userId)
          .eq('board_id', 'quick-tasks-board')
          .maybeSingle();

      if (boardRes == null) return;

      final lists = (boardRes['lists'] as List?) ?? [];
      // Use first list (primary "My Tasks")
      if (lists.isEmpty) return;
      final firstList = lists.first;
      final tasks = (firstList['tasks'] as List?) ?? [];

      // Find the first incomplete task
      for (final t in tasks) {
        final completed = t['completed'] as bool? ?? false;
        final status = t['status'] as String? ?? '';
        if (!completed && status != 'done') {
          final text = t['content'] as String? ?? t['text'] as String? ?? '';
          if (text.isNotEmpty && mounted) {
            setState(() => _nextTask = text);
          }
          return;
        }
      }
    } catch (_) {}
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Focus and Settings are two views of the same app-wide theme choice.
    // Watching the provider also updates an already-open Focus screen when
    // the user changes the theme from Settings.
    _focusTheme = context.watch<SettingsProvider>().themeChoice;
  }

  String get _hourString => _now.hour.toString().padLeft(2, '0');
  String get _minuteString => _now.minute.toString().padLeft(2, '0');

  String get _dateString {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${days[_now.weekday - 1]}, ${_now.day} ${months[_now.month - 1]}';
  }

  Widget _buildTabletFocusLayout(_FocusPalette palette) {
    final panelWidth = (MediaQuery.sizeOf(context).width * 0.45)
        .clamp(320.0, 440.0)
        .toDouble();
    return Stack(
      children: [
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(126, 36, 38, 36),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'POWER FOCUS',
                        style: GoogleFonts.outfit(
                          color: Colors.white.withAlpha(180),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2.2,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Column(
                        key: _clockKey,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _dateString,
                            style: GoogleFonts.outfit(
                              color: Colors.white.withAlpha(225),
                              fontSize: 16,
                              letterSpacing: 1.3,
                              shadows: const [
                                Shadow(color: Colors.black54, blurRadius: 12),
                              ],
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '$_hourString:$_minuteString',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 68,
                              height: 0.95,
                              fontWeight: FontWeight.w300,
                              letterSpacing: -3,
                              shadows: const [
                                Shadow(color: Colors.black54, blurRadius: 16),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 430),
                        child: _MiniWeekCalendar(now: _now),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 42),
                SizedBox(
                  width: panelWidth,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _Tile(
                        key: _insightKey,
                        icon: Icons.format_quote_outlined,
                        label: 'INSIGHT',
                        value: '"${_todayQuote['text']!}"',
                        subValue: '— ${_todayQuote['author']!}',
                        isDark: palette.isDark,
                        accent: palette.accent,
                        textPrimary: palette.textPrimary,
                        textLabel: palette.textLabel,
                        tileBg: palette.tileBg,
                        tileBorder: palette.tileBorder,
                        italic: true,
                        onTap: () => Navigator.of(
                          context,
                          rootNavigator: true,
                        ).pop(FocusAppShortcut.insights),
                      ),
                      const SizedBox(height: 14),
                      _Tile(
                        key: _goalKey,
                        icon: Icons.flag_outlined,
                        label: 'FOCUS GOAL',
                        value: _focusGoal?.text ?? 'No active goal set',
                        isDark: palette.isDark,
                        accent: palette.accent,
                        textPrimary: palette.textPrimary,
                        textLabel: palette.textLabel,
                        tileBg: palette.tileBg,
                        tileBorder: palette.tileBorder,
                        onTap: _openFocusGoal,
                      ),
                      const SizedBox(height: 14),
                      _Tile(
                        key: _taskKey,
                        icon: Icons.check_circle_outline,
                        label: 'NEXT QUICK TASK',
                        value: _nextTask ?? 'All clear — no pending tasks',
                        isDark: palette.isDark,
                        accent: palette.accent,
                        textPrimary: palette.textPrimary,
                        textLabel: palette.textLabel,
                        tileBg: palette.tileBg,
                        tileBorder: palette.tileBorder,
                        onTap: () => Navigator.of(
                          context,
                          rootNavigator: true,
                        ).pop(FocusAppShortcut.tasks),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          child: FocusModeNavRail(
            appsKey: _appDrawerKey,
            settingsKey: _settingsKey,
            focusSelected: true,
            backgroundColor: Colors.black.withAlpha(105),
            iconColor: Colors.white.withAlpha(220),
            onOpenAi: () => Navigator.of(
              context,
              rootNavigator: true,
            ).pop(FocusAppShortcut.coaching),
            onOpenApps: _showAppDrawer,
            onOpenFocus: () {},
            onOpenCalendar: () => Navigator.of(
              context,
              rootNavigator: true,
            ).pop(FocusAppShortcut.calendar),
            onOpenSettings: _openFocusSettings,
          ),
        ),
      ],
    );
  }

  Widget _buildWallpaperImage() {
    final customWallpaperPath = _customWallpaperPath;
    if (customWallpaperPath != null) {
      final customFile = File(customWallpaperPath);
      if (customFile.existsSync()) {
        return Image.file(
          customFile,
          fit: BoxFit.cover,
          alignment: Alignment.center,
          errorBuilder: (_, _, _) => Image.asset(
            _kFocusWallpapers[_wallpaperIndex].asset,
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
        );
      }
    }
    return Image.asset(
      _kFocusWallpapers[_wallpaperIndex].asset,
      fit: BoxFit.cover,
      alignment: Alignment.center,
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = _FocusPalette.forTheme(_focusTheme);

    return FadeTransition(
      opacity: _fadeAnim,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onLongPress: () => _showFocusOptions(palette),
        onVerticalDragStart: _handleFocusSwipeStart,
        onVerticalDragUpdate: _handleFocusSwipeUpdate,
        onVerticalDragEnd: _handleFocusSwipeEnd,
        onVerticalDragCancel: () {
          _focusSwipeDistance = 0;
          _focusSwipeStartedInBody = false;
        },
        child: Material(
          color: Colors.black,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildWallpaperImage(),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x78000000),
                      Color(0x08000000),
                      Color(0x99000000),
                    ],
                    stops: [0, 0.38, 1],
                  ),
                ),
              ),
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth >= 700) {
                    return _buildTabletFocusLayout(palette);
                  }
                  final compact = constraints.maxHeight < 720;
                  final gap = compact ? 8.0 : 10.0;
                  return Stack(
                    children: [
                      SafeArea(
                        child: Stack(
                          children: [
                            Positioned(
                              left: 22,
                              right: 22,
                              bottom: compact ? 78 : 84,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Expanded(
                                        flex: 4,
                                        child: Column(
                                          key: _clockKey,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _dateString,
                                              maxLines: 1,
                                              style: GoogleFonts.outfit(
                                                color: Colors.white.withAlpha(
                                                  220,
                                                ),
                                                fontSize: 11,
                                                letterSpacing: 1.2,
                                                shadows: const [
                                                  Shadow(
                                                    color: Colors.black54,
                                                    blurRadius: 10,
                                                    offset: Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              '$_hourString:$_minuteString',
                                              maxLines: 1,
                                              style: GoogleFonts.outfit(
                                                color: Colors.white,
                                                fontSize: compact ? 38 : 42,
                                                fontWeight: FontWeight.w300,
                                                height: 0.95,
                                                letterSpacing: -2,
                                                shadows: const [
                                                  Shadow(
                                                    color: Colors.black54,
                                                    blurRadius: 12,
                                                    offset: Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        flex: 7,
                                        child: _MiniWeekCalendar(now: _now),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: compact ? 10 : 14),
                                  _Tile(
                                    key: _insightKey,
                                    icon: Icons.format_quote_outlined,
                                    label: 'INSIGHT',
                                    value: '"${_todayQuote['text']!}"',
                                    subValue: '— ${_todayQuote['author']!}',
                                    isDark: palette.isDark,
                                    accent: palette.accent,
                                    textPrimary: palette.textPrimary,
                                    textLabel: palette.textLabel,
                                    tileBg: palette.tileBg,
                                    tileBorder: palette.tileBorder,
                                    italic: true,
                                    compact: compact,
                                    onTap: () => Navigator.of(
                                      context,
                                      rootNavigator: true,
                                    ).pop(FocusAppShortcut.insights),
                                  ),
                                  SizedBox(height: gap),
                                  _Tile(
                                    key: _goalKey,
                                    icon: Icons.flag_outlined,
                                    label: 'FOCUS GOAL',
                                    value:
                                        _focusGoal?.text ??
                                        'No active goal set',
                                    isDark: palette.isDark,
                                    accent: palette.accent,
                                    textPrimary: palette.textPrimary,
                                    textLabel: palette.textLabel,
                                    tileBg: palette.tileBg,
                                    tileBorder: palette.tileBorder,
                                    compact: compact,
                                    onTap: _openFocusGoal,
                                  ),
                                  SizedBox(height: gap),
                                  _Tile(
                                    key: _taskKey,
                                    icon: Icons.check_circle_outline,
                                    label: 'NEXT QUICK TASK',
                                    value:
                                        _nextTask ??
                                        'All clear — no pending tasks',
                                    isDark: palette.isDark,
                                    accent: palette.accent,
                                    textPrimary: palette.textPrimary,
                                    textLabel: palette.textLabel,
                                    tileBg: palette.tileBg,
                                    tileBorder: palette.tileBorder,
                                    compact: compact,
                                    onTap: () => Navigator.of(
                                      context,
                                      rootNavigator: true,
                                    ).pop(FocusAppShortcut.tasks),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: FocusModeNavBar(
                          appsKey: _appDrawerKey,
                          settingsKey: _settingsKey,
                          focusSelected: true,
                          backgroundColor: Colors.black.withAlpha(105),
                          iconColor: Colors.white.withAlpha(220),
                          onOpenAi: () => Navigator.of(
                            context,
                            rootNavigator: true,
                          ).pop(FocusAppShortcut.coaching),
                          onOpenApps: _showAppDrawer,
                          onOpenFocus: () {},
                          onOpenCalendar: () => Navigator.of(
                            context,
                            rootNavigator: true,
                          ).pop(FocusAppShortcut.calendar),
                          onOpenSettings: _openFocusSettings,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

IconData _themeIcon(AppThemeChoice choice) {
  switch (choice) {
    case AppThemeChoice.lake:
      return Icons.landscape_outlined;
    case AppThemeChoice.slate:
      return Icons.layers_outlined;
    case AppThemeChoice.white:
      return Icons.light_mode;
    case AppThemeChoice.black:
      return Icons.dark_mode;
  }
}

class _FocusPalette {
  final bool isDark;
  final Color bgColor;
  final Color accent;
  final Color textPrimary;
  final Color textMuted;
  final Color textLabel;
  final Color tileBg;
  final Color tileBorder;
  final Color dividerFade;
  final Color chipText;

  const _FocusPalette({
    required this.isDark,
    required this.bgColor,
    required this.accent,
    required this.textPrimary,
    required this.textMuted,
    required this.textLabel,
    required this.tileBg,
    required this.tileBorder,
    required this.dividerFade,
    required this.chipText,
  });

  factory _FocusPalette.forTheme(AppThemeChoice choice) {
    switch (choice) {
      case AppThemeChoice.lake:
        return _FocusPalette(
          isDark: false,
          bgColor: const Color(0xFFF4F8F5),
          accent: const Color(0xFF77ADA4),
          textPrimary: const Color(0xFF173A28),
          textMuted: const Color(0xFF2C5954).withAlpha(150),
          textLabel: const Color(0xFF2C5954).withAlpha(105),
          tileBg: Colors.white.withAlpha(128),
          tileBorder: const Color(0xFF77ADA4).withAlpha(95),
          dividerFade: const Color(0xFF77ADA4).withAlpha(35),
          chipText: const Color(0xFF2C5954),
        );
      case AppThemeChoice.slate:
        return _FocusPalette(
          isDark: true,
          bgColor: const Color(0xFF0B0E12),
          accent: const Color(0xFF7F9BB8),
          textPrimary: Colors.white,
          textMuted: const Color(0xFFB5C0C9).withAlpha(190),
          textLabel: const Color(0xFF7F9BB8).withAlpha(170),
          tileBg: const Color(0xFF101820).withAlpha(138),
          tileBorder: const Color(0xFF3F4A55),
          dividerFade: Colors.transparent,
          chipText: const Color(0xFFE8ECEF),
        );
      case AppThemeChoice.white:
        return _FocusPalette(
          isDark: false,
          bgColor: const Color(0xFFF9FAFB),
          accent: const Color(0xFF065F46),
          textPrimary: const Color(0xFF18181B),
          textMuted: const Color(0xFF4B5563),
          textLabel: const Color(0xFF6B7280),
          tileBg: Colors.white.withAlpha(138),
          tileBorder: const Color(0xFFE5E7EB),
          dividerFade: const Color(0xFFE5E7EB),
          chipText: const Color(0xFF065F46),
        );
      case AppThemeChoice.black:
        return _FocusPalette(
          isDark: true,
          bgColor: const Color(0xFF050506),
          accent: const Color(0xFF10B981),
          textPrimary: Colors.white,
          textMuted: const Color(0xFFEDEFEF).withAlpha(170),
          textLabel: const Color(0xFF8D9491),
          tileBg: const Color(0xFF101113).withAlpha(145),
          tileBorder: const Color(0xFF33383B),
          dividerFade: Colors.transparent,
          chipText: const Color(0xFFEDEFEF),
        );
    }
  }
}

class _ThemeSwatch extends StatelessWidget {
  final Color color;

  const _ThemeSwatch({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withAlpha(35)),
      ),
    );
  }
}

class _FocusDrawerThemeCard extends StatelessWidget {
  final _FocusDrawerTheme theme;
  final bool selected;
  final _FocusPalette palette;
  final double visualScale;
  final VoidCallback onTap;

  const _FocusDrawerThemeCard({
    required this.theme,
    required this.selected,
    required this.palette,
    required this.visualScale,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scale = visualScale;
    final radius = 18 * scale;
    return Material(
      color: palette.tileBg,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Container(
          padding: EdgeInsets.all(11 * scale),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: selected ? palette.accent : palette.tileBorder,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(theme.icon, color: palette.accent, size: 20 * scale),
                  const Spacer(),
                  if (selected)
                    Icon(
                      Icons.check_circle,
                      color: palette.accent,
                      size: 18 * scale,
                    ),
                ],
              ),
              SizedBox(height: 8 * scale),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 9 * scale,
                  vertical: 5 * scale,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(145),
                  borderRadius: BorderRadius.circular(12 * scale),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _FocusDrawerButtonPreview(
                      theme: theme,
                      accent: const Color(0xFF62D6A7),
                      icon: Icons.account_balance_wallet_outlined,
                      visualScale: scale,
                    ),
                    _FocusDrawerButtonPreview(
                      theme: theme,
                      accent: const Color(0xFF78A9FF),
                      icon: Icons.psychology_alt_outlined,
                      visualScale: scale,
                    ),
                    _FocusDrawerButtonPreview(
                      theme: theme,
                      accent: const Color(0xFFC493FF),
                      icon: Icons.auto_awesome,
                      visualScale: scale,
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                theme.label,
                style: GoogleFonts.outfit(
                  color: palette.textPrimary,
                  fontSize: 15 * scale,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 2 * scale),
              Text(
                theme.description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  color: palette.textMuted,
                  fontSize: 10 * scale,
                  height: 1.15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FocusDrawerButtonPreview extends StatelessWidget {
  final _FocusDrawerTheme theme;
  final Color accent;
  final IconData icon;
  final double visualScale;

  const _FocusDrawerButtonPreview({
    required this.theme,
    required this.accent,
    required this.icon,
    required this.visualScale,
  });

  @override
  Widget build(BuildContext context) {
    final scale = visualScale;
    final isTextPreview =
        theme == _FocusDrawerTheme.text || theme == _FocusDrawerTheme.textDot;
    if (isTextPreview) {
      return SizedBox(
        width: 34 * scale,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: SizedBox(
                height: 2 * scale,
                child: const ColoredBox(color: Colors.white70),
              ),
            ),
            if (theme == _FocusDrawerTheme.textDot) ...[
              SizedBox(width: 3 * scale),
              Container(
                width: 5 * scale,
                height: 5 * scale,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      );
    }

    final isSquare =
        theme == _FocusDrawerTheme.colour ||
        theme == _FocusDrawerTheme.solid ||
        theme == _FocusDrawerTheme.technicolour ||
        theme == _FocusDrawerTheme.unite;
    final background = switch (theme) {
      _FocusDrawerTheme.glass => Colors.white.withAlpha(28),
      _FocusDrawerTheme.colour => accent.withAlpha(90),
      _FocusDrawerTheme.outline => accent.withAlpha(235),
      _FocusDrawerTheme.solid => Colors.white.withAlpha(230),
      _FocusDrawerTheme.technicolour => accent,
      _FocusDrawerTheme.unite => Colors.transparent,
      _FocusDrawerTheme.text || _FocusDrawerTheme.textDot => Colors.transparent,
    };
    final border = switch (theme) {
      _FocusDrawerTheme.glass => Colors.white.withAlpha(65),
      _FocusDrawerTheme.colour => accent.withAlpha(210),
      _FocusDrawerTheme.outline => accent,
      _FocusDrawerTheme.solid => Colors.white,
      _FocusDrawerTheme.technicolour => Colors.white.withAlpha(190),
      _FocusDrawerTheme.unite => Colors.white.withAlpha(190),
      _FocusDrawerTheme.text || _FocusDrawerTheme.textDot => Colors.transparent,
    };
    final foreground =
        theme == _FocusDrawerTheme.solid || theme == _FocusDrawerTheme.outline
        ? const Color(0xFF17212B)
        : Colors.white;

    return Container(
      width: 34 * scale,
      height: 34 * scale,
      decoration: BoxDecoration(
        color: background,
        gradient: theme == _FocusDrawerTheme.unite
            ? SweepGradient(
                colors: [
                  ..._uniteColours.skip(icon.codePoint % _uniteColours.length),
                  ..._uniteColours.take(icon.codePoint % _uniteColours.length),
                  _uniteColours[icon.codePoint % _uniteColours.length],
                ],
              )
            : null,
        shape: isSquare ? BoxShape.rectangle : BoxShape.circle,
        borderRadius: isSquare ? BorderRadius.circular(10 * scale) : null,
        border: Border.all(color: border),
      ),
      child: Icon(icon, size: 17 * scale, color: foreground),
    );
  }
}

class _FocusOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final bool isExit;
  final VoidCallback onTap;

  const _FocusOptionTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
    this.isExit = false,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = isExit
        ? const Color(0xFFFFC2BC)
        : Colors.white.withAlpha(235);

    return Material(
      color: Colors.white.withAlpha(18),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withAlpha(35)),
          ),
          child: Row(
            children: [
              Icon(icon, color: foreground, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        color: foreground,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        color: Colors.white.withAlpha(135),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.white.withAlpha(105),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniWeekCalendar extends StatelessWidget {
  final DateTime now;

  const _MiniWeekCalendar({required this.now});

  @override
  Widget build(BuildContext context) {
    const dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final today = DateTime(now.year, now.month, now.day);
    final monday = today.subtract(Duration(days: today.weekday - 1));

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(72),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withAlpha(62)),
          ),
          child: Row(
            children: List.generate(7, (index) {
              final date = monday.add(Duration(days: index));
              final isToday = date == today;
              return Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      dayLabels[index],
                      style: GoogleFonts.outfit(
                        color: Colors.white.withAlpha(isToday ? 245 : 150),
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 22,
                      height: 22,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isToday
                            ? Colors.white.withAlpha(220)
                            : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${date.day}',
                        style: GoogleFonts.outfit(
                          color: isToday
                              ? const Color(0xFF173A28)
                              : Colors.white.withAlpha(220),
                          fontSize: 10,
                          fontWeight: isToday
                              ? FontWeight.w800
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Data tile
// ---------------------------------------------------------------------------
class _Tile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? subValue;
  final bool italic;
  final bool isDark;
  final Color accent;
  final Color textPrimary;
  final Color textLabel;
  final Color tileBg;
  final Color tileBorder;
  final bool compact;
  final VoidCallback onTap;

  const _Tile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.subValue,
    this.italic = false,
    required this.isDark,
    required this.accent,
    required this.textPrimary,
    required this.textLabel,
    required this.tileBg,
    required this.tileBorder,
    this.compact = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Open $label',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: EdgeInsets.all(compact ? 11 : 14),
              decoration: BoxDecoration(
                color: tileBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: tileBorder),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(compact ? 6 : 8),
                    decoration: BoxDecoration(
                      color: accent.withAlpha(20),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: accent, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: GoogleFonts.outfit(
                            color: textLabel,
                            fontSize: 10,
                            letterSpacing: 2,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          value,
                          style: GoogleFonts.outfit(
                            color: textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                            fontStyle: italic
                                ? FontStyle.italic
                                : FontStyle.normal,
                          ),
                          maxLines: compact ? 2 : 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (subValue != null) ...[
                          const SizedBox(height: 3),
                          Text(
                            subValue!,
                            style: GoogleFonts.outfit(
                              color: accent.withAlpha(isDark ? 180 : 210),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: textLabel, size: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
