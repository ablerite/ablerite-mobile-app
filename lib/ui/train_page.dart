import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'widgets/focus_app_bar_actions.dart';
import 'widgets/tablet_layout.dart';
import 'dart:math';
import 'dart:async';
import 'package:confetti/confetti.dart';
import '../services/memory_match_service.dart';

// ─── Campaign Data ───────────────────────────────────────────────────────

class CampaignLevel {
  final int level;
  final String title;
  final int cols;
  final int rows;
  final int timeLimit; // 0 = no limit
  final String achievementTitle;
  final String achievementIcon;
  final String knowledgeTitle;
  final String knowledgeBody;
  final String knowledgeCategory;

  const CampaignLevel({
    required this.level,
    required this.title,
    required this.cols,
    required this.rows,
    required this.timeLimit,
    required this.achievementTitle,
    required this.achievementIcon,
    required this.knowledgeTitle,
    required this.knowledgeBody,
    required this.knowledgeCategory,
  });
}

const List<CampaignLevel> campaignLevels = [
  CampaignLevel(
    level: 1,
    title: 'First Steps',
    cols: 2,
    rows: 3,
    timeLimit: 0,
    achievementTitle: 'Beginner Mind',
    achievementIcon: '🌱',
    knowledgeTitle: 'The Power of Neuroplasticity',
    knowledgeCategory: 'Mind',
    knowledgeBody:
        'Your brain can rewire itself at any age. Every time you learn something new, neural connections strengthen. This is neuroplasticity — the foundation of all personal growth. By training your memory, you\'re literally building a better brain.',
  ),
  CampaignLevel(
    level: 2,
    title: 'Warming Up',
    cols: 3,
    rows: 4,
    timeLimit: 0,
    achievementTitle: 'Pattern Seeker',
    achievementIcon: '🔍',
    knowledgeTitle: 'Growth Mindset',
    knowledgeCategory: 'Mind',
    knowledgeBody:
        'Dr. Carol Dweck\'s research shows that believing your abilities can develop (growth mindset) leads to greater achievement. Challenges aren\'t threats — they\'re opportunities to grow. Each level you conquer reinforces this powerful belief.',
  ),
  CampaignLevel(
    level: 3,
    title: 'Building Focus',
    cols: 4,
    rows: 4,
    timeLimit: 0,
    achievementTitle: 'Focused Mind',
    achievementIcon: '🎯',
    knowledgeTitle: 'The 10,000 Hour Rule',
    knowledgeCategory: 'Life',
    knowledgeBody:
        'Malcolm Gladwell popularised the idea that mastery takes roughly 10,000 hours of deliberate practice. But the key word is "deliberate" — mindful, focused effort. This game trains exactly that: sustained, purposeful concentration.',
  ),
  CampaignLevel(
    level: 4,
    title: 'Rising Challenge',
    cols: 4,
    rows: 5,
    timeLimit: 0,
    achievementTitle: 'Memory Master',
    achievementIcon: '🧠',
    knowledgeTitle: 'Compound Interest of Health',
    knowledgeCategory: 'Health',
    knowledgeBody:
        'Just as money compounds over time, small daily health habits compound into extraordinary results. 30 minutes of brain training, exercise, or meditation each day creates exponential cognitive gains over months and years.',
  ),
  CampaignLevel(
    level: 5,
    title: 'Speed Test',
    cols: 4,
    rows: 5,
    timeLimit: 180,
    achievementTitle: 'Speed Runner',
    achievementIcon: '⚡',
    knowledgeTitle: 'The Wealth Mindset',
    knowledgeCategory: 'Wealth',
    knowledgeBody:
        'Wealth isn\'t just about money — it\'s about resourcefulness. Studies show that people who regularly challenge their cognitive abilities make better financial decisions because they develop superior pattern recognition and risk assessment skills.',
  ),
  CampaignLevel(
    level: 6,
    title: 'Deep Memory',
    cols: 4,
    rows: 6,
    timeLimit: 0,
    achievementTitle: 'Deep Thinker',
    achievementIcon: '💎',
    knowledgeTitle: 'The Science of Love',
    knowledgeCategory: 'Love',
    knowledgeBody:
        'Oxytocin, the "love hormone", strengthens when we connect deeply with others. Research shows that people with strong memory and focus build deeper relationships because they remember details that matter — showing others they truly care.',
  ),
  CampaignLevel(
    level: 7,
    title: 'Pressure Cooker',
    cols: 4,
    rows: 6,
    timeLimit: 150,
    achievementTitle: 'Pressure Player',
    achievementIcon: '🔥',
    knowledgeTitle: 'Stress as a Superpower',
    knowledgeCategory: 'Health',
    knowledgeBody:
        'Dr. Kelly McGonigal\'s research reveals that stress isn\'t inherently harmful — it\'s your belief about stress that matters. When you embrace pressure as performance fuel rather than a threat, your body rises to the challenge. This game trains exactly that.',
  ),
  CampaignLevel(
    level: 8,
    title: 'Expert Grid',
    cols: 4,
    rows: 7,
    timeLimit: 0,
    achievementTitle: 'Brain Athlete',
    achievementIcon: '🏋️',
    knowledgeTitle: 'The Flow State',
    knowledgeCategory: 'Life',
    knowledgeBody:
        'Mihaly Csikszentmihalyi discovered that peak human performance occurs in "flow" — a state of effortless concentration where time seems to stop. Memory games are one of the best ways to practice entering flow, a skill that transfers to every area of life.',
  ),
  CampaignLevel(
    level: 9,
    title: 'Speed Expert',
    cols: 4,
    rows: 7,
    timeLimit: 120,
    achievementTitle: 'Lightning Mind',
    achievementIcon: '⭐',
    knowledgeTitle: 'Abundance Thinking',
    knowledgeCategory: 'Wealth',
    knowledgeBody:
        'Stephen Covey taught that an abundance mindset — the belief there\'s enough success for everyone — is essential for true wealth. Training your brain to find patterns quickly builds the optimistic neural pathways that support abundance thinking in all areas.',
  ),
  CampaignLevel(
    level: 10,
    title: 'The Gauntlet',
    cols: 4,
    rows: 7,
    timeLimit: 90,
    achievementTitle: 'Grandmaster',
    achievementIcon: '🏆',
    knowledgeTitle: 'The Mastery of Self',
    knowledgeCategory: 'Love',
    knowledgeBody:
        'The greatest achievement isn\'t conquering the world — it\'s conquering yourself. By completing this journey, you\'ve proven that consistent effort, focus, and resilience can overcome any challenge. Carry this confidence into every relationship and endeavour.',
  ),
  CampaignLevel(
    level: 11,
    title: 'Ultra Gauntlet',
    cols: 4,
    rows: 7,
    timeLimit: 75,
    achievementTitle: 'Elite Mind',
    achievementIcon: '💫',
    knowledgeTitle: 'The Power of Visualisation',
    knowledgeCategory: 'Life',
    knowledgeBody:
        'Elite athletes and top performers use mental rehearsal to prime their brains for success. Neuroscience shows that vividly imagining an outcome activates the same neural circuits as physically performing it. Your trained memory makes you a natural visualiser.',
  ),
  CampaignLevel(
    level: 12,
    title: 'The Impossible',
    cols: 4,
    rows: 7,
    timeLimit: 60,
    achievementTitle: 'Legend',
    achievementIcon: '👑',
    knowledgeTitle: 'The Ripple Effect',
    knowledgeCategory: 'Love',
    knowledgeBody:
        'Every skill you master creates a ripple outward. Your improved focus enhances your work, your resilience strengthens relationships, and your discipline inspires others. You are proof that the mind, once stretched, never returns to its original dimensions.',
  ),
];

