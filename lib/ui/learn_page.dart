import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'widgets/ablerite_loading_indicator.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'widgets/focus_app_bar_actions.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import '../services/navigation_service.dart';
import 'self_help_page.dart';
import 'widgets/confirmation_dialog.dart';
import 'widgets/hub_intro_panel.dart';
import 'widgets/tablet_layout.dart';

class LearnPage extends StatefulWidget {
  final String initialView;
  final String initialTopic;

  const LearnPage({
    super.key,
    this.initialView = 'home',
    this.initialTopic = 'smart',
  });

  @override
  State<LearnPage> createState() => _LearnPageState();
}

class _LearnPageState extends State<LearnPage> {
  String _selectedView = 'home';
  String _selectedTopic = 'smart';
  // Tracks the current SMART Goals sub-tab so the back button can navigate
  // to Overview first instead of immediately popping the route.
  final ValueNotifier<String> _smartTabNotifier = ValueNotifier('overview');

  final List<Map<String, dynamic>> _topics = [
    {
      'id': 'smart',
      'title': 'SMART Goals',
      'icon': Icons.adjust,
      'color': null,
      'subtitle': 'The proven framework for goal setting',
    },
    {
      'id': 'habits',
      'title': 'Habit Stacking',
      'icon': Icons.layers,
      'color': null,
      'subtitle': 'Build powerful routines',
    },
    {
      'id': 'visualize',
      'title': 'Visualization',
      'icon': Icons.visibility,
      'color': null,
      'subtitle': 'See it to achieve it',
    },
    {
      'id': 'mindset',
      'title': 'Growth Mindset',
      'icon': Icons.psychology,
      'color': null,
      'subtitle': 'Unlock your potential',
    },
    {
      'id': 'focus',
      'title': 'Deep Focus',
      'icon': Icons.center_focus_strong,
      'color': null,
      'subtitle': 'Eliminate distractions',
    },
    {
      'id': 'gratitude',
      'title': 'Gratitude Practice',
      'icon': Icons.favorite,
      'color': null,
      'subtitle': 'Attract abundance',
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedView = widget.initialView;
    _selectedTopic = widget.initialTopic;
  }

  @override
  void dispose() {
    _smartTabNotifier.dispose();
    super.dispose();
  }

  /// Returns true if back should pop the route, false if handled internally.
  bool _handleBack() {
    if (_selectedView == 'smart' && _smartTabNotifier.value != 'overview') {
      // Go back to overview within SMART Goals
      _smartTabNotifier.value = 'overview';
      return false;
    }
    final routeHome = widget.initialView == 'criticalHome'
        ? 'criticalHome'
        : 'home';
    if (_selectedView != routeHome) {
      setState(() => _selectedView = routeHome);
      return false;
    }
    return true; // Let it pop
  }

  String get _appBarTitle {
    if (_selectedView == 'home') return 'Knowledge';
    if (_selectedView == 'criticalHome') return 'Critical Learning';
    if (_selectedView == 'audio') return 'Audio Episodes';
    if (_selectedView == 'smart') return 'SMART Goals';
    return _getTopicTitle(_selectedTopic);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_handleBack()) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
          elevation: 0,
          title: FocusAwareAppBarTitle(
            child: Text(
              _appBarTitle,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          leading: FocusAwareBackButton(
            onPressed: () {
              if (_handleBack()) Navigator.pop(context);
            },
          ),
          actions: const [
            FocusAppBarActions(guide: FocusHelpGuide.selfDevelopment),
          ],
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedView) {
      case 'smart':
        return Column(
          children: [
            _TopicSelector(
              selectedTopicId: _selectedTopic,
              onTopicSelected: _openKnowledgeTopic,
            ),
            Expanded(
              child: _SmartGoalsPage(
                onTopicSelected: _openKnowledgeTopic,
                tabNotifier: _smartTabNotifier,
              ),
            ),
          ],
        );
      case 'audio':
        return const _AudioEpisodesPage();
      case 'criticalHome':
        return _CriticalLearningHomePage(
          onStart: () {
            _smartTabNotifier.value = 'overview';
            setState(() {
              _selectedTopic = 'smart';
              _selectedView = 'smart';
            });
          },
        );
      case 'topic':
        return Column(
          children: [
            _TopicSelector(
              selectedTopicId: _selectedTopic,
              onTopicSelected: _openKnowledgeTopic,
            ),
            Expanded(child: _buildTopicDetails()),
          ],
        );
      case 'home':
      default:
        return _KnowledgeHomePage(
          onOpenAudio: () => setState(() => _selectedView = 'audio'),
          onOpenSelfHelpCourses: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) =>
                    const SelfHelpPage(showHomeInitially: false),
              ),
            );
          },
        );
    }
  }

  void _openKnowledgeTopic(String id) {
    setState(() {
      _selectedTopic = id;
      _selectedView = id == 'smart' ? 'smart' : 'topic';
    });
    if (id == 'smart') _smartTabNotifier.value = 'overview';
  }

  String _getTopicTitle(String id) {
    return _topics.firstWhere((t) => t['id'] == id)['title'];
  }

  Widget _buildTopicDetails() {
    final topic = _topics.firstWhere((t) => t['id'] == _selectedTopic);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 24.0, left: 8.0),
              child: Text(
                topic['subtitle'],
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
                ),
              ),
            ),
            _buildTopicContent(topic),
          ],
        ),
      ),
    );
  }

  Widget _buildTopicContent(Map<String, dynamic> topic) {
    final String id = topic['id'];
    final topicData = _TopicDetailPageStatefulState._topicContent[id];

    if (topicData == null) {
      return Padding(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Column(
            children: [
              const Text('📝', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 16),
              Text(
                'Content coming soon!',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final Color color =
        (topicData['color'] as Color?) ?? Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Intro Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withAlpha(76)),
          ),
          child: Text(
            (topicData['intro'] as String?) ?? 'No introduction available.',
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withAlpha(200),
              height: 1.6,
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Principles
        Text(
          'Key Principles',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        ...((topicData['principles'] as List?) ?? []).map<Widget>((p) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withAlpha(13),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withAlpha(38)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (p['title'] as String?) ?? 'Untitled Principle',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  (p['desc'] as String?) ?? 'No description provided.',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withAlpha(180),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 16),

        // Pro Tip
        if (topicData['tip'] != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withAlpha(13),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withAlpha(51),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('💡', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pro Tip',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        topicData['tip'] as String,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withAlpha(180),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 40),
      ],
    );
  }
}

class _CriticalLearningHomePage extends StatelessWidget {
  final VoidCallback onStart;

  const _CriticalLearningHomePage({required this.onStart});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 14, left: 8),
              child: Text(
                'Core frameworks for practical personal growth.',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  color: colorScheme.onSurface.withAlpha(150),
                ),
              ),
            ),
            Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: primary.withValues(alpha: 0.16)),
                boxShadow: [
                  BoxShadow(
                    color: primary.withValues(alpha: 0.12),
                    blurRadius: 22,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AspectRatio(
                    aspectRatio: isTabletLandscape(context) ? 16 / 5 : 16 / 9,
                    child: Image.asset(
                      'assets/images/app_banners/smartgoals.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Focused learning',
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Critical Learning gives you the core ideas behind better goals, stronger habits, clearer visualization, deeper focus, and a growth mindset.\n\nUse this area when you want short, practical frameworks that explain why a method works and how to apply it immediately.\n\nStart with SMART Goals, then move through the supporting topics to build a stronger operating system for daily action.',
                          style: GoogleFonts.outfit(
                            fontSize: 12.6,
                            height: 1.24,
                            color: colorScheme.onSurface.withAlpha(180),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: onStart,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 18),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: primary,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: primary.withValues(alpha: 0.28),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.school, color: Colors.white, size: 22),
                    const SizedBox(width: 10),
                    Text(
                      'Start Learning',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KnowledgeHomePage extends StatelessWidget {
  final VoidCallback onOpenAudio;
  final VoidCallback onOpenSelfHelpCourses;

  const _KnowledgeHomePage({
    required this.onOpenAudio,
    required this.onOpenSelfHelpCourses,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final landscapeTablet = isTabletLandscape(context);
          final audioCard = _KnowledgeHomeButton(
            title: 'Audio Episodes',
            subtitle:
                'Download guided coaching episodes into Ablerite, then listen offline whenever you need a reset.',
            icon: Icons.headphones,
            bannerAsset: 'assets/images/app_banners/audio.png',
            onTap: onOpenAudio,
          );
          final selfHelpCard = _KnowledgeHomeButton(
            title: 'Self-Help Courses',
            subtitle:
                'Open structured courses across health, wealth, relationships, career, spirituality, and growth.',
            icon: Icons.menu_book_rounded,
            bannerAsset: 'assets/images/app_banners/selfhelp.png',
            onTap: onOpenSelfHelpCourses,
          );
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 20,
              ),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 4,
                        right: 4,
                        bottom: 8,
                      ),
                      child: Text(
                        'Learn the insights you need to succeed.',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withAlpha(160),
                          height: 1.25,
                        ),
                      ),
                    ),
                    if (landscapeTablet)
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              flex: 5,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(child: audioCard),
                                  const SizedBox(height: 10),
                                  Expanded(child: selfHelpCard),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              flex: 4,
                              child: Align(
                                alignment: Alignment.topCenter,
                                child: HubLandscapeInfoPanel(
                                  icon: Icons.school_outlined,
                                  title: 'Turn knowledge into action',
                                  body:
                                      'Choose the learning format that fits the moment. Listen when you want guided support, or open a structured course when you are ready to work through a subject step by step.',
                                  highlights: [
                                    'Audio Episodes for guided learning on the move.',
                                    'Self-Help Courses for deeper, structured progress.',
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else ...[
                      Expanded(child: audioCard),
                      const SizedBox(height: 10),
                      Expanded(child: selfHelpCard),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _KnowledgeHomeButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String bannerAsset;
  final VoidCallback onTap;

  const _KnowledgeHomeButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.bannerAsset,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.primary.withAlpha(38)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: AspectRatio(
                  aspectRatio: isTabletLandscape(context) ? 16 / 6.5 : 16 / 9,
                  child: Image.asset(
                    bannerAsset,
                    fit: BoxFit.cover,
                    alignment: isTabletLandscape(context)
                        ? Alignment.topCenter
                        : Alignment.center,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: colorScheme.primary.withAlpha(24),
                        child: Icon(icon, color: colorScheme.primary, size: 36),
                      );
                    },
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            color: colorScheme.onSurface.withAlpha(110),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: colorScheme.onSurface.withAlpha(150),
                          height: 1.28,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AudioEpisode {
  final String id;
  final String title;
  final String description;
  final String duration;
  final String fileName;
  final String url;
  final String category;
  final String sectionId;
  final String sectionTitle;
  final String? subsectionId;
  final String? subsectionTitle;
  final String? transcriptUrl;

  const _AudioEpisode({
    required this.id,
    required this.title,
    required this.description,
    required this.duration,
    required this.fileName,
    required this.url,
    required this.category,
    required this.sectionId,
    required this.sectionTitle,
    this.subsectionId,
    this.subsectionTitle,
    this.transcriptUrl,
  });

  factory _AudioEpisode.fromJson(Map<String, dynamic> json) {
    final url = (json['url'] as String?)?.trim() ?? '';
    final title = (json['title'] as String?)?.trim() ?? 'Audio Episode';
    final fallbackFileName = url.isNotEmpty
        ? Uri.parse(url).pathSegments.last
        : '${_slugify(title)}.mp3';
    final category =
        ((json['category'] ?? json['area'] ?? json['section']) as String?)
            ?.trim()
            .toLowerCase() ??
        'growth';
    final sectionTitle = ((json['sectionTitle'] ?? json['section']) as String?)
        ?.trim();
    final subsectionTitle =
        ((json['subsectionTitle'] ?? json['folder']) as String?)?.trim();
    final sectionId = ((json['sectionId'] ?? json['section']) as String?)
        ?.trim();
    final subsectionId = ((json['subsectionId'] ?? json['folderId']) as String?)
        ?.trim();
    final transcriptUrl = (json['transcriptUrl'] as String?)?.trim();

    return _AudioEpisode(
      id: (json['id'] as String?)?.trim().isNotEmpty == true
          ? (json['id'] as String).trim()
          : _slugify(title),
      title: title,
      description: (json['description'] as String?)?.trim() ?? '',
      duration: (json['duration'] as String?)?.trim() ?? 'Audio',
      fileName: (json['fileName'] as String?)?.trim().isNotEmpty == true
          ? (json['fileName'] as String).trim()
          : fallbackFileName,
      url: url,
      category: category,
      sectionId: sectionId?.isNotEmpty == true ? sectionId! : category,
      sectionTitle: sectionTitle?.isNotEmpty == true
          ? sectionTitle!
          : _titleFromId(category),
      subsectionId: subsectionId?.isNotEmpty == true ? subsectionId : null,
      subsectionTitle: subsectionTitle?.isNotEmpty == true
          ? subsectionTitle
          : null,
      transcriptUrl: transcriptUrl?.isNotEmpty == true ? transcriptUrl : null,
    );
  }

  static String _slugify(String value) {
    final slug = value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return slug.isEmpty ? 'audio-episode' : slug;
  }

  static String _titleFromId(String id) {
    return id
        .split(RegExp(r'[-_\s]+'))
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }
}

class _AudioSectionSummary {
  final String id;
  final String title;
  final int episodeCount;
  final int subsectionCount;
  final Set<String>? subsectionIds;

  const _AudioSectionSummary({
    required this.id,
    required this.title,
    required this.episodeCount,
    required this.subsectionCount,
    this.subsectionIds,
  });
}

class _AudioEpisodesPage extends StatefulWidget {
  const _AudioEpisodesPage();

  @override
  State<_AudioEpisodesPage> createState() => _AudioEpisodesPageState();
}

class _AudioEpisodesPageState extends State<_AudioEpisodesPage> {
  final Map<String, double> _progress = {};
  final Map<String, bool> _downloaded = {};
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isLoadingCatalog = true;
  String? _catalogError;
  String? _activeEpisodeId;
  String? _selectedSectionId;
  String? _selectedSubsectionId;
  List<_AudioEpisode> _episodes = const [];
  int _sectionPageIndex = 0;

  static const List<_AudioEpisode> _fallbackEpisodes = [];
  static const Map<String, String> _sectionCoverAssets = {
    'finance': 'assets/images/audio_covers/finance.png',
    'brain-training': 'assets/images/audio_covers/brain-training.png',
    'knowledge': 'assets/images/audio_covers/knowledge.png',
    'self-help': 'assets/images/audio_covers/self-help.png',
    'key-insights': 'assets/images/audio_covers/key-insights.png',
    'goals': 'assets/images/audio_covers/goals.png',
    'task-lists': 'assets/images/audio_covers/task-lists.png',
    'affirmations': 'assets/images/audio_covers/affirmations.png',
    'coaching': 'assets/images/audio_covers/coaching.png',
    'vision-boards': 'assets/images/audio_covers/vision-boards.png',
    'expectations': 'assets/images/audio_covers/expectations.png',
    'records': 'assets/images/audio_covers/records.png',
  };

  static const Map<String, String> _sectionSubtitles = {
    'finance': 'Money clarity and calm',
    'brain-training': 'Sharpen focus and memory',
    'knowledge': 'Understand what works',
    'self-help': 'Guided personal growth',
    'key-insights': 'Short shifts in perspective',
    'goals': 'Turn intention into direction',
    'task-lists': 'Plan the next clear action',
    'affirmations': 'Rehearse your better identity',
    'coaching': 'Reflect, reset, and move',
    'vision-boards': 'Keep your future visible',
    'expectations': 'Name what you are growing into',
    'records': 'Review your saved work',
  };

  List<_AudioSectionSummary> get _sections {
    final sections = <String, _AudioSectionSummary>{};
    for (final episode in _episodes) {
      final existing = sections[episode.sectionId];
      sections[episode.sectionId] = _AudioSectionSummary(
        id: episode.sectionId,
        title: episode.sectionTitle,
        episodeCount: (existing?.episodeCount ?? 0) + 1,
        subsectionCount: {
          ...?existing?.subsectionIds,
          if (episode.subsectionId != null) episode.subsectionId!,
        }.length,
        subsectionIds: {
          ...?existing?.subsectionIds,
          if (episode.subsectionId != null) episode.subsectionId!,
        },
      );
    }
    return sections.values.toList();
  }

  List<_AudioSectionSummary> get _subsections {
    final sectionId = _selectedSectionId;
    if (sectionId == null) return const [];
    final subsections = <String, _AudioSectionSummary>{};
    for (final episode in _episodes.where((e) => e.sectionId == sectionId)) {
      final id = episode.subsectionId;
      if (id == null) continue;
      final existing = subsections[id];
      subsections[id] = _AudioSectionSummary(
        id: id,
        title: episode.subsectionTitle ?? _AudioEpisode._titleFromId(id),
        episodeCount: (existing?.episodeCount ?? 0) + 1,
        subsectionCount: 0,
        subsectionIds: const {},
      );
    }
    return subsections.values.toList();
  }

  List<_AudioEpisode> get _filteredEpisodes {
    final sectionId = _selectedSectionId;
    if (sectionId == null) return const [];
    final subsectionId = _selectedSubsectionId;
    return _episodes.where((episode) {
      if (episode.sectionId != sectionId) return false;
      if (subsectionId == null) return true;
      return episode.subsectionId == subsectionId;
    }).toList();
  }

  List<_AudioEpisode> get _selectedScopeEpisodes {
    final sectionId = _selectedSectionId;
    if (sectionId == null) return const [];
    final subsectionId = _selectedSubsectionId;
    return _episodes.where((episode) {
      if (episode.sectionId != sectionId) return false;
      if (subsectionId == null) return true;
      return episode.subsectionId == subsectionId;
    }).toList();
  }

  _AudioEpisode? get _selectedTranscriptEpisode {
    final withTranscript = _selectedScopeEpisodes
        .where((episode) => episode.transcriptUrl?.isNotEmpty == true)
        .toList();
    if (withTranscript.isEmpty) return null;
    final urls = withTranscript.map((episode) => episode.transcriptUrl).toSet();
    if (urls.length != 1) return null;
    return withTranscript.first;
  }

  @override
  void initState() {
    super.initState();
    _loadEpisodes();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadEpisodes() async {
    setState(() {
      _isLoadingCatalog = true;
      _catalogError = null;
    });

    final catalogUrl = (dotenv.env['AUDIO_CATALOG_URL'] ?? '').trim();
    var episodes = _fallbackEpisodes;

    if (catalogUrl.isNotEmpty) {
      try {
        final response = await http.get(Uri.parse(catalogUrl));
        if (response.statusCode < 200 || response.statusCode >= 300) {
          throw HttpException('Catalog returned ${response.statusCode}');
        }
        final decoded = jsonDecode(response.body);
        final episodeJson = decoded is List ? decoded : decoded['episodes'];
        if (episodeJson is! List) {
          throw const FormatException('Catalog episodes must be a JSON array');
        }

        final remoteEpisodes = episodeJson
            .whereType<Map<String, dynamic>>()
            .map(_AudioEpisode.fromJson)
            .where((episode) => episode.url.isNotEmpty)
            .toList();
        if (remoteEpisodes.isNotEmpty) episodes = remoteEpisodes;
      } catch (e) {
        _catalogError = 'Using built-in episode list. Catalog did not load.';
      }
    }

    if (!mounted) return;
    setState(() {
      _episodes = episodes;
      if (_selectedSectionId != null &&
          !_sections.any((section) => section.id == _selectedSectionId)) {
        _selectedSectionId = null;
        _selectedSubsectionId = null;
      }
      if (_selectedSubsectionId != null &&
          !_subsections.any(
            (subsection) => subsection.id == _selectedSubsectionId,
          )) {
        _selectedSubsectionId = null;
      }
      _isLoadingCatalog = false;
    });
    await _refreshDownloadedState();
  }

  Future<Directory> get _audioDirectory async {
    final documents = await getApplicationDocumentsDirectory();
    final directory = Directory('${documents.path}/audio_episodes');
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  Future<File> _episodeFile(_AudioEpisode episode) async {
    final directory = await _audioDirectory;
    return File('${directory.path}/${episode.fileName}');
  }

  Future<void> _refreshDownloadedState() async {
    final next = <String, bool>{};
    for (final episode in _episodes) {
      final file = await _episodeFile(episode);
      next[episode.id] = await file.exists();
    }
    if (mounted) setState(() => _downloaded.addAll(next));
  }

  Future<void> _downloadEpisode(_AudioEpisode episode) async {
    final url = episode.url.trim();
    if (url.isEmpty) {
      _showMessage('This episode does not have an audio URL yet.');
      return;
    }

    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) {
      _showMessage('The audio URL for ${episode.title} is invalid.');
      return;
    }

    setState(() => _progress[episode.id] = 0);
    final targetFile = await _episodeFile(episode);
    final partialFile = File('${targetFile.path}.download');

    try {
      final request = http.Request('GET', uri);
      final response = await http.Client().send(request);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException('Download failed with ${response.statusCode}');
      }

      final sink = partialFile.openWrite();
      var received = 0;
      final total = response.contentLength;

      await for (final chunk in response.stream) {
        received += chunk.length;
        sink.add(chunk);
        if (total != null && total > 0 && mounted) {
          setState(() => _progress[episode.id] = received / total);
        }
      }

      await sink.close();
      if (await targetFile.exists()) await targetFile.delete();
      await partialFile.rename(targetFile.path);

      if (mounted) {
        setState(() {
          _progress.remove(episode.id);
          _downloaded[episode.id] = true;
        });
      }
      _showMessage('${episode.title} downloaded.');
    } catch (e) {
      if (await partialFile.exists()) await partialFile.delete();
      if (mounted) setState(() => _progress.remove(episode.id));
      _showMessage('Could not download ${episode.title}.');
    }
  }

  Future<void> _playEpisode(_AudioEpisode episode) async {
    final file = await _episodeFile(episode);
    if (!await file.exists()) {
      await _downloadEpisode(episode);
      return;
    }

    try {
      if (_activeEpisodeId == episode.id && _audioPlayer.playing) {
        await _audioPlayer.pause();
        return;
      }

      if (_activeEpisodeId != episode.id) {
        await _audioPlayer.setFilePath(file.path);
        if (mounted) setState(() => _activeEpisodeId = episode.id);
      }

      await _audioPlayer.play();
    } catch (e) {
      _showMessage('Could not play ${episode.title}.');
    }
  }

  Future<void> _stopEpisode() async {
    await _audioPlayer.stop();
    if (mounted) setState(() => _activeEpisodeId = null);
  }

  Future<void> _removeEpisode(_AudioEpisode episode) async {
    final shouldRemove = await showDeleteBottomSheet(
      context,
      title: 'Remove download?',
      subtitle:
          'The recording will be removed. You will need to redownload it to listen again.',
    );
    if (shouldRemove != true || !mounted) return;

    final file = await _episodeFile(episode);
    try {
      if (_activeEpisodeId == episode.id) await _stopEpisode();
      if (await file.exists()) await file.delete();
      if (!mounted) return;
      setState(() => _downloaded[episode.id] = false);
      _showMessage('${episode.title} removed from this device.');
    } catch (e) {
      _showMessage('Could not remove ${episode.title}.');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4, right: 4, bottom: 16),
                  child: Text(
                    'Episodes download only when requested, then stay available on this device for offline listening.',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withAlpha(150),
                      height: 1.4,
                    ),
                  ),
                ),
                if (_isLoadingCatalog)
                  const Expanded(
                    child: Center(child: AbleriteLoadingIndicator()),
                  )
                else ...[
                  if (_catalogError != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        _catalogError!,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withAlpha(130),
                        ),
                      ),
                    ),
                  if (_episodes.isEmpty)
                    _buildEmptyAudioState()
                  else if (_selectedSectionId == null)
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, gridConstraints) =>
                            _buildSectionGrid(
                              _sections,
                              availableHeight: gridConstraints.maxHeight,
                            ),
                      ),
                    )
                  else ...[
                    _buildAudioBackButton(),
                    const SizedBox(height: 12),
                    if (_subsections.isNotEmpty &&
                        _selectedSubsectionId == null) ...[
                      if (_selectedSectionId == 'finance') ...[
                        _buildFinanceIntroCard(),
                        const SizedBox(height: 12),
                      ],
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, gridConstraints) =>
                              _buildSectionGrid(
                                _subsections,
                                isSubsectionGrid: true,
                                availableHeight: gridConstraints.maxHeight,
                              ),
                        ),
                      ),
                    ] else
                      Expanded(
                        child: ListView(
                          padding: EdgeInsets.zero,
                          children: _filteredEpisodes
                              .map(_buildEpisodeCard)
                              .toList(),
                        ),
                      ),
                  ],
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFinanceIntroCard() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primary.withAlpha(12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.primary.withAlpha(28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: colorScheme.primary.withAlpha(18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.account_balance_wallet_rounded,
              color: colorScheme.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Finance for a holistic life',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Financial clarity is one of the most critical learning areas because it supports freedom, stability, health, relationships, and the lifestyle you are trying to build.',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    height: 1.35,
                    color: colorScheme.onSurface.withAlpha(155),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyAudioState() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withAlpha(45)),
      ),
      child: Text(
        'No audio episodes are available yet. Check your catalog connection and try again.',
        style: GoogleFonts.outfit(
          fontSize: 14,
          color: colorScheme.onSurface.withAlpha(155),
          height: 1.35,
        ),
      ),
    );
  }

  Widget _buildAudioBackButton() {
    final colorScheme = Theme.of(context).colorScheme;
    final selectedSections = _sections
        .where((section) => section.id == _selectedSectionId)
        .toList();
    final selectedSubsections = _subsections
        .where((subsection) => subsection.id == _selectedSubsectionId)
        .toList();
    final sectionTitle = selectedSections.isEmpty
        ? null
        : selectedSections.first.title;
    final subsectionTitle = selectedSubsections.isEmpty
        ? null
        : selectedSubsections.first.title;
    final transcriptEpisode = _selectedTranscriptEpisode;

    return Row(
      children: [
        IconButton.filledTonal(
          onPressed: () {
            setState(() {
              if (_selectedSubsectionId != null) {
                _selectedSubsectionId = null;
              } else {
                _selectedSectionId = null;
              }
            });
          },
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            subsectionTitle ?? sectionTitle ?? 'Audio Episodes',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
        ),
        if (transcriptEpisode != null) ...[
          const SizedBox(width: 8),
          IconButton.filledTonal(
            onPressed: () => _showTranscript(transcriptEpisode),
            icon: const Icon(Icons.article_outlined),
            tooltip: 'Read transcript',
          ),
        ],
      ],
    );
  }

  Widget _buildSectionGrid(
    List<_AudioSectionSummary> sections, {
    bool isSubsectionGrid = false,
    double? availableHeight,
  }) {
    if (isSubsectionGrid) {
      final listHeight =
          availableHeight ?? (MediaQuery.sizeOf(context).height - 480);
      final itemGap = 10.0;
      final totalGap = itemGap * (sections.length - 1);
      final itemHeight = sections.isEmpty
          ? 0.0
          : (listHeight - totalGap) / sections.length;
      return Column(
        children: [
          for (var index = 0; index < sections.length; index++)
            Padding(
              padding: EdgeInsets.only(
                bottom: index == sections.length - 1 ? 0 : itemGap,
              ),
              child: _buildSectionButton(
                sections[index],
                isSubsection: true,
                heightOverride: itemHeight,
              ),
            ),
        ],
      );
    }

    const itemsPerPage = 6;
    final pageCount = (sections.length / itemsPerPage)
        .ceil()
        .clamp(1, 999)
        .toInt();
    final pageIndex = _sectionPageIndex.clamp(0, pageCount - 1).toInt();
    final pageSections = sections
        .skip(pageIndex * itemsPerPage)
        .take(itemsPerPage)
        .toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final controlsHeight = pageCount > 1 ? 66.0 : 0.0;
        final stackHeight = (constraints.maxHeight - controlsHeight).clamp(
          0.0,
          constraints.maxHeight,
        );

        return Column(
          children: [
            SizedBox(
              height: stackHeight,
              child: SingleChildScrollView(
                padding: EdgeInsets.zero,
                physics: const ClampingScrollPhysics(),
                child: _AudioStackedSectionList(
                  itemCount: pageSections.length,
                  availableHeight: stackHeight,
                  onTap: (index) =>
                      _showAudioSectionPreview(pageSections[index]),
                  itemBuilder: (context, index) {
                    final section = pageSections[index];
                    return _buildAudioStackedSectionCard(section);
                  },
                ),
              ),
            ),
            if (pageCount > 1)
              _AudioPageControls(
                currentPage: pageIndex,
                pageCount: pageCount,
                onPrevious: pageIndex == 0
                    ? null
                    : () => setState(() => _sectionPageIndex = pageIndex - 1),
                onNext: pageIndex >= pageCount - 1
                    ? null
                    : () => setState(() => _sectionPageIndex = pageIndex + 1),
              ),
          ],
        );
      },
    );
  }

  void _showAudioSectionPreview(_AudioSectionSummary section) {
    final color = _audioSectionColor(section.id);
    final coverAsset = _sectionCoverAssets[section.id];
    final detail = _audioSectionSubtitle(section);
    final description = section.subsectionCount == 0
        ? 'Listen to ${section.episodeCount} focused audio episodes in this section.'
        : 'Explore ${section.subsectionCount} series with ${section.episodeCount} audio episodes.';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _AudioSectionPreviewSheet(
          title: section.title,
          subtitle: detail,
          description: description,
          color: color,
          coverAsset: coverAsset,
          actionLabel: 'Enter ${section.title}',
          onAction: () {
            Navigator.pop(sheetContext);
            setState(() {
              _selectedSectionId = section.id;
              _selectedSubsectionId = null;
            });
          },
        );
      },
    );
  }

  Widget _buildAudioStackedSectionCard(_AudioSectionSummary section) {
    final color = _audioSectionColor(section.id);
    final foreground = _readableAudioCardForeground(color);
    final coverAsset = _sectionCoverAssets[section.id];

    return SizedBox(
      height: 176,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: foreground.withAlpha(18)),
          boxShadow: [
            BoxShadow(
              color: foreground.withAlpha(24),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            if (coverAsset != null)
              Positioned.fill(
                child: Image.asset(
                  coverAsset,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox.shrink(),
                ),
              ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [color.withAlpha(186), color.withAlpha(226), color],
                    stops: const [0, 0.58, 1],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 18, 18),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              section.title,
                              textAlign: TextAlign.right,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                color: foreground,
                                fontSize: 23,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Icon(
                      Icons.chevron_right_rounded,
                      color: foreground.withAlpha(150),
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _audioSectionColor(String id) {
    final index = _sections.indexWhere((section) => section.id == id);
    final base = Theme.of(context).colorScheme.primary;
    const strengths = [0.0, 0.09, 0.17, 0.24, 0.12, 0.29, 0.2, 0.34];
    final strength = strengths[(index < 0 ? 0 : index) % strengths.length];
    return index.isEven
        ? Color.lerp(base, Colors.white, strength)!
        : Color.lerp(base, Colors.black, strength * 0.58)!;
  }

  String _audioSectionSubtitle(_AudioSectionSummary section) {
    return _sectionSubtitles[section.id] ?? 'Focused listening';
  }

  Widget _buildSectionButton(
    _AudioSectionSummary section, {
    required bool isSubsection,
    double? heightOverride,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final detail = _audioSectionSubtitle(section);
    final height = heightOverride ?? (isSubsection ? 82.0 : 112.0);
    final icon = isSubsection
        ? Icons.headphones_rounded
        : Icons.spatial_audio_off_rounded;
    final coverAsset = _sectionCoverAssets[section.id];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isSubsection
        ? colorScheme.primary.withAlpha(30)
        : isDark
        ? Colors.white.withAlpha(12)
        : colorScheme.primary.withAlpha(24);

    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          setState(() {
            if (isSubsection) {
              _selectedSubsectionId = section.id;
            } else {
              _selectedSectionId = section.id;
              _selectedSubsectionId = null;
            }
          });
        },
        child: Container(
          height: height,
          padding: EdgeInsets.all(isSubsection ? 14 : 0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: isSubsection
              ? Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withAlpha(18),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(icon, color: colorScheme.primary, size: 25),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            section.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            detail,
                            style: GoogleFonts.outfit(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface.withAlpha(145),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: colorScheme.onSurface.withAlpha(120),
                    ),
                  ],
                )
              : _buildCoverTileContent(section, coverAsset, colorScheme, icon),
        ),
      ),
    );
  }

  Widget _buildCoverTileContent(
    _AudioSectionSummary section,
    String? coverAsset,
    ColorScheme colorScheme,
    IconData fallbackIcon,
  ) {
    final titleRowColor = Theme.of(context).brightness == Brightness.dark
        ? colorScheme.surface
        : Colors.white;

    if (coverAsset == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              color: colorScheme.primary.withAlpha(18),
              child: Icon(fallbackIcon, color: colorScheme.primary, size: 24),
            ),
          ),
          _buildAudioCoverTitleRow(section.title, colorScheme, titleRowColor),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: SizedBox(
            width: double.infinity,
            child: Image.asset(
              coverAsset,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(color: colorScheme.primary.withAlpha(24));
              },
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: _buildAudioCoverTitleRow(
            section.title,
            colorScheme,
            titleRowColor,
          ),
        ),
      ],
    );
  }

  Widget _buildAudioCoverTitleRow(
    String title,
    ColorScheme colorScheme,
    Color backgroundColor,
  ) {
    return Container(
      width: double.infinity,
      color: backgroundColor,
      padding: const EdgeInsets.fromLTRB(9, 6, 9, 7),
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.outfit(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface,
          height: 1,
        ),
      ),
    );
  }

  Future<void> _showTranscript(_AudioEpisode episode) async {
    final url = episode.transcriptUrl;
    if (url == null || url.isEmpty) {
      _showMessage('Transcript is not available for ${episode.title}.');
      return;
    }

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException('Transcript returned ${response.statusCode}');
      }
      if (!mounted) return;
      final transcriptBody = utf8.decode(response.bodyBytes);
      await Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(
          builder: (_) => _AudioTranscriptReaderPage(
            title: episode.subsectionTitle ?? episode.sectionTitle,
            body: transcriptBody,
          ),
        ),
      );
    } catch (e) {
      _showMessage('Could not load transcript for ${episode.title}.');
    }
  }

  Widget _buildEpisodeCard(_AudioEpisode episode) {
    final colorScheme = Theme.of(context).colorScheme;
    final progress = _progress[episode.id];
    final isDownloading = progress != null;
    final isDownloaded = _downloaded[episode.id] ?? false;
    final isConfigured = episode.url.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: !isConfigured || isDownloading
              ? null
              : () {
                  if (isDownloaded) {
                    _playEpisode(episode);
                  } else {
                    _downloadEpisode(episode);
                  }
                },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorScheme.primary.withAlpha(28)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withAlpha(22),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.graphic_eq, color: colorScheme.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            episode.title,
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            episode.description,
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: colorScheme.onSurface.withAlpha(155),
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              _buildEpisodeMetaChip(
                                episode.subsectionTitle ?? episode.sectionTitle,
                                Icons.headphones_rounded,
                                colorScheme,
                              ),
                              _buildEpisodeMetaChip(
                                episode.duration,
                                Icons.schedule_rounded,
                                colorScheme,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (!isConfigured)
                  Text(
                    'Waiting for audio URL',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: colorScheme.error,
                    ),
                  ),
                if (isDownloading) ...[
                  LinearProgressIndicator(
                    value: progress == 0 ? null : progress,
                  ),
                  const SizedBox(height: 12),
                ],
                if (isDownloaded)
                  _buildPlayerControls(episode, colorScheme)
                else
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: isDownloading
                          ? null
                          : () => _downloadEpisode(episode),
                      icon: const Icon(Icons.download),
                      label: const Text('Download'),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEpisodeMetaChip(
    String text,
    IconData icon,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: colorScheme.primary.withAlpha(18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: colorScheme.primary),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.outfit(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerControls(_AudioEpisode episode, ColorScheme colorScheme) {
    return StreamBuilder<PlayerState>(
      stream: _audioPlayer.playerStateStream,
      builder: (context, snapshot) {
        final playerState = snapshot.data;
        final isActive = _activeEpisodeId == episode.id;
        final isPlaying = isActive && (playerState?.playing ?? false);

        return Column(
          children: [
            StreamBuilder<Duration>(
              stream: _audioPlayer.positionStream,
              builder: (context, positionSnapshot) {
                return StreamBuilder<Duration?>(
                  stream: _audioPlayer.durationStream,
                  builder: (context, durationSnapshot) {
                    final liveDuration = durationSnapshot.data ?? Duration.zero;
                    final duration = isActive
                        ? liveDuration
                        : _durationFromLabel(episode.duration);
                    final position = isActive
                        ? positionSnapshot.data ?? Duration.zero
                        : Duration.zero;
                    final max = duration.inMilliseconds.toDouble();
                    final value = max <= 0
                        ? 0.0
                        : position.inMilliseconds
                              .clamp(0, max.toInt())
                              .toDouble();

                    return Slider(
                      value: value,
                      max: max <= 0 ? 1 : max,
                      onChanged: !isActive || max <= 0
                          ? null
                          : (next) => _audioPlayer.seek(
                              Duration(milliseconds: next.round()),
                            ),
                    );
                  },
                );
              },
            ),
            StreamBuilder<Duration?>(
              stream: _audioPlayer.durationStream,
              builder: (context, durationSnapshot) {
                return StreamBuilder<Duration>(
                  stream: _audioPlayer.positionStream,
                  builder: (context, positionSnapshot) {
                    final liveDuration = durationSnapshot.data ?? Duration.zero;
                    final catalogDuration = _durationFromLabel(
                      episode.duration,
                    );
                    final duration = isActive && liveDuration > Duration.zero
                        ? liveDuration
                        : catalogDuration;
                    final position = isActive
                        ? positionSnapshot.data ?? Duration.zero
                        : Duration.zero;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(position),
                            style: GoogleFonts.outfit(
                              fontSize: 11.5,
                              color: colorScheme.onSurface.withAlpha(140),
                            ),
                          ),
                          Text(
                            _formatDuration(duration),
                            style: GoogleFonts.outfit(
                              fontSize: 11.5,
                              color: colorScheme.onSurface.withAlpha(140),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _playEpisode(episode),
                    icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                    label: Text(isPlaying ? 'Pause' : 'Play'),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.filledTonal(
                  onPressed: isActive ? _stopEpisode : null,
                  icon: const Icon(Icons.stop),
                  tooltip: 'Stop',
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  onPressed: () => _removeEpisode(episode),
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Remove download',
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString();
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    final hours = duration.inHours;
    if (hours <= 0) return '$minutes:$seconds';
    return '$hours:${minutes.padLeft(2, '0')}:$seconds';
  }

  Duration _durationFromLabel(String label) {
    final parts = label
        .split(':')
        .map((part) => int.tryParse(part.trim()))
        .toList();
    if (parts.any((part) => part == null)) return Duration.zero;
    if (parts.length == 2) {
      return Duration(minutes: parts[0]!, seconds: parts[1]!);
    }
    if (parts.length == 3) {
      return Duration(hours: parts[0]!, minutes: parts[1]!, seconds: parts[2]!);
    }
    return Duration.zero;
  }
}

class _AudioTranscriptReaderPage extends StatelessWidget {
  final String title;
  final String body;

  const _AudioTranscriptReaderPage({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final blocks = _buildTranscriptBlocks(context, colorScheme);
    return Scaffold(
      appBar: AppBar(
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 10, 22, 36),
          child: SelectionArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: blocks,
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildTranscriptBlocks(
    BuildContext context,
    ColorScheme colorScheme,
  ) {
    final lines = body
        .replaceAll('\u0000', '')
        .replaceAll('\uFFFD', "'")
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    if (lines.isEmpty) {
      return [
        Text(
          'Transcript unavailable.',
          style: GoogleFonts.outfit(
            fontSize: 16,
            color: colorScheme.onSurface.withAlpha(150),
          ),
        ),
      ];
    }

    final widgets = <Widget>[
      Text(
        lines.first,
        style: GoogleFonts.outfit(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          height: 1.18,
          color: colorScheme.onSurface,
        ),
      ),
      const SizedBox(height: 18),
    ];

    for (final line in lines.skip(1)) {
      final isHeading = _looksLikeHeading(line);
      widgets.add(
        Padding(
          padding: EdgeInsets.only(
            top: isHeading ? 14 : 0,
            bottom: isHeading ? 10 : 14,
          ),
          child: Text(
            line,
            style: GoogleFonts.outfit(
              fontSize: isHeading ? 18 : 16,
              fontWeight: isHeading ? FontWeight.bold : FontWeight.w400,
              height: isHeading ? 1.22 : 1.55,
              color: colorScheme.onSurface,
            ),
          ),
        ),
      );
    }

    return widgets;
  }

  bool _looksLikeHeading(String line) {
    if (line.length > 72) return false;
    if (RegExp(r'[.!?]$').hasMatch(line)) return false;
    final words = line.split(RegExp(r'\s+')).where((word) => word.isNotEmpty);
    if (words.length > 8) return false;
    return true;
  }
}

Color _readableAudioCardForeground(Color color) {
  return color.computeLuminance() > 0.62
      ? Color.lerp(color, Colors.black, 0.68)!
      : Colors.white;
}

class _AudioSectionPreviewSheet extends StatelessWidget {
  final String title;
  final String subtitle;
  final String description;
  final Color color;
  final String? coverAsset;
  final String actionLabel;
  final VoidCallback onAction;

  const _AudioSectionPreviewSheet({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.color,
    required this.coverAsset,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final foreground = _readableAudioCardForeground(color);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        child: Material(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 230,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ColoredBox(color: color),
                      if (coverAsset != null)
                        Image.asset(
                          coverAsset!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const SizedBox.shrink(),
                        ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              color.withAlpha(176),
                              color.withAlpha(222),
                              color,
                            ],
                            stops: const [0, 0.56, 1],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 20,
                        right: 20,
                        bottom: 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              title,
                              textAlign: TextAlign.right,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                color: foreground,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              textAlign: TextAlign.right,
                              style: GoogleFonts.outfit(
                                color: foreground.withAlpha(190),
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        description,
                        style: GoogleFonts.outfit(
                          color: colorScheme.onSurface.withAlpha(185),
                          fontSize: 15,
                          height: 1.42,
                        ),
                      ),
                      const SizedBox(height: 18),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: color,
                          foregroundColor: foreground,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: onAction,
                        child: Text(
                          actionLabel,
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
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

class _AudioPageControls extends StatelessWidget {
  final int currentPage;
  final int pageCount;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  const _AudioPageControls({
    required this.currentPage,
    required this.pageCount,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton.filledTonal(
            onPressed: onPrevious,
            icon: const Icon(Icons.chevron_left_rounded),
            tooltip: 'Previous audio page',
          ),
          const SizedBox(width: 12),
          Row(
            children: List.generate(pageCount, (index) {
              final selected = index == currentPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: selected ? 18 : 7,
                height: 7,
                decoration: BoxDecoration(
                  color: selected
                      ? colorScheme.primary
                      : colorScheme.onSurface.withAlpha(70),
                  borderRadius: BorderRadius.circular(999),
                ),
              );
            }),
          ),
          const SizedBox(width: 12),
          IconButton.filledTonal(
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right_rounded),
            tooltip: 'Next audio page',
          ),
        ],
      ),
    );
  }
}

class _AudioStackedSectionList extends StatefulWidget {
  final int itemCount;
  final double availableHeight;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final ValueChanged<int> onTap;

  const _AudioStackedSectionList({
    required this.itemCount,
    required this.availableHeight,
    required this.itemBuilder,
    required this.onTap,
  });

  @override
  State<_AudioStackedSectionList> createState() =>
      _AudioStackedSectionListState();
}

class _AudioStackedSectionListState extends State<_AudioStackedSectionList> {
  static const _cardHeight = 176.0;
  static const _collapsedStep = 92.0;
  static const _expandedStep = 132.0;

  int? _activeIndex;

  @override
  Widget build(BuildContext context) {
    final availableStep = widget.itemCount <= 1
        ? _collapsedStep
        : ((widget.availableHeight - _cardHeight - 14) / (widget.itemCount - 1))
              .clamp(64.0, _collapsedStep);
    final height = _cardHeight + ((widget.itemCount - 1) * availableStep) + 6;
    final expandedHeight =
        _cardHeight + ((widget.itemCount - 1) * _expandedStep) + 8;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      height: _activeIndex == null ? height : expandedHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: List.generate(widget.itemCount, (index) {
          final isActive = _activeIndex == index;
          final step = _activeIndex == null ? availableStep : _expandedStep;

          return AnimatedPositioned(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            top: index * step,
            left: 0,
            right: 0,
            child: AnimatedScale(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              scale: isActive ? 1.025 : 1,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 180),
                opacity: _activeIndex == null || isActive ? 1 : 0.94,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () async {
                    if (_activeIndex != null) return;
                    setState(() => _activeIndex = index);
                    await Future<void>.delayed(
                      const Duration(milliseconds: 190),
                    );
                    if (!mounted) return;
                    widget.onTap(index);
                    setState(() => _activeIndex = null);
                  },
                  child: widget.itemBuilder(context, index),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─── SMART Goals Page (full tabbed content from desktop) ───
class _SmartGoalsPage extends StatefulWidget {
  final Function(String) onTopicSelected;
  final ValueNotifier<String>? tabNotifier;
  const _SmartGoalsPage({required this.onTopicSelected, this.tabNotifier});

  @override
  State<_SmartGoalsPage> createState() => _SmartGoalsPageState();
}

class _SmartGoalsPageState extends State<_SmartGoalsPage> {
  String _tab = 'overview';

  void _setTab(String tab) {
    setState(() => _tab = tab);
    widget.tabNotifier?.value = tab;
  }

  @override
  void initState() {
    super.initState();
    pushPage();
    // Listen to external tab changes (e.g. back button resetting to overview)
    widget.tabNotifier?.addListener(_onTabNotifierChanged);
  }

  void _onTabNotifierChanged() {
    final newTab = widget.tabNotifier?.value;
    if (newTab != null && newTab != _tab) {
      setState(() => _tab = newTab);
    }
  }

  @override
  void dispose() {
    widget.tabNotifier?.removeListener(_onTabNotifierChanged);
    popPage();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSmartTabs(),
        Expanded(child: _buildTabContent()),
      ],
    );
  }

  Widget _buildSmartTabs() {
    final tabs = [
      {'id': 'overview', 'label': 'Overview'},
      {'id': 'specific', 'label': 'S'},
      {'id': 'measurable', 'label': 'M'},
      {'id': 'achievable', 'label': 'A'},
      {'id': 'relevant', 'label': 'R'},
      {'id': 'timebound', 'label': 'T'},
      {'id': 'examples', 'label': 'Examples'},
    ];

    return Container(
      height: 45,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withAlpha(50),
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: tabs.map((tab) {
            final isSelected = _tab == tab['id'];
            final flex = tab['id'] == 'overview' || tab['id'] == 'examples'
                ? 3
                : 1;

            return Expanded(
              flex: flex,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _setTab(tab['id'] as String),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      tab['label'] as String,
                      maxLines: 1,
                      overflow: TextOverflow.visible,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(
                                context,
                              ).colorScheme.onSurface.withAlpha(120),
                      ),
                    ),
                    if (isSelected)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        height: 2,
                        width: 20,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_tab) {
      case 'overview':
        return _buildOverview();
      case 'specific':
        return _buildLetterTab(
          'S',
          'Specific',
          'Define exactly what you want to accomplish',
          Theme.of(context).colorScheme.primary,
          body:
              'A specific goal answers the five W\'s: Who is involved? What do I want to accomplish? Where will this happen? When do I want to achieve this? Why is this goal important? The more precise your goal, the clearer your path to achieving it.',
          questions: [
            {
              'q': 'What exactly do I want to achieve?',
              'hint': 'Be as detailed as possible',
            },
            {
              'q': 'Who needs to be involved?',
              'hint': 'Mentors, partners, teams',
            },
            {
              'q': 'Where will this take place?',
              'hint': 'Location, platform, context',
            },
            {
              'q': 'Why is this important to me?',
              'hint': 'Connect to your core values',
            },
          ],
          vague: [
            'I want to get in shape',
            'I want to make more money',
            'I want to read more books',
          ],
          smart: [
            'Run a 5K race in my city this spring',
            'Increase freelance income by \$1,000/month',
            'Read 2 non-fiction books per month',
          ],
          tip:
              'Read your goal to someone who knows nothing about it. If they can picture exactly what success looks like, your goal is specific enough.',
        );
      case 'measurable':
        return _buildLetterTab(
          'M',
          'Measurable',
          'Track your progress with concrete metrics',
          Theme.of(context).colorScheme.primary,
          body:
              'If you can\'t measure it, you can\'t manage it. A measurable goal includes specific criteria for tracking progress — a number, percentage, frequency, or any quantifiable indicator that tells you how close you are to success.',
          questions: [
            {
              'q': 'How will I track progress?',
              'hint': 'Numbers, frequency, milestones',
            },
            {
              'q': 'How will I know when it\'s done?',
              'hint': 'Define your finish line clearly',
            },
            {
              'q': 'What are my milestone markers?',
              'hint': 'Break into checkpoints',
            },
          ],
          vague: [
            'Get better at coding',
            'Save more money',
            'Exercise regularly',
          ],
          smart: [
            'Complete 3 coding projects by March',
            'Save \$10,000 in emergency fund',
            'Exercise 4 days/week for 30 min',
          ],
          tip:
              'Break your goal into milestones — checkpoints along the way. If your goal is to save \$10,000 in a year, set monthly milestones of ~\$834.',
        );
      case 'achievable':
        return _buildLetterTab(
          'A',
          'Achievable',
          'Stretch yourself, but stay realistic',
          Theme.of(context).colorScheme.primary,
          body:
              'An achievable goal strikes the balance between challenging enough to inspire growth and realistic enough to maintain motivation. Goals that are too easy breed complacency; goals that are impossible breed frustration.',
          questions: [
            {
              'q': 'Do I have the skills needed?',
              'hint': 'If not, can I learn them in time?',
            },
            {'q': 'Do I have the resources?', 'hint': 'Time, money, tools'},
            {
              'q': 'Has someone similar achieved this?',
              'hint': 'Find precedent',
            },
            {
              'q': 'Can I break this into smaller steps?',
              'hint': 'Decomposition',
            },
          ],
          vague: [],
          smart: [],
          tip:
              'If you\'re about 70% confident you can achieve a goal, it\'s in the sweet spot. Much lower = defeated. Much higher = not challenged enough.',
          extraWidget: _buildGoldilocksZone(),
        );
      case 'relevant':
        return _buildLetterTab(
          'R',
          'Relevant',
          'Align goals with your life\'s bigger picture',
          Theme.of(context).colorScheme.primary,
          body:
              'A relevant goal matters to you. It aligns with your core values, supports your long-term vision, and fits the current season of your life. The most important question: "Does this goal move me closer to the person I want to become?"',
          questions: [
            {
              'q': 'Does this align with my core values?',
              'hint': 'Goals disconnected from values feel hollow',
            },
            {
              'q': 'Is this the right time?',
              'hint': 'Be honest about your current season',
            },
            {
              'q': 'Does this support my other goals?',
              'hint': 'Goals should complement, not compete',
            },
            {
              'q': 'Will I still want this in 5 years?',
              'hint': 'Fleeting desire vs life priority',
            },
          ],
          vague: [],
          smart: [],
          tip:
              'Use your Values & Goals widget to define your core values first. If a goal doesn\'t connect to at least one core value, question whether it belongs in your life right now.',
        );
      case 'timebound':
        return _buildLetterTab(
          'T',
          'Time-Bound',
          'Create urgency with deadlines',
          Theme.of(context).colorScheme.primary,
          body:
              'A goal without a deadline is just a wish. Time-bound goals create healthy pressure that prevents procrastination and forces decision-making. Set a target date, then work backwards to create your action plan.',
          questions: [
            {
              'q': 'What is my hard deadline?',
              'hint': 'Events, seasons, commitments',
            },
            {
              'q': 'What are my sprint milestones?',
              'hint': '2-4 week mini-deadlines',
            },
            {
              'q': 'What daily anchors can I set?',
              'hint': 'Recurring time-specific commitments',
            },
          ],
          vague: [],
          smart: [],
          tip:
              'Work expands to fill the time available (Parkinson\'s Law). If you give yourself a year for a goal that could be done in 3 months, it\'ll take a year.',
          extraWidget: _buildReverseTimeline(),
        );
      case 'examples':
        return _buildExamples();
      default:
        return _buildOverview();
    }
  }

  Widget _buildOverview() {
    final smartLetters = [
      {
        'letter': 'S',
        'word': 'Specific',
        'color': Theme.of(context).colorScheme.primary,
        'desc': 'Clearly define what you want to accomplish',
      },
      {
        'letter': 'M',
        'word': 'Measurable',
        'color': Theme.of(context).colorScheme.primary,
        'desc': 'Quantify your progress and success',
      },
      {
        'letter': 'A',
        'word': 'Achievable',
        'color': Theme.of(context).colorScheme.primary,
        'desc': 'Set realistic yet challenging targets',
      },
      {
        'letter': 'R',
        'word': 'Relevant',
        'color': Theme.of(context).colorScheme.primary,
        'desc': 'Align with your values and bigger vision',
      },
      {
        'letter': 'T',
        'word': 'Time-Bound',
        'color': Theme.of(context).colorScheme.primary,
        'desc': 'Set a deadline to create urgency',
      },
    ];

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        // Header
        Stack(
          children: [
            Center(
              child: Column(
                children: [
                  const Text('🎯', style: TextStyle(fontSize: 28)),
                  Text(
                    'The SMART Goals Framework',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'SMART transforms vague aspirations into actionable objectives.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withAlpha(180),
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 0,
              top: 0,
              child: IconButton(
                icon: Icon(
                  Icons.lightbulb_outline,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                onPressed: () => _showInfoModal(context),
                tooltip: 'How it works',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Letter Cards
        ...smartLetters.map<Widget>((item) {
          return GestureDetector(
            onTap: () => setState(
              () => _tab = (item['word'] as String).toLowerCase().replaceAll(
                '-',
                '',
              ),
            ),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: (item['color'] as Color).withAlpha(
                    (0.3 * 255).toInt(),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: (item['color'] as Color).withAlpha(
                        (0.15 * 255).toInt(),
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        item['letter'] as String,
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: item['color'] as Color,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['word'] as String,
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item['desc'] as String,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withAlpha(150),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: item['color'] as Color,
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 16),
      ],
    );
  }

  void _showInfoModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb,
                        color: Theme.of(context).colorScheme.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'About SMART Goals',
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withAlpha(150),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Why SMART Works
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withAlpha((0.05 * 255).toInt()),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withAlpha((0.2 * 255).toInt()),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '💡 Why SMART Goals Work',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Research shows that people who write down specific, measurable goals are 42% more likely to achieve them. The framework eliminates ambiguity — the #1 killer of goal completion.',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withAlpha(180),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // How to Use
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withAlpha(100),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).dividerColor.withAlpha(20),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How to Use in Ablerite',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...[
                      'Create and track goals in Action Center',
                      'Break goals into measurable sub-goals',
                      'Set due dates for accountability',
                      'Connect to values for deeper motivation',
                    ].asMap().entries.map((e) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary
                                    .withAlpha((0.15 * 255).toInt()),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${e.key + 1}',
                                  style: GoogleFonts.outfit(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                e.value,
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withAlpha(200),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLetterTab(
    String letter,
    String word,
    String subtitle,
    Color color, {
    required String body,
    required List<Map<String, String>> questions,
    required List<String> vague,
    required List<String> smart,
    required String tip,
    Widget? extraWidget,
  }) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withAlpha((0.15 * 255).toInt()),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  letter,
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    word,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withAlpha(120),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Body
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            body,
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withAlpha(200),
              height: 1.6,
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Questions
        if (questions.isNotEmpty) ...[
          Text(
            'Ask Yourself',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          ...questions.map<Widget>(
            (q) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withAlpha((0.05 * 255).toInt()),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: color.withAlpha((0.15 * 255).toInt()),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    q['q'] ?? 'No question',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    q['hint'] ?? 'No hint',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withAlpha(140),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Vague vs Smart comparison
        if (vague.isNotEmpty && smart.isNotEmpty) ...[
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildComparisonColumn('❌ Vague', vague, const Color(0xFFEF4444)),
              const SizedBox(height: 12),
              _buildComparisonColumn(
                '✅ $word',
                smart,
                Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],

        // Extra Widget
        if (extraWidget != null) ...[extraWidget, const SizedBox(height: 16)],

        // Pro Tip
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withAlpha((0.05 * 255).toInt()),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withAlpha((0.2 * 255).toInt())),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '💡 Pro Tip',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                tip,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(200),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildComparisonColumn(String title, List<String> items, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha((0.05 * 255).toInt()),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha((0.2 * 255).toInt())),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          ...items.map<Widget>(
            (g) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(top: 5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      g,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withAlpha(180),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoldilocksZone() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withAlpha(100),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'The Goldilocks Zone',
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _goldilocksTile(
                '😴',
                'Too Easy',
                'No growth',
                Theme.of(context).colorScheme.onSurface.withAlpha(120),
              ),
              const Spacer(),
              _goldilocksTile(
                '🎯',
                'Goldilocks',
                'Peak flow',
                const Color(0xFF10B981),
              ),
              const Spacer(),
              _goldilocksTile(
                '😰',
                'Too Hard',
                'Burnout risk',
                Theme.of(context).colorScheme.onSurface.withAlpha(120),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _goldilocksTile(String emoji, String label, String sub, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color == Theme.of(context).colorScheme.primary
              ? Theme.of(
                  context,
                ).colorScheme.primary.withAlpha((0.1 * 255).toInt())
              : Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withAlpha(100),
          borderRadius: BorderRadius.circular(10),
          border: color == Theme.of(context).colorScheme.primary
              ? Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withAlpha((0.3 * 255).toInt()),
                )
              : null,
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: color == Theme.of(context).colorScheme.primary
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface.withAlpha(150),
              ),
            ),
            Text(
              sub,
              style: GoogleFonts.outfit(
                fontSize: 9,
                color: Theme.of(context).colorScheme.onSurface.withAlpha(120),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReverseTimeline() {
    final steps = [
      {
        'time': 'Month 6',
        'action': '🏁 Race day — run 21.1 km',
        'color': Theme.of(context).colorScheme.primary,
      },
      {
        'time': 'Month 5',
        'action': 'Run 18 km long runs weekly',
        'color': Theme.of(context).colorScheme.primary,
      },
      {
        'time': 'Month 4',
        'action': 'Run 15 km, add speed work',
        'color': Theme.of(
          context,
        ).colorScheme.primary.withAlpha((0.8 * 255).toInt()),
      },
      {
        'time': 'Month 3',
        'action': 'Run 10 km consistently 3x/week',
        'color': Theme.of(
          context,
        ).colorScheme.primary.withAlpha((0.7 * 255).toInt()),
      },
      {
        'time': 'Month 2',
        'action': 'Build to 5 km runs, 4x/week',
        'color': Theme.of(
          context,
        ).colorScheme.primary.withAlpha((0.6 * 255).toInt()),
      },
      {
        'time': 'Month 1',
        'action': 'Start couch-to-5K program',
        'color': Theme.of(
          context,
        ).colorScheme.primary.withAlpha((0.5 * 255).toInt()),
      },
      {
        'time': 'Today',
        'action': '🎬 Buy running shoes, download app',
        'color': Theme.of(
          context,
        ).colorScheme.primary.withAlpha((0.4 * 255).toInt()),
      },
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withAlpha(100),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reverse Timeline Example',
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          Text(
            '"I want to run a half-marathon in 6 months"',
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withAlpha(120),
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 16),
          ...steps.map<Widget>(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  SizedBox(
                    width: 60,
                    child: Text(
                      s['time'] as String,
                      textAlign: TextAlign.right,
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: s['color'] as Color,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: s['color'] as Color,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      s['action'] as String,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withAlpha(180),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExamples() {
    final examples = [
      {
        'category': '💰 Financial',
        'before': 'I want to save more money',
        'after':
            'I will save \$500/month by automating transfers, reaching \$6,000 by December 31st, to build a 3-month emergency fund.',
        'breakdown': {
          'S': 'Save \$500/month via auto-transfers',
          'M': '\$6,000 total, \$500 monthly',
          'A': 'Budget shows \$600 discretionary',
          'R': 'Financial security for family',
          'T': 'December 31st deadline',
        },
      },
      {
        'category': '💪 Health',
        'before': 'I want to get fit',
        'after':
            'I will complete a 5K in under 30 min by training 3 days/week using Couch-to-5K, registering for the City Run on April 12th.',
        'breakdown': {
          'S': '5K under 30 minutes',
          'M': '3 training days/week',
          'A': 'C25K designed for beginners',
          'R': 'Energy for daily life',
          'T': 'April 12th race day',
        },
      },
      {
        'category': '📚 Learning',
        'before': 'I want to learn coding',
        'after':
            'I will complete a full-stack course and build 3 portfolio projects by June 30th, studying 1 hour every weekday morning.',
        'breakdown': {
          'S': 'Course + 3 projects',
          'M': '1 hour/day, 3 projects',
          'A': 'Free course, laptop',
          'R': 'Career transition to tech',
          'T': 'June 30th completion',
        },
      },
      {
        'category': '🧘 Spiritual',
        'before': 'I want to pray more',
        'after':
            'I will pray for 15 min every morning at 6 AM and journal one gratitude reflection, maintaining a streak through end of quarter.',
        'breakdown': {
          'S': '15 min prayer + gratitude',
          'M': 'Daily streak tracker',
          'A': 'Wake 15 min earlier',
          'R': 'Deeper faith & peace',
          'T': '90-day commitment',
        },
      },
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            const Text('💡', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Examples',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    'See how vague ideas become powerful goals',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withAlpha(160),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...examples.map<Widget>((ex) {
          final breakdown = ex['breakdown'] as Map<String, String>;
          final colors = {
            'S': Theme.of(context).colorScheme.primary,
            'M': Theme.of(context).colorScheme.primary,
            'A': Theme.of(context).colorScheme.primary,
            'R': Theme.of(context).colorScheme.primary,
            'T': Theme.of(context).colorScheme.primary,
          };
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withAlpha((0.08 * 255).toInt()),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest.withAlpha(150),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        ex['category'] as String,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '❌ BEFORE',
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFEF4444),
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '"${ex['before']}"',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withAlpha(140),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Divider(
                        color: Theme.of(context).dividerColor.withAlpha(50),
                        thickness: 1,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '✅ AFTER (SMART)',
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '"${ex['after']}"',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withAlpha(200),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: breakdown.entries.map((e) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest
                                  .withAlpha(100),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  e.key,
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    color: colors[e.key],
                                  ),
                                ),
                                const SizedBox(height: 2),
                                SizedBox(
                                  width: 80,
                                  child: Text(
                                    e.value,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.outfit(
                                      fontSize: 9,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface.withAlpha(150),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 40),
      ],
    );
  }
}

class _TopicSelector extends StatefulWidget {
  final String selectedTopicId;
  final Function(String) onTopicSelected;
  const _TopicSelector({
    required this.selectedTopicId,
    required this.onTopicSelected,
  });

  @override
  State<_TopicSelector> createState() => _TopicSelectorState();
}

class _TopicSelectorState extends State<_TopicSelector> {
  final ScrollController _topicScrollController = ScrollController();
  late List<GlobalKey> _topicKeys;

  final List<Map<String, dynamic>> _topicsList = [
    {'id': 'smart', 'title': 'SMART Goals', 'icon': Icons.adjust},
    {'id': 'habits', 'title': 'Habit Stacking', 'icon': Icons.layers},
    {'id': 'visualize', 'title': 'Visualization', 'icon': Icons.visibility},
    {'id': 'mindset', 'title': 'Growth Mindset', 'icon': Icons.psychology},
    {'id': 'focus', 'title': 'Deep Focus', 'icon': Icons.center_focus_strong},
    {'id': 'gratitude', 'title': 'Gratitude', 'icon': Icons.favorite},
  ];

  @override
  void initState() {
    super.initState();
    _topicKeys = List.generate(_topicsList.length, (index) => GlobalKey());
    WidgetsBinding.instance.addPostFrameCallback((_) => _snapToInitialTopic());
  }

  void _snapToInitialTopic() {
    final index = _topicsList.indexWhere(
      (t) => t['id'] == widget.selectedTopicId,
    );
    if (index != -1 && _topicScrollController.hasClients) {
      // Logic for snapping scroll to selected topic
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        controller: _topicScrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _topicsList.length,
        itemBuilder: (context, index) {
          final topic = _topicsList[index];
          final isSelected = topic['id'] == widget.selectedTopicId;
          return Padding(
            key: _topicKeys[index],
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    topic['icon'] as IconData,
                    size: 16,
                    color: isSelected
                        ? Theme.of(context).colorScheme.surface
                        : Theme.of(
                            context,
                          ).colorScheme.onSurface.withAlpha(120),
                  ),
                  const SizedBox(width: 6),
                  Text(topic['title'] as String),
                ],
              ),
              labelStyle: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? Theme.of(context).colorScheme.surface
                    : Theme.of(context).colorScheme.onSurface.withAlpha(120),
              ),
              selectedColor: Theme.of(context).colorScheme.primary,
              backgroundColor: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withAlpha(50),
              side: BorderSide(
                color: isSelected
                    ? Colors.transparent
                    : Theme.of(
                        context,
                      ).colorScheme.onSurface.withAlpha(isSelected ? 0 : 40),
              ),
              showCheckmark: false,
              onSelected: (_) {
                widget.onTopicSelected(topic['id'] as String);
              },
            ),
          );
        },
      ),
    );
  }
}

class _TopicDetailPageStateful extends StatefulWidget {
  final String topicId;
  const _TopicDetailPageStateful({required this.topicId});
  @override
  State<_TopicDetailPageStateful> createState() =>
      _TopicDetailPageStatefulState();
}

class _TopicDetailPageStatefulState extends State<_TopicDetailPageStateful> {
  @override
  Widget build(BuildContext context) {
    // Build directly using a simplified approach
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        title: Text(
          _getTitle(),
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        children: [
          // Topic selector at top
          _buildTopicSelector(),
          const SizedBox(height: 8),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  String _getTitle() {
    final titles = {
      'habits': 'Habit Stacking',
      'visualize': 'Visualization',
      'mindset': 'Growth Mindset',
      'focus': 'Deep Focus',
      'gratitude': 'Gratitude Practice',
    };
    return titles[widget.topicId] ?? 'Learn';
  }

  void _navigateToTopic(String topicId) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => _TopicDetailPageStateful(topicId: topicId),
      ),
    );
  }

  final ScrollController _topicScrollController = ScrollController();
  late List<GlobalKey> _topicKeys;
  final GlobalKey _selectorKey = GlobalKey();

  final List<Map<String, dynamic>> topics = [
    {
      'id': 'smart',
      'title': 'SMART Goals',
      'icon': Icons.adjust,
      'color': null,
    },
    {
      'id': 'habits',
      'title': 'Habit Stacking',
      'icon': Icons.layers,
      'color': null,
    },
    {
      'id': 'visualize',
      'title': 'Visualization',
      'icon': Icons.visibility,
      'color': null,
    },
    {
      'id': 'mindset',
      'title': 'Growth Mindset',
      'icon': Icons.psychology,
      'color': null,
    },
    {
      'id': 'focus',
      'title': 'Deep Focus',
      'icon': Icons.center_focus_strong,
      'color': null,
    },
    {
      'id': 'gratitude',
      'title': 'Gratitude',
      'icon': Icons.favorite,
      'color': null,
    },
  ];

  @override
  void initState() {
    super.initState();
    _topicKeys = List.generate(topics.length, (index) => GlobalKey());
    WidgetsBinding.instance.addPostFrameCallback((_) => _snapToInitialTopic());
  }

  void _snapToInitialTopic() {
    if (!_topicScrollController.hasClients) return;
    final index = topics.indexWhere((t) => t['id'] == widget.topicId);
    if (index == -1) return;

    final keyContext = _topicKeys[index].currentContext;
    final listViewBox =
        _selectorKey.currentContext?.findRenderObject() as RenderBox?;
    if (keyContext != null && listViewBox != null) {
      final box = keyContext.findRenderObject() as RenderBox?;
      if (box != null) {
        final screenX = box.localToGlobal(Offset.zero).dx;
        final viewportScreenX = listViewBox.localToGlobal(Offset.zero).dx;

        final targetScreenX = viewportScreenX + 16.0;
        final shift = screenX - targetScreenX;
        final targetOffset = _topicScrollController.offset + shift;

        final maxScroll = _topicScrollController.position.maxScrollExtent;
        final minScroll = _topicScrollController.position.minScrollExtent;
        final clampedOffset = targetOffset.clamp(minScroll, maxScroll);

        _topicScrollController.jumpTo(clampedOffset);
      }
    }
  }

  Widget _buildTopicSelector() {
    return SizedBox(
      key: _selectorKey,
      height: 50,
      child: SingleChildScrollView(
        controller: _topicScrollController,
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.only(
          left: 16,
          right: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Row(
          children: List.generate(topics.length, (index) {
            final topic = topics[index];
            final isSelected = topic['id'] == widget.topicId;
            return Padding(
              key: _topicKeys[index],
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                selected: isSelected,
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      topic['icon'],
                      size: 16,
                      color: isSelected
                          ? Theme.of(context).colorScheme.surface
                          : Theme.of(
                              context,
                            ).colorScheme.onSurface.withAlpha(150),
                    ),
                    const SizedBox(width: 6),
                    Text(topic['title']),
                  ],
                ),
                labelStyle: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? Theme.of(context).colorScheme.surface
                      : Theme.of(context).colorScheme.onSurface.withAlpha(150),
                ),
                selectedColor: Theme.of(context).colorScheme.primary,
                backgroundColor: Theme.of(context).colorScheme.surface,
                side: BorderSide(
                  color: isSelected
                      ? Colors.transparent
                      : Theme.of(context).dividerColor.withAlpha(40),
                ),
                onSelected: (_) {
                  final keyContext = _topicKeys[index].currentContext;
                  final listViewBox =
                      _selectorKey.currentContext?.findRenderObject()
                          as RenderBox?;
                  if (keyContext != null &&
                      listViewBox != null &&
                      _topicScrollController.hasClients) {
                    final box = keyContext.findRenderObject() as RenderBox?;
                    if (box != null) {
                      final screenX = box.localToGlobal(Offset.zero).dx;
                      final viewportScreenX = listViewBox
                          .localToGlobal(Offset.zero)
                          .dx;

                      final targetScreenX = viewportScreenX + 16.0;
                      final shift = screenX - targetScreenX;
                      final targetOffset =
                          _topicScrollController.offset + shift;

                      final maxScroll =
                          _topicScrollController.position.maxScrollExtent;
                      final minScroll =
                          _topicScrollController.position.minScrollExtent;
                      final clampedOffset = targetOffset.clamp(
                        minScroll,
                        maxScroll,
                      );

                      _topicScrollController.animateTo(
                        clampedOffset,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                      _navigateToTopic(topic['id'] as String);
                    }
                  } else {
                    _navigateToTopic(topic['id'] as String);
                  }
                },
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final Map<String, dynamic>? contentInfo = _topicContent[widget.topicId];
    if (contentInfo == null) {
      return Center(
        child: Text(
          'Content not found: ${widget.topicId}',
          style: GoogleFonts.outfit(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      );
    }

    final Color color =
        contentInfo['color'] as Color? ?? Theme.of(context).colorScheme.primary;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withAlpha(76)),
          ),
          child: Text(
            contentInfo['intro'] as String,
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withAlpha(200),
              height: 1.6,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Key Principles',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        ...(contentInfo['principles'] as List).map<Widget>((p) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withAlpha(13),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withAlpha(38)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p['title'],
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  p['desc'],
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withAlpha(180),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withAlpha(13),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withAlpha(51),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('💡', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pro Tip',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      contentInfo['tip'] as String,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withAlpha(180),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  static final Map<String, Map<String, dynamic>> _topicContent = {
    'habits': {
      'color': null, // Use theme primary
      'intro':
          'Habit stacking is linking a new habit to an existing one. The formula: "After I [CURRENT HABIT], I will [NEW HABIT]." This leverages your brain\'s existing neural pathways to build new behaviors effortlessly.',
      'principles': [
        {
          'title': 'Anchor to Existing Habits',
          'desc':
              'Identify habits you already do every day (brushing teeth, morning coffee) and attach new behaviors to them.',
        },
        {
          'title': 'Start Ridiculously Small',
          'desc':
              'Two-Minute Rule: New habits should take less than 2 minutes. "Read before bed" becomes "Read one page before bed."',
        },
        {
          'title': 'Chain Multiple Habits',
          'desc':
              'Stack 3-5 habits together into a morning or evening routine. Each completed habit triggers the next.',
        },
        {
          'title': 'Track Your Streaks',
          'desc':
              'Visual streak tracking creates a "don\'t break the chain" mentality that compounds motivation over time.',
        },
      ],
      'tip':
          'The key to lasting change isn\'t motivation — it\'s making the behavior so easy you can\'t say no. Shrink the habit until it feels effortless, then grow it gradually.',
    },
    'visualize': {
      'color': null,
      'intro':
          'Visualization is the practice of creating a detailed mental image of your desired future. Research shows that the brain activates the same neural networks whether you perform an action or vividly imagine it.',
      'principles': [
        {
          'title': 'Mental Rehearsal',
          'desc':
              'Athletes use visualization to practice performances. You can rehearse presentations, negotiations, or any outcome in vivid detail.',
        },
        {
          'title': 'Vision Boards',
          'desc':
              'Create a visual collage of your goals, values, and aspirations. Place it where you\'ll see it daily to keep your subconscious aligned.',
        },
        {
          'title': 'Process Visualization',
          'desc':
              'Don\'t just visualize the outcome — visualize the work. See yourself doing the hard parts. This builds realistic confidence.',
        },
        {
          'title': 'Emotional Connection',
          'desc':
              'Feel the emotions of achieving your goal: pride, joy, gratitude, relief. Emotion is the fuel that turns vision into action.',
        },
      ],
      'tip':
          'Spend 5 minutes each morning visualizing your ideal day. See the details, feel the emotions, and notice how it shifts your energy and decision-making throughout the day.',
    },
    'mindset': {
      'color': null,
      'intro':
          'Carol Dweck\'s research reveals two mindsets: Fixed ("I am what I am") and Growth ("I can learn and improve"). A Growth Mindset is the foundation of all achievement — the belief that effort, not talent, determines success.',
      'principles': [
        {
          'title': 'Embrace Challenges',
          'desc':
              'Fixed: "This is too hard, I\'ll fail." Growth: "This is a chance to learn something new."',
        },
        {
          'title': 'Learn from Criticism',
          'desc':
              'Fixed: "They\'re judging me." Growth: "What useful feedback can I extract from this?"',
        },
        {
          'title': 'Persist Through Setbacks',
          'desc':
              'Fixed: "I tried and failed." Growth: "This attempt taught me how to do it better next time."',
        },
        {
          'title': 'Celebrate Effort, Not Outcome',
          'desc':
              'Replace "I\'m smart" with "I worked hard." This rewires your brain to value the process over the result.',
        },
      ],
      'tip':
          'When you catch yourself saying "I can\'t do this," add the word "yet" — "I can\'t do this yet." One word transforms a dead end into a pathway.',
    },
    'focus': {
      'color': null,
      'intro':
          'Cal Newport\'s Deep Work principle: the ability to focus without distraction on a cognitively demanding task is becoming increasingly rare — and increasingly valuable. Those who master it will thrive.',
      'principles': [
        {
          'title': 'Time-Boxing',
          'desc':
              'Schedule specific blocks for deep work. Protect them like meetings. 90-minute blocks are ideal for most people.',
        },
        {
          'title': 'Eliminate Triggers',
          'desc':
              'Put your phone in another room. Close email. Use website blockers. Willpower is finite — design your environment instead.',
        },
        {
          'title': 'The Pomodoro Technique',
          'desc':
              '25 minutes of focused work → 5 minute break. After 4 cycles, take a longer 15-30 minute break.',
        },
        {
          'title': 'Single-Tasking',
          'desc':
              'Multitasking is a myth. Your brain switches tasks, losing 20-40% efficiency each switch. Do one thing at a time.',
        },
      ],
      'tip':
          'Your phone is the #1 productivity killer. Research shows that even having your phone visible (face down, silent) reduces cognitive capacity by 10%. Put it in another room during deep work.',
    },
    'gratitude': {
      'color': null,
      'intro':
          'Gratitude practice rewires your brain\'s reticular activating system (RAS) to notice more positive opportunities. What you focus on expands — gratitude shifts your filter from scarcity to abundance.',
      'principles': [
        {
          'title': 'Daily Gratitude Journal',
          'desc':
              'Write 3 specific things you\'re grateful for each morning. Specificity matters: not "family" but "my partner making me coffee today."',
        },
        {
          'title': 'Gratitude Letters',
          'desc':
              'Write a letter to someone who impacted your life. Reading it aloud to them is one of the most powerful happiness interventions known.',
        },
        {
          'title': 'Reframe Challenges',
          'desc':
              '"I have to..." becomes "I get to..." This simple language shift transforms obligations into privileges.',
        },
        {
          'title': 'Mental Subtraction',
          'desc':
              'Imagine your life without key people, health, or opportunities. This contrast makes present blessings vivid and real.',
        },
      ],
      'tip':
          'The happiest people aren\'t grateful because they have more — they have more because they\'re grateful. Gratitude opens you to see opportunities that scarcity-thinking blinds you to.',
    },
  };
}
