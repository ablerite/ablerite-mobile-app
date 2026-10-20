import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'widgets/ablerite_loading_indicator.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'widgets/focus_app_bar_actions.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/navigation_service.dart';
import '../services/notification_service.dart';
import '../services/reminder_schedule.dart';
import '../services/system_ui_service.dart';
import '../services/device_layout_service.dart';
import '../models/habit_reminder.dart';
import 'widgets/confirmation_dialog.dart';

class AffirmationsPage extends StatefulWidget {
  const AffirmationsPage({super.key});

  @override
  State<AffirmationsPage> createState() => _AffirmationsPageState();
}

class _AffirmationsPageState extends State<AffirmationsPage>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _focusController = TextEditingController();

  // Navigation State
  String _currentView = 'practice'; // 'practice', 'reminders', 'guide'

  // Practice State
  bool _isGenerating = false;
  bool _isLoadingSessions = true;
  List<String>? _activeAffirmations;
  bool _isLibrarySession = false;
  List<Map<String, dynamic>> _userGoals = [];
  List<Map<String, dynamic>> _savedSessions = [];
  List<Map<String, dynamic>> _affirmationFolders = [];
  String _selectedFolderId = 'ALL';

  // Session State
  int _currentSetIndex = 0;
  int _currentRep = 1;
  final int _repsPerAffirmation = 3;
  final PageController _pageController = PageController();
  final List<_SessionAffirmationChoice> _sessionBuilderSelection = [];
  late final ConfettiController _confettiController;
  late final AnimationController _completionController;
  bool _isCompleting = false;
  bool _isSavingCompletion = false;
  bool _rotationEnabled = false;
  bool _bottomNavWasVisible = true;
  double _sessionHorizontalDrag = 0;
  bool _isAffirmationSwipeAnimating = false;

  // Reminder State
  bool _remindersEnabled = false;
  List<TimeOfDay> _reminderTimes = [const TimeOfDay(hour: 9, minute: 0)];

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    _completionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    pushPage();
    _fetchGoals();
    _fetchSavedSessions();
    _loadReminderSettings();
  }

  @override
  void dispose() {
    popPage();
    _exitAffirmationFullscreen();
    DeviceLayoutService.applyPreferredOrientations();
    if (_activeAffirmations != null) {
      setBottomNavVisible(_bottomNavWasVisible);
    }
    _focusController.dispose();
    _pageController.dispose();
    _confettiController.dispose();
    _completionController.dispose();
    super.dispose();
  }

  // --- Persistence & Logic ---

  Future<void> _loadReminderSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('affirmations_reminders_enabled') ?? false;
    final timesJson = prefs.getString('affirmations_reminders_times');

    List<TimeOfDay> times = [const TimeOfDay(hour: 9, minute: 0)];
    if (timesJson != null) {
      try {
        final List<dynamic> raw = jsonDecode(timesJson);
        times = normalizeReminderTimes(
          raw
              .map(
                (t) => TimeOfDay(
                  hour: t['hour'] as int,
                  minute: t['minute'] as int,
                ),
              )
              .toList(),
        );
      } catch (_) {}
    } else {
      // Legacy single-time fallback
      final hour = prefs.getInt('affirmations_reminders_hour') ?? 9;
      final minute = prefs.getInt('affirmations_reminders_minute') ?? 0;
      times = [TimeOfDay(hour: hour, minute: minute)];
    }

    if (!mounted) return;
    setState(() {
      _remindersEnabled = enabled;
      _reminderTimes = times;
    });

    // Rebuild enabled reminders on entry. Besides applying the current device
    // timezone, this removes duplicate/orphaned alarms left by older builds.
    if (enabled) {
      await _saveAllReminders();
    }
  }

  Future<void> _saveAllReminders() async {
    final normalizedTimes = normalizeReminderTimes(_reminderTimes);
    if (mounted && normalizedTimes.length != _reminderTimes.length) {
      setState(() => _reminderTimes = normalizedTimes);
    } else {
      _reminderTimes = normalizedTimes;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('affirmations_reminders_enabled', _remindersEnabled);
    final timesJson = jsonEncode(
      _reminderTimes.map((t) => {'hour': t.hour, 'minute': t.minute}).toList(),
    );
    await prefs.setString('affirmations_reminders_times', timesJson);

    final userId = Supabase.instance.client.auth.currentUser?.id ?? 'anon';

    try {
      await NotificationService().initialize();

      final reminders = _remindersEnabled
          ? [
              for (int i = 0; i < _reminderTimes.length; i++)
                HabitReminder(
                  id: 'affirmations_reminder_${userId}_$i',
                  userId: userId,
                  category: HabitCategory.mind,
                  habitName: 'Affirmations',
                  habitEmoji: '✨',
                  reminderTime: _reminderTimes[i],
                  enabled: true,
                ),
            ]
          : <HabitReminder>[];
      await NotificationService().replaceHabitReminders(
        payloadPrefix: 'affirmations_reminder_',
        reminders: reminders,
      );
    } catch (e) {
      debugPrint('Reminder scheduling error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not set reminder: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleReminders(bool enabled) async {
    setState(() => _remindersEnabled = enabled);
    await _saveAllReminders();
    if (enabled && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Reminders enabled — ${_reminderTimes.length} time${_reminderTimes.length == 1 ? '' : 's'} scheduled ✅',
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    }
  }

  Future<void> _addReminderTime() async {
    if (_reminderTimes.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 5 reminders per day')),
      );
      return;
    }
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );
    if (time != null) {
      setState(() => _reminderTimes.add(time));
      await _saveAllReminders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reminder added: ${time.format(context)} ✅'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    }
  }

  Future<void> _editReminderTime(int index) async {
    final time = await showTimePicker(
      context: context,
      initialTime: _reminderTimes[index],
    );
    if (time != null) {
      setState(() => _reminderTimes[index] = time);
      await _saveAllReminders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reminder updated: ${time.format(context)} ✅'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    }
  }

  Future<void> _removeReminderTime(int index) async {
    setState(() => _reminderTimes.removeAt(index));
    await _saveAllReminders();
  }

  Future<void> _fetchGoals() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;
      final res = await Supabase.instance.client
          .from('items')
          .select()
          .eq('user_id', userId)
          .eq('section', 'activeGoals');
      if (mounted) {
        setState(
          () => _userGoals = List<Map<String, dynamic>>.from(res as List),
        );
      }
    } catch (e) {
      debugPrint('Error fetching goals: $e');
    }
  }

  Future<void> _fetchSavedSessions() async {
    setState(() => _isLoadingSessions = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;
      final responses = await Future.wait([
        Supabase.instance.client
            .from('items')
            .select()
            .eq('user_id', userId)
            .eq('section', 'affirmations')
            .order('order_index', ascending: true)
            .order('created_at', ascending: false),
        Supabase.instance.client
            .from('items')
            .select('id, text, order_index, created_at')
            .eq('user_id', userId)
            .eq('section', 'affirmationFolders')
            .order('order_index', ascending: true)
            .order('created_at', ascending: true),
      ]);
      if (mounted) {
        setState(() {
          _savedSessions = List<Map<String, dynamic>>.from(
            responses[0] as List,
          );
          _affirmationFolders = List<Map<String, dynamic>>.from(
            responses[1] as List,
          );
          final availableChoiceKeys = <String>{};
          for (final session in _savedSessions) {
            final sessionId = session['id']?.toString();
            if (sessionId == null) continue;
            final affirmations = _affirmationsInSession(session);
            for (var index = 0; index < affirmations.length; index++) {
              availableChoiceKeys.add('$sessionId:$index');
            }
          }
          _sessionBuilderSelection.removeWhere(
            (choice) => !availableChoiceKeys.contains(choice.key),
          );
          if (_selectedFolderId != 'ALL' &&
              _selectedFolderId != 'MAIN' &&
              !_affirmationFolders.any(
                (folder) => folder['id'] == _selectedFolderId,
              )) {
            _selectedFolderId = 'ALL';
          }
          _isLoadingSessions = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching sessions: $e');
      if (mounted) setState(() => _isLoadingSessions = false);
    }
  }

  List<Map<String, dynamic>> get _visibleSavedSessions {
    if (_selectedFolderId == 'ALL') return List.of(_savedSessions);
    if (_selectedFolderId == 'MAIN') {
      return _savedSessions
          .where((session) => session['parent_id'] == null)
          .toList();
    }
    return _savedSessions
        .where((session) => session['parent_id'] == _selectedFolderId)
        .toList();
  }

  Future<void> _createAffirmationFolder(String name) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      await Supabase.instance.client.from('items').insert({
        'user_id': userId,
        'section': 'affirmationFolders',
        'text': name,
        'order_index': _affirmationFolders.length,
      });
      await _fetchSavedSessions();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create folder: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showCreateAffirmationFolderDialog() {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('New Folder'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText: 'Folder name',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) {
            final name = value.trim();
            if (name.isEmpty) return;
            Navigator.pop(dialogContext);
            _createAffirmationFolder(name);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(dialogContext);
              _createAffirmationFolder(name);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _renameAffirmationFolder(
    Map<String, dynamic> folder,
    String name,
  ) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null || name.trim().isEmpty) return;
    try {
      await Supabase.instance.client
          .from('items')
          .update({'text': name.trim()})
          .eq('id', folder['id'])
          .eq('user_id', userId);
      await _fetchSavedSessions();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to rename folder: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showRenameAffirmationFolderDialog(Map<String, dynamic> folder) {
    final controller = TextEditingController(text: folder['text'] ?? '');
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Rename Folder'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(border: OutlineInputBorder()),
          onSubmitted: (value) {
            if (value.trim().isEmpty) return;
            Navigator.pop(dialogContext);
            _renameAffirmationFolder(folder, value);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isEmpty) return;
              Navigator.pop(dialogContext);
              _renameAffirmationFolder(folder, controller.text);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAffirmationFolder(Map<String, dynamic> folder) async {
    final confirmed = await showDeleteBottomSheet(
      context,
      title: 'Delete Folder?',
      subtitle:
          'Delete "${folder['text']}"? Its affirmation sets will be moved to Main.',
    );
    if (confirmed != true) return;

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      await Supabase.instance.client
          .from('items')
          .update({'parent_id': null})
          .eq('parent_id', folder['id'])
          .eq('user_id', userId)
          .eq('section', 'affirmations');
      final deletedFolders = await Supabase.instance.client
          .from('items')
          .delete()
          .eq('id', folder['id'])
          .eq('user_id', userId)
          .eq('section', 'affirmationFolders')
          .select('id');
      if ((deletedFolders as List).isEmpty) {
        throw Exception('Folder deletion could not be verified.');
      }
      _selectedFolderId = 'MAIN';
      await _fetchSavedSessions();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete folder: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _moveAffirmationSet(Map<String, dynamic> session) async {
    const mainFolder = 'MAIN';
    var selectedFolder = session['parent_id'] as String? ?? mainFolder;
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Move Set'),
          content: DropdownButtonFormField<String>(
            initialValue: selectedFolder,
            decoration: const InputDecoration(
              labelText: 'Folder',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem(
                value: mainFolder,
                child: Text('Main (no folder)'),
              ),
              ..._affirmationFolders.map(
                (folder) => DropdownMenuItem<String>(
                  value: folder['id'] as String,
                  child: Text(folder['text'] as String? ?? 'Untitled'),
                ),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                setDialogState(() => selectedFolder = value);
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, selectedFolder),
              child: const Text('Move'),
            ),
          ],
        ),
      ),
    );
    if (result == null) return;

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      await Supabase.instance.client
          .from('items')
          .update({'parent_id': result == mainFolder ? null : result})
          .eq('id', session['id'])
          .eq('user_id', userId);
      await _fetchSavedSessions();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to move set: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _generateAffirmation({String? focusOverride}) async {
    final focus = (focusOverride ?? _focusController.text).trim();
    if (focus.isEmpty) return;
    if (_focusController.text.trim() != focus) {
      _focusController.text = focus;
    }
    setState(() => _isGenerating = true);
    try {
      final affirmationLibrary = await _affirmationLibraryForGeneration();
      final libraryReference = affirmationLibrary
          .take(120)
          .map((affirmation) => '- $affirmation')
          .join('\n');
      const contextInstruction =
          'Use only the single focus supplied below. Do not reference, combine, infer, or borrow from any other active goal.';
      final systemMessage =
          '''You are a mindset coach. Generate EXACTLY 4 POWERFUL, REALISTIC, SHORT-TERM affirmations for this focus: "$focus".
$contextInstruction
${libraryReference.isEmpty ? 'The saved affirmations library is empty.' : 'SAVED AFFIRMATIONS LIBRARY — do not repeat or closely rephrase any of these:\n$libraryReference'}

CRITICAL INSTRUCTIONS:
1. Output ONLY the 4 affirmations.
2. Use a numbered list (1., 2., 3., 4.).
3. Each affirmation must be under 12 words.
4. Every affirmation must be a complete sentence.
5. Every affirmation must begin exactly with "I am".
6. Make all 4 affirmations meaningfully distinct from one another.
7. Never repeat or closely rephrase an affirmation in the saved library.
8. NO introductory text, NO conversational filler, NO conclusion.
9. NO bolding or special characters.
10. NO word-count markers or numbering of any kind inside an affirmation (e.g. do not write "word (1) word (2)"). Output plain sentences only.''';
      final res = await Supabase.instance.client.functions.invoke(
        'gemini-chat',
        body: {
          'messages': [
            {
              'role': 'user',
              'content':
                  'Provide 4 complete affirmations for this exact focus: "$focus".',
            },
          ],
          'systemMessage': systemMessage,
        },
      );
      if (res.data != null && res.data['response'] != null) {
        final responseText = res.data['response'].toString();
        final cleanedAffirmations = _parseAffirmations(
          responseText,
          focus,
          affirmationLibrary,
        );

        if (cleanedAffirmations.length == 4) {
          _startAffirmationSession(cleanedAffirmations);
        } else {
          throw 'Could not generate four new affirmations. Please try again.';
        }
      } else {
        throw 'The AI service returned no response. Check your connection.';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
      setState(() => _isGenerating = false);
    }
  }

  Future<List<String>> _affirmationLibraryForGeneration() async {
    List<Map<String, dynamic>> sessions = List.of(_savedSessions);
    if (_isLoadingSessions) {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        try {
          final response = await Supabase.instance.client
              .from('items')
              .select('text')
              .eq('user_id', userId)
              .eq('section', 'affirmations')
              .order('created_at', ascending: false);
          sessions = List<Map<String, dynamic>>.from(response as List);
        } catch (error) {
          debugPrint('Could not refresh affirmation library: $error');
        }
      }
    }

    final unique = <String, String>{};
    for (final session in sessions) {
      for (final affirmation in _affirmationsInSession(session)) {
        unique.putIfAbsent(
          _normaliseAffirmation(affirmation),
          () => affirmation,
        );
      }
    }
    return unique.values.toList();
  }

  List<String> _parseAffirmations(
    String responseText,
    String focus,
    List<String> affirmationLibrary,
  ) {
    final numberedMatches = RegExp(
      r'(?:^|\n)\s*\d+[\.\)]\s*([\s\S]*?)(?=(?:\n\s*\d+[\.\)]\s*)|$)',
      multiLine: true,
    ).allMatches(responseText);
    final rawItems = numberedMatches.isNotEmpty
        ? numberedMatches.map((match) => match.group(1) ?? '')
        : responseText.split('\n');

    final cleanedAffirmations = <String>[];
    for (final raw in rawItems) {
      final cleaned = _cleanAffirmation(raw);
      if (_isUsableAffirmation(cleaned) &&
          !_isRepeatedAffirmation(cleaned, [
            ...affirmationLibrary,
            ...cleanedAffirmations,
          ])) {
        cleanedAffirmations.add(cleaned);
      }
    }

    final fallbackAffirmations = [
      'I am taking clear action toward $focus today.',
      'I am steadily building momentum for $focus.',
      'I am confident in my next step toward $focus.',
      'I am prepared to follow through on $focus.',
      'I am focused on meaningful progress with $focus.',
      'I am capable of moving $focus forward today.',
      'I am consistent in the actions that strengthen $focus.',
      'I am becoming more effective with $focus each day.',
    ];

    for (final fallback in fallbackAffirmations) {
      if (cleanedAffirmations.length >= 4) break;
      if (!_isRepeatedAffirmation(fallback, [
        ...affirmationLibrary,
        ...cleanedAffirmations,
      ])) {
        cleanedAffirmations.add(fallback);
      }
    }

    return cleanedAffirmations.take(4).toList();
  }

  String _normaliseAffirmation(String affirmation) {
    return affirmation
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  bool _isRepeatedAffirmation(
    String candidate,
    Iterable<String> existingAffirmations,
  ) {
    final normalisedCandidate = _normaliseAffirmation(candidate);
    if (normalisedCandidate.isEmpty) return true;
    final candidateWords = normalisedCandidate
        .split(' ')
        .where((word) => word != 'i' && word != 'am')
        .toSet();

    for (final existing in existingAffirmations) {
      final normalisedExisting = _normaliseAffirmation(existing);
      if (normalisedCandidate == normalisedExisting) return true;

      final existingWords = normalisedExisting
          .split(' ')
          .where((word) => word != 'i' && word != 'am')
          .toSet();
      if (candidateWords.isEmpty || existingWords.isEmpty) continue;

      final shared = candidateWords.intersection(existingWords).length;
      final union = candidateWords.union(existingWords).length;
      final shorter = candidateWords.length < existingWords.length
          ? candidateWords.length
          : existingWords.length;
      if (shared / union >= 0.72 || shared / shorter >= 0.86) return true;
    }
    return false;
  }

  String _cleanAffirmation(String raw) {
    return raw
        .replaceAll('\n', ' ')
        .replaceFirst(RegExp(r'^(\d+[\.\)]|[\-\*\u2022])\s*'), '')
        // Strip inline word-count markers the model sometimes leaks, e.g.
        // "opportunities (2) consistently (3)". Genuine numbers like
        // "$350,000" are never wrapped in parentheses, so this is safe.
        .replaceAll(RegExp(r'\s*\(\d+\)'), '')
        .replaceAll(RegExp(r'^["\x27\u201C\u201D]'), '')
        .replaceAll(RegExp(r'["\x27\u201C\u201D]$'), '')
        .replaceAll('*', '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  bool _isUsableAffirmation(String affirmation) {
    if (affirmation.length < 6) return false;
    final lower = affirmation.toLowerCase();
    if (!lower.startsWith('i am ') ||
        lower.startsWith('here') ||
        lower.startsWith('sure') ||
        lower.contains('affirmations for') ||
        lower.startsWith('i hope')) {
      return false;
    }

    final lastWordMatch = RegExp(r'([a-z]+)[^a-z]*$').firstMatch(lower);
    final lastWord = lastWordMatch?.group(1);
    const danglingWords = {
      'a',
      'an',
      'and',
      'at',
      'by',
      'for',
      'from',
      'in',
      'into',
      'my',
      'of',
      'on',
      'or',
      'the',
      'through',
      'to',
      'toward',
      'with',
    };
    return lastWord == null || !danglingWords.contains(lastWord);
  }

  void _startAffirmationSession(
    List<String> affirmations, {
    bool isLibrarySession = false,
  }) {
    if (affirmations.isEmpty) return;
    _bottomNavWasVisible = bottomNavVisibleNotifier.value;
    setBottomNavVisible(false);
    _enterAffirmationFullscreen();
    if (_pageController.hasClients) {
      _pageController.jumpToPage(0);
    }
    setState(() {
      _activeAffirmations = List<String>.from(affirmations);
      _isGenerating = false;
      _isLibrarySession = isLibrarySession;
      _currentSetIndex = 0;
      _currentRep = 1;
      _isCompleting = false;
      _isSavingCompletion = false;
      _rotationEnabled = false;
    });
    _completionController.reset();
    DeviceLayoutService.applyPreferredOrientations();
  }

  Future<void> _enterAffirmationFullscreen() {
    return SystemUiService.apply(SystemUiMode.immersiveSticky);
  }

  Future<void> _exitAffirmationFullscreen() {
    // The app's default mode is already immersiveSticky, but re-apply
    // explicitly in case a stray system UI reveal changed it mid-session.
    return SystemUiService.apply(SystemUiMode.immersiveSticky);
  }

  void _endAffirmationSession() {
    _exitAffirmationFullscreen();
    DeviceLayoutService.applyPreferredOrientations();
    setBottomNavVisible(_bottomNavWasVisible);
    _confettiController.stop();
    _completionController.reset();
    setState(() {
      _activeAffirmations = null;
      _isCompleting = false;
      _isSavingCompletion = false;
      _rotationEnabled = false;
    });
  }

  Future<void> _toggleAffirmationRotation() async {
    final enableRotation = !_rotationEnabled;
    setState(() => _rotationEnabled = enableRotation);
    if (enableRotation) {
      await SystemChrome.setPreferredOrientations(const [
        DeviceOrientation.portraitUp,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      await DeviceLayoutService.applyPreferredOrientations();
    }
  }

  Future<void> _moveToAdjacentAffirmationPage(int direction) async {
    final affirmations = _activeAffirmations;
    if (_isCompleting ||
        _isAffirmationSwipeAnimating ||
        affirmations == null ||
        affirmations.isEmpty) {
      return;
    }

    final currentPage =
        (_currentSetIndex * _repsPerAffirmation) + (_currentRep - 1);
    final lastPage = (affirmations.length * _repsPerAffirmation) - 1;
    final targetPage = (currentPage + direction).clamp(0, lastPage);
    if (targetPage == currentPage) return;

    setState(() {
      _currentSetIndex = targetPage ~/ _repsPerAffirmation;
      _currentRep = (targetPage % _repsPerAffirmation) + 1;
    });
    HapticFeedback.selectionClick();
    _isAffirmationSwipeAnimating = true;
    try {
      await _pageController.animateToPage(
        targetPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    } finally {
      _isAffirmationSwipeAnimating = false;
    }
  }

  Future<void> _saveSession(List<String> affirmations, String focus) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw 'User session expired. Please sign in again.';

      final String sessionFocus = focus.isEmpty
          ? 'General Affirmations'
          : focus;

      await Supabase.instance.client.from('items').insert({
        'user_id': userId,
        'section': 'affirmations',
        'text': jsonEncode(affirmations),
        'category': sessionFocus,
      });
      await _fetchSavedSessions();
    } catch (e) {
      debugPrint('Save error: $e');
      rethrow;
    }
  }

  Future<void> _renameSession(
    Map<String, dynamic> session,
    String newTitle,
  ) async {
    final trimmed = newTitle.trim();
    if (trimmed.isEmpty) return;
    try {
      await Supabase.instance.client
          .from('items')
          .update({'category': trimmed})
          .eq('id', session['id']);
      await _fetchSavedSessions();
    } catch (e) {
      debugPrint('Rename error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to rename: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showRenameDialog(Map<String, dynamic> session) {
    final controller = TextEditingController(text: session['category'] ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          'Rename Set',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: GoogleFonts.outfit(
            color: Theme.of(context).colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            hintText: 'Enter a title...',
            hintStyle: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withAlpha(120),
            ),
            filled: true,
            fillColor: Theme.of(context).scaffoldBackgroundColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          onSubmitted: (value) {
            Navigator.pop(ctx);
            _renameSession(session, value);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.outfit(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _renameSession(session, controller.text);
            },
            child: Text(
              'Save',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // --- UI Components ---

  Widget _buildSideBar() {
    return Drawer(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(32.0),
              alignment: Alignment.centerLeft,
              child: Text(
                'Affirmations',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const Divider(),
            _buildDrawerItem('Practice', CupertinoIcons.sparkles, 'practice'),
            _buildDrawerItem('My Library', CupertinoIcons.folder, 'saved'),
            _buildDrawerItem(
              'Session Builder',
              CupertinoIcons.square_list,
              'builder',
            ),
            _buildDrawerItem('Reminders', CupertinoIcons.alarm, 'reminders'),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(String title, IconData icon, String value) {
    final isSelected = _currentView == value;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey,
      ),
      title: Text(
        title,
        style: GoogleFonts.outfit(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Theme.of(context).colorScheme.primary : null,
        ),
      ),
      selected: isSelected,
      onTap: () async {
        setState(() => _currentView = value);
        Navigator.pop(context);
        if (value == 'saved' || value == 'builder') {
          await _fetchSavedSessions();
        }
      },
    );
  }

  Widget _buildPracticeView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_userGoals.isNotEmpty) ...[
            Text(
              'Suggested from your active goals',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _userGoals
                  .take(4)
                  .map(
                    (goal) => GestureDetector(
                      onTap: _isGenerating
                          ? null
                          : () {
                              _generateAffirmation(
                                focusOverride: goal['text'] ?? '',
                              );
                            },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withAlpha(20),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withAlpha(50),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              CupertinoIcons.sparkles,
                              size: 14,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                goal['text'] ?? '',
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 32),
          ],
          _buildWizardCard(),
        ],
      ),
    );
  }

  Widget _buildWizardCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Custom',
          style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Enter a focus area and Diana will create four distinct “I am” affirmations for you. She checks your saved library to avoid repetition.',
          style: GoogleFonts.outfit(
            fontSize: 14,
            height: 1.45,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Theme.of(context).dividerColor.withAlpha(20),
            ),
          ),
          child: Column(
            children: [
              TextField(
                controller: _focusController,
                decoration: InputDecoration(
                  hintText: 'Enter focus area...',
                  filled: true,
                  fillColor: Theme.of(context).scaffoldBackgroundColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isGenerating ? null : _generateAffirmation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isGenerating
                      ? const AbleriteLoadingIndicator(color: Colors.white)
                      : Text(
                          'Generate 4-Set',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReminderView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reminders',
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Set multiple daily reminders for your affirmation sessions.',
            style: GoogleFonts.outfit(color: Colors.grey),
          ),
          const SizedBox(height: 32),

          // Enable toggle
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Daily Reminders',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Switch(
                  value: _remindersEnabled,
                  activeThumbColor: Theme.of(context).colorScheme.primary,
                  onChanged: _toggleReminders,
                ),
              ],
            ),
          ),

          if (_remindersEnabled) ...[
            const SizedBox(height: 20),

            // Times list
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  // Header row
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Scheduled Times',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                        if (_reminderTimes.length < 5)
                          TextButton.icon(
                            onPressed: _addReminderTime,
                            icon: Icon(
                              Icons.add_circle_outline,
                              size: 18,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            label: Text(
                              'Add Time',
                              style: GoogleFonts.outfit(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),

                  // Time tiles
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _reminderTimes.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (ctx, i) {
                      final t = _reminderTimes[i];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 4,
                        ),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withAlpha(20),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.alarm,
                            color: Theme.of(context).colorScheme.primary,
                            size: 18,
                          ),
                        ),
                        title: Text(
                          t.format(context),
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.edit_outlined,
                                size: 20,
                                color: Colors.grey,
                              ),
                              tooltip: 'Edit time',
                              onPressed: () => _editReminderTime(i),
                            ),
                            if (_reminderTimes.length > 1)
                              IconButton(
                                icon: const Icon(
                                  Icons.remove_circle_outline,
                                  size: 20,
                                  color: Colors.red,
                                ),
                                tooltip: 'Remove',
                                onPressed: () => _removeReminderTime(i),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),
          const InfoBanner(
            text:
                'Reminders are scheduled via your device and will appear as notifications at the time you set.',
          ),
        ],
      ),
    );
  }

  Widget _buildGuideView() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      children: [
        _buildGuideHero(
          headline:
              'A guide to using the Affirmation Engine — and anchoring your belief.',
          imageAsset: 'assets/images/audio_covers/affirmations.png',
        ),
        const SizedBox(height: 16),
        _buildGuideSectionCard(
          icon: Icons.repeat,
          title: '12-Set Persistence',
          body:
              'Neuroplasticity requires repeated engagement. By cycling through 4 affirmations 3 times each, you reach the critical 12-repetition threshold for belief anchoring.',
        ),
        _buildGuideSectionCard(
          icon: Icons.touch_app_outlined,
          title: 'Moving Through a Session',
          body:
              'Read each affirmation aloud, then tap anywhere on the screen to move to the next repetition or affirmation.',
        ),
        _buildGuideSectionCard(
          icon: Icons.favorite_border,
          title: 'Emotional Anchoring',
          body:
              'The second and third reps of each set are for deepening the emotion. Do not just speak; experience the outcome as if it has already occurred.',
        ),
        _buildGuideSectionCard(
          icon: Icons.record_voice_over_outlined,
          title: '“I am” Identity Focus',
          body:
              'Each generated statement begins with “I am” to frame the quality or action as part of your present identity.',
        ),
        _buildGuideSectionCard(
          icon: Icons.track_changes,
          title: 'Tactical Accuracy',
          body:
              'The engine cross-references your saved library, avoids close repeats, and creates tactical near-term statements for your chosen focus.',
        ),
      ],
    );
  }

  Widget _buildGuideHero({required String headline, String? imageAsset}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.primary.withAlpha(42)),
        image: imageAsset == null
            ? null
            : DecorationImage(
                image: AssetImage(imageAsset),
                fit: BoxFit.cover,
                opacity: 0.18,
              ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.menu_book_outlined, color: colorScheme.primary, size: 30),
          const SizedBox(height: 14),
          Text(
            headline,
            style: GoogleFonts.outfit(
              fontSize: 24,
              height: 1.08,
              fontWeight: FontWeight.w900,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideSectionCard({
    required IconData icon,
    required String title,
    required String body,
    String? imageAsset,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withAlpha(80),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outline.withAlpha(35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: colorScheme.primary, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: GoogleFonts.outfit(
              fontSize: 14,
              height: 1.45,
              color: colorScheme.onSurface.withAlpha(180),
            ),
          ),
          if (imageAsset != null) ...[
            const SizedBox(height: 14),
            _AffirmationsGuideImagePreview(
              imageAsset: imageAsset,
              title: title,
            ),
          ],
        ],
      ),
    );
  }

  /// Returns true if we should pop the route, false if handled internally.
  bool _handleBack() {
    if (_currentView != 'practice') {
      // On a sub-page — go back to the main Practice view
      setState(() => _currentView = 'practice');
      return false;
    }
    return true; // On practice view — exit the page
  }

  void _popAffirmationsRoute() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    if (_activeAffirmations != null) return _buildSessionView();

    String title = '';
    if (_currentView == 'practice') title = 'Affirmations';
    if (_currentView == 'saved') title = 'My Library';
    if (_currentView == 'builder') title = 'Session Builder';
    if (_currentView == 'reminders') title = 'Reminders';
    if (_currentView == 'guide') title = 'Affirmations Guide';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_handleBack()) {
          _popAffirmationsRoute();
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: FocusAwareAppBarTitle(
            child: Text(
              title,
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: FocusAwareBackButton(
            onPressed: () {
              if (_handleBack()) _popAffirmationsRoute();
            },
          ),
          actions: [
            const FocusAppBarActions(),
            IconButton(
              icon: const Icon(Icons.help_outline),
              tooltip: 'Affirmations Guide',
              onPressed: () => setState(() => _currentView = 'guide'),
            ),
            IconButton(
              icon: const Icon(Icons.menu),
              tooltip: 'Affirmations menu',
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
          ],
        ),
        drawer: _buildSideBar(),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentView) {
      case 'practice':
        return _buildPracticeView();
      case 'saved':
        return _buildSavedSetsView();
      case 'builder':
        return _buildSessionBuilderView();
      case 'reminders':
        return _buildReminderView();
      case 'guide':
        return _buildGuideView();
      default:
        return _buildPracticeView();
    }
  }

  List<String> _affirmationsInSession(Map<String, dynamic> session) {
    try {
      final decoded = jsonDecode(session['text']?.toString() ?? '[]');
      if (decoded is! List) return const [];
      return decoded
          .map((affirmation) => affirmation.toString().trim())
          .where((affirmation) => affirmation.isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  void _toggleSessionBuilderChoice(_SessionAffirmationChoice choice) {
    setState(() {
      final existingIndex = _sessionBuilderSelection.indexWhere(
        (selected) => selected.key == choice.key,
      );
      if (existingIndex == -1) {
        _sessionBuilderSelection.add(choice);
      } else {
        _sessionBuilderSelection.removeAt(existingIndex);
      }
    });
  }

  List<_SessionAffirmationChoice> _choicesInSession(
    Map<String, dynamic> session,
  ) {
    final sessionId = session['id']?.toString() ?? session.hashCode.toString();
    final affirmations = _affirmationsInSession(session);
    return [
      for (var index = 0; index < affirmations.length; index++)
        _SessionAffirmationChoice(
          key: '$sessionId:$index',
          text: affirmations[index],
        ),
    ];
  }

  bool _allSessionBuilderChoicesSelected(
    List<_SessionAffirmationChoice> choices,
  ) {
    if (choices.isEmpty) return false;
    final selectedKeys = _sessionBuilderSelection
        .map((choice) => choice.key)
        .toSet();
    return choices.every((choice) => selectedKeys.contains(choice.key));
  }

  void _toggleAllSessionBuilderChoices(
    List<_SessionAffirmationChoice> choices,
  ) {
    if (choices.isEmpty) return;
    setState(() {
      if (_allSessionBuilderChoicesSelected(choices)) {
        final keysToRemove = choices.map((choice) => choice.key).toSet();
        _sessionBuilderSelection.removeWhere(
          (choice) => keysToRemove.contains(choice.key),
        );
        return;
      }

      final selectedKeys = _sessionBuilderSelection
          .map((choice) => choice.key)
          .toSet();
      for (final choice in choices) {
        if (selectedKeys.add(choice.key)) {
          _sessionBuilderSelection.add(choice);
        }
      }
    });
  }

  Widget _buildSessionBuilderView() {
    final colorScheme = Theme.of(context).colorScheme;
    final allChoices = _savedSessions
        .expand(_choicesInSession)
        .toList(growable: false);
    final allSelected = _allSessionBuilderChoicesSelected(allChoices);

    if (_isLoadingSessions) {
      return const Center(child: AbleriteLoadingIndicator());
    }

    if (_savedSessions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                CupertinoIcons.square_list,
                size: 48,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Build Your Own Session',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Save an affirmation set first, then return here to combine affirmations into a custom sequence.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  color: colorScheme.onSurface.withAlpha(155),
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 30,
                      child: FittedBox(
                        alignment: Alignment.centerLeft,
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Create a custom sequence',
                          maxLines: 1,
                          softWrap: false,
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    key: const ValueKey('select-all-affirmations'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () =>
                        _toggleAllSessionBuilderChoices(allChoices),
                    icon: Icon(
                      allSelected
                          ? Icons.deselect_rounded
                          : Icons.select_all_rounded,
                    ),
                    label: Text(
                      allSelected ? 'Deselect all' : 'Select all',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Choose at least two affirmations. They will play in the order you select them.',
                style: GoogleFonts.outfit(
                  color: colorScheme.onSurface.withAlpha(155),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              for (final session in _savedSessions)
                _buildSessionBuilderSet(session, colorScheme),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            border: Border(
              top: BorderSide(color: colorScheme.outline.withAlpha(35)),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(18),
                blurRadius: 18,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${_sessionBuilderSelection.length} selected',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    if (_sessionBuilderSelection.isNotEmpty)
                      TextButton(
                        onPressed: () =>
                            setState(() => _sessionBuilderSelection.clear()),
                        child: const Text('Clear'),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    key: const ValueKey('start-custom-affirmation-session'),
                    onPressed: _sessionBuilderSelection.length < 2
                        ? null
                        : () => _startAffirmationSession(
                            _sessionBuilderSelection
                                .map((choice) => choice.text)
                                .toList(),
                            isLibrarySession: true,
                          ),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Start Session'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSessionBuilderSet(
    Map<String, dynamic> session,
    ColorScheme colorScheme,
  ) {
    final choices = _choicesInSession(session);
    if (choices.isEmpty) return const SizedBox.shrink();
    final title = session['category']?.toString() ?? 'General Affirmations';
    final allSetChoicesSelected = _allSessionBuilderChoicesSelected(choices);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(16, 16, 12, 10),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outline.withAlpha(35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => _toggleAllSessionBuilderChoices(choices),
                child: Text(
                  allSetChoicesSelected ? 'Deselect all' : 'Select all',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final choice in choices)
            Builder(
              builder: (context) {
                final selectedIndex = _sessionBuilderSelection.indexWhere(
                  (selected) => selected.key == choice.key,
                );
                final isSelected = selectedIndex != -1;
                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _toggleSessionBuilderChoice(choice),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 40,
                          height: 36,
                          child: isSelected
                              ? Center(
                                  child: Container(
                                    width: 26,
                                    height: 26,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: colorScheme.primary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      '${selectedIndex + 1}',
                                      style: TextStyle(
                                        color: colorScheme.onPrimary,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                )
                              : Checkbox.adaptive(
                                  value: false,
                                  onChanged: (_) =>
                                      _toggleSessionBuilderChoice(choice),
                                ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 7),
                            child: Text(
                              choice.text,
                              style: GoogleFonts.outfit(
                                color: colorScheme.onSurface,
                                fontSize: 15,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSavedSetsView() {
    final visibleSessions = _visibleSavedSessions;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Your Library',
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton.filledTonal(
                onPressed: _showCreateAffirmationFolderDialog,
                icon: const Icon(Icons.create_new_folder_outlined),
                tooltip: 'New folder',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Organise and repeat your saved affirmation sets.',
            style: GoogleFonts.outfit(color: Colors.grey),
          ),
          const SizedBox(height: 20),
          _buildAffirmationFolderSelector(),
          const SizedBox(height: 24),
          if (_isLoadingSessions)
            const Center(child: AbleriteLoadingIndicator())
          else if (visibleSessions.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Text(
                  _savedSessions.isEmpty
                      ? 'No saved sets.\nFinish a session to save it here.'
                      : 'No affirmation sets in this folder.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(color: Colors.grey),
                ),
              ),
            )
          else
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: visibleSessions.length,
              onReorderItem: (oldIndex, newIndex) async {
                final reordered = List<Map<String, dynamic>>.of(
                  visibleSessions,
                );
                final item = reordered.removeAt(oldIndex);
                reordered.insert(newIndex, item);

                setState(() {
                  final visibleIds = visibleSessions
                      .map((session) => session['id'])
                      .toSet();
                  final positions = <int>[
                    for (var i = 0; i < _savedSessions.length; i++)
                      if (visibleIds.contains(_savedSessions[i]['id'])) i,
                  ];
                  for (var i = 0; i < positions.length; i++) {
                    _savedSessions[positions[i]] = reordered[i];
                  }
                });

                try {
                  final userId = Supabase.instance.client.auth.currentUser?.id;
                  if (userId == null) return;
                  for (int i = 0; i < reordered.length; i++) {
                    await Supabase.instance.client
                        .from('items')
                        .update({'order_index': i})
                        .eq('id', reordered[i]['id'])
                        .eq('user_id', userId);
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error sorting: $e')),
                    );
                    await _fetchSavedSessions();
                  }
                }
              },
              itemBuilder: (c, index) {
                final session = visibleSessions[index];
                final focus = session['category'] ?? 'General';
                return Container(
                  key: ValueKey(session['id']),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(context).dividerColor.withAlpha(20),
                    ),
                  ),
                  child: ListTile(
                    title: Text(
                      focus,
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                    ),
                    subtitle: session['parent_id'] == null
                        ? null
                        : Text(
                            _affirmationFolders
                                    .where(
                                      (folder) =>
                                          folder['id'] == session['parent_id'],
                                    )
                                    .firstOrNull?['text']
                                    ?.toString() ??
                                '',
                            style: GoogleFonts.outfit(fontSize: 12),
                          ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PopupMenuButton<String>(
                          tooltip: 'Set options',
                          onSelected: (value) async {
                            switch (value) {
                              case 'rename':
                                _showRenameDialog(session);
                              case 'move':
                                await _moveAffirmationSet(session);
                              case 'delete':
                                final confirmed = await showDeleteBottomSheet(
                                  context,
                                  title: 'Delete Set?',
                                  subtitle: 'This action cannot be undone.',
                                );
                                if (confirmed == true) {
                                  final userId = Supabase
                                      .instance
                                      .client
                                      .auth
                                      .currentUser
                                      ?.id;
                                  if (userId == null) return;
                                  await Supabase.instance.client
                                      .from('items')
                                      .delete()
                                      .eq('id', session['id'])
                                      .eq('user_id', userId);
                                  await _fetchSavedSessions();
                                }
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: 'rename',
                              child: ListTile(
                                leading: Icon(Icons.edit_outlined),
                                title: Text('Rename'),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                            PopupMenuItem(
                              value: 'move',
                              child: ListTile(
                                leading: Icon(Icons.drive_file_move_outline),
                                title: Text('Move to folder'),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: ListTile(
                                leading: Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                ),
                                title: Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.red),
                                ),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.play_circle_fill,
                            color: Theme.of(context).colorScheme.primary,
                            size: 30,
                          ),
                          tooltip: 'Start session',
                          onPressed: () {
                            final List<String> affs = List<String>.from(
                              jsonDecode(session['text']),
                            );
                            _startAffirmationSession(
                              affs,
                              isLibrarySession: true,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildAffirmationFolderSelector() {
    final folders = <Map<String, dynamic>>[
      {'id': 'ALL', 'text': 'All'},
      {'id': 'MAIN', 'text': 'Main'},
      ..._affirmationFolders,
    ];
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: folders.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final folder = folders[index];
          final id = folder['id'] as String;
          final isCustom = id != 'ALL' && id != 'MAIN';
          final selected = id == _selectedFolderId;
          final colorScheme = Theme.of(context).colorScheme;
          final folderName = folder['text'] as String? ?? 'Untitled';
          return Semantics(
            button: true,
            selected: selected,
            label: isCustom
                ? '$folderName folder. Long press for folder options.'
                : folderName,
            child: Material(
              color: selected
                  ? colorScheme.primary
                  : colorScheme.surfaceContainerHighest,
              shape: StadiumBorder(
                side: BorderSide(
                  color: selected
                      ? colorScheme.primary
                      : colorScheme.outlineVariant,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => setState(() => _selectedFolderId = id),
                onLongPress: isCustom
                    ? () => _showAffirmationFolderMenu(folder)
                    : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        id == 'ALL'
                            ? Icons.all_inbox_outlined
                            : Icons.folder_outlined,
                        size: 17,
                        color: selected
                            ? colorScheme.onPrimary
                            : colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 7),
                      Text(
                        folderName,
                        style: GoogleFonts.outfit(
                          color: selected
                              ? colorScheme.onPrimary
                              : colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAffirmationFolderMenu(Map<String, dynamic> folder) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Rename folder'),
              onTap: () {
                Navigator.pop(sheetContext);
                _showRenameAffirmationFolderDialog(folder);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text(
                'Delete folder',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(sheetContext);
                _deleteAffirmationFolder(folder);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionView() {
    final colorScheme = Theme.of(context).colorScheme;
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = colorScheme.onSurface;
    final accent = Theme.of(context).colorScheme.primary;
    final highlightColors = [
      accent.withAlpha(34),
      Colors.cyan.withAlpha(30),
      Colors.amber.withAlpha(34),
    ];

    return AnimatedBuilder(
      animation: _completionController,
      builder: (context, _) {
        final progress = _completionController.value;
        final exitProgress = Curves.easeInCubic.transform(
          const Interval(0, 0.34).transform(progress),
        );
        return Scaffold(
          backgroundColor: bgColor,
          body: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragStart: _isCompleting
                ? null
                : (_) => _sessionHorizontalDrag = 0,
            onHorizontalDragUpdate: _isCompleting
                ? null
                : (details) =>
                      _sessionHorizontalDrag += details.primaryDelta ?? 0,
            onHorizontalDragEnd: _isCompleting
                ? null
                : (details) {
                    final velocity = details.primaryVelocity ?? 0;
                    if (_sessionHorizontalDrag <= -48 || velocity <= -180) {
                      _moveToAdjacentAffirmationPage(1);
                    } else if (_sessionHorizontalDrag >= 48 ||
                        velocity >= 180) {
                      _moveToAdjacentAffirmationPage(-1);
                    }
                    _sessionHorizontalDrag = 0;
                  },
            onHorizontalDragCancel: () => _sessionHorizontalDrag = 0,
            onTap: _isCompleting
                ? null
                : () {
                    if (_currentRep < _repsPerAffirmation) {
                      setState(() => _currentRep++);
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                      );
                    } else if (_currentSetIndex <
                        _activeAffirmations!.length - 1) {
                      setState(() {
                        _currentSetIndex++;
                        _currentRep = 1;
                      });
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      _beginCompletion();
                    }
                  },
            child: Stack(
              children: [
                IgnorePointer(
                  ignoring: _isCompleting,
                  child: Opacity(
                    opacity: 1 - exitProgress,
                    child: Transform.scale(
                      scale: 1 - (exitProgress * 0.12),
                      child: PageView.builder(
                        controller: _pageController,
                        physics: const NeverScrollableScrollPhysics(),
                        itemBuilder: (c, index) {
                          final affIdx = index ~/ 3;
                          final rep = (index % 3) + 1;
                          final aff = _activeAffirmations![affIdx];
                          String prompt = '';
                          if (rep == 1) {
                            prompt = 'Repeat The Following Affirmation';
                          }
                          if (rep == 2) {
                            prompt = 'Again, with more passion and conviction';
                          }
                          if (rep == 3) {
                            prompt = 'Experience it as already done';
                          }
                          return SafeArea(
                            minimum: isLandscape
                                ? const EdgeInsets.fromLTRB(72, 24, 72, 24)
                                : const EdgeInsets.fromLTRB(28, 88, 28, 88),
                            child: Center(
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: isLandscape ? 500 : double.infinity,
                                ),
                                child: Column(
                                  children: [
                                    const Spacer(),
                                    if (isLandscape) ...[
                                      _buildSessionProgressPill(
                                        bgColor: bgColor,
                                        accent: accent,
                                        textColor: textColor,
                                        affirmationIndex: affIdx,
                                        repetition: rep,
                                      ),
                                      const SizedBox(height: 10),
                                    ],
                                    SizedBox(
                                      width: double.infinity,
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          prompt,
                                          maxLines: 1,
                                          softWrap: false,
                                          style: TextStyle(
                                            color: accent,
                                            fontWeight: FontWeight.w800,
                                            fontSize: isLandscape ? 15 : 17,
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: isLandscape ? 10 : 18),
                                    AnimatedContainer(
                                      key: ValueKey(
                                        'affirmation_${affIdx}_rep_$rep',
                                      ),
                                      duration: const Duration(
                                        milliseconds: 240,
                                      ),
                                      curve: Curves.easeOutCubic,
                                      width: double.infinity,
                                      padding: isLandscape
                                          ? const EdgeInsets.fromLTRB(
                                              20,
                                              14,
                                              20,
                                              18,
                                            )
                                          : const EdgeInsets.fromLTRB(
                                              24,
                                              26,
                                              24,
                                              30,
                                            ),
                                      decoration: BoxDecoration(
                                        color:
                                            highlightColors[(rep - 1).clamp(
                                              0,
                                              2,
                                            )],
                                        borderRadius: BorderRadius.circular(28),
                                        border: Border.all(
                                          color: accent.withAlpha(
                                            rep == 1 ? 70 : 105,
                                          ),
                                          width: 1.2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: accent.withAlpha(
                                              22 + (rep * 10),
                                            ),
                                            blurRadius: 28,
                                            offset: const Offset(0, 16),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (!isLandscape) ...[
                                            _buildSessionProgressPill(
                                              bgColor: bgColor,
                                              accent: accent,
                                              textColor: textColor,
                                              affirmationIndex: affIdx,
                                              repetition: rep,
                                            ),
                                            const SizedBox(height: 28),
                                          ],
                                          SingleChildScrollView(
                                            child: Text(
                                              aff,
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: textColor,
                                                fontWeight: FontWeight.bold,
                                                fontSize: isLandscape ? 23 : 30,
                                                height: 1.28,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Spacer(),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    minimum: EdgeInsets.fromLTRB(
                      20,
                      isLandscape ? 8 : 44,
                      20,
                      0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: _isCompleting
                              ? null
                              : _endAffirmationSession,
                          icon: Icon(
                            Icons.close,
                            color: textColor.withAlpha(
                              ((1 - exitProgress) * 100).round(),
                            ),
                          ),
                        ),
                        IconButton(
                          key: const ValueKey('affirmation-rotation-button'),
                          onPressed: _isCompleting
                              ? null
                              : _toggleAffirmationRotation,
                          tooltip: _rotationEnabled
                              ? 'Lock to portrait'
                              : 'Enable screen rotation',
                          icon: Icon(
                            Icons.screen_rotation_rounded,
                            color: _rotationEnabled
                                ? accent
                                : textColor.withAlpha(100),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_isCompleting)
                  Positioned.fill(
                    child: _buildCompletionView(
                      colorScheme,
                      progress,
                      isLandscape: isLandscape,
                    ),
                  ),
                if (_isCompleting)
                  Align(
                    alignment: Alignment.topCenter,
                    child: IgnorePointer(
                      child: ConfettiWidget(
                        confettiController: _confettiController,
                        blastDirectionality: BlastDirectionality.explosive,
                        emissionFrequency: 0.035,
                        numberOfParticles: 46,
                        minBlastForce: 10,
                        maxBlastForce: 30,
                        gravity: 0.22,
                        colors: [
                          colorScheme.primary,
                          colorScheme.secondary,
                          colorScheme.tertiary,
                          colorScheme.onSurface,
                          Colors.amberAccent,
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSessionProgressPill({
    required Color bgColor,
    required Color accent,
    required Color textColor,
    required int affirmationIndex,
    required int repetition,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor.withAlpha(190),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withAlpha(60)),
      ),
      child: Text(
        'Affirmation ${affirmationIndex + 1} of ${_activeAffirmations!.length}  •  Rep $repetition of 3',
        maxLines: 1,
        style: TextStyle(
          color: textColor.withAlpha(175),
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  void _beginCompletion() {
    if (_isCompleting) return;
    setState(() => _isCompleting = true);
    HapticFeedback.mediumImpact();
    _completionController.forward(from: 0);
    Future<void>.delayed(const Duration(milliseconds: 720), () {
      if (!mounted || !_isCompleting) return;
      _confettiController.play();
      HapticFeedback.heavyImpact();
    });
  }

  Widget _buildCompletionView(
    ColorScheme colorScheme,
    double progress, {
    required bool isLandscape,
  }) {
    final reveal = Curves.easeOutBack.transform(
      const Interval(0.4, 0.76).transform(progress),
    );
    final copyOpacity = Curves.easeOut.transform(
      const Interval(0.58, 0.82).transform(progress),
    );
    final actionsOpacity = Curves.easeOut.transform(
      const Interval(0.74, 1).transform(progress),
    );
    final mark = _buildCompletionMark(colorScheme, reveal);
    final copy = _buildCompletionCopy(colorScheme, copyOpacity);
    final actions = IgnorePointer(
      ignoring: actionsOpacity < 0.99 || _isSavingCompletion,
      child: Opacity(
        opacity: actionsOpacity,
        child: _buildCompletionActions(colorScheme),
      ),
    );

    if (isLandscape) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(64, 24, 64, 24),
          child: Row(
            children: [
              Expanded(child: mark),
              const SizedBox(width: 44),
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [copy, const SizedBox(height: 22), actions],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 48, 28, 34),
        child: Column(
          children: [
            const Spacer(flex: 2),
            mark,
            const SizedBox(height: 34),
            copy,
            const Spacer(flex: 2),
            actions,
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionMark(ColorScheme colorScheme, double reveal) {
    final accent = colorScheme.primary;
    return Opacity(
      opacity: reveal.clamp(0, 1),
      child: Transform.scale(
        scale: 0.45 + (reveal * 0.55),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [accent.withAlpha(90), Colors.transparent],
                ),
              ),
            ),
            Container(
              width: 106,
              height: 106,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent,
                border: Border.all(color: colorScheme.onSurface, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: accent.withAlpha(150),
                    blurRadius: 42,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Icon(
                Icons.check_rounded,
                color: colorScheme.onPrimary,
                size: 64,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionCopy(ColorScheme colorScheme, double opacity) {
    final contentColor = colorScheme.onSurface;
    return Opacity(
      opacity: opacity,
      child: Transform.translate(
        offset: Offset(0, 18 * (1 - opacity)),
        child: Column(
          children: [
            Text(
              'YOU DID IT',
              key: const ValueKey('affirmation-success-title'),
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: contentColor,
                fontSize: 34,
                fontWeight: FontWeight.w900,
                letterSpacing: 3.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _isLibrarySession
                  ? '${_activeAffirmations!.length} affirmations. ${_activeAffirmations!.length * _repsPerAffirmation} powerful repetitions. Your intention is anchored.'
                  : 'Your focus and conviction are locked in. Keep this set close and return whenever you need it.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: contentColor.withAlpha(185),
                fontSize: 16,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionActions(ColorScheme colorScheme) {
    final accent = colorScheme.primary;
    if (_isLibrarySession) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          key: const ValueKey('affirmation-finish-button'),
          onPressed: _endAffirmationSession,
          style: ElevatedButton.styleFrom(
            backgroundColor: accent,
            foregroundColor: colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(vertical: 17),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          child: Text(
            'Finish Session',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            key: const ValueKey('affirmation-save-button'),
            onPressed: _saveCompletedSession,
            style: ElevatedButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 17),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: _isSavingCompletion
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: AbleriteLoadingIndicator(
                      color: colorScheme.onPrimary,
                    ),
                  )
                : Text(
                    'Save to Library',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _endAffirmationSession,
          child: Text(
            'Not now',
            style: GoogleFonts.outfit(
              color: colorScheme.onSurface.withAlpha(150),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _saveCompletedSession() async {
    if (_isSavingCompletion) return;
    final currentAffirmations = _activeAffirmations;
    if (currentAffirmations == null) return;

    setState(() => _isSavingCompletion = true);
    try {
      await _saveSession(currentAffirmations, _focusController.text.trim());
      if (!mounted) return;
      final successColor = Theme.of(context).colorScheme.primary;
      _endAffirmationSession();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Affirmation set added to library!'),
          backgroundColor: successColor,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSavingCompletion = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class _SessionAffirmationChoice {
  const _SessionAffirmationChoice({required this.key, required this.text});

  final String key;
  final String text;
}

class InfoBanner extends StatelessWidget {
  final String text;
  const InfoBanner({super.key, required this.text});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withAlpha(50),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AffirmationsGuideImagePreview extends StatelessWidget {
  final String imageAsset;
  final String title;

  const _AffirmationsGuideImagePreview({
    required this.imageAsset,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              elevation: 0,
              title: Text(title, style: GoogleFonts.outfit()),
            ),
            body: Center(
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 4,
                child: Image.asset(imageAsset, fit: BoxFit.contain),
              ),
            ),
          ),
        ),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: double.infinity,
              color: colorScheme.surface,
              child: Image.asset(
                imageAsset,
                fit: BoxFit.fitWidth,
                width: double.infinity,
              ),
            ),
          ),
          Positioned(
            right: 8,
            bottom: 8,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(140),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.zoom_in, color: Colors.white, size: 16),
            ),
          ),
        ],
      ),
    );
  }
}