class _MemoryMatchPalette {
  final bool isDark;
  final Color accent;
  final Color accentDark;
  final Color accentSoft;
  final Color surface;
  final Color card;
  final Color cardAlt;
  final Color border;
  final Color text;
  final Color mutedText;

  const _MemoryMatchPalette({
    required this.isDark,
    required this.accent,
    required this.accentDark,
    required this.accentSoft,
    required this.surface,
    required this.card,
    required this.cardAlt,
    required this.border,
    required this.text,
    required this.mutedText,
  });

  factory _MemoryMatchPalette.of(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    final accent = scheme.primary;
    return _MemoryMatchPalette(
      isDark: isDark,
      accent: accent,
      accentDark: isDark ? scheme.secondary : scheme.primary,
      accentSoft: accent.withAlpha(isDark ? 42 : 24),
      surface: Theme.of(context).scaffoldBackgroundColor,
      card: scheme.surface,
      cardAlt: scheme.surfaceContainerHighest.withAlpha(isDark ? 220 : 145),
      border: scheme.outline.withAlpha(isDark ? 95 : 55),
      text: scheme.onSurface,
      mutedText: scheme.onSurface.withAlpha(isDark ? 178 : 155),
    );
  }

  LinearGradient get actionGradient {
    return LinearGradient(
      colors: [accentDark, accent],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
}

// ─── Train Page (Pelmanism Intro) ────────────────────────────────────────

class TrainPage extends StatelessWidget {
  const TrainPage({super.key});

  void _showBenefitDialog(
    BuildContext context,
    String title,
    String desc,
    IconData icon,
    Color color,
  ) {
    final isTablet = isTabletLayout(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        constraints: isTablet
            ? tabletDialogConstraints(
                context,
                portraitWidth: 560,
                landscapeWidth: 640,
                heightFactor: 0.72,
              )
            : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          desc,
          style: GoogleFonts.outfit(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurface.withAlpha(200),
            height: 1.6,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Got it',
              style: GoogleFonts.outfit(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final memoryTheme = _MemoryMatchPalette.of(context);
    return Scaffold(
      backgroundColor: memoryTheme.surface,
      appBar: AppBar(
        backgroundColor: memoryTheme.surface,
        elevation: 0,
        title: FocusAwareAppBarTitle(
          child: Text(
            'Train Your Brain',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        leading: const FocusAwareBackButton(),
        actions: [
          const FocusAppBarActions(guide: FocusHelpGuide.selfDevelopment),
          IconButton(
            icon: const Icon(
              Icons.military_tech,
              color: Color(0xFF10B981),
              size: 26,
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AchievementsPage()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isTablet = isTabletLayout(context);
            final landscape = isTabletLandscape(context);
            final content = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 10, left: 8),
                  child: Text(
                    'Sharpen your focus & concentration',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withAlpha(150),
                    ),
                  ),
                ),
                Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: memoryTheme.accent.withValues(alpha: 0.18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: memoryTheme.accent.withValues(alpha: 0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isTablet)
                        SizedBox(
                          width: double.infinity,
                          height: landscape ? 320 : 360,
                          child: ColoredBox(
                            color: memoryTheme.accentSoft,
                            child: Image.asset(
                              'assets/images/app_banners/braintraining.png',
                              width: double.infinity,
                              fit: BoxFit.cover,
                              alignment: Alignment.center,
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Icon(
                                    Icons.psychology,
                                    color: memoryTheme.accent,
                                    size: 58,
                                  ),
                                );
                              },
                            ),
                          ),
                        )
                      else
                        AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Image.asset(
                            'assets/images/app_banners/braintraining.png',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: memoryTheme.accentSoft,
                                child: Center(
                                  child: Icon(
                                    Icons.psychology,
                                    color: memoryTheme.accent,
                                    size: 44,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(9),
                                  decoration: BoxDecoration(
                                    color: memoryTheme.accentSoft,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.psychology,
                                    color: memoryTheme.accent,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Pelmanism',
                                    style: GoogleFonts.outfit(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'A scientifically-backed memory training technique that strengthens neural pathways for concentration, working memory, and focus.\n\nRegular practice helps you hold attention longer, recognise patterns faster, and build the calm persistence needed for better decisions.',
                              style: GoogleFonts.outfit(
                                fontSize: 12.8,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withAlpha(185),
                                height: 1.28,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Core Benefits',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                if (isTablet) const SizedBox(height: 8),
                if (isTablet)
                  Row(
                    children: [
                      for (final benefit in const [
                        (
                          Icons.center_focus_strong,
                          'Sharper Focus',
                          'Memory games force sustained attention, training your brain to concentrate for longer periods.',
                        ),
                        (
                          Icons.trending_up,
                          'Better Decisions',
                          'Pattern recognition improves your ability to spot opportunities and make faster decisions.',
                        ),
                        (
                          Icons.bolt,
                          'Faster Recall',
                          'Regular practice strengthens working memory, helping you learn new skills more quickly.',
                        ),
                        (
                          Icons.self_improvement,
                          'Resilience',
                          'Challenging your brain builds cognitive reserve — your mental armour against stress.',
                        ),
                      ].indexed) ...[
                        if (benefit.$1 > 0) const SizedBox(width: 12),
                        Expanded(
                          child: _buildBenefitIcon(
                            context,
                            benefit.$2.$1,
                            benefit.$2.$2,
                            memoryTheme.accent,
                            benefit.$2.$3,
                            tablet: true,
                          ),
                        ),
                      ],
                    ],
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildBenefitIcon(
                        context,
                        Icons.center_focus_strong,
                        'Sharper Focus',
                        memoryTheme.accent,
                        'Memory games force sustained attention, training your brain to concentrate for longer periods.',
                      ),
                      _buildBenefitIcon(
                        context,
                        Icons.trending_up,
                        'Better Decision Making',
                        memoryTheme.accent,
                        'Pattern recognition improves your ability to spot opportunities and make faster decisions.',
                      ),
                      _buildBenefitIcon(
                        context,
                        Icons.bolt,
                        'Faster Recall',
                        memoryTheme.accent,
                        'Regular practice strengthens working memory, helping you learn new skills more quickly.',
                      ),
                      _buildBenefitIcon(
                        context,
                        Icons.self_improvement,
                        'Mental Resilience',
                        memoryTheme.accent,
                        'Challenging your brain builds cognitive reserve — your mental armour against stress.',
                      ),
                    ],
                  ),
                if (isTablet)
                  const SizedBox(height: 28)
                else
                  const Spacer(flex: 2),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      fullscreenDialog: true,
                      builder: (_) => const GameModeScreen(),
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      gradient: memoryTheme.actionGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: memoryTheme.accent.withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Play Memory Match',
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
                const SizedBox(height: 8),
              ],
            );
            return Align(
              alignment: isTablet ? Alignment.topCenter : Alignment.center,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isTablet ? 960 : double.infinity,
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: isTablet ? 28 : 16),
                  child: isTablet
                      ? SingleChildScrollView(child: content)
                      : content,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBenefitIcon(
    BuildContext context,
    IconData icon,
    String title,
    Color color,
    String desc, {
    bool tablet = false,
  }) {
    final memoryTheme = _MemoryMatchPalette.of(context);
    return GestureDetector(
      onTap: () => _showBenefitDialog(context, title, desc, icon, color),
      child: Container(
        width: tablet ? double.infinity : 64,
        height: tablet ? 96 : 54,
        padding: EdgeInsets.symmetric(horizontal: tablet ? 12 : 0),
        decoration: BoxDecoration(
          color: memoryTheme.cardAlt,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.22)),
        ),
        child: tablet
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: color, size: 32),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      color: memoryTheme.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      height: 1.05,
                    ),
                  ),
                ],
              )
            : Center(child: Icon(icon, color: color, size: 24)),
      ),
    );
  }
}

// ─── Game Mode Selection Screen (4 buttons) ──────────────────────────────

class GameModeScreen extends StatelessWidget {
  const GameModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final memoryTheme = _MemoryMatchPalette.of(context);
    final isTablet = isTabletLayout(context);
    final horizontalPadding = isTablet
        ? ((MediaQuery.sizeOf(context).width - 760) / 2)
              .clamp(24.0, 320.0)
              .toDouble()
        : 16.0;
    return Scaffold(
      backgroundColor: memoryTheme.surface,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        color: Theme.of(context).colorScheme.onSurface,
                        size: 26,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Spacer(),
                    Text(
                      'Select Mode',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 48), // balance
                  ],
                ),
              ),
              const Spacer(),
              _buildModeButton(
                context,
                '🗺️',
                'Campaign',
                'Progressive levels with rewards',
                memoryTheme.accent,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CampaignScreen()),
                ),
              ),
              const SizedBox(height: 12),
              _buildModeButton(
                context,
                '🧠',
                'Standard',
                'Play at your own pace',
                memoryTheme.accent,
                () => _showStandardSheet(context),
              ),
              const SizedBox(height: 12),
              _buildModeButton(
                context,
                '⚡',
                'Speed',
                'Beat the clock',
                memoryTheme.accent,
                () => _showSpeedSheet(context),
              ),
              const SizedBox(height: 12),
              _buildModeButton(
                context,
                '💫',
                'Achievements',
                'View unlocked rewards',
                memoryTheme.accent,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AchievementsPage()),
                ),
              ),
              const SizedBox(height: 12),
              _buildModeButton(
                context,
                '🏆',
                'High Scores',
                'View your best records',
                memoryTheme.accent,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HighScoresPage()),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeButton(
    BuildContext context,
    String emoji,
    String title,
    String subtitle,
    Color color,
    VoidCallback onTap,
  ) {
    final memoryTheme = _MemoryMatchPalette.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          color: memoryTheme.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(
                  alpha: memoryTheme.isDark ? 0.16 : 0.12,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(emoji, style: const TextStyle(fontSize: 28)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: memoryTheme.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: memoryTheme.mutedText,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: color, size: 18),
          ],
        ),
      ),
    );
  }

  void _startGame(
    BuildContext context, {
    required String mode,
    required String difficulty,
    required int cols,
    required int rows,
    required int timeLimit,
  }) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MemoryMatchGame(
          cols: cols,
          rows: rows,
          timeLimit: timeLimit,
          mode: mode,
          difficulty: difficulty,
        ),
      ),
    );
  }

  void _showStandardSheet(BuildContext context) {
    final memoryTheme = _MemoryMatchPalette.of(context);
    final isTablet = isTabletLayout(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      constraints: isTablet
          ? tabletDialogConstraints(
              context,
              portraitWidth: 620,
              landscapeWidth: 720,
              heightFactor: 0.82,
            )
          : null,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[700],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Standard Mode',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: memoryTheme.text,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Complete at your own pace',
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: memoryTheme.mutedText,
              ),
            ),
            const SizedBox(height: 20),
            _buildOption(
              ctx,
              'Easy',
              '3 × 4 grid  •  6 pairs',
              memoryTheme.accent,
              Icons.sentiment_satisfied,
              () => _startGame(
                ctx,
                mode: 'standard',
                difficulty: 'easy',
                cols: 3,
                rows: 4,
                timeLimit: 0,
              ),
            ),
            const SizedBox(height: 10),
            _buildOption(
              ctx,
              'Medium',
              '4 × 5 grid  •  10 pairs',
              memoryTheme.accent,
              Icons.sentiment_neutral,
              () => _startGame(
                ctx,
                mode: 'standard',
                difficulty: 'medium',
                cols: 4,
                rows: 5,
                timeLimit: 0,
              ),
            ),
            const SizedBox(height: 10),
            _buildOption(
              ctx,
              'Expert',
              '4 × 7 grid  •  14 pairs',
              memoryTheme.accent,
              Icons.local_fire_department,
              () => _startGame(
                ctx,
                mode: 'standard',
                difficulty: 'expert',
                cols: 4,
                rows: 7,
                timeLimit: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSpeedSheet(BuildContext context) {
    final memoryTheme = _MemoryMatchPalette.of(context);
    final isTablet = isTabletLayout(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      isScrollControlled: true,
      constraints: isTablet
          ? tabletDialogConstraints(
              context,
              portraitWidth: 620,
              landscapeWidth: 720,
              heightFactor: 0.86,
            )
          : null,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Speed Mode',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: memoryTheme.text,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Beat the clock on a 4×7 grid',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: memoryTheme.mutedText,
                ),
              ),
              const SizedBox(height: 20),
              _buildOption(
                ctx,
                'Easy',
                '5 minutes',
                memoryTheme.accent,
                Icons.timer,
                () => _startGame(
                  ctx,
                  mode: 'speed',
                  difficulty: 'easy',
                  cols: 4,
                  rows: 7,
                  timeLimit: 300,
                ),
              ),
              const SizedBox(height: 10),
              _buildOption(
                ctx,
                'Medium',
                '3 minutes',
                memoryTheme.accent,
                Icons.timer,
                () => _startGame(
                  ctx,
                  mode: 'speed',
                  difficulty: 'medium',
                  cols: 4,
                  rows: 7,
                  timeLimit: 180,
                ),
              ),
              const SizedBox(height: 10),
              _buildOption(
                ctx,
                'Hard',
                '2 minutes',
                memoryTheme.accent.withValues(alpha: 0.85),
                Icons.timer,
                () => _startGame(
                  ctx,
                  mode: 'speed',
                  difficulty: 'hard',
                  cols: 4,
                  rows: 7,
                  timeLimit: 120,
                ),
              ),
              const SizedBox(height: 10),
              _buildOption(
                ctx,
                'Ultra Hard',
                '1 minute',
                memoryTheme.accent.withValues(alpha: 0.7),
                Icons.whatshot,
                () => _startGame(
                  ctx,
                  mode: 'speed',
                  difficulty: 'ultra',
                  cols: 4,
                  rows: 7,
                  timeLimit: 60,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOption(
    BuildContext context,
    String title,
    String subtitle,
    Color color,
    IconData icon,
    VoidCallback onTap,
  ) {
    final memoryTheme = _MemoryMatchPalette.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: memoryTheme.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.16)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: memoryTheme.isDark ? 0.16 : 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: memoryTheme.text,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: memoryTheme.mutedText,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.play_arrow_rounded, color: color, size: 24),
          ],
        ),
      ),
    );
  }
}

