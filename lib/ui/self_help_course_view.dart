import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'self_help_lesson_view.dart';

class SelfHelpCourseView extends StatefulWidget {
  final String title;
  final String description;
  final String category;
  final Color color;
  final List<Map<String, String>>? modules;

  const SelfHelpCourseView({
    super.key,
    required this.title,
    required this.description,
    required this.category,
    required this.color,
    this.modules,
  });

  @override
  State<SelfHelpCourseView> createState() => _SelfHelpCourseViewState();
}

class _SelfHelpCourseViewState extends State<SelfHelpCourseView> {
  int _unlockedModuleIndex = -1; // -1 means not started
  int? _activeModuleIndex;
  bool _courseStarted = false;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'course_${widget.title}_unlocked';
    final savedIndex = prefs.getInt(key);

    if (savedIndex != null) {
      if (mounted) {
        setState(() {
          _unlockedModuleIndex = savedIndex;
          _courseStarted = true;

          if (savedIndex >= _effectiveModules.length - 1) {
            _activeModuleIndex = _effectiveModules.length - 1;
          } else {
            _activeModuleIndex = savedIndex;
          }
        });
      }
    }
  }

  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'course_${widget.title}_unlocked';
    await prefs.setInt(key, _unlockedModuleIndex);
  }

  List<Map<String, String>> get _effectiveModules {
    if (widget.modules != null && widget.modules!.isNotEmpty) {
      return widget.modules!;
    }
    return _fallbackModules;
  }

  List<Map<String, String>> get _fallbackModules {
    final subject = widget.title;
    final lens = _courseLens;
    final practice = _coursePractice;
    final evidence = _courseEvidence;

    return [
      {
        'title': 'Define What $subject Means',
        'duration': '15 min',
        'content':
            '$subject needs a clear definition before it can become useful. ${widget.description}\n\n$lens\n\nStart by separating the result you want from the practice that may produce it. A result is the change you hope to see; a practice is the repeatable behaviour under your control. Confusing the two often creates frustration because results rarely arrive on command.\n\nYour action: write one sentence beginning “For me, $subject means…” Then name one result you want and one behaviour you can control this week.',
      },
      {
        'title': 'Map Your Starting Point',
        'duration': '20 min',
        'content':
            'Before changing $subject, establish an honest baseline. Look at what currently happens, when it happens, and what makes the pattern easier or harder. Avoid judging the starting point; accurate information is more useful than a flattering story.\n\nAudit these four areas:\n• Current behaviour or routine\n• Trigger, environment, or timing\n• Short-term reward or cost\n• Support, skill, or resource that is missing\n\n$evidence\n\nYour action: record one real example from the last seven days. Mark the earliest moment where a different choice was realistically available.',
      },
      {
        'title': 'Practise $subject',
        'duration': '25 min',
        'content':
            'Understanding $subject is not the same as practising it. The next step should be small enough to repeat and specific enough to observe.\n\n$practice\n\nUse a short learning cycle:\n• Choose one behaviour\n• Decide when and where it will happen\n• Complete the smallest useful version\n• Record what happened without exaggeration\n• Adjust one variable before repeating\n\nYour action: schedule the first practice within the next 24 hours. Define the minimum version that still counts, especially on a difficult day.',
      },
      {
        'title': 'Make $subject Sustainable',
        'duration': '18 min',
        'content':
            'Lasting progress with $subject comes from review and adjustment, not permanent intensity. A useful plan can survive busy weeks, setbacks, low motivation, and imperfect results.\n\nReview weekly:\n• What changed in the evidence you chose?\n• Which part of the practice helped most?\n• What created friction or avoidance?\n• What should be continued, reduced, or replaced?\n• What support would make the next week easier?\n\nDo not restart from zero after a miss. Resume with the smallest version, learn from the obstacle, and rebuild consistency.\n\nYour action: choose a weekly review time and write a recovery rule beginning “If I miss the practice, I will…”',
      },
    ];
  }

  String get _courseLens {
    final subject = widget.title.toLowerCase();
    if (subject.contains('sleep')) {
      return 'Restorative sleep is the foundational pillar of physical vitality, cellular repair, and neurological sharpness. Optimizing your sleep environment and circadian rhythm creates a biological baseline for high performance and deep well-being.';
    }
    if (subject.contains('fitness') ||
        subject.contains('workout') ||
        subject.contains('yoga')) {
      return 'Physical movement is a sacred daily ritual that builds strength, mobility, and systemic longevity. Sustainable training pairs progressive challenge with deep rest, transforming your physical vessel into a resilient tool for your purpose.';
    }
    if (subject.contains('nutrition') || subject.contains('gut')) {
      return 'Nourishment is cellular information that communicates directly with your genes, energy systems, and mood. Eating clean, nutrient-dense foods fuels your microbiome and maintains vibrant, disease-resistant health.';
    }
    if (subject.contains('anxiety') || subject.contains('depression')) {
      return 'Mental and emotional well-being begins with restoring safety to your nervous system. By cultivating self-compassion, physical grounding, and supportive daily rituals, you reclaim peace and emotional equilibrium.';
    }
    if (subject.contains('invest') ||
        subject.contains('stock') ||
        subject.contains('real estate') ||
        subject.contains('retirement')) {
      return 'Investing is the strategic discipline of compounding your capital so your money works continuously for your long-term independence. Building clear asset allocation rules removes emotional volatility and guarantees financial security.';
    }
    if (subject.contains('money') ||
        subject.contains('wealth') ||
        subject.contains('financial') ||
        subject.contains('budget')) {
      return 'Financial sovereignty pairs an abundant prosperity mindset with clean, disciplined money systems. Directing your cash flow intentionally creates freedom, eliminates debt anxiety, and fuels lifelong wealth creation.';
    }
    if (subject.contains('relationship') ||
        subject.contains('marriage') ||
        subject.contains('dating') ||
        subject.contains('attachment') ||
        subject.contains('conflict')) {
      return 'Deep human relationship is built on emotional safety, authentic vulnerability, clear boundaries, and persistent repair. Nurturing authentic connection elevates your happiness, longevity, and peace of mind.';
    }
    if (subject.contains('career') ||
        subject.contains('leadership') ||
        subject.contains('interview') ||
        subject.contains('resume') ||
        subject.contains('network')) {
      return 'Professional mastery is the expression of your unique talents in service of high-impact goals. Aligning your career with your core strengths and building trust creates extraordinary professional advancement.';
    }
    if (subject.contains('meditation') ||
        subject.contains('spiritual') ||
        subject.contains('intuition') ||
        subject.contains('chakra') ||
        subject.contains('enlightenment')) {
      return 'Spiritual practice opens your awareness to the infinite intelligence and divine presence moving through all existence. Cultivating inner stillness aligns your consciousness with your highest soul purpose.';
    }
    if (subject.contains('manifest') || subject.contains('visual') || subject.contains('quantum')) {
      return 'Manifestation and quantum shift operate on the universal law that your internal vibrational state magnetizes your physical reality. Holding a vivid vision with deep feeling, faith, and aligned action collapses pure potential into physical form.';
    }
    return 'Personal growth is the conscious evolution of your character, habits, and mindset. Defining progress through aligned behavior and high standards transforms your life from the inside out.';
  }

  String get _coursePractice {
    final subject = widget.title.toLowerCase();
    if (subject.contains('sleep')) {
      return 'Establish a calm wind-down sanctuary 60 minutes before bed: dim evening lights, remove digital screens, and let your nervous system down-regulate into deep rest.';
    }
    if (subject.contains('fitness') ||
        subject.contains('workout') ||
        subject.contains('yoga')) {
      return 'Schedule movement sessions into your calendar as non-negotiable health appointments. Focus on technique, breath control, and gradual progression.';
    }
    if (subject.contains('nutrition') || subject.contains('gut')) {
      return 'Build every meal around vibrant, whole, nutrient-dense ingredients. Eat mindfully and notice how clean nutrition elevates your daily physical energy.';
    }
    if (subject.contains('invest') ||
        subject.contains('stock') ||
        subject.contains('real estate') ||
        subject.contains('retirement')) {
      return 'Research assets thoroughly, maintain long-term horizons, and automate your monthly investment contributions to let compound growth build your fortune.';
    }
    if (subject.contains('relationship') ||
        subject.contains('marriage') ||
        subject.contains('dating') ||
        subject.contains('conflict')) {
      return 'Practice present, active listening and warm appreciation in your daily interactions. State your needs vulnerably and resolve conflicts with deep empathy.';
    }
    if (subject.contains('career') ||
        subject.contains('leadership') ||
        subject.contains('interview') ||
        subject.contains('resume') ||
        subject.contains('network')) {
      return 'Focus your peak daily energy on high-value output, communicate your vision clearly, and build authentic relationships across your industry.';
    }
    if (subject.contains('meditation') || subject.contains('spiritual')) {
      return 'Set aside quiet time daily to anchor your attention in silent presence. Listen to your inner intuition and let peace guide your actions.';
    }
    if (subject.contains('manifest') || subject.contains('visual') || subject.contains('quantum')) {
      return 'Enter a deep meditative state, visualize your desired reality as ALREADY fulfilled, feel the elevated joy and gratitude in your chest, and act from that new identity today.';
    }
    return 'Choose one high-impact habit connected to $subject, set a clear daily cue, and complete it consistently to lock in your identity shift.';
  }

  String get _courseEvidence {
    final subject = widget.title.toLowerCase();
    if (subject.contains('health') ||
        subject.contains('fitness') ||
        subject.contains('sleep') ||
        subject.contains('nutrition')) {
      return 'Useful evidence may include energy, sleep quality, symptoms, strength, consistency, or daily function. Choose one measure that matters and can be recorded safely.';
    }
    if (subject.contains('money') ||
        subject.contains('wealth') ||
        subject.contains('invest') ||
        subject.contains('budget')) {
      return 'Useful evidence may include spending, saving, debt, income, fees, completed research, or fewer impulsive decisions. Choose a number or behaviour you can verify.';
    }
    if (subject.contains('relationship') ||
        subject.contains('marriage') ||
        subject.contains('dating') ||
        subject.contains('conflict')) {
      return 'Useful evidence may include clearer requests, respected boundaries, completed repairs, reduced escalation, or more consistent contact. Do not use another person\'s feelings as your only measure.';
    }
    if (subject.contains('career') ||
        subject.contains('leadership') ||
        subject.contains('interview') ||
        subject.contains('resume')) {
      return 'Useful evidence may include work completed, feedback received, applications sent, skills demonstrated, decisions clarified, or conversations initiated.';
    }
    return 'Choose evidence that can be observed: a completed behaviour, a written decision, a repeated practice, feedback, or a measurable change in the pattern.';
  }

  void _startCourse() {
    setState(() {
      _courseStarted = true;
      _unlockedModuleIndex = 0; // Unlock first module
      _activeModuleIndex = 0;
    });
    _saveProgress();
  }

  void _unlockNextModule() {
    if (_unlockedModuleIndex < _effectiveModules.length - 1) {
      setState(() {
        _unlockedModuleIndex++;
        _activeModuleIndex = _unlockedModuleIndex;
      });
      _saveProgress();
    }
  }

  void _completeCurrentModule() {
    _unlockNextModule();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: _courseStarted ? 120.0 : 200.0,
            floating: false,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      widget.color.withValues(alpha: 0.3),
                      Theme.of(context).scaffoldBackgroundColor,
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(
                    CupertinoIcons.book_fill,
                    size: 60,
                    color: widget.color.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(24.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: widget.color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'MINI COURSE',
                        style: GoogleFonts.outfit(
                          color: widget.color,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      widget.category.toUpperCase(),
                      style: GoogleFonts.outfit(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withAlpha(150),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  widget.title,
                  style: GoogleFonts.outfit(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.description,
                  style: GoogleFonts.outfit(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withAlpha(150),
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),

                const SizedBox(height: 32),

                // Modules Section Header with Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _courseStarted ? 'Your Progress' : 'Modules',
                      style: GoogleFonts.outfit(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (!_courseStarted)
                      ElevatedButton(
                        onPressed: () {
                          _startCourse();
                          _openLesson(0);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.color == Colors.black
                              ? Theme.of(context).colorScheme.primary
                              : (widget.color == Colors.white
                                    ? Theme.of(context).colorScheme.primary
                                    : widget.color),
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.surface,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'START COURSE',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            letterSpacing: 1.1,
                          ),
                        ),
                      )
                    else if (_unlockedModuleIndex <
                        _effectiveModules.length - 1)
                      ElevatedButton(
                        onPressed: _completeCurrentModule,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.color == Colors.black
                              ? Theme.of(context).colorScheme.primary
                              : (widget.color == Colors.white
                                    ? Theme.of(context).colorScheme.primary
                                    : widget.color),
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.surface,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'CONTINUE',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Module List
                ...List.generate(_effectiveModules.length, (index) {
                  return _buildModuleItem(index);
                }),

                const SizedBox(height: 32),

                // Course Complete Message (only shown when course is finished)
                if (_courseStarted &&
                    _unlockedModuleIndex >= _effectiveModules.length - 1)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: widget.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: widget.color.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          CupertinoIcons.checkmark_seal_fill,
                          color: widget.color,
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Course Complete!',
                          style: GoogleFonts.outfit(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'You\'ve finished all modules. Great job!',
                          style: GoogleFonts.outfit(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withAlpha(150),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  void _openLesson(int index) {
    final module = _effectiveModules[index];
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SelfHelpLessonView(
          title: module['title'] ?? 'Module ${index + 1}',
          content: _getModuleContent(index),
          category: widget.category,
          color: widget.color,
          moduleIndex: index,
          onComplete: () {
            if (index == _unlockedModuleIndex) {
              _unlockNextModule();
            }
          },
        ),
      ),
    );
  }

  String _getModuleContent(int index) {
    final module = _effectiveModules[index];
    final content = module['content'];
    if (content != null && content.trim().isNotEmpty) {
      return content;
    }

    return 'This lesson is being prepared for ${widget.title}. Return to the course overview and choose another available module.';
  }

  Widget _buildModuleItem(int index) {
    final module = _effectiveModules[index];
    final isUnlocked = index <= _unlockedModuleIndex;
    final isActive = index == _activeModuleIndex && _courseStarted;
    final isCompleted = index < _unlockedModuleIndex;

    return GestureDetector(
      onTap: isUnlocked ? () => _openLesson(index) : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isActive
              ? widget.color.withValues(alpha: 0.1)
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive
                ? widget.color
                : isCompleted
                ? widget.color.withValues(alpha: 0.3)
                : Theme.of(context).dividerColor.withAlpha(50),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isCompleted
                    ? widget.color
                    : isUnlocked
                    ? widget.color.withValues(alpha: 0.1)
                    : Theme.of(context).dividerColor.withAlpha(50),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: isCompleted
                    ? Icon(
                        Icons.check,
                        color: Theme.of(context).colorScheme.surface,
                        size: 18,
                      )
                    : Text(
                        '${index + 1}',
                        style: GoogleFonts.outfit(
                          color: isUnlocked
                              ? widget.color
                              : Theme.of(
                                  context,
                                ).colorScheme.onSurface.withAlpha(120),
                          fontWeight: FontWeight.bold,
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
                    module['title'] ?? 'Module ${index + 1}',
                    style: GoogleFonts.outfit(
                      color: isUnlocked
                          ? Theme.of(context).colorScheme.onSurface
                          : Theme.of(
                              context,
                            ).colorScheme.onSurface.withAlpha(120),
                      fontWeight: FontWeight.w600,
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
}
