import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/cupertino.dart';

class SelfHelpArticleView extends StatelessWidget {
  final String title;
  final String description;
  final String category;
  final String? parentCategory;
  final Color color;

  const SelfHelpArticleView({
    super.key,
    required this.title,
    required this.description,
    required this.category,
    this.parentCategory,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final sections = _articleSections;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
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
                      color.withValues(alpha: 0.3),
                      Theme.of(context).scaffoldBackgroundColor,
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(CupertinoIcons.book_fill, size: 60, color: color),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(24.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    category.toUpperCase(),
                    style: GoogleFonts.outfit(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  description,
                  style: GoogleFonts.outfit(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withAlpha(180),
                    fontSize: 18,
                    height: 1.5,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 32),
                Divider(color: Theme.of(context).dividerColor.withAlpha(50)),
                const SizedBox(height: 32),
                _buildContentParagraph(context, sections.first.body),
                ...sections
                    .skip(1)
                    .map((section) => _buildArticleSection(context, section)),
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  List<_ArticleSection> get _articleSections {
    return [
      _ArticleSection('Insight', _insight),
      _ArticleSection('Key Takeaway', _usefulInformation),
      _ArticleSection('Watch Point', _watchPoint),
      _ArticleSection('Action Step', _actionStep),
    ];
  }

  String get _area => parentCategory ?? 'Self Help';

  String get _insight {
    final subject = title.toLowerCase();
    if (category == 'Manifestation') {
      return '$title is the intentional alignment of your subconscious belief, emotional frequency, and daily focus with the reality you choose to experience. It operates on the fundamental law that your internal state dictates your external trajectory; whatever vision you hold with conviction, feeling, and persistent focus begins to magnetize the opportunities, ideas, and synchronicities necessary for its creation.\n\nTo master $title, you must move beyond passive wishing and step into full energetic embodiment. By holding the vivid mental state of your desire as already real and pairing that elevated state with bold, committed action, you collapse the distance between intention and physical manifestation in $_area.';
    }
    if (category == 'Psychology') {
      return '$title illuminates the hidden architecture of your mind, revealing how subconscious conditioning, core beliefs, and emotional triggers shape your daily reality. When you illuminate these subterranean mental patterns with compassionate self-awareness, you gain the power to break unhelpful loops and consciously rewire your mental programming.\n\nMastering $title transforms vague personal struggles into clear opportunities for psychological mastery. By observing your thoughts without judgment and choosing empowering mental responses, you cultivate emotional resilience, mental clarity, and lasting inner peace.';
    }
    if (category == 'Nutrition') {
      return '$title honors food as sacred cellular information and vital energy that directly communicates with every gene, cell, and organ in your body. Beyond calorie counting, the nourishment you consume creates the biological foundation for your vitality, mental clarity, emotional mood, and immune strength.\n\nApplying $title means tuning into your body\'s deep wisdom and feeding it clean, vibrant nourishment. By establishing conscious eating practices and honoring your unique biological needs, you unlock boundless natural energy and radiant physical health.';
    }
    if (category == 'Biohacking') {
      return '$title is the deliberate optimization of your human biology through targeted environmental cues, physiological rituals, and cellular enhancement. By understanding the biological levers of human performance, you can upgrade your physical energy, mental focus, and systemic resilience.\n\nWhen you practice $title, you work in harmony with your natural biology to stimulate cellular repair, mitochondrial vitality, and neurological sharpness. Measured experimentation and recovery turn your body into a peak-performing vehicle for your life\'s purpose.';
    }
    if (category == 'Longevity') {
      return '$title focuses on expanding your healthspan—ensuring that your years are filled with robust physical strength, cognitive sharpness, vibrant energy, and joyful independence. It is an investment in cellular preservation and systemic vitality so that time enhances your wisdom without diminishing your body.\n\nPracticing $title empowers you to protect your cellular integrity, optimize mitochondrial health, and build lasting physical reserves. True longevity is living fully in the present while cultivating a resilient body that thrives for decades to come.';
    }
    if (category == 'Investing') {
      return '$title is the strategic discipline of channeling your resources into assets that generate compounding wealth over time. It shifts your relationship with capital from short-term consumption to long-term freedom, allowing your money to work energetically for you around the clock.\n\nBy building a clear framework for $title, you remove emotional volatility from your financial decisions. Diversification, patient compounding, and written investment principles create an unshakeable foundation for perpetual financial independence.';
    }
    if (category == 'Side Hustles') {
      return '$title is the art of transforming your unique talents, knowledge, and passions into a valuable, revenue-generating offering. It provides financial flexibility and creative freedom, allowing you to build an independent stream of income outside traditional employment.\n\nTo succeed with $title, focus on delivering genuine, transformative value to a specific audience. By testing ideas quickly, refining your offer, and building efficient systems, you create a scalable project that expands your financial abundance.';
    }
    if (category == 'Budgeting') {
      return '$title is an empowering tool of financial sovereignty that directs your money toward your highest values and goals. Rather than restrictive deprivation, a well-designed budget grants complete visibility, control, and peace of mind over your financial flow.\n\nImplementing $title ensures that every unit of currency has a clear purpose—building security, eliminating debt, funding dreams, and supporting lifestyle choices. Intentional money allocation eliminates financial anxiety and fuels lasting wealth creation.';
    }
    if (category == 'Resolution') {
      return '$title is the crucial interpersonal skill of navigating conflict with grace, emotional maturity, and mutual respect. It transforms friction into an opportunity for deeper understanding, preserving human dignity while addressing underlying issues directly.\n\nMastering $title requires active listening, emotional self-regulation, and clear communication. By separating personal attacks from core needs, you de-escalate tension and build resilient, trust-filled relationships.';
    }
    if (category == 'Dating') {
      return '$title empowers you to approach romantic connection from self-worth, emotional clarity, and authentic expression rather than performance or anxiety. It allows you to attract compatible partners who honor your values, boundaries, and vision for life.\n\nBy practicing $title, you replace needy attachment with magnetizing self-confidence. Clear communication, healthy pacing, and discernment ensure your dating journey leads to fulfilling, harmonious, and deep connection.';
    }
    if (category == 'Social') {
      return '$title is the art of fostering authentic, warm, and meaningful human connections in every social interaction. Strong social skills combine active presence, empathetic listening, emotional intelligence, and clean boundaries to make others feel seen and valued.\n\nApplying $title expands your circle of influence and enriches your daily life with vibrant community. By bringing genuine interest and warmth to every encounter, you naturally attract uplifting and supportive relationships.';
    }
    if (category == 'Leadership') {
      return '$title is the practice of inspiring, empowering, and guiding others toward a shared vision through unwavering integrity and consistent modeling. True leadership is not about command or control; it is about serving the growth and success of the team.\n\nEmbodying $title requires clear communication, emotional poise, and high accountability. When you foster psychological safety and reward excellence, you cultivate a high-performing culture of trust and shared achievement.';
    }
    if (category == 'Speaking') {
      return '$title transforms public communication into a powerful vehicle for inspiration, education, and influence. The true mark of great speaking is not sounding impressive, but delivering ideas with such clarity, conviction, and warmth that they deeply resonate with your audience.\n\nMastering $title involves structuring your message effectively, mastering vocal presence, and connecting authentically. By focusing on serving your listeners, you turn nervous energy into captivating presence and lasting impact.';
    }
    if (category == 'Productivity') {
      return '$title is the intentional alignment of your time, energy, and attention with your highest-priority goals. True productivity is not about busywork or endless hustling; it is about working deeply on what creates meaningful, high-impact results.\n\nBy applying $title, you eliminate friction, minimize distractions, and protect your peak focus blocks. Structured systems and clear boundaries allow you to produce extraordinary work while maintaining mental clarity and balance.';
    }
    if (category == 'Wisdom') {
      return '$title is the deep inner discernment that transforms life experience into profound self-knowledge and right action. It invites you to pause, reflect on underlying truths, and align your life choices with universal principles of balance, integrity, and truth.\n\nCultivating $title elevates your decision-making beyond temporary emotions or societal pressure. By listening to the quiet guidance of reflection and experience, you navigate life\'s challenges with quiet confidence and enduring peace.';
    }
    if (category == 'Quantum') {
      return '$title taps into the infinite quantum field of energy and potential where all possibilities exist simultaneously. In this realm of reality, your focused consciousness acts as the observer that collapses pure potential into tangible physical outcomes, proving that your mind and the material world are deeply interconnected aspects of one conscious universe.\n\nWhen you engage with $title, you are learning to shift your vibrational signature to match the exact timeline you wish to inhabit. By aligning your mind, feeling, and physical movement with this elevated quantum frequency, breakthroughs that once seemed impossible occur with effortless, miraculous speed.';
    }
    if (category == 'Stoicism') {
      return '$title is the practice of cultivating inner freedom and emotional equilibrium by mastering what is within your direct control while letting go of external events. It equips you with unshakeable mental fortitude, clarity, and virtue in the face of life\'s uncertainties.\n\nApplying $title teaches you to meet challenges as material for personal growth and character development. By aligning your mind with reason and virtue, you maintain complete peace and power regardless of outer circumstances.';
    }
    if (category == 'Discipline') {
      return '$title is the art of self-mastery that bridges the gap between your highest intentions and daily reality. Rather than harsh self-punishment, true discipline is an act of deep self-love that honors your long-term vision over short-term impulses.\n\nBuilding $title involves designing supportive environments, establishing clear cues, and keeping small daily promises to yourself. Consistent execution turns discipline into an effortless identity that guarantees long-term achievement.';
    }
    if (category == 'Time Mgmt') {
      return '$title is the strategic management of your lifespan and daily attention, ensuring your calendar directly reflects your core values and life purpose. Time is your most precious non-renewable asset, and managing it intentionally protects you from reactivity and burnout.\n\nMastering $title involves setting firm boundaries, prioritizing high-value outcomes, and scheduling intentional rest. When you take control of your time, you create space for deep achievement, rich relationships, and personal fulfillment.';
    }
    if (category == 'Confidence') {
      return '$title is an unshakable state of internal trust built on small promises kept, courage in the face of fear, and radical self-acceptance. Genuine confidence is not the absence of doubt, but the deep conviction that you can handle whatever arises.\n\nDeveloping $title requires stepping into discomfort, taking imperfect action, and building competence through practice. As you replace self-criticism with supportive self-belief, your energy commands respect and magnetizes success.';
    }
    if (subject.contains('anxiety') || subject.contains('stress')) {
      return '$title begins by calming the nervous system and establishing physical and emotional safety. When your body feels secure, your mind regains access to higher perspective, creative solutions, and emotional balance.\n\nBy practicing $title, you learn gentle, effective techniques to soothe your physical response to pressure. Restoring inner balance allows you to respond to life with clarity and calm power.';
    }
    if (category == 'Career Change') {
      return '$title is a pivotal journey of aligning your professional life with who you are today. It is an exploration of whether your current work environment, culture, and purpose truly reflect your evolving talents, values, and vision.\n\nEngaging with $title gives you the clarity and strategy needed to transition smoothly. By evaluating what actually fulfills you and testing new paths deliberately, you step into a career that energizes and sustains you.';
    }
    if (category == 'Entrepreneurship') {
      return '$title is the creative discipline of building a sustainable, value-generating enterprise that solves real problems. It requires courage, strategic vision, and resilience to convert an idea into a thriving business model.\n\nPracticing $title focuses your effort on market validation, customer satisfaction, and efficient operations. By taking calculated risks and delivering genuine value, you build financial independence and impact.';
    }
    if (category == 'Family') {
      return '$title focuses on nurturing and repairing the foundational relationships of your life. Because family dynamics are rehearsed over years, small, consistent shifts in communication and emotional warmth yield profound long-term harmony.\n\nApplying $title requires patience, healthy boundaries, and compassionate repair. By modeling emotional maturity and respect, you create a safer, more loving family environment.';
    }
    if (category == 'Fitness') {
      return '$title approaches physical movement as a sacred daily ritual that enhances your strength, energy, and overall healthspan. Consistency in movement transforms your physical resilience and boosts your neurological and metabolic vitality.\n\nEmbodying $title means respecting your physical potential while listening to your body. Daily, enjoyable movement creates compound physical progress that fuels every other area of your life.';
    }
    if (category == 'Goals') {
      return '$title turns abstract dreams into concrete, structured realities. A well-designed goal bridges vision and daily action, making progress measurable, exciting, and sustainable.\n\nMastering $title involves breaking large outcomes into immediate, actionable steps. By focusing on daily execution rather than distant wishes, you build momentum and guarantee achievement.';
    }
    if (category == 'Mental Health') {
      return '$title honors mental and emotional well-being as foundational to human flourishing. It recognizes that mental health requires compassionate self-care, supportive habits, and environment optimization.\n\nPracticing $title gives you practical tools to navigate challenging emotions and restore psychological equilibrium. Prioritizing your mental health creates a steady foundation of inner peace and resilience.';
    }
    if (category == 'Mini Course') {
      return '$title is a focused, step-by-step module designed to build a practical skill or mindset shift. Its value compounds when each lesson is tested and integrated into daily life before moving forward.\n\nEngaging with $title accelerates your personal development through structured learning cycles. Consistent application transforms fresh insights into permanent capability.';
    }
    if (category == 'Practices') {
      return '$title relies on simple, repeatable rituals that ground your focus and elevate your daily experience. Small, daily practices done consistently create far greater transformation than intermittent intense efforts.\n\nIntegrating $title into your daily flow anchors your attention and reinforces your desired identity. Consistency in small practices builds undeniable momentum over time.';
    }
    if (category == 'Saving') {
      return '$title creates a protective financial buffer that grants peace of mind and guards against life\'s unexpected turns. Saving consistently builds the financial strength needed to take bold, confident steps toward your long-term dreams.\n\nPracticing $title turns saving into an automatic, rewarding habit. Even small, steady contributions compound into lasting financial security and freedom.';
    }
    if (category == 'Self-Discovery') {
      return '$title is an illuminating exploration into your authentic values, innate strengths, and core desires. It guides you to uncover what truly matters to you across different life contexts, allowing you to live with purpose and authenticity.\n\nEngaging with $title deepens your self-awareness and aligns your choices with your true nature. Recognizing your repeatable patterns empowers you to create a life of deep alignment and joy.';
    }
    return '$title provides a focused framework for continuous self-improvement in $_area. It invites you to observe your patterns, elevate your standards, and make intentional choices that foster growth.\n\nApplying $title daily connects insight with real-world action, ensuring every step forward builds lasting wisdom, confidence, and fulfillment.';
  }

  String get _usefulInformation =>
      description.replaceAll(RegExp(r'\s+'), ' ').trim();

  String get _watchPoint {
    final normalized = title.toLowerCase().trim();
    if (_topicWatchPoints.containsKey(normalized)) {
      return _topicWatchPoints[normalized]!;
    }
    if (category == 'Manifestation' || category == 'Quantum') {
      return 'Do not let visualization become avoidance. If the practice does not change a real behavior, it remains entertainment rather than transformation.';
    }
    if (category == 'Nutrition' ||
        category == 'Biohacking' ||
        category == 'Longevity') {
      return 'Avoid extremes. Your body responds to consistency, context, and recovery. Stop any practice that creates pain, distress, or worsening symptoms.';
    }
    if (category == 'Investing' || category == 'Budgeting') {
      return 'Avoid urgency. Rushed financial choices are often emotional choices wearing a logical disguise.';
    }
    if (category == 'Dating' ||
        category == 'Resolution' ||
        category == 'Social') {
      return 'Do not confuse intensity with intimacy. Secure connection usually feels steady, respectful, and clear.';
    }
    if (category == 'Productivity' ||
        category == 'Discipline' ||
        category == 'Time Mgmt') {
      return 'Do not turn self-improvement into self-punishment. A system that depends on constant pressure will eventually break.';
    }
    if (category == 'Career Change' ||
        category == 'Entrepreneurship' ||
        category == 'Goals') {
      return 'Do not confuse a fresh start with fixing the underlying issue. Check whether the change addresses the real problem or just relocates it.';
    }
    if (category == 'Family' || category == 'Self-Discovery') {
      return 'Do not expect one conversation or insight to undo a long-standing pattern. Real change in close relationships and self-understanding usually shows up gradually, through repetition.';
    }
    if (category == 'Fitness' || category == 'Practices') {
      return 'Avoid all-or-nothing thinking. Missing one session does not undo progress; the real risk is stopping entirely rather than restarting small.';
    }
    if (category == 'Mental Health') {
      return 'This is general education, not a diagnosis or treatment plan. If symptoms are significant, persistent, or affecting daily life, involve a qualified professional.';
    }
    if (category == 'Saving') {
      return 'Do not treat saving as only for large emergencies. Small, regular amounts build the habit that makes bigger saving possible later.';
    }
    if (category == 'Mini Course') {
      return 'Do not rush through the sequence without applying each lesson. Skipping ahead usually means arriving at the end with ideas but no practised skill.';
    }
    return 'The main risk with $title is staying abstract. Decide in advance which observable behaviour or result would show that you have applied the lesson.';
  }

  String get _actionStep {
    final action = _topicAction;
    if (action != null) {
      return action;
    }

    final focus = _actionFocus;
    if (category == 'Manifestation') {
      return 'For $title, write a three-line vision for $focus: what changes, how daily life feels, and the first visible behavior you will complete today.';
    }
    if (category == 'Psychology') {
      return 'Apply $title to one real moment: note the trigger, your automatic response, the cost of that response, and one replacement response you will rehearse once today.';
    }
    if (category == 'Nutrition') {
      return 'Build one meal around $focus today. Decide the ingredients before you are hungry, eat slowly, and record your energy two hours later.';
    }
    if (category == 'Biohacking') {
      return 'Test $title as a three-day experiment: set the smallest useful dose, record sleep and energy each day, and stop if your body pushes back.';
    }
    if (category == 'Longevity') {
      return 'Choose one longevity behavior linked to $focus and schedule it twice this week. Treat the calendar entry as health maintenance, not motivation.';
    }
    if (category == 'Investing') {
      return 'Before acting on $title, write your time horizon, risk comfort, fees to check, and the one question you need answered by a qualified source.';
    }
    if (category == 'Side Hustles') {
      return 'Turn $title into one market test: write "I help [person] achieve [result] by [method]" and send it to one real person for feedback.';
    }
    if (category == 'Budgeting') {
      return 'Use $title on your last seven days of spending. Label each item need, want, future, or leak, then remove or cap one leak this week.';
    }
    if (category == 'Resolution') {
      return 'Practice $title with one low-stakes repair sentence: "When X happened, I felt Y. What I need next is Z. How does that land for you?"';
    }
    if (category == 'Dating') {
      return 'Before your next dating decision, use $title to write one standard, one boundary, and one sign that the connection is genuinely healthy.';
    }
    if (category == 'Social') {
      return 'In your next conversation, practice $title once: prepare one opener, one follow-up question, and one clean way to close the exchange.';
    }
    if (category == 'Leadership') {
      return 'Apply $title to one team expectation today. State the desired behavior, why it matters, and what support or feedback will follow.';
    }
    if (category == 'Speaking') {
      return 'Prepare a 60-second talk on $focus using point, reason, example, next step. Say it out loud twice and remove one sentence each time.';
    }
    if (category == 'Productivity') {
      return 'Use $title on one task today: define the finish line, block 25 minutes, remove one distraction, and stop only when the finish line is reached.';
    }
    if (category == 'Wisdom') {
      return 'Journal on $title with one question: "What lesson keeps repeating because I have not fully acted on it yet?"';
    }
    if (category == 'Quantum') {
      return 'Name the identity state behind $title, then take one grounded action that proves that state before the day ends.';
    }
    if (category == 'Stoicism') {
      return 'Run $title through two columns: "mine to choose" and "not mine to control." Act on one item from the first column today.';
    }
    if (category == 'Discipline') {
      return 'Make $title practical by choosing a two-minute version of the behavior and doing it today before negotiating with your mood.';
    }
    if (category == 'Time Mgmt') {
      return 'Use $title to design tomorrow: place one priority block, one recovery block, and one admin block on the calendar before bed.';
    }
    if (category == 'Confidence') {
      return 'Choose one small brave action related to $title. Do it imperfectly, then write one piece of evidence that you handled more than fear predicted.';
    }
    if (category == 'Career Change') {
      return 'Write down the one thing not working in your current path and one small, low-risk way to test the alternative this month — a conversation, a shadow day, or a short course.';
    }
    if (category == 'Entrepreneurship') {
      return 'Turn $title into one market test: describe who you help, with what problem, and how — then share it with one real potential customer for honest feedback.';
    }
    if (category == 'Family') {
      return 'Apply $title to one family relationship this week: choose a small, repeatable behavior that would make the relationship feel safer or more connected.';
    }
    if (category == 'Fitness') {
      return 'Schedule one $focus session in the next two days. Keep it short enough that missing it would feel like a genuine loss, not a relief.';
    }
    if (category == 'Goals') {
      return 'Write $title as one goal, one milestone for this month, and one action you will take today. Put the action on your calendar now.';
    }
    if (category == 'Mental Health') {
      return 'Choose one small, supportive action related to $title today — reaching out, resting, moving, or writing down what you\'re feeling — and note how your state shifts afterward.';
    }
    if (category == 'Mini Course') {
      return 'Before moving to the next lesson, apply today\'s idea on $title to one real situation and write down what happened.';
    }
    if (category == 'Practices') {
      return 'Choose the smallest version of $title you can realistically repeat daily, and do it once today before deciding whether to expand it.';
    }
    if (category == 'Saving') {
      return 'Set up one small, automatic transfer toward savings today, even if the amount feels insignificant. Consistency matters more than size at the start.';
    }
    if (category == 'Self-Discovery') {
      return 'Write about $title using one real situation from the last week. Note what it reveals about what you actually value, then look for whether the same pattern shows up elsewhere in your life.';
    }
    return 'Turn $title into one visible behavior today. Keep it small enough to complete, specific enough to measure, and tied directly to $focus.';
  }

  String get _actionFocus {
    final cleanDescription = description
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll('.', '')
        .trim();
    if (cleanDescription.isEmpty) {
      return title.toLowerCase();
    }
    return cleanDescription[0].toLowerCase() + cleanDescription.substring(1);
  }

  String? get _topicAction {
    final normalized = title.toLowerCase();
    if (normalized.contains('quantum manifestation')) {
      return 'Sit in stillness for 5 minutes, visualize your desired reality as ALREADY existing in the quantum field, feel its elevated frequency in your chest, and take one bold action today aligned with that frequency.';
    }
    if (normalized.contains('observer effect')) {
      return 'Spend 5 minutes observing your thoughts without judgment. Whenever a limiting thought arises, consciously shift your observation to your desired state, collapsing that positive potential into reality.';
    }
    if (normalized.contains('quantum achievement')) {
      return 'Identify one "quantum leap" goal. Write down the identity of the person who has already achieved it, and perform one action today strictly as that future identity.';
    }
    if (normalized.contains('quantum enlightenment')) {
      return 'Spend 10 minutes in silent meditation, holding the awareness that your consciousness is connected to all creation. Write down one intuitive insight that arises.';
    }
    if (normalized.contains('body gratitude')) {
      return 'Stand in front of a mirror and thank three specific body parts for what they help you do. Then choose one supportive action for your body today.';
    }
    if (normalized.contains('healthy identity')) {
      return 'Write down three core beliefs of your healthiest self. Act on one of those beliefs today by preparing a clean meal or committing to movement.';
    }
    if (normalized.contains('future self letter')) {
      return 'Write 150 words from your healthiest future self. Include one warning, one encouragement, and one habit they want you to begin this week.';
    }
    if (normalized.contains('cellular healing')) {
      return 'Spend five minutes breathing slowly while picturing one part of your body receiving care, oxygen, and repair. Afterwards, drink water and rest your screen-heavy inputs for ten minutes.';
    }
    if (normalized.contains('law of attraction for health')) {
      return 'State five positive health declarations in the present tense (e.g. "My body is vibrant, strong, and healing"). Feel the truth of each statement deeply.';
    }
    if (normalized.contains('affirmations for healing')) {
      return 'Record your voice reciting three empowering healing affirmations, then listen to the recording twice while resting deeply.';
    }
    if (normalized.contains('stress and your nervous system')) {
      return 'Notice one stress signal in your body today. Name it, exhale slowly for six rounds, and write what helped your system settle by even 5%.';
    }
    if (normalized.contains('mind-body')) {
      return 'Choose one physical symptom or energy dip and write what emotion, thought, or pressure may be connected to it. Pick one gentle response instead of forcing through.';
    }
    if (normalized.contains('anti-inflammatory')) {
      return 'Build one anti-inflammatory plate today with colorful plants, protein, healthy fat, and water. Note any difference in bloating, mood, or energy.';
    }
    if (normalized.contains('intermittent fasting')) {
      return 'Choose a gentle eating window that still supports your energy. Write your start time, end time, and the symptom that would tell you to stop or adjust.';
    }
    if (normalized.contains('gut-brain')) {
      return 'Add one gut-supportive food today, such as fermented food or fiber-rich plants, and record whether cravings, mood, or focus changes afterwards.';
    }
    if (normalized.contains('cold exposure')) {
      return 'End one shower with 20 to 30 seconds of cool water while keeping your breath steady. Stop early if your breathing becomes panicked.';
    }
    if (normalized.contains('microbiome')) {
      return 'List three foods you eat often and mark whether they feed or weaken your microbiome. Upgrade one repeat food this week.';
    }
    if (normalized.contains('nervous system regulation')) {
      return 'Create a two-minute regulation menu: one breath practice, one grounding practice, and one movement practice. Use one before your next reactive decision.';
    }
    if (normalized.contains('blue zones')) {
      return 'Borrow one Blue Zones habit today: walk after a meal, eat more plants, call someone, or connect the day to a clear purpose.';
    }
    if (normalized.contains('abundance visualization')) {
      return 'Visualize one ordinary money moment feeling calm and handled, then take one practical step: check a balance, schedule a payment, or move a small amount to savings.';
    }
    if (normalized.contains('money affirmations')) {
      return 'Write three powerful financial abundance statements on a card and place it where you will see it multiple times today.';
    }
    if (normalized.contains('living in abundance')) {
      return 'Identify one area where you felt scarcity today and intentionally reframe it by listing three abundant resources you currently possess.';
    }
    if (normalized.contains('generosity frequency')) {
      return 'Perform one anonymous or selfless act of generosity today—whether sharing knowledge, a genuine compliment, or a helpful resource.';
    }
    if (normalized.contains('money story')) {
      return 'Complete this sentence five times: "Money meant ___ in my home." Circle one belief you are ready to update.';
    }
    if (normalized.contains('stock market')) {
      return 'Look up one broad market index and write what it represents, what risk it carries, and why buying one company is different from buying a basket.';
    }
    if (normalized.contains('index funds')) {
      return 'Compare two index funds on fees, holdings, and long-term purpose. Do not buy today; simply learn what the differences mean.';
    }
    if (normalized.contains('emergency fund')) {
      return 'Set a starter emergency fund target. Choose the first amount, however small, and schedule when it will move out of everyday spending.';
    }
    if (normalized.contains('apology')) {
      return 'Write a real apology in four parts: what I did, how it affected you, what I understand now, and what I will do differently.';
    }
    if (normalized.contains('active listening')) {
      return 'In one conversation today, summarize what the other person said before giving your view. Ask, "Did I get that right?"';
    }
    if (normalized.contains('boundaries')) {
      return 'Write one boundary as a behavior, not a complaint: "I can do X, but I cannot do Y." Practice saying it out loud once.';
    }
    if (normalized.contains('first date')) {
      return 'Before a date or conversation, write two questions that reveal values and one thing you want to notice about how you feel around them.';
    }
    if (normalized.contains('body language')) {
      return 'Observe one conversation without interrupting. Notice posture, pace, eye contact, and tension, then compare those cues with the words being spoken.';
    }
    if (normalized.contains('imposter')) {
      return 'Write the evidence for and against the thought "I am not qualified." Then write one grounded sentence that is more accurate than the fear.';
    }
    if (normalized.contains('public speaking')) {
      return 'Record yourself giving a 60-second explanation of one idea. Replay it once and improve only your opening sentence.';
    }
    if (normalized.contains('deep work')) {
      return 'Choose tomorrow\'s first deep-work block tonight. Put your phone away, define the output, and start with the hardest five minutes.';
    }
    if (normalized.contains('email') || normalized.contains('slack')) {
      return 'Choose two message-checking windows tomorrow and write them down. Outside those windows, keep notifications off for one focused block.';
    }
    if (normalized.contains('morning spiritual')) {
      return 'Create a five-minute morning practice: one breath, one intention, one gratitude, and one action that would make the day meaningful.';
    }
    if (normalized.contains('gratitude')) {
      return 'Write three gratitudes, then add why each one matters. Let the "why" turn the list into a felt practice.';
    }
    if (normalized.contains('flow states')) {
      return 'Pick one task with clear challenge and clear feedback. Remove interruptions for 30 minutes and start with a tiny warm-up.';
    }
    if (normalized.contains('presence')) {
      return 'Set a three-minute timer and do one ordinary thing with full attention: drinking, walking, washing, or listening.';
    }
    if (normalized.contains('ritual')) {
      return 'Design one tiny ritual around a transition you usually rush: waking, starting work, eating, or ending the day.';
    }
    if (normalized.contains('silence')) {
      return 'Take ten minutes without input today. No phone, audio, reading, or task. Afterwards, write what surfaced.';
    }
    if (normalized.contains('memento mori')) {
      return 'Write one sentence: "If I remembered life was finite today, I would stop delaying ___." Then act on the smallest version of it.';
    }
    if (normalized.contains('growth mindset')) {
      return 'Choose one skill you have labelled yourself bad at. Add the word "yet" and schedule a ten-minute practice session.';
    }
    if (normalized.contains('self-compassion')) {
      return 'Write to yourself as you would to a friend facing the same problem. Include understanding, responsibility, and one next step.';
    }
    if (normalized.contains('procrastination')) {
      return 'Start the avoided task for exactly two minutes. Your win condition is opening the loop, not finishing the whole thing.';
    }
    if (normalized.contains('eisenhower')) {
      return 'Sort today\'s tasks into urgent-important, important-not urgent, urgent-not important, and neither. Protect one important-not urgent task.';
    }
    if (normalized.contains('time blocking')) {
      return 'Block tomorrow in three named chunks: build, maintain, recover. Put one realistic outcome beside each chunk.';
    }
    if (normalized.contains('power of "no"')) {
      return 'Choose one request, habit, or distraction that deserves a respectful no. Write the sentence before you need it.';
    }
    return null;
  }

  Widget _buildArticleSection(BuildContext context, _ArticleSection section) {
    final isActionStep = section.title == 'Action Step';
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: isActionStep ? const EdgeInsets.all(18) : EdgeInsets.zero,
      decoration: isActionStep
          ? BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.28)),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.title,
            style: GoogleFonts.outfit(
              color: isActionStep
                  ? color
                  : Theme.of(context).colorScheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            section.body,
            style: GoogleFonts.outfit(
              color: Theme.of(context).colorScheme.onSurface.withAlpha(160),
              fontSize: 16,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentParagraph(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Text(
        text,
        style: GoogleFonts.outfit(
          color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
          fontSize: 16,
          height: 1.6,
        ),
      ),
    );
  }

  static const Map<String, String> _topicWatchPoints = {
    // Health -> Manifestation
    'body gratitude meditation':
        'Be mindful to ground your gratitude in real love for your physical body, avoiding mechanical repetition or body judgment.',
    'healthy identity visualization':
        'Ensure your visual practice is paired with loving daily self-care rather than perfectionist self-criticism.',
    'future self letter':
        'Write from deep compassion and inspiration rather than using your future self\'s success to diminish where you are now.',
    'cellular healing visualization':
        'Hold the vision of radiant cell-level energy with complete faith while continuing to nurture your body with clean habits.',
    'the power of visualization':
        'Stay fully present in the elevated feeling during visualization; the feeling of state-fulfillment is what magnetizes the outcome.',
    'law of attraction for health':
        'Keep your attention centered entirely on vibrant vitality rather than giving energy to fear of illness or physical decay.',
    'affirmations for healing':
        'Speak your healing affirmations with genuine feeling and conviction so your subconscious accepts them as current truth.',

    // Health -> Psychology
    'cognitive behavioral therapy basics':
        'Notice automatic mental patterns without self-judgment; awareness is the doorway to choosing empowering thoughts.',
    'mindfulness and stress reduction':
        'Allow feelings to move through you freely; mindfulness is presence with what is, not forcing quietness.',
    'the mind-body connection':
        'Honor the deep intelligence of your physical body when it sends signals; treat symptoms as sacred messages to adjust your state.',
    'the habits of exceptionally healthy people':
        'Build healthy habits sequentially with joy rather than overwhelming yourself with a drastic lifestyle overhaul.',
    'stress and your nervous system':
        'Focus on gentle, soothing sensory resets rather than over-analyzing every nervous system response.',
    'psychological resilience':
        'Remember that true resilience includes deep rest, vulnerability, and honoring your biological need for recovery.',
    '30-day fitness journey':
        'Celebrate small daily movement wins rather than comparing your current physical pace to long-term goals.',
    'sleep better tonight':
        'Create a peaceful evening sanctuary without watching the clock or stressing about exact sleep hours.',
    'plant-based nutrition guide':
        'Enjoy the abundant variety of plant foods rather than focusing on restrictive eating rules.',
    'gut health revolution':
        'Nurture your internal ecosystem with diverse whole foods and calm presence during mealtime.',
    'home workout essentials':
        'Focus on clean technique and joyful movement rather than pushing past joint pain or fatigue.',
    'yoga for beginners':
        'Listen to your body\'s natural limits in every pose; yoga is a personal practice of breath and presence.',
    'managing anxiety naturally':
        'Breathe deeply and remind yourself that anxiety is temporary energy passing through your physical vessel.',
    'depression recovery guide':
        'Be profoundly gentle with yourself; celebrate every small step forward as a victory of self-care.',

    // Health -> Nutrition & Biohacking & Longevity
    'the anti-inflammatory diet':
        'Focus on adding vibrant, anti-inflammatory whole foods rather than obsessing over strict dietary restrictions.',
    'intermittent fasting guide':
        'Listen to your body\'s energy signals during fasting, keeping your hydration and recovery optimal.',
    'metabolic health 101':
        'Build balanced meals with fiber, protein, and healthy fats to support steady energy and cellular health.',
    'the gut-brain axis':
        'Feed your microbiome whole foods and practice stress reduction to optimize the gut-brain energy line.',
    'cold exposure protocols':
        'Begin cold exposure gradually, maintaining calm breath and honoring your body\'s physiological limits.',
    'optimizing your microbiome':
        'Prioritize a diverse range of plant fibers and fermented foods to cultivate a thriving inner ecosystem.',
    'nervous system regulation':
        'Use gentle breathing and grounding rituals to shift your nervous system into peaceful recovery mode.',
    'light & mitochondrial health':
        'Get natural morning sunlight daily to synchronize your circadian rhythm and boost cellular energy.',
    'the science of aging':
        'Focus on expanding your healthspan through vibrant daily habits rather than fearing the passage of time.',
    'zone 2 training for life':
        'Maintain a steady, conversational pace in Zone 2 to build mitochondrial capacity without overtraining.',
    'blue zones lessons':
        'Integrate natural movement, plant-rich nutrition, and strong community into your daily rhythm.',
    'supplementation for longevity':
        'Focus first on foundational sleep, nutrition, and movement before layering in targeted longevity supplements.',

    // Wealth -> Manifestation
    'abundance visualization':
        'Focus on the deep feeling of financial freedom and peace rather than worrying about the exact timeline of how it arrives.',
    'money affirmations practice':
        'Repeat your financial affirmations in an energetic state of gratitude, feeling the reality of prosperity now.',
    'living in abundance':
        'Shift your perspective from scarcity to endless possibility; notice the wealth already present around you.',
    'the generosity frequency':
        'Give and invest with joy and open hands, knowing that abundance flows infinitely when circulated.',
    'manifesting financial abundance':
        'Align your thoughts, feelings, and actions with prosperity; release subconscious scarcity programming completely.',
    'the science of getting rich':
        'Focus your mind on creating real value with certainty of purpose rather than competing or operating out of fear.',
    'wealth affirmations daily':
        'Anchor each affirmation in your body as felt truth so your identity expands to hold higher wealth.',
    'money mindset makeover':
        'Release old inherited stories about money; claim your sovereign right to create and enjoy financial abundance.',

    // Wealth -> Psychology
    'the psychology of money':
        'Separate your personal self-worth from temporary net worth fluctuations; stay grounded in your wealth vision.',
    'your money story':
        'Acknowledge past financial patterns with forgiveness as you consciously write an empowered financial chapter.',
    'delayed gratification as a skill':
        'Frame delayed gratification as choosing your ultimate freedom over temporary short-term distraction.',
    'wealth identity shift':
        'Allow yourself to feel completely comfortable receiving, holding, and multiplying larger sums of wealth.',
    'behavioral finance fundamentals':
        'Recognize emotional spending triggers early so you can respond with calm financial sovereignty.',
    'overcoming financial fear':
        'Replace financial anxiety with systematic knowledge, clear planning, and strong faith in your capacity.',

    // Wealth -> Investing
    'stock market basics':
        'Maintain a steady, long-term horizon; avoid letting short-term market noise disrupt your investment strategy.',
    'the power of index funds':
        'Trust the long-term compounding of broad asset growth rather than chasing volatile speculative trends.',
    'real estate for beginners':
        'Conduct thorough due diligence and build conservative financial buffers before purchasing physical assets.',
    'compound interest mastery':
        'Never underestimate the exponential momentum of time; start compounding your resources immediately.',
    'real estate investing':
        'Factor in management, maintenance, and liquidity needs so your physical property investments stay profitable.',
    'emergency fund essentials':
        'Keep your emergency reserves liquid and distinct so they serve as an unshakeable fortress of peace.',
    'retirement planning early':
        'Automate your wealth contributions early so freedom becomes an inevitable mathematical reality.',

    // Wealth -> Side Hustles
    'finding your side hustle':
        'Choose a market offer at the intersection of your natural strengths and genuine customer demand.',
    'scaling small projects':
        'Systematize core processes before expanding so growth increases your freedom rather than your workload.',
    'passive income realities':
        'Front-load high-quality creation and smart systems so your assets generate income continuously.',
    'digital product blueprint':
        'Validate customer demand early with a simple initial offer before spending months building complex assets.',
    'starting your online business':
        'Focus on solving one specific problem exceptionally well before expanding your product line.',
    'side hustle mastery':
        'Manage your time boundaries carefully so your side business fuels your life without causing exhaustion.',

    // Wealth -> Budgeting
    'the 50/30/20 rule':
        'Adapt framework percentages flexibly to serve your current life stage while protecting your savings rate.',
    'automation for wealth':
        'Review automated transfers periodically to ensure your banking infrastructure supports your evolving goals.',
    'managing debt effectivly':
        'Focus on systematic payoff momentum while protecting your cash flow and avoiding new debt.',
    'strategic tax planning':
        'Align your financial structures legally and intelligently to retain maximum earnings for compounding.',

    // Relationships -> Manifestation
    'ideal relationship visualization':
        'Focus on the emotional quality, safety, and mutual support of the connection rather than superficial checklists.',
    'loving-kindness meditation':
        'Radiate unconditional love outward while keeping your personal boundaries clear and self-respecting.',
    'heart opening practice':
        'Allow your heart energy to expand naturally while maintaining discernment about where you invest trust.',
    'attracting your soul circle':
        'Embody the qualities of the community you seek; vibrationally like attracts like.',
    'manifesting your soulmate':
        'Become the loving, grounded partner you wish to meet; align your identity with harmonious love.',
    'loving affirmations':
        'Feel the warmth and truth of love filling your relationship field as you speak your affirmations.',
    'visualizing your ideal relationship':
        'Hold the vivid feeling of sacred partnership, letting it guide how you treat yourself and others.',

    // Relationships -> Psychology & Resolution & Dating & Social
    'the 5 love languages':
        'Express love in your partner\'s preferred style rather than expecting them to receive it only in yours.',
    'attachment theory explained':
        'Use attachment awareness as a roadmap for developing earned security rather than a rigid excuse.',
    'boundaries as self-love':
        'State boundaries clearly as self-respecting behavioral standards rather than attempts to control others.',
    'the shadow in relationships':
        'Observe your interpersonal triggers as mirrors revealing unintegrated parts of your own psyche.',
    'the art of apology':
        'Offer sincere accountability for the impact of your actions without defensive explanations or excuses.',
    'active listening drills':
        'Listen with full presence to understand the other person\'s experience before offering your perspective.',
    'expressing needs clearly':
        'State your requests directly and vulnerably rather than assuming others can read your mind.',
    'the de-escalation protocol':
        'Pause and restore nervous system calm before attempting to resolve intense emotional disagreements.',
    'authenticity in attraction':
        'Show up genuinely as your true self; magnetic attraction naturally filters for compatible matches.',
    'first date dynamics':
        'Enjoy discovering whether you genuinely connect with their spirit rather than performing to be liked.',
    'the science of charisma':
        'Combine deep attention, authentic warmth, and grounded presence to radiate natural magnetic charisma.',
    'intentional dating blueprint':
        'Maintain your core values and relationship standards even when feelings of chemistry are intense.',
    'masters of conversation':
        'Balance curious questions with warm self-disclosure to create a natural, mutual conversational flow.',
    'reading body language':
        'Observe non-verbal cues in complete context rather than jumping to conclusions based on a single gesture.',
    'network with integrity':
        'Focus on building authentic human friendships and mutual value rather than transactional networking.',
    'the art of directness':
        'Deliver clear truth with profound empathy and respect so your directness builds deeper trust.',

    // Career -> All Subcategories
    'dream career visualization':
        'Pair your inspiring career vision with consistent skill development and proactive professional action.',
    'calling vs career':
        'Recognize that purpose can be expressed through any work when you bring craftsmanship and service to it.',
    'abundant work mindset':
        'Celebrate market opportunities and peer success knowing that creative value is infinite.',
    'professional identity shift':
        'Anchor your identity in your innate capability and adaptability rather than a temporary job title.',
    'imposter syndrome decoded':
        'Recognize imposter feelings as a sign that you are expanding into higher levels of growth.',
    'strengths-based leadership':
        'Lead from your natural zones of genius while surrounding yourself with complementary team talent.',
    'the paradox of choice in careers':
        'Choose a promising direction with commitment; mastery and passion develop through deep execution.',
    'growth vs fixed professionalism':
        'Embrace challenges and feedback as fuel for expanding your professional capabilities.',
    'servant leadership foundations':
        'Support your team\'s growth and success while holding high standards of shared accountability.',
    'radical candor in teams':
        'Deliver direct feedback with genuine personal care so your team feels supported in their growth.',
    'decision-making frameworks':
        'Apply clear criteria to make swift decisions, knowing that momentum beats perfection.',
    'building psychological safety':
        'Encourage honest communication and risk-taking while maintaining high performance standards.',
    'public speaking mastery':
        'Focus on serving your audience with clear value; genuine connection matters far more than perfection.',
    'the art of storytelling':
        'Use vivid narratives to highlight core truths while keeping facts accurate and clear.',
    'presentation design':
        'Keep visual slides minimal and impactful so they amplify rather than distract from your spoken message.',
    'command the room':
        'Anchor your presence in deep breathing and authentic conviction to project natural authority.',
    'deep work strategies':
        'Protect your focus blocks fiercely from digital interruptions to produce extraordinary results.',
    'the 80/20 of workflow':
        'Focus your prime energy on the vital few tasks that generate the vast majority of your career impact.',
    'email & slack management':
        'Set intentional communication windows so asynchronous messages don\'t dictate your workday flow.',
    'energy management mastery':
        'Match your most demanding tasks to your natural daily energy peaks for effortless high performance.',

    // Spiritual -> All Subcategories
    'morning spiritual practice':
        'Keep your morning ritual vibrant and deeply meaningful rather than letting it become a rigid task.',
    'gratitude as spiritual practice':
        'Allow gratitude to open your heart to the sacred grace present in ordinary moments.',
    'manifesting your purpose':
        'Listen to your quiet inner calling and take daily steps toward what brings you alive.',
    'ego vs soul alignment':
        'Choose choices that bring expansive inner peace over choices driven by temporary ego validation.',
    'the science of flow states':
        'Establish clear goals and zero distraction, allowing flow to emerge naturally.',
    'transcendence and well-being':
        'Integrate mystical insights and feelings of awe into compassionate daily actions in the physical world.',
    'the power of presence':
        'Bring your complete awareness into the present moment where all creation and power reside.',
    'the psychology of belief':
        'Hold empowering spiritual beliefs that expand love, connection, and human unity.',
    'ancient wisdom for modern life':
        'Extract core philosophical principles and apply them wisely to modern challenges.',
    'the power of ritual':
        'Infuse your routines with conscious intention so everyday moments become sacred rituals.',
    'sacred geometry foundations':
        'Appreciate the sublime mathematical harmony reflected in nature and universal form.',
    'the wisdom of silence':
        'Use periods of quiet reflection to listen to your inner voice and recharge your spiritual energy.',
    'quantum manifestation':
        'Be mindful to maintain your high vibrational frequency; falling back into doubt or low-frequency anxiety can temporarily disrupt your quantum alignment.',
    'the observer effect':
        'Remember that your consciousness is constantly observing and collapsing reality; stay acutely aware of what thoughts you allow your focus to linger on.',
    'quantum achievement':
        'Avoid doubting the speed of quantum leaps; when your identity fully shifts, external reality often transforms far faster than logical expectation predicts.',
    'quantum enlightenment':
        'Stay centered in profound humility and gratitude as you tap into universal oneness; divine wisdom elevates service to others rather than ego.',
    'stoic mindset training':
        'Focus your mind exclusively on what is in your control, releasing outer circumstances with peace.',
    'the obstacle is the way':
        'View every challenge as a divine opportunity to forge character, patience, and inner strength.',
    'daily stoic reflections':
        'Use morning and evening review to align your daily choices with wisdom, justice, courage, and moderation.',
    'memento mori':
        'Let the awareness of life\'s finite nature clarify what truly matters, inspiring you to live fully now.',

    // Personal / Growth -> All Subcategories
    'identity bucket list':
        'Focus on who you are becoming with self-love, allowing your elevated identity to attract experiences.',
    'future self visualization':
        'Receive guidance from your future self while honoring and loving the present version of you.',
    'limiting belief removal':
        'Replace restrictive thoughts with expansive, empowering truths through persistent repetition.',
    'the power of "as-if"':
        'Embody the energy, posture, and decisions of your desired state with joy and authenticity.',
    'the growth mindset advantage':
        'Pair your belief in human growth with effective strategies and consistent feedback.',
    'emotional intelligence 101':
        'Use emotional self-awareness to navigate interactions with empathy, wisdom, and tact.',
    'the power of self-compassion':
        'Treat yourself with the same deep understanding and encouragement you give a dear friend.',
    'cognitive reframing':
        'Find the empowering perspective in any situation while allowing space to process true emotions.',
    'the discipline blueprint':
        'Build discipline through self-respect and supportive habits rather than harsh self-punishment.',
    'building unbreakable habits':
        'Focus on establishing small daily habit streaks until the momentum becomes effortless.',
    'overcoming procrastination':
        'Lower the barrier to entry and start for just two minutes; momentum will carry you forward.',
    'the 2-minute rule':
        'Master the art of showing up consistently before focusing on the duration of your habit.',
    'time auditing for growth':
        'Audit your time spend with honest curiosity, using the data to reclaim hours for your priorities.',
    'the eisenhower matrix':
        'Protect your time for non-urgent, high-importance goals that build your long-term legacy.',
    'time blocking mastery':
        'Schedule realistic blocks for priority work, admin, and deep recovery to maintain peak energy.',
    'productive solitude':
        'Embrace quiet solitude as a powerful space for mental clarity, creativity, and inner renewal.',
    'confidence from competence':
        'Take immediate action; building competence through practice naturally creates unshakable confidence.',
    'the power of "no"':
        'Deliver a clear, respectful "no" to secondary requests so you can say a full "yes" to your purpose.',
    'self-image reconstruction':
        'Supply your mind with daily evidence of your growth to lock in your updated self-image.',
    'radical self-acceptance':
        'Fully embrace who you are today as the solid foundation from which all future growth expands.',
  };
}

class _ArticleSection {
  final String title;
  final String body;

  const _ArticleSection(this.title, this.body);
}