// ─── Campaign Screen ─────────────────────────────────────────────────────

class CampaignScreen extends StatefulWidget {
  const CampaignScreen({super.key});
  @override
  State<CampaignScreen> createState() => _CampaignScreenState();
}

class _CampaignScreenState extends State<CampaignScreen> {
  int _unlockedLevel = 1;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final unlockedLevel = await MemoryMatchService.loadCampaignUnlockedLevel();
    if (mounted) setState(() => _unlockedLevel = unlockedLevel);
  }

  Color _categoryColor(String cat) {
    switch (cat) {
      case 'Mind':
        return const Color(0xFF7F9BB8);
      case 'Life':
        return const Color(0xFF77ADA4);
      case 'Health':
        return const Color(0xFF10B981);
      case 'Wealth':
        return const Color(0xFFB59A6A);
      case 'Love':
        return const Color(0xFFB98AA0);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final memoryTheme = _MemoryMatchPalette.of(context);
    return Scaffold(
      backgroundColor: memoryTheme.surface,
      appBar: AppBar(
        backgroundColor: memoryTheme.surface,
        elevation: 0,
        title: Text(
          'Campaign',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '${(_unlockedLevel - 1).clamp(0, 12)} / 12',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: memoryTheme.accent,
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: campaignLevels.length,
        itemBuilder: (context, index) {
          final lvl = campaignLevels[index];
          final isUnlocked = lvl.level <= _unlockedLevel;
          final isComplete = lvl.level < _unlockedLevel;
          final catColor = _categoryColor(lvl.knowledgeCategory);

          return GestureDetector(
            onTap: isUnlocked
                ? () async {
                    final result = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MemoryMatchGame(
                          cols: lvl.cols,
                          rows: lvl.rows,
                          timeLimit: lvl.timeLimit,
                          mode: 'campaign',
                          difficulty: 'level_${lvl.level}',
                          campaignLevel: lvl,
                        ),
                      ),
                    );
                    if (result == true) {
                      await _loadProgress();
                    }
                  }
                : null,
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: isComplete
                    ? memoryTheme.accentSoft
                    : isUnlocked
                    ? memoryTheme.card
                    : memoryTheme.cardAlt.withAlpha(
                        memoryTheme.isDark ? 120 : 95,
                      ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isComplete
                      ? memoryTheme.accent.withAlpha(85)
                      : isUnlocked
                      ? memoryTheme.accent.withAlpha(45)
                      : memoryTheme.border,
                ),
                boxShadow: isUnlocked
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isComplete
                          ? memoryTheme.accent.withAlpha(34)
                          : isUnlocked
                          ? memoryTheme.accentSoft
                          : memoryTheme.border.withValues(alpha: 0.35),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: isComplete
                          ? Icon(
                              Icons.check_circle,
                              color: memoryTheme.accent,
                              size: 24,
                            )
                          : Text(
                              '${lvl.level}',
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isUnlocked
                                    ? memoryTheme.accent
                                    : memoryTheme.mutedText.withAlpha(130),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lvl.title,
                          style: GoogleFonts.outfit(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: isUnlocked
                                ? memoryTheme.text
                                : memoryTheme.mutedText.withAlpha(135),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${lvl.cols}×${lvl.rows}${lvl.timeLimit > 0 ? '  •  ${lvl.timeLimit ~/ 60}m limit' : ''}',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            color: isUnlocked
                                ? memoryTheme.mutedText
                                : memoryTheme.mutedText.withAlpha(130),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isComplete)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: catColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        lvl.knowledgeCategory,
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: catColor,
                        ),
                      ),
                    ),
                  if (!isComplete && isUnlocked)
                    Icon(
                      Icons.play_circle_filled,
                      color: memoryTheme.accent,
                      size: 32,
                    ),
                  if (!isUnlocked)
                    Icon(
                      Icons.lock_person_rounded,
                      color: Colors.grey[350],
                      size: 20,
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Achievements Page ───────────────────────────────────────────────

class AchievementsPage extends StatefulWidget {
  const AchievementsPage({super.key});
  @override
  State<AchievementsPage> createState() => _AchievementsPageState();
}

class _AchievementsPageState extends State<AchievementsPage> {
  int _unlockedLevel = 1;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final unlockedLevel = await MemoryMatchService.loadCampaignUnlockedLevel();
    if (mounted) setState(() => _unlockedLevel = unlockedLevel);
  }

  Color _categoryColor(String cat) {
    switch (cat) {
      case 'Mind':
        return const Color(0xFF7F9BB8);
      case 'Life':
        return const Color(0xFF77ADA4);
      case 'Health':
        return const Color(0xFF10B981);
      case 'Wealth':
        return const Color(0xFFB59A6A);
      case 'Love':
        return const Color(0xFFB98AA0);
      default:
        return Colors.grey;
    }
  }

  IconData _categoryIcon(String cat) {
    switch (cat) {
      case 'Mind':
        return Icons.psychology;
      case 'Life':
        return Icons.auto_awesome;
      case 'Health':
        return Icons.favorite;
      case 'Wealth':
        return Icons.diamond;
      case 'Love':
        return Icons.volunteer_activism;
      default:
        return Icons.lightbulb;
    }
  }

  @override
  Widget build(BuildContext context) {
    final memoryTheme = _MemoryMatchPalette.of(context);
    return Scaffold(
      backgroundColor: memoryTheme.surface,
      appBar: AppBar(
        backgroundColor: memoryTheme.surface,
        elevation: 0,
        title: Text(
          'Achievements',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '${(_unlockedLevel - 1).clamp(0, campaignLevels.length)} / ${campaignLevels.length}',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: memoryTheme.accent,
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: campaignLevels.length,
        itemBuilder: (context, index) {
          final lvl = campaignLevels[index];
          final isUnlocked = lvl.level < _unlockedLevel;
          final catColor = _categoryColor(lvl.knowledgeCategory);

          return GestureDetector(
            onTap: isUnlocked
                ? () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => _KnowledgeCardPage(
                        level: lvl,
                        color: catColor,
                        icon: _categoryIcon(lvl.knowledgeCategory),
                      ),
                    ),
                  )
                : null,
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isUnlocked
                    ? memoryTheme.accentSoft
                    : memoryTheme.cardAlt.withAlpha(
                        memoryTheme.isDark ? 120 : 90,
                      ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isUnlocked
                      ? memoryTheme.accent.withValues(alpha: 0.24)
                      : memoryTheme.border,
                ),
                boxShadow: isUnlocked
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUnlocked
                          ? memoryTheme.accent.withValues(alpha: 0.14)
                          : memoryTheme.border.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      isUnlocked ? lvl.achievementIcon : '🔒',
                      style: TextStyle(fontSize: isUnlocked ? 32 : 24),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isUnlocked
                              ? lvl.achievementTitle
                              : 'Locked Achievement',
                          style: GoogleFonts.outfit(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: isUnlocked
                                ? memoryTheme.text
                                : memoryTheme.mutedText.withAlpha(120),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isUnlocked
                              ? lvl.knowledgeTitle
                              : 'Keep training to unlock rewards',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: isUnlocked
                                ? catColor
                                : memoryTheme.mutedText.withAlpha(120),
                          ),
                        ),
                        if (isUnlocked) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: catColor.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              lvl.knowledgeCategory,
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: catColor,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (isUnlocked)
                    Icon(
                      Icons.arrow_forward_ios,
                      color: memoryTheme.accent,
                      size: 16,
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Full-Page Knowledge Card ─────────────────────────────────────────

class _KnowledgeCardPage extends StatelessWidget {
  final CampaignLevel level;
  final Color color;
  final IconData icon;

  const _KnowledgeCardPage({
    required this.level,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final memoryTheme = _MemoryMatchPalette.of(context);
    return Scaffold(
      backgroundColor: memoryTheme.surface,
      appBar: AppBar(
        backgroundColor: memoryTheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: memoryTheme.text),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Achievement badge
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: memoryTheme.card,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Text(
                        level.achievementIcon,
                        style: const TextStyle(fontSize: 56),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      level.achievementTitle,
                      style: GoogleFonts.outfit(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: memoryTheme.text,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Level ${level.level}: ${level.title}',
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        color: memoryTheme.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Category badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: color, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      level.knowledgeCategory,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Knowledge title
              Text(
                level.knowledgeTitle,
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: memoryTheme.text,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 20),

              // Divider
              Container(height: 1, color: memoryTheme.border),
              const SizedBox(height: 20),

              // Knowledge body
              Text(
                level.knowledgeBody,
                style: GoogleFonts.outfit(
                  fontSize: 17,
                  color: memoryTheme.mutedText,
                  height: 1.7,
                ),
              ),
              const SizedBox(height: 32),

              // Insight footer
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: memoryTheme.cardAlt,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withValues(alpha: 0.18)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.tips_and_updates_rounded,
                      color: color,
                      size: 24,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'Apply this insight daily to build lasting positive change.',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: memoryTheme.text,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Full-Screen Memory Match Game ───────────────────────────────────────

class MemoryMatchGame extends StatefulWidget {
  final int cols;
  final int rows;
  final int timeLimit;
  final String mode;
  final String difficulty;
  final CampaignLevel? campaignLevel;

  const MemoryMatchGame({
    super.key,
    required this.cols,
    required this.rows,
    required this.timeLimit,
    required this.mode,
    required this.difficulty,
    this.campaignLevel,
  });

  @override
  State<MemoryMatchGame> createState() => _MemoryMatchGameState();
}

class _MemoryMatchGameState extends State<MemoryMatchGame> {
  static const List<String> _allEmojis = [
    '🎯',
    '🧠',
    '⚡',
    '🔥',
    '💎',
    '🌟',
    '🚀',
    '🏆',
    '🎨',
    '🎵',
    '🌈',
    '🦋',
    '🍀',
    '🔮',
    '🎪',
    '🌺',
  ];

  late int _gridSize;
  late int _pairsCount;
  late List<String> _cards;
  late List<bool> _revealed;
  late List<bool> _matched;
  int? _firstIndex;
  int? _secondIndex;
  bool _isChecking = false;
  int _moves = 0;
  int _matchesFound = 0;
  late Stopwatch _stopwatch;
  Timer? _timer;
  int _remainingSeconds = 0;
  bool _gameOver = false;
  bool _won = false;

  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
    _gridSize = widget.cols * widget.rows;
    _pairsCount = _gridSize ~/ 2;
    _startNewGame();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startNewGame() {
    _timer?.cancel();
    final rng = Random();
    final selected = List<String>.from(_allEmojis)..shuffle(rng);
    final chosen = selected.take(_pairsCount).toList();
    _cards = _buildSeparatedLayout(chosen, rng);
    _revealed = List.filled(_gridSize, false);
    _matched = List.filled(_gridSize, false);
    _firstIndex = null;
    _secondIndex = null;
    _isChecking = false;
    _moves = 0;
    _matchesFound = 0;
    _gameOver = false;
    _won = false;
    _stopwatch = Stopwatch()..start();

    if (widget.timeLimit > 0) {
      _remainingSeconds = widget.timeLimit;
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) {
          t.cancel();
          return;
        }
        setState(() {
          _remainingSeconds--;
          if (_remainingSeconds <= 0) {
            _remainingSeconds = 0;
            _gameOver = true;
            _won = false;
            _stopwatch.stop();
            t.cancel();
          }
        });
      });
    }
    setState(() {});
  }

  List<String> _buildSeparatedLayout(List<String> chosen, Random rng) {
    final deck = [...chosen, ...chosen];
    var bestLayout = List<String>.from(deck)..shuffle(rng);
    var bestScore = _layoutClosenessScore(bestLayout);
    final attempts = max(2000, _gridSize * 300);

    for (var attempt = 0; attempt < attempts; attempt++) {
      final candidate = List<String>.from(deck)..shuffle(rng);
      final score = _layoutClosenessScore(candidate);
      if (score < bestScore) {
        bestLayout = candidate;
        bestScore = score;
        if (bestScore == 0) break;
      }
    }

    return bestLayout;
  }

  int _layoutClosenessScore(List<String> layout) {
    final firstSeen = <String, int>{};
    var score = 0;

    for (var index = 0; index < layout.length; index++) {
      final symbol = layout[index];
      final firstIndex = firstSeen[symbol];
      if (firstIndex == null) {
        firstSeen[symbol] = index;
        continue;
      }

      final firstRow = firstIndex ~/ widget.cols;
      final firstCol = firstIndex % widget.cols;
      final secondRow = index ~/ widget.cols;
      final secondCol = index % widget.cols;
      final rowGap = (firstRow - secondRow).abs();
      final colGap = (firstCol - secondCol).abs();
      final manhattan = rowGap + colGap;

      if (manhattan == 1) {
        score += 300;
      } else if (rowGap <= 1 && colGap <= 1) {
        score += 140;
      } else if (manhattan == 2) {
        score += 60;
      } else if (rowGap <= 2 && colGap <= 2) {
        score += 16;
      }

      if (rowGap == 0) {
        score += 1000;
      } else if (rowGap == 1) {
        score += 40;
      }

      if (colGap == 0) {
        score += 160;
      } else if (colGap == 1) {
        score += 18;
      }
    }

    return score;
  }

  void _onCardTap(int index) {
    if (_isChecking || _gameOver) return;
    if (_revealed[index] || _matched[index]) return;
    setState(() => _revealed[index] = true);

    if (_firstIndex == null) {
      _firstIndex = index;
    } else {
      _secondIndex = index;
      _moves++;
      _isChecking = true;
      Future.delayed(const Duration(milliseconds: 600), () {
        if (!mounted) return;
        setState(() {
          if (_cards[_firstIndex!] == _cards[_secondIndex!]) {
            _matched[_firstIndex!] = true;
            _matched[_secondIndex!] = true;
            _matchesFound++;
            if (_matchesFound == _pairsCount) {
              _stopwatch.stop();
              _timer?.cancel();
              _gameOver = true;
              _won = true;
              _saveHighScore();
              if (widget.mode == 'campaign') _completeCampaignLevel();
            }
          } else {
            _revealed[_firstIndex!] = false;
            _revealed[_secondIndex!] = false;
          }
          _firstIndex = null;
          _secondIndex = null;
          _isChecking = false;
        });
      });
    }
  }

  Future<void> _completeCampaignLevel() async {
    if (widget.campaignLevel == null) return;
    final current = await MemoryMatchService.loadCampaignUnlockedLevel();
    final nextLevel = widget.campaignLevel!.level + 1;
    if (nextLevel > current) {
      await MemoryMatchService.saveCampaignUnlockedLevel(nextLevel);
    }
    // Show reward after short delay
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      _showCampaignReward();
    });
  }

  void _showCampaignReward() {
    final lvl = widget.campaignLevel!;
    final gameNavigator = Navigator.of(context);
    final memoryTheme = _MemoryMatchPalette.of(context);

    // Fire confetti!
    _confettiController.play();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Stack(
        children: [
          AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(lvl.achievementIcon, style: const TextStyle(fontSize: 48)),
                const SizedBox(height: 12),
                Text(
                  'Achievement Unlocked!',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: memoryTheme.accent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  lvl.achievementTitle,
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: memoryTheme.cardAlt,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: memoryTheme.accent.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.lightbulb,
                            color: memoryTheme.accent,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Knowledge Card',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: memoryTheme.accent,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        lvl.knowledgeTitle,
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        lvl.knowledgeBody,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.8),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(); // close dialog
                  gameNavigator.pop(true); // pop game screen back to campaign
                },
                child: Text(
                  'Continue',
                  style: GoogleFonts.outfit(
                    color: memoryTheme.accent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              emissionFrequency: 0.05,
              numberOfParticles: 50,
              maxBlastForce: 100,
              minBlastForce: 80,
              gravity: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveHighScore() async {
    await MemoryMatchService.saveHighScore(
      mode: widget.mode,
      difficulty: widget.difficulty,
      moves: _moves,
      time: _stopwatch.elapsed.inSeconds,
      date: DateTime.now(),
    );
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String get _elapsedFormatted => _formatTime(_stopwatch.elapsed.inSeconds);

  @override
  Widget build(BuildContext context) {
    final memoryTheme = _MemoryMatchPalette.of(context);
    return Scaffold(
      backgroundColor: memoryTheme.surface,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          color: Theme.of(context).colorScheme.onSurface,
                          size: 28,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      if (widget.mode == 'campaign')
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: memoryTheme.accentSoft,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: memoryTheme.accent.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Text(
                            'Lv.${widget.campaignLevel?.level ?? ""}',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: memoryTheme.accent,
                            ),
                          ),
                        ),
                      _buildStatChip(Icons.touch_app_rounded, '$_moves'),
                      const SizedBox(width: 8),
                      widget.timeLimit > 0
                          ? _buildStatChip(
                              Icons.timer_rounded,
                              _formatTime(_remainingSeconds),
                              urgent: _remainingSeconds <= 10,
                            )
                          : _buildStatChip(
                              Icons.timer_outlined,
                              _elapsedFormatted,
                            ),
                      const SizedBox(width: 8),
                      if (widget.mode != 'campaign')
                        IconButton(
                          icon: Icon(
                            Icons.refresh_rounded,
                            color: memoryTheme.accent,
                            size: 26,
                          ),
                          onPressed: _startNewGame,
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final cardW =
                            (constraints.maxWidth - (widget.cols - 1) * 8) /
                            widget.cols;
                        final cardH =
                            (constraints.maxHeight - (widget.rows - 1) * 8) /
                            widget.rows;
                        return Center(
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: List.generate(
                              _gridSize,
                              (i) => SizedBox(
                                width: cardW,
                                height: cardH,
                                child: _buildCard(i),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                if (_gameOver) _buildGameOverBanner(),
                if (!_gameOver) const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameOverBanner() {
    final memoryTheme = _MemoryMatchPalette.of(context);
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _won
              ? [memoryTheme.accentDark, memoryTheme.accent]
              : [
                  const Color(0xFF991B1B),
                  const Color(0xFFEF4444).withValues(alpha: 0.8),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (_won ? memoryTheme.accent : const Color(0xFFEF4444))
                .withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Text(
              _won ? '🏆' : '⏰',
              style: const TextStyle(fontSize: 24),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _won ? 'Excellent!' : 'Time\'s Up!',
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _won
                      ? '$_moves moves \u2022 $_elapsedFormatted'
                      : '$_matchesFound / $_pairsCount pairs found',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          if (widget.mode != 'campaign')
            GestureDetector(
              onTap: _startNewGame,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 18,
                ),
                decoration: BoxDecoration(
                  color: memoryTheme.card,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Play Again',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: memoryTheme.text,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label, {bool urgent = false}) {
    final memoryTheme = _MemoryMatchPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: urgent ? const Color(0xFF7F1D1D) : memoryTheme.cardAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: urgent ? const Color(0xFFEF4444) : memoryTheme.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: urgent ? const Color(0xFFEF4444) : memoryTheme.accent,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: memoryTheme.text,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(int index) {
    final memoryTheme = _MemoryMatchPalette.of(context);
    final isRevealed = _revealed[index] || _matched[index];
    final isMatched = _matched[index];
    final isTablet = isTabletLayout(context);
    return GestureDetector(
      onTap: () => _onCardTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: isMatched
              ? memoryTheme.accent.withAlpha(76)
              : isRevealed
              ? memoryTheme.cardAlt
              : memoryTheme.cardAlt.withAlpha(memoryTheme.isDark ? 95 : 65),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isMatched
                ? memoryTheme.accent
                : isRevealed
                ? memoryTheme.accent.withAlpha(76)
                : memoryTheme.border,
            width: isMatched ? 2 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isRevealed
                  ? memoryTheme.accent.withAlpha(38)
                  : Colors.black.withAlpha(46),
              blurRadius: isRevealed ? 8 : 10,
              offset: isRevealed ? Offset.zero : const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: isRevealed
                ? Text(
                    _cards[index],
                    key: ValueKey('e_$index'),
                    style: TextStyle(
                      fontSize: isTablet
                          ? (isMatched ? 58 : 66)
                          : (isMatched ? 26 : 30),
                    ),
                  )
                : Icon(
                    Icons.question_mark_rounded,
                    key: ValueKey('h_$index'),
                    color: memoryTheme.text.withAlpha(180),
                    size: isTablet ? 44 : 22,
                  ),
          ),
        ),
      ),
    );
  }
}

// ─── High Scores Page ────────────────────────────────────────────────────

class HighScoresPage extends StatefulWidget {
  const HighScoresPage({super.key});
  @override
  State<HighScoresPage> createState() => _HighScoresPageState();
}

class _HighScoresPageState extends State<HighScoresPage> {
  String _selectedMode = 'standard';
  String _selectedDifficulty = 'easy';
  final Map<String, List<Map<String, String>>> _modes = {
    'standard': [
      {'id': 'easy', 'label': 'Easy'},
      {'id': 'medium', 'label': 'Medium'},
      {'id': 'expert', 'label': 'Expert'},
    ],
    'speed': [
      {'id': 'easy', 'label': 'Easy'},
      {'id': 'medium', 'label': 'Medium'},
      {'id': 'hard', 'label': 'Hard'},
      {'id': 'ultra', 'label': 'Ultra Hard'},
    ],
  };

  Future<List<Map<String, dynamic>>> _loadScores() async {
    return MemoryMatchService.loadHighScores(
      _selectedMode,
      _selectedDifficulty,
    );
  }

  String _formatTime(int s) {
    final m = s ~/ 60;
    return '${m.toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        title: Text(
          'High Scores',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildModeTab('Standard', 'standard'),
                const SizedBox(width: 8),
                _buildModeTab('Speed', 'speed'),
              ],
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: (_modes[_selectedMode] ?? []).map((d) {
                final sel = _selectedDifficulty == d['id'];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: sel,
                    label: Text(d['label']!),
                    labelStyle: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: sel
                          ? Colors.black
                          : Theme.of(
                              context,
                            ).colorScheme.onSurface.withAlpha(100),
                    ),
                    selectedColor: const Color(0xFF10B981),
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    onSelected: (_) =>
                        setState(() => _selectedDifficulty = d['id']!),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _loadScores(),
              builder: (ctx, snap) {
                if (!snap.hasData || snap.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.emoji_events_outlined,
                          size: 48,
                          color: Colors.grey[800],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No scores yet',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          'Play a game to set your first record!',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: snap.data!.length,
                  itemBuilder: (ctx, i) {
                    final s = snap.data![i];
                    final rank = i + 1;
                    final medal = rank == 1
                        ? '🥇'
                        : rank == 2
                        ? '🥈'
                        : rank == 3
                        ? '🥉'
                        : '#$rank';
                    final date = DateTime.tryParse(s['date'] ?? '');
                    final dateStr = date != null
                        ? '${date.day}/${date.month}/${date.year}'
                        : '';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: rank <= 3
                            ? const Color(0xFFF0FDF4)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: rank <= 3
                              ? const Color(0xFF10B981).withValues(alpha: 0.3)
                              : Colors.black.withValues(alpha: 0.05),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: rank <= 3
                                  ? const Color(0xFFDCFCE7)
                                  : const Color(0xFFF9FAFB),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                medal,
                                style: GoogleFonts.outfit(
                                  fontSize: rank <= 3 ? 20 : 14,
                                  fontWeight: FontWeight.bold,
                                  color: rank <= 3
                                      ? const Color(0xFF065F46)
                                      : Colors.grey[500],
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
                                  _formatTime(s['time'] as int),
                                  style: GoogleFonts.outfit(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF111827),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${s['moves']} moves \u2022 $dateStr',
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    color: const Color(0xFF4B5563),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (rank <= 3)
                            const Icon(
                              Icons.stars_rounded,
                              color: Color(0xFF10B981),
                              size: 24,
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeTab(String label, String value) {
    final sel = _selectedMode == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _selectedMode = value;
          _selectedDifficulty = _modes[value]!.first['id']!;
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: sel
                ? const Color(0xFF10B981)
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: sel
                  ? Colors.black
                  : Theme.of(context).colorScheme.onSurface.withAlpha(100),
            ),
          ),
        ),
      ),
    );
  }
}
