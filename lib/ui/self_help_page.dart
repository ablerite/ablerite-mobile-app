import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/cupertino.dart';
import 'self_help_article_view.dart';
import 'self_help_course_view.dart';

class SelfHelpPage extends StatefulWidget {
  final bool showHomeInitially;

  const SelfHelpPage({super.key, this.showHomeInitially = true});

  @override
  State<SelfHelpPage> createState() => _SelfHelpPageState();
}

class _SelfHelpPageState extends State<SelfHelpPage> {
  String? _selectedCategory;
  late bool _showHome;

  @override
  void initState() {
    super.initState();
    _showHome = widget.showHomeInitially;
  }

  static const Map<String, String> _categoryPreviews = {
    'health':
        'Strengthen your body, energy, nutrition, resilience, and long-term wellbeing with practical lessons and mindset work.',
    'wealth':
        'Build financial confidence through money psychology, investing, budgeting, side income, and abundance practice.',
    'relationships':
        'Improve connection, communication, dating, conflict repair, and the patterns that shape healthier relationships.',
    'career':
        'Develop professional confidence through leadership, productivity, communication, performance, and career vision.',
    'spiritual':
        'Explore purpose, presence, wisdom, stoic tools, manifestation, and deeper inner development.',
    'personal':
        'Build habits, discipline, time mastery, self-image, confidence, and the identity behind lasting growth.',
  };

  Color _categoryColor(String id, BuildContext context) {
    final index = _categories.indexWhere((category) => category['id'] == id);
    return _themeStackColor(context, index < 0 ? 0 : index);
  }

  void _showCategoryPreview(Map<String, dynamic> category) {
    final id = category['id'] as String;
    final color = _categoryColor(id, context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _WalletPreviewSheet(
          title: category['title'],
          subtitle: category['subtitle'],
          description: _categoryPreviews[id] ?? '',
          color: color,
          glyph: category['glyph'],
          actionLabel: 'Enter ${category['title']}',
          onAction: () {
            Navigator.pop(sheetContext);
            setState(() => _selectedCategory = id);
          },
        );
      },
    );
  }

  final List<Map<String, dynamic>> _categories = [
    {
      'id': 'health',
      'title': 'Health',
      'subtitle': 'Holistic wellbeing',
      'icon': CupertinoIcons.heart_fill,
      'glyph': 'health',
    },
    {
      'id': 'wealth',
      'title': 'Wealth',
      'subtitle': 'Financial abundance',
      'icon': Icons.diamond,
      'glyph': 'wealth',
    },
    {
      'id': 'relationships',
      'title': 'Relationships',
      'subtitle': 'Connections',
      'icon': CupertinoIcons.person_2_fill,
      'glyph': 'relationships',
    },
    {
      'id': 'career',
      'title': 'Career',
      'subtitle': 'Professional growth',
      'icon': CupertinoIcons.briefcase_fill,
      'glyph': 'career',
    },
    {
      'id': 'spiritual',
      'title': 'Spiritual',
      'subtitle': 'Inner development',
      'icon': CupertinoIcons.sparkles,
      'glyph': 'spiritual',
    },
    {
      'id': 'personal',
      'title': 'Growth',
      'subtitle': 'Become your best self',
      'icon': CupertinoIcons.arrow_up_circle_fill,
      'glyph': 'growth',
    },
  ];

  @override
  Widget build(BuildContext context) {
    if (_showHome) {
      return _SelfHelpHomePage(
        onStart: () => setState(() => _showHome = false),
      );
    }

    if (_selectedCategory != null) {
      final category = _categories.firstWhere(
        (c) => c['id'] == _selectedCategory,
      );
      return _CategoryDetailPage(
        category: category,
        color: _categoryColor(category['id'], context),
        onBack: () => setState(() => _selectedCategory = null),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () {
            if (widget.showHomeInitially) {
              setState(() => _showHome = true);
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          'Self Help',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.search,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const _SelfHelpSearchPage(),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(
                  top: 8.0,
                  bottom: 24.0,
                  left: 8.0,
                ),
                child: Text(
                  'Your personal development library.',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    color: Colors.grey[400],
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 28),
                  child: _StackedIndexCardList(
                    itemCount: _categories.length,
                    onTap: (index) => _showCategoryPreview(_categories[index]),
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      return _CategoryCard(
                        category: category,
                        color: _categoryColor(category['id'], context),
                      );
                    },
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

class _SelfHelpHomePage extends StatelessWidget {
  final VoidCallback onStart;

  const _SelfHelpHomePage({required this.onStart});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Self Help Courses',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 24),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 10, left: 8),
                child: Text(
                  'Choose the area you want to strengthen.',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withAlpha(150),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: primary.withAlpha(46)),
                    boxShadow: [
                      BoxShadow(
                        color: primary.withAlpha(16),
                        blurRadius: 14,
                        offset: const Offset(0, 7),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AspectRatio(
                        aspectRatio: 16 / 9,
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                          child: ColoredBox(
                            color: Theme.of(context).colorScheme.surface,
                            child: Image.asset(
                              'assets/images/app_banners/selfhelp.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Structured support',
                                style: GoogleFonts.outfit(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 7),
                              Text(
                                'Learning gives you a clearer way to understand yourself, change old patterns, and practise better choices in daily life.\n\nThese courses turn personal development into small, focused lessons across health, wealth, connections, career, spirituality, and growth.\n\nUse them as a steady place to return to whenever you want practical guidance, fresh perspective, and a more intentional next step. Build confidence through repetition, reflection, and simple actions you can actually use.',
                                style: GoogleFonts.outfit(
                                  fontSize: 12.35,
                                  height: 1.21,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withAlpha(180),
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
              const SizedBox(height: 10),
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
                      const Icon(
                        CupertinoIcons.square_grid_2x2_fill,
                        color: Colors.white,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Browse Courses',
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
      ),
    );
  }
}

class _SelfHelpSearchPage extends StatefulWidget {
  const _SelfHelpSearchPage();

  @override
  State<_SelfHelpSearchPage> createState() => _SelfHelpSearchPageState();
}

class _SelfHelpSearchPageState extends State<_SelfHelpSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  final List<Map<String, dynamic>> _allContent = [
    // Health - Manifestation
    {
      'title': 'The Power of Visualization',
      'category': 'Health',
      'section': 'Manifestation',
      'tags': [
        'visualization',
        'imagery',
        'goal setting',
        'mindfulness',
        'relaxation',
      ],
      'desc':
          'Learn how to use mental imagery to manifest your health goals and promote healing.',
      'isCourse': true,
    },
    {
      'title': 'Law of Attraction for Health',
      'category': 'Health',
      'section': 'Manifestation',
      'tags': [
        'law of attraction',
        'positive thinking',
        'abundance',
        'beliefs',
        'manifesting',
      ],
      'desc':
          'Apply the law of attraction to create vibrant health and wellness.',
      'isCourse': false,
    },
    {
      'title': 'Affirmations for Healing',
      'category': 'Health',
      'section': 'Manifestation',
      'tags': [
        'affirmations',
        'healing',
        'positive self-talk',
        'self-love',
        'wellness',
      ],
      'desc': 'Transform your mindset with powerful healing affirmations.',
      'isCourse': false,
    },
    // Health - Psychology
    {
      'title': 'Cognitive Behavioral Therapy Basics',
      'category': 'Health',
      'section': 'Psychology',
      'tags': [
        'CBT',
        'thoughts',
        'behaviors',
        'mental health',
        'therapy',
        'cognitive',
      ],
      'desc':
          'Understand how your thoughts shape your health behaviors and outcomes.',
      'isCourse': true,
    },
    {
      'title': 'Mindfulness and Stress Reduction',
      'category': 'Health',
      'section': 'Psychology',
      'tags': [
        'mindfulness',
        'stress',
        'meditation',
        'relaxation',
        'awareness',
      ],
      'desc':
          'Practice mindfulness techniques to reduce stress and improve immunity.',
      'isCourse': true,
    },
    {
      'title': 'The Mind-Body Connection',
      'category': 'Health',
      'section': 'Psychology',
      'tags': [
        'mind-body',
        'psychosomatic',
        'holistic',
        'wellness',
        'intuition',
      ],
      'desc':
          'Explore how your thoughts and emotions directly impact your physical health.',
      'isCourse': false,
    },
    // Health - Mini Courses
    {
      'title': '30-Day Fitness Journey',
      'category': 'Health',
      'section': 'Mini Course',
      'tags': [
        'fitness',
        'exercise',
        'workout',
        'strength',
        'endurance',
        '30 days',
      ],
      'desc': 'A progressive 30-day program to build lasting fitness habits.',
      'isCourse': true,
    },
    {
      'title': 'Sleep Better Tonight',
      'category': 'Health',
      'section': 'Mini Course',
      'tags': [
        'sleep',
        'insomnia',
        'rest',
        'recovery',
        'relaxation',
        'bedtime',
      ],
      'desc': 'Improve your sleep quality with science-backed techniques.',
      'isCourse': true,
    },
    // Health - Nutrition
    {
      'title': 'Plant-Based Nutrition Guide',
      'category': 'Health',
      'section': 'Nutrition',
      'tags': [
        'vegan',
        'plants',
        'diet',
        'vitamins',
        'minerals',
        'whole foods',
      ],
      'desc':
          'Transition to a nutrient-rich plant-based diet for optimal vitality.',
      'isCourse': true,
    },
    {
      'title': 'Gut Health Revolution',
      'category': 'Health',
      'section': 'Nutrition',
      'tags': [
        'gut',
        'probiotics',
        'digestion',
        'microbiome',
        'intestines',
        'bacteria',
      ],
      'desc':
          'Heal your gut and transform your overall health from the inside out.',
      'isCourse': false,
    },
    // Health - Fitness
    {
      'title': 'Home Workout Essentials',
      'category': 'Health',
      'section': 'Fitness',
      'tags': [
        'home workout',
        'bodyweight',
        'exercise',
        'strength',
        'no equipment',
      ],
      'desc': 'Build strength and endurance with no gym required.',
      'isCourse': false,
    },
    {
      'title': 'Yoga for Beginners',
      'category': 'Health',
      'section': 'Fitness',
      'tags': [
        'yoga',
        'stretching',
        'flexibility',
        'poses',
        'breathing',
        'beginners',
      ],
      'desc':
          'Start your yoga practice with foundational poses and breathing techniques.',
      'isCourse': true,
    },
    // Health - Mental Health
    {
      'title': 'Managing Anxiety Naturally',
      'category': 'Health',
      'section': 'Mental Health',
      'tags': ['anxiety', 'panic', 'worry', 'fear', 'calm', 'natural remedies'],
      'desc': 'Coping strategies for anxiety without medication.',
      'isCourse': false,
    },
    {
      'title': 'Depression Recovery Guide',
      'category': 'Health',
      'section': 'Mental Health',
      'tags': [
        'depression',
        'sadness',
        'low mood',
        'support',
        'therapy',
        'help',
      ],
      'desc':
          'A compassionate guide to understanding and overcoming depression.',
      'isCourse': true,
    },

    // Wealth - Manifestation
    {
      'title': 'Manifesting Financial Abundance',
      'category': 'Wealth',
      'section': 'Manifestation',
      'tags': [
        'manifesting',
        'abundance',
        'prosperity',
        'money mindset',
        'affirmations',
      ],
      'desc':
          'Align your mindset with financial abundance using proven techniques.',
      'isCourse': true,
    },
    {
      'title': 'The Science of Getting Rich',
      'category': 'Wealth',
      'section': 'Manifestation',
      'tags': [
        'rich',
        'wealth',
        'success',
        'thinking',
        'action',
        ' Wallace D. Wattles',
      ],
      'desc': 'Apply timeless principles of wealth creation and prosperity.',
      'isCourse': false,
    },
    {
      'title': 'Wealth Affirmations Daily',
      'category': 'Wealth',
      'section': 'Manifestation',
      'tags': [
        'affirmations',
        'money',
        'prosperity',
        'abundance',
        'wealth mindset',
      ],
      'desc': 'Reprogram your money mindset with daily wealth affirmations.',
      'isCourse': false,
    },
    // Wealth - Psychology
    {
      'title': 'Money Mindset Makeover',
      'category': 'Wealth',
      'section': 'Psychology',
      'tags': [
        'mindset',
        'beliefs',
        'money blocks',
        'limiting beliefs',
        'abundance',
      ],
      'desc':
          'Identify and overcome the hidden beliefs keeping you from wealth.',
      'isCourse': true,
    },
    {
      'title': 'Behavioral Finance Fundamentals',
      'category': 'Wealth',
      'section': 'Psychology',
      'tags': [
        'behavior',
        'finance',
        'investing',
        'decisions',
        'psychology',
        'biases',
      ],
      'desc': 'Understand how psychology influences your financial decisions.',
      'isCourse': false,
    },
    {
      'title': 'Overcoming Financial Fear',
      'category': 'Wealth',
      'section': 'Psychology',
      'tags': ['fear', 'money', 'anxiety', 'scarcity', 'risk', 'investment'],
      'desc': 'Transform fear-based financial decisions into confident action.',
      'isCourse': false,
    },
    // Wealth - Mini Courses
    {
      'title': 'Investing 101',
      'category': 'Wealth',
      'section': 'Mini Course',
      'tags': [
        'investing',
        'stocks',
        'bonds',
        'portfolio',
        'beginners',
        'basics',
      ],
      'desc': 'Start your investment journey with foundational knowledge.',
      'isCourse': true,
      'modules': [
        {
          'title': 'Before You Invest',
          'duration': '18 min',
          'content':
              'Investing starts before you buy anything. The first job is to make sure your foundation can survive normal life: rent, bills, emergencies, irregular expenses, and short-term commitments.\n\nThe investment order:\n• Track your income and outgoings\n• Build a small starter buffer\n• Clear or control high-interest debt\n• Protect essential expenses\n• Invest only money you can leave alone\n\nYour action: write down the amount you can invest every month without needing it back for at least five years. If that number is zero, your next wealth move is building stability first.',
        },
        {
          'title': 'How Markets Work',
          'duration': '22 min',
          'content':
              'A share is ownership in a business. A bond is money lent to a government or company. A fund is a basket of investments. A market is simply the place where buyers and sellers agree on price.\n\nPrices move because expectations move. News, earnings, interest rates, fear, excitement, and global events all affect what people are willing to pay today.\n\nKey principle: you do not need to predict every movement to build wealth. Most beginners are better served by broad, low-cost, long-term investing than by trying to trade every headline.\n\nYour action: choose three words for your investing style: simple, consistent, patient. Use them as a filter before making decisions.',
        },
        {
          'title': 'Risk, Time, and Diversification',
          'duration': '20 min',
          'content':
              'Risk is not just losing money. Risk is also needing money at the wrong time, concentrating too much in one thing, reacting emotionally, or investing without understanding what you own.\n\nDiversification means spreading money across different assets so one bad outcome does not destroy the whole plan. Time reduces the pressure to be perfect because compounding needs repetition, not drama.\n\nBeginner rules:\n• Do not put emergency money into volatile assets\n• Avoid investing in anything you cannot explain\n• Spread risk across funds, sectors, or asset types\n• Expect drops before they happen\n• Decide your plan before emotion arrives\n\nYour action: write your personal rule for what you will do when your investments fall in value.',
        },
        {
          'title': 'Your First Investment Plan',
          'duration': '25 min',
          'content':
              'A plan protects you from impulse. Your first plan should be boring enough to repeat and clear enough to follow when markets feel noisy.\n\nBuild your plan:\n• Goal: what is the money for?\n• Timeframe: when might you need it?\n• Monthly amount: what can you invest consistently?\n• Asset mix: how much risk can you tolerate?\n• Review rhythm: monthly contributions, quarterly review\n\nDo not confuse checking with managing. Looking every day often creates anxiety without improving results.\n\nYour action: create a one-page investment policy for yourself. Include what you will buy, how often you will invest, and what would make you pause or change the plan.',
        },
      ],
    },
    {
      'title': 'Budgeting for Beginners',
      'category': 'Wealth',
      'section': 'Mini Course',
      'tags': ['budget', 'saving', 'expenses', 'tracking', 'money management'],
      'desc':
          'Master the basics of budgeting and taking control of your finances.',
      'isCourse': true,
      'modules': [
        {
          'title': 'Know Your Real Numbers',
          'duration': '15 min',
          'content':
              'A budget is not punishment. It is visibility. You cannot direct money you cannot see.\n\nStart with three numbers:\n• Income: what actually lands in your account\n• Fixed costs: bills that repeat\n• Flexible costs: food, travel, subscriptions, shopping, social spending\n\nMost people are not broke because of one giant mistake. They are leaking money through small untracked decisions.\n\nYour action: list every recurring payment. Cancel, pause, or challenge anything that no longer earns its place.',
        },
        {
          'title': 'Give Every Pound a Job',
          'duration': '20 min',
          'content':
              'Money behaves better when it has a job before it arrives. The aim is to decide in advance instead of negotiating with yourself every day.\n\nUseful categories:\n• Essentials\n• Future you: saving, investing, debt payoff\n• Lifestyle\n• Giving or family support\n• Learning and growth\n\nThe right budget is not the strictest one. It is the one you can repeat.\n\nYour action: create a simple split for next month. If you are unsure, start with essentials, debt minimums, a starter saving amount, and a realistic spending allowance.',
        },
        {
          'title': 'Stop the Leaks',
          'duration': '18 min',
          'content':
              'Spending leaks usually hide in convenience, boredom, emotional stress, and subscriptions. Fixing them is not about shame. It is about designing fewer traps.\n\nLeak controls:\n• Add a 24-hour pause before non-essential buys\n• Keep fun money separate\n• Unsubscribe from sales emails\n• Meal plan two simple default meals\n• Move savings on payday, not month-end\n\nYour action: pick one leak and design a rule around it. Make the rule specific enough that you do not need willpower in the moment.',
        },
        {
          'title': 'Build a Budget You Keep',
          'duration': '22 min',
          'content':
              'Your budget will fail if it has no room for real life. Irregular costs, birthdays, repairs, travel, and emotional spending all need a place.\n\nMonthly review questions:\n• What surprised me?\n• What category was unrealistic?\n• What can be automated?\n• What should I stop pretending I will not spend on?\n\nA working budget improves through feedback. Missing the target is information, not failure.\n\nYour action: set a weekly 10-minute money check-in. Look at spending, move anything needed, and choose one adjustment for the week ahead.',
        },
      ],
    },
    {
      'title': 'Passive Income Streams',
      'category': 'Wealth',
      'section': 'Mini Course',
      'tags': [
        'passive income',
        'side hustle',
        'residuals',
        'investment',
        'freedom',
      ],
      'desc': 'Build multiple streams of income that work while you sleep.',
      'isCourse': true,
      'modules': [
        {
          'title': 'The Truth About Passive Income',
          'duration': '16 min',
          'content':
              'Passive income is rarely passive at the start. Most streams require upfront work, capital, skill, audience, systems, or risk. The goal is not effortless money. The goal is income that becomes less dependent on your direct time.\n\nTypes of income:\n• Active: paid for your time\n• Leveraged: paid through systems or people\n• Asset-based: paid from something you own\n• Portfolio: paid through investments\n\nYour action: choose whether your next stream will use skill, capital, audience, or assets. Do not try to build all four at once.',
        },
        {
          'title': 'Choose the Right Stream',
          'duration': '20 min',
          'content':
              'A good income stream fits your current resources. If you have skills but little capital, start with services or digital products. If you have capital but little time, learn investing carefully. If you have an audience, package trust into useful offers.\n\nScore each idea from 1 to 5:\n• Startup cost\n• Time required\n• Skill fit\n• Demand\n• Risk\n• Repeatability\n\nYour action: list five income ideas and score them. Pick the one with the best combination of demand and repeatability, not the one that sounds most exciting.',
        },
        {
          'title': 'Build Once, Improve Often',
          'duration': '24 min',
          'content':
              'A stream becomes powerful when it can be improved instead of rebuilt. This is why templates, courses, content libraries, rentals, royalties, automated sales funnels, and long-term investments can compound.\n\nThe build cycle:\n• Create the first version\n• Put it in front of real people\n• Measure response\n• Improve the offer\n• Systemise delivery\n\nYour action: design a version you can launch in seven days. Keep it small enough to finish, but useful enough to test demand.',
        },
        {
          'title': 'Protect and Scale',
          'duration': '22 min',
          'content':
              'Scaling too early creates chaos. First prove the stream works, then make it easier to repeat.\n\nScale checklist:\n• Clear offer\n• Reliable delivery\n• Simple tracking\n• Customer feedback\n• Basic legal and tax awareness\n• Time boundaries\n\nPassive income should support your life, not quietly become another stressful job.\n\nYour action: write the next three improvements for your income stream: one to increase sales, one to reduce delivery time, and one to reduce risk.',
        },
      ],
    },
    // Wealth - Entrepreneurship
    {
      'title': 'Starting Your Online Business',
      'category': 'Wealth',
      'section': 'Entrepreneurship',
      'tags': [
        'online business',
        'e-commerce',
        'startup',
        'entrepreneur',
        'digital',
      ],
      'desc': 'Launch a profitable online business from scratch.',
      'isCourse': true,
    },
    {
      'title': 'Side Hustle Mastery',
      'category': 'Wealth',
      'section': 'Entrepreneurship',
      'tags': [
        'side hustle',
        'gig economy',
        'freelance',
        'extra income',
        'moonlighting',
      ],
      'desc': 'Turn your skills into a profitable side business.',
      'isCourse': false,
    },
    // Wealth - Investing
    {
      'title': 'Stock Market Basics',
      'category': 'Wealth',
      'section': 'Investing',
      'tags': ['stocks', 'shares', 'market', 'trading', 'dividends', 'growth'],
      'desc':
          'Understand how the stock market works and how to start investing.',
      'isCourse': false,
    },
    {
      'title': 'Real Estate Investing',
      'category': 'Wealth',
      'section': 'Investing',
      'tags': [
        'real estate',
        'property',
        'rental',
        'landlord',
        'REIT',
        'investing',
      ],
      'desc': 'Build wealth through residential and commercial real estate.',
      'isCourse': true,
    },
    // Wealth - Saving
    {
      'title': 'Emergency Fund Essentials',
      'category': 'Wealth',
      'section': 'Saving',
      'tags': [
        'emergency fund',
        'savings',
        'safety net',
        'financial security',
        'buffer',
      ],
      'desc': 'Create a financial cushion for life unexpected events.',
      'isCourse': false,
    },
    {
      'title': 'Retirement Planning Early',
      'category': 'Wealth',
      'section': 'Saving',
      'tags': ['retirement', '401k', 'IRA', 'pension', 'future', 'seniors'],
      'desc':
          'Why starting early matters and how to maximize your retirement savings.',
      'isCourse': false,
    },

    // Relationships - Manifestation
    {
      'title': 'Manifesting Your Soulmate',
      'category': 'Relationships',
      'section': 'Manifestation',
      'tags': [
        'soulmate',
        'love',
        'partner',
        'manifesting',
        'romance',
        'relationship',
      ],
      'desc':
          'Use visualization and affirmation to attract your ideal partner.',
      'isCourse': true,
    },
    {
      'title': 'Loving Affirmations',
      'category': 'Relationships',
      'section': 'Manifestation',
      'tags': [
        'affirmations',
        'love',
        'self-love',
        'relationship',
        'heart',
        'romance',
      ],
      'desc':
          'Open your heart with loving affirmations for yourself and others.',
      'isCourse': false,
    },
    {
      'title': 'Visualizing Your Ideal Relationship',
      'category': 'Relationships',
      'section': 'Manifestation',
      'tags': [
        'visualization',
        'relationship',
        'partner',
        'ideal',
        'love',
        'imagery',
      ],
      'desc': 'Create a clear vision of the relationship you desire.',
      'isCourse': false,
    },
    // Relationships - Psychology
    {
      'title': 'Attachment Theory Explained',
      'category': 'Relationships',
      'section': 'Psychology',
      'tags': [
        'attachment',
        'anxious',
        'avoidant',
        'secure',
        'relationships',
        'bonding',
      ],
      'desc':
          'Understand your attachment style and how it affects your connections.',
      'isCourse': true,
    },
    {
      'title': 'Communication Skills Mastery',
      'category': 'Relationships',
      'section': 'Psychology',
      'tags': [
        'communication',
        'talking',
        'listening',
        'conflict',
        'resolution',
        'assertive',
      ],
      'desc': 'Transform your relationships through powerful communication.',
      'isCourse': true,
    },
    {
      'title': 'Emotional Intelligence in Love',
      'category': 'Relationships',
      'section': 'Psychology',
      'tags': [
        'emotional intelligence',
        'EQ',
        'empathy',
        'feelings',
        'awareness',
        'relationships',
      ],
      'desc': 'Use emotional intelligence to deepen your connections.',
      'isCourse': false,
    },
    // Relationships - Mini Courses
    {
      'title': 'Building Lasting Marriage',
      'category': 'Relationships',
      'section': 'Mini Course',
      'tags': [
        'marriage',
        'spouse',
        'wedding',
        'commitment',
        'long-term',
        'partnership',
      ],
      'desc':
          'Strengthen your marriage with proven strategies for lasting love.',
      'isCourse': true,
      'modules': [
        {
          'title': 'The Marriage Foundation',
          'duration': '18 min',
          'content':
              'A lasting marriage is built less on grand moments and more on repeated emotional safety. The daily tone matters: how you greet each other, repair tension, share responsibility, and protect the relationship from neglect.\n\nCore foundations:\n• Respect before agreement\n• Curiosity before criticism\n• Repair before resentment grows\n• Shared responsibility, not scorekeeping\n• Regular appreciation\n\nYour action: ask your partner one simple question: What is one thing I do that helps you feel loved, and one thing I could do more consistently?',
        },
        {
          'title': 'Communication Under Pressure',
          'duration': '22 min',
          'content':
              'Most couples do not struggle because they lack love. They struggle because stress changes how they speak, listen, and interpret each other.\n\nUse a pressure script:\n• I am feeling...\n• The story I am telling myself is...\n• What I need right now is...\n• Can we work on this together?\n\nAvoid mind-reading, blame, and bringing in every past issue. Stay with one topic long enough to understand it.\n\nYour action: choose one recurring argument and rewrite your opening sentence so it invites teamwork instead of defence.',
        },
        {
          'title': 'Repair and Reconnection',
          'duration': '20 min',
          'content':
              'Healthy couples still hurt each other. The difference is repair. Repair means returning to the bond and saying: we matter more than winning this moment.\n\nA proper repair includes:\n• Naming what happened\n• Owning your part without excuses\n• Validating the impact\n• Asking what would help now\n• Agreeing on one behaviour change\n\nYour action: practise a clean apology: I can see that when I did or said this, it affected you this way. I am sorry. Next time I will...',
        },
        {
          'title': 'Keeping Love Alive',
          'duration': '20 min',
          'content':
              'Long-term love needs rituals. Without them, logistics take over and the relationship becomes a household management system.\n\nCreate rituals for:\n• Daily check-ins\n• Weekly quality time\n• Physical affection\n• Shared planning\n• Play and laughter\n• Appreciation\n\nSmall rituals create a sense of us. They remind both people that the relationship is alive and chosen.\n\nYour action: create one weekly connection ritual that is easy enough to repeat even during busy weeks.',
        },
      ],
    },
    {
      'title': 'Friendship & Social Connection',
      'category': 'Relationships',
      'section': 'Mini Course',
      'tags': [
        'friends',
        'social',
        'community',
        'connection',
        'loneliness',
        'networking',
      ],
      'desc': 'Build meaningful friendships and expand your social circle.',
      'isCourse': true,
      'modules': [
        {
          'title': 'Audit Your Social World',
          'duration': '15 min',
          'content':
              'Friendship begins with awareness. Your social world may include close friends, casual friends, work connections, family, online communities, and people you have outgrown.\n\nMap your circle:\n• Who energises you?\n• Who drains you?\n• Who feels safe and honest?\n• Who do you want to know better?\n• Where are you relying on old proximity instead of real connection?\n\nYour action: list ten people in your current orbit and mark each as nourishing, neutral, or draining.',
        },
        {
          'title': 'Become Easier to Connect With',
          'duration': '20 min',
          'content':
              'Good friendships are not only found. They are made through warmth, consistency, and initiative. Many people wait to be chosen, then wonder why connection feels scarce.\n\nConnection behaviours:\n• Ask better follow-up questions\n• Remember details\n• Invite people clearly\n• Respond with presence\n• Share honestly without oversharing too soon\n• Celebrate other people without comparison\n\nYour action: message one person with a specific invitation, not a vague we should catch up sometime.',
        },
        {
          'title': 'Build Community Through Repetition',
          'duration': '18 min',
          'content':
              'Friendship grows fastest where people see each other repeatedly. One-off events can start connection, but rhythm turns strangers into familiar faces.\n\nHigh-connection environments:\n• Classes\n• Sports or fitness groups\n• Volunteering\n• Creative communities\n• Faith or spiritual spaces\n• Professional circles\n• Local interest groups\n\nYour action: choose one recurring place to show up for the next four weeks. Do not judge it after one visit.',
        },
        {
          'title': 'Maintain Healthy Friendships',
          'duration': '22 min',
          'content':
              'A strong friendship needs both openness and boundaries. You can care about people without becoming available for everything at all times.\n\nMaintain the bond by practising:\n• Honest check-ins\n• Clear limits\n• Repair after distance or tension\n• Giving support without fixing everything\n• Letting friendships change season by season\n\nYour action: pick one friendship to nurture this week. Send appreciation, arrange time together, or repair a small distance.',
        },
      ],
    },
    {
      'title': 'Conflict Resolution Skills',
      'category': 'Relationships',
      'section': 'Mini Course',
      'tags': [
        'conflict',
        'argument',
        'disagreement',
        'resolution',
        'anger',
        'mediation',
      ],
      'desc': 'Turn conflicts into opportunities for deeper understanding.',
      'isCourse': true,
      'modules': [
        {
          'title': 'Understand the Real Conflict',
          'duration': '16 min',
          'content':
              'The surface argument is often not the real conflict. The topic may be chores, timing, money, tone, or plans, but underneath there may be a need for respect, safety, freedom, fairness, or reassurance.\n\nAsk beneath the argument:\n• What am I protecting?\n• What am I afraid will happen?\n• What need feels ignored?\n• What meaning am I attaching to their behaviour?\n\nYour action: take one recent disagreement and write the surface issue, then the deeper need underneath it.',
        },
        {
          'title': 'De-escalate Before Solving',
          'duration': '20 min',
          'content':
              'You cannot solve well while your nervous system is in threat mode. De-escalation is not avoidance. It is creating the conditions where the conversation can become useful.\n\nUse this pause:\n• Lower your voice\n• Slow your breathing\n• Stop interrupting\n• Name the shared goal\n• Take a time-out if either person is flooded\n\nA good time-out includes a return time. Otherwise it feels like abandonment.\n\nYour action: create a phrase you can use when conflict is getting too heated: I want to solve this, but I need ten minutes to calm down so I do not make it worse.',
        },
        {
          'title': 'Speak Needs Without Attack',
          'duration': '22 min',
          'content':
              'Needs are easier to hear when they are not wrapped in accusation. Replace blame with observation, feeling, need, and request.\n\nFormula:\n• When this happens...\n• I feel...\n• Because I need/value...\n• Would you be willing to...\n\nExample: When plans change last minute, I feel unsettled because I value reliability. Would you be willing to tell me earlier when something shifts?\n\nYour action: rewrite one complaint as a clear request.',
        },
        {
          'title': 'Repair the Pattern',
          'duration': '20 min',
          'content':
              'Resolving one argument is useful. Changing the pattern is powerful. After conflict, review what happened when both people are calm.\n\nPattern review:\n• What triggered us?\n• Where did we escalate?\n• What helped us calm down?\n• What do we understand better now?\n• What agreement will we try next time?\n\nYour action: after your next difficult conversation, write one pattern you want to interrupt earlier next time.',
        },
      ],
    },
    // Relationships - Dating
    {
      'title': 'Dating After Divorce',
      'category': 'Relationships',
      'section': 'Dating',
      'tags': [
        'divorce',
        'dating',
        'single',
        'again',
        'rebound',
        'starting over',
      ],
      'desc': 'Navigate the dating world with confidence after divorce.',
      'isCourse': false,
    },
    {
      'title': 'Healthy Dating Boundaries',
      'category': 'Relationships',
      'section': 'Dating',
      'tags': [
        'boundaries',
        'dating',
        'limits',
        'self-respect',
        'standards',
        'healthy',
      ],
      'desc': 'Set and maintain healthy boundaries in dating relationships.',
      'isCourse': false,
    },
    // Relationships - Family
    {
      'title': 'Parenting with Connection',
      'category': 'Relationships',
      'section': 'Family',
      'tags': ['parenting', 'children', 'kids', 'family', 'attachment', 'bond'],
      'desc': 'Build strong parent-child connections that last a lifetime.',
      'isCourse': true,
    },
    {
      'title': 'Setting Family Boundaries',
      'category': 'Relationships',
      'section': 'Family',
      'tags': [
        'family',
        'boundaries',
        'limits',
        'toxic',
        'enmeshment',
        'boundaries',
      ],
      'desc': 'Create healthy boundaries with family members.',
      'isCourse': false,
    },
    {
      'title': 'Sibling Relationships',
      'category': 'Relationships',
      'section': 'Family',
      'tags': [
        'siblings',
        'brothers',
        'sisters',
        'family',
        'childhood',
        'bonding',
      ],
      'desc': 'Heal and strengthen your bond with your siblings.',
      'isCourse': false,
    },

    // Career - Manifestation
    {
      'title': 'Dream Career Visualization',
      'category': 'Career',
      'section': 'Manifestation',
      'tags': [
        'visualization',
        'dream job',
        'career',
        'success',
        'ideal work',
        'imagery',
      ],
      'desc': 'Use visualization to manifest your perfect career.',
      'isCourse': false,
    },
    {
      'title': 'Career Affirmations for Success',
      'category': 'Career',
      'section': 'Manifestation',
      'tags': [
        'affirmations',
        'career',
        'success',
        'job',
        'professional',
        'confidence',
      ],
      'desc': 'Boost your career confidence with powerful affirmations.',
      'isCourse': false,
    },
    // Career - Psychology
    {
      'title': 'Imposter Syndrome Overcome',
      'category': 'Career',
      'section': 'Psychology',
      'tags': [
        'imposter syndrome',
        'confidence',
        'self-doubt',
        'success',
        'fake',
        'feelings',
      ],
      'desc': 'Overcome imposter syndrome and own your professional success.',
      'isCourse': true,
    },
    {
      'title': 'Work-Life Balance',
      'category': 'Career',
      'section': 'Psychology',
      'tags': [
        'work-life balance',
        'burnout',
        'stress',
        'boundaries',
        'rest',
        'productivity',
      ],
      'desc': 'Create sustainable balance between work and personal life.',
      'isCourse': true,
    },
    {
      'title': 'Networking Without Anxiety',
      'category': 'Career',
      'section': 'Psychology',
      'tags': [
        'networking',
        'social',
        'connections',
        'career',
        'interactions',
        'introvert',
      ],
      'desc':
          'Build professional relationships even if you are shy or introverted.',
      'isCourse': false,
    },
    // Career - Mini Courses
    {
      'title': 'Resume Writing that Lands Jobs',
      'category': 'Career',
      'section': 'Mini Course',
      'tags': [
        'resume',
        'CV',
        'job application',
        'hiring',
        'career',
        'interview',
      ],
      'desc': 'Write a resume that gets you noticed and lands interviews.',
      'isCourse': true,
      'modules': [
        {
          'title': 'Position Before You Write',
          'duration': '16 min',
          'content':
              'A strong resume is not a life history. It is a positioning document. Its job is to show a hiring manager why you fit this role, this team, and this level of responsibility.\n\nBefore writing, define:\n• The role you are targeting\n• The problems that role solves\n• The skills repeatedly named in job posts\n• Your strongest proof of those skills\n• The career story you want the page to tell\n\nYour action: choose one target role and highlight the five phrases that appear most often across three job descriptions.',
        },
        {
          'title': 'Turn Duties into Evidence',
          'duration': '22 min',
          'content':
              'Most resumes are weak because they list duties. Strong resumes show evidence: outcomes, scale, improvement, ownership, and impact.\n\nUpgrade bullet points with this structure:\n• Action verb\n• What you did\n• How or with what tools\n• Result or business value\n\nWeak: Responsible for social media.\nStrong: Planned and scheduled weekly social content that increased engagement by 32% over three months.\n\nYour action: rewrite three resume bullets so each one includes a result, number, or clear improvement.',
        },
        {
          'title': 'ATS and Human Readability',
          'duration': '18 min',
          'content':
              'Your resume needs to pass two readers: software and a human. Applicant tracking systems scan for relevance. Humans scan for clarity.\n\nKeep it readable:\n• Use standard section headings\n• Avoid tables and heavy graphics\n• Match role keywords naturally\n• Put strongest experience near the top\n• Keep bullets concise\n• Use consistent formatting\n\nDo not stuff keywords. A resume should sound like a competent person, not a search engine.\n\nYour action: compare your resume against one job description and add missing keywords only where they honestly fit.',
        },
        {
          'title': 'Final Polish and Application Strategy',
          'duration': '20 min',
          'content':
              'A polished resume is accurate, targeted, and easy to scan. But a resume alone is not the whole strategy. The best applications combine a relevant resume with thoughtful outreach where possible.\n\nFinal checks:\n• No spelling or date errors\n• Clear job titles and company names\n• Strong first third of the page\n• Relevant achievements over generic claims\n• File name is professional\n\nYour action: create a master resume and one tailored version for your next application. Then identify one person or company touchpoint you can contact respectfully.',
        },
      ],
    },
    {
      'title': 'Acing the Job Interview',
      'category': 'Career',
      'section': 'Mini Course',
      'tags': [
        'interview',
        'job',
        'hiring',
        'questions',
        'answers',
        'preparation',
      ],
      'desc': 'Master interview techniques to secure your dream job.',
      'isCourse': true,
      'modules': [
        {
          'title': 'Research the Role Like a Strategist',
          'duration': '15 min',
          'content':
              'Interview confidence comes from preparation. You are not memorising a script. You are understanding the job well enough to connect your experience to their needs.\n\nResearch:\n• Company mission and current priorities\n• Role responsibilities\n• Required skills\n• Recent news or product changes\n• Team or industry challenges\n\nYour action: write three reasons this role matters to the company and three examples from your experience that match those needs.',
        },
        {
          'title': 'Build Your Story Bank',
          'duration': '22 min',
          'content':
              'Most interview questions are asking for evidence. A story bank helps you answer clearly without rambling.\n\nPrepare stories for:\n• Solving a problem\n• Handling conflict\n• Learning quickly\n• Leading or influencing\n• Recovering from a mistake\n• Delivering a measurable result\n\nUse STAR lightly: Situation, Task, Action, Result. Keep the action and result strongest.\n\nYour action: write four interview stories and mark the result in each one.',
        },
        {
          'title': 'Answer with Confidence and Warmth',
          'duration': '20 min',
          'content':
              'A great interview answer is clear, relevant, and human. You want to sound prepared, not robotic.\n\nAnswer rhythm:\n• Short direct answer\n• One supporting example\n• What you learned or how it applies\n• Pause\n\nIf you do not know something, do not fake it. Say how you would approach learning or solving it.\n\nYour action: practise answering Tell me about yourself in under 90 seconds, linking your background to the role.',
        },
        {
          'title': 'Close and Follow Up',
          'duration': '18 min',
          'content':
              'The end of the interview is a chance to show judgment. Ask questions that reveal how you think about the role, not just benefits or logistics.\n\nGood questions:\n• What would success look like in the first 90 days?\n• What problems would you most want this person to solve?\n• How does the team make decisions?\n• What separates great performers here?\n\nYour action: prepare three thoughtful questions and write a short follow-up message that thanks them and reinforces your fit.',
        },
      ],
    },
    {
      'title': 'Leadership Fundamentals',
      'category': 'Career',
      'section': 'Mini Course',
      'tags': [
        'leadership',
        'leader',
        'management',
        'team',
        'influence',
        'motivation',
      ],
      'desc': 'Develop essential leadership skills for career advancement.',
      'isCourse': true,
      'modules': [
        {
          'title': 'Lead Before the Title',
          'duration': '18 min',
          'content':
              'Leadership starts before authority. You lead when you take ownership, improve clarity, help others succeed, and make the work easier to move forward.\n\nEarly leadership behaviours:\n• Notice problems without waiting to be told\n• Communicate next steps clearly\n• Follow through reliably\n• Share credit\n• Make decisions easier for others\n\nYour action: choose one area at work where you can take more ownership this week without needing permission.',
        },
        {
          'title': 'Communication and Expectations',
          'duration': '20 min',
          'content':
              'Leadership depends on clear expectations. People struggle when priorities, standards, timing, or ownership are vague.\n\nClarify:\n• What matters most?\n• Who owns what?\n• What does done mean?\n• When will we check progress?\n• What risks should be raised early?\n\nYour action: write a short project expectation note for something you are working on. Include owner, deadline, definition of done, and next check-in.',
        },
        {
          'title': 'Feedback Without Ego',
          'duration': '22 min',
          'content':
              'Good leaders give feedback that is direct enough to help and respectful enough to be heard. Avoid vague praise, delayed criticism, and feedback that attacks identity.\n\nFeedback structure:\n• What I noticed...\n• Why it matters...\n• What good would look like...\n• How can I support you?\n\nReceive feedback with the same discipline. Do not defend immediately. Ask what would make the work better.\n\nYour action: give one piece of useful appreciation or constructive feedback this week using specific behaviour.',
        },
        {
          'title': 'Influence and Trust',
          'duration': '20 min',
          'content':
              'Influence is built through trust. People follow those who are competent, consistent, fair, and calm under pressure.\n\nBuild trust by:\n• Doing what you said you would do\n• Explaining decisions\n• Owning mistakes quickly\n• Protecting people from chaos where possible\n• Being consistent with standards\n\nYour action: identify one trust leak in your work behaviour and choose a repair: clearer updates, faster follow-through, better preparation, or cleaner ownership.',
        },
      ],
    },
    // Career - Productivity
    {
      'title': 'Time Management Mastery',
      'category': 'Career',
      'section': 'Productivity',
      'tags': [
        'time management',
        'productivity',
        'efficiency',
        'procrastination',
        'focus',
        'priorities',
      ],
      'desc': 'Maximize your productivity and accomplish more in less time.',
      'isCourse': true,
    },
    {
      'title': 'Goal Setting for Professionals',
      'category': 'Career',
      'section': 'Productivity',
      'tags': [
        'goals',
        'SMART goals',
        'career',
        'planning',
        'milestones',
        'achievement',
      ],
      'desc': 'Set and achieve professional goals that advance your career.',
      'isCourse': false,
    },
    {
      'title': 'Overcoming Procrastination',
      'category': 'Career',
      'section': 'Productivity',
      'tags': [
        'procrastination',
        'delay',
        'productivity',
        'motivation',
        'discipline',
        'habits',
      ],
      'desc': 'Break the procrastination habit and get things done.',
      'isCourse': false,
    },
    // Career - Career Change
    {
      'title': 'Career Transition Guide',
      'category': 'Career',
      'section': 'Career Change',
      'tags': [
        'career change',
        'transition',
        'pivot',
        'new career',
        'switch',
        'restart',
      ],
      'desc': 'Successfully navigate changing careers later in life.',
      'isCourse': false,
    },
    {
      'title': 'Finding Your Purpose',
      'category': 'Career',
      'section': 'Career Change',
      'tags': [
        'purpose',
        'calling',
        'passion',
        'meaning',
        'work',
        'fulfillment',
      ],
      'desc':
          'Discover your professional purpose and align your career with your values.',
      'isCourse': true,
    },

    // Spiritual - Manifestation
    {
      'title': 'Spiritual Manifesting Basics',
      'category': 'Spiritual',
      'section': 'Manifestation',
      'tags': [
        'manifesting',
        'spiritual',
        'energy',
        'vibration',
        'universe',
        'law of attraction',
      ],
      'desc': 'Align with spiritual forces to manifest your desires.',
      'isCourse': true,
    },
    {
      'title': 'Chakra Alignment Practice',
      'category': 'Spiritual',
      'section': 'Manifestation',
      'tags': [
        'chakras',
        'energy',
        'spiritual',
        'balance',
        'meditation',
        ' Kundalini',
      ],
      'desc': 'Balance your energy centers for spiritual manifestation.',
      'isCourse': false,
    },
    {
      'title': 'Gratitude Manifesting',
      'category': 'Spiritual',
      'section': 'Manifestation',
      'tags': [
        'gratitude',
        'manifesting',
        'abundance',
        'thanks',
        'appreciation',
        'abundance',
      ],
      'desc': 'Use gratitude as a powerful manifesting tool.',
      'isCourse': false,
    },
    // Spiritual - Psychology
    {
      'title': 'Jungian Shadow Work',
      'category': 'Spiritual',
      'section': 'Psychology',
      'tags': [
        'shadow work',
        'Jung',
        'Carl Jung',
        'self-discovery',
        'dark side',
        'integration',
      ],
      'desc': 'Integrate your shadow self for spiritual growth.',
      'isCourse': true,
    },
    {
      'title': 'Archetypes and Self',
      'category': 'Spiritual',
      'section': 'Psychology',
      'tags': [
        'archetypes',
        'Jung',
        'symbols',
        'collective unconscious',
        'mythology',
        'self',
      ],
      'desc': 'Understand universal archetypes that shape your life.',
      'isCourse': false,
    },
    {
      'title': 'Spiritual Bypassing Explained',
      'category': 'Spiritual',
      'section': 'Psychology',
      'tags': [
        'spiritual bypassing',
        'avoidance',
        'shadow',
        'growth',
        'denial',
        'awareness',
      ],
      'desc':
          'Recognize when spirituality is used to avoid dealing with problems.',
      'isCourse': false,
    },
    // Spiritual - Mini Courses
    {
      'title': 'Meditation for Beginners',
      'category': 'Spiritual',
      'section': 'Mini Course',
      'tags': [
        'meditation',
        'mindfulness',
        'beginners',
        'sitting',
        'breathing',
        'awareness',
      ],
      'desc': 'Start a daily meditation practice from scratch.',
      'isCourse': true,
      'modules': [
        {
          'title': 'What Meditation Really Is',
          'duration': '12 min',
          'content':
              'Meditation is not forcing your mind to be blank. It is training attention. You notice where the mind goes, then gently return to the chosen anchor.\n\nBeginner truths:\n• Thoughts are not failure\n• Restlessness is normal\n• Consistency matters more than length\n• The practice is returning, not perfect stillness\n• Your nervous system learns through repetition\n\nYour action: set a timer for five minutes and practise returning to your breath every time the mind wanders.',
        },
        {
          'title': 'Breath and Body Awareness',
          'duration': '15 min',
          'content':
              'The breath and body give the mind somewhere simple to rest. This creates steadiness without needing to control every thought.\n\nPractice:\n• Sit comfortably\n• Notice the breath entering and leaving\n• Feel the body touching the chair or floor\n• Relax the jaw and shoulders\n• Return gently when distracted\n\nDo not chase a special experience. Let ordinary awareness become enough.\n\nYour action: practise five slow breaths before checking your phone in the morning.',
        },
        {
          'title': 'Working with Thoughts',
          'duration': '18 min',
          'content':
              'Thoughts will appear. Meditation teaches you to relate to them differently. Instead of climbing into every thought, you learn to watch it arrive, change, and pass.\n\nTry labels:\n• Planning\n• Remembering\n• Judging\n• Worrying\n• Imagining\n\nA label creates distance without hostility. You are not fighting the mind; you are learning its patterns.\n\nYour action: during meditation, label three thoughts softly and return to the breath.',
        },
        {
          'title': 'Build a Daily Practice',
          'duration': '15 min',
          'content':
              'A meditation routine should be small enough to keep. Start with five minutes at the same time and place. Once the identity is built, duration can grow naturally.\n\nRoutine design:\n• Same trigger each day\n• Comfortable posture\n• Short timer\n• Simple anchor\n• One sentence after: What did I notice?\n\nYour action: choose your meditation trigger: after waking, after brushing teeth, after lunch, or before sleep. Commit to seven days.',
        },
      ],
    },
    {
      'title': 'Understanding Enlightenment',
      'category': 'Spiritual',
      'section': 'Mini Course',
      'tags': [
        'enlightenment',
        'awakening',
        'self-realization',
        'Satori',
        'Buddha',
        'consciousness',
      ],
      'desc': 'Explore the concept of enlightenment across traditions.',
      'isCourse': true,
      'modules': [
        {
          'title': 'Enlightenment Without Fantasy',
          'duration': '16 min',
          'content':
              'Enlightenment is described differently across traditions, but it often points toward freedom from illusion, ego fixation, compulsive suffering, or mistaken identity.\n\nGrounded understanding:\n• It is not superiority\n• It is not escaping ordinary life\n• It is not permanent bliss on demand\n• It often includes humility, compassion, and clarity\n• It is approached through practice, not performance\n\nYour action: write what enlightenment currently means to you, then remove any part that sounds like ego trying to become special.',
        },
        {
          'title': 'Self, Ego, and Awareness',
          'duration': '20 min',
          'content':
              'Many teachings distinguish between the changing self-story and the awareness that notices it. Your roles, thoughts, moods, and memories change. Awareness is the space in which they appear.\n\nInquiry questions:\n• Am I this thought, or am I aware of it?\n• Am I this feeling, or am I experiencing it?\n• What remains when I stop narrating myself for a moment?\n\nThis inquiry is not about rejecting personality. It is about loosening identification.\n\nYour action: pause three times today and ask: What am I aware of right now?',
        },
        {
          'title': 'Awakening in Daily Life',
          'duration': '18 min',
          'content':
              'Spiritual insight has to meet ordinary life: dishes, messages, work, conflict, tiredness, and responsibility. If practice makes you less kind or less honest, something is out of balance.\n\nDaily-life practice:\n• Bring presence to simple tasks\n• Notice reactivity as it begins\n• Choose compassion when possible\n• Admit when you are wrong\n• Return to the moment through the body\n\nYour action: choose one routine task and do it with full attention today.',
        },
        {
          'title': 'Humility and Integration',
          'duration': '20 min',
          'content':
              'Spiritual growth needs integration. Insights become real when they change how you treat yourself, others, your body, your choices, and your responsibilities.\n\nIntegration signs:\n• More honesty\n• More patience\n• Less need to prove yourself\n• Better repair after mistakes\n• More grounded compassion\n\nBeware of using spiritual ideas to avoid pain, conflict, money, health, or relationships.\n\nYour action: choose one spiritual insight and name the practical behaviour that would prove it in your life.',
        },
      ],
    },
    {
      'title': 'Developing Intuition',
      'category': 'Spiritual',
      'section': 'Mini Course',
      'tags': [
        'intuition',
        'gut feeling',
        'sixth sense',
        'psychic',
        'inner wisdom',
        'guidance',
      ],
      'desc': 'Develop and trust your intuitive guidance.',
      'isCourse': true,
      'modules': [
        {
          'title': 'Intuition vs Impulse',
          'duration': '15 min',
          'content':
              'Intuition is quiet, grounded knowing. Impulse is often urgent, reactive, or fear-driven. Learning the difference protects you from confusing anxiety with guidance.\n\nCompare:\n• Intuition feels clear, steady, and simple\n• Fear feels contracted, repetitive, and catastrophic\n• Wishful thinking ignores evidence\n• Wisdom can hold both inner knowing and practical facts\n\nYour action: recall one time your intuition was right. What did it feel like in your body?',
        },
        {
          'title': 'Body Signals and Inner Knowing',
          'duration': '18 min',
          'content':
              'The body often notices before the mind explains. Tightness, openness, heaviness, calm, energy, or resistance can all carry information. The skill is listening without instantly obeying.\n\nPractice:\n• Ask a clear question\n• Notice body response\n• Breathe before interpreting\n• Write what came up\n• Check against facts and values\n\nYour action: ask your body a simple yes/no question and journal the sensations without forcing an answer.',
        },
        {
          'title': 'Strengthen the Signal',
          'duration': '20 min',
          'content':
              'Intuition gets clearer when the mind is less cluttered. Noise comes from overstimulation, people pleasing, fear, and constant input.\n\nStrengthen intuition through:\n• Meditation\n• Journaling\n• Time in nature\n• Reducing digital noise\n• Tracking intuitive hits\n• Acting on small low-risk guidance\n\nYour action: keep an intuition log for seven days: prompt, feeling, action, outcome.',
        },
        {
          'title': 'Discernment and Action',
          'duration': '18 min',
          'content':
              'Trusting intuition does not mean abandoning discernment. The mature path combines inner guidance with values, evidence, timing, and responsibility.\n\nDiscernment questions:\n• Is this aligned with my values?\n• Is fear or urgency driving me?\n• What practical information do I need?\n• What is the smallest wise action?\n• Who can offer grounded perspective?\n\nYour action: choose one intuitive nudge and turn it into a small, reversible action.',
        },
      ],
    },
    // Spiritual - Practices
    {
      'title': 'Daily Spiritual Practice',
      'category': 'Spiritual',
      'section': 'Practices',
      'tags': [
        'spiritual practice',
        'daily',
        'routine',
        'ritual',
        'habit',
        'devotion',
      ],
      'desc': 'Create a sustainable daily spiritual practice.',
      'isCourse': false,
    },
    {
      'title': 'Prayer and its Power',
      'category': 'Spiritual',
      'section': 'Practices',
      'tags': [
        'prayer',
        'faith',
        'spirituality',
        'communication',
        'divine',
        'belief',
      ],
      'desc': 'Understand and harness the power of prayer.',
      'isCourse': false,
    },
    {
      'title': 'Energy Protection Techniques',
      'category': 'Spiritual',
      'section': 'Practices',
      'tags': [
        'protection',
        'energy',
        'auras',
        'shielding',
        'psychic defense',
        'spiritual',
      ],
      'desc': 'Protect your energy from negative influences.',
      'isCourse': false,
    },
    // Spiritual - Wisdom
    {
      'title': 'Buddha\'s Teachings',
      'category': 'Spiritual',
      'section': 'Wisdom',
      'tags': [
        'Buddha',
        'Buddhism',
        'Dharma',
        'Four Noble Truths',
        'Eightfold Path',
        'teachings',
      ],
      'desc': 'Core teachings of Buddha for modern spiritual seekers.',
      'isCourse': true,
    },
    {
      'title': 'Stoic Philosophy for Life',
      'category': 'Spiritual',
      'section': 'Wisdom',
      'tags': [
        'Stoicism',
        'Marcus Aurelius',
        'Seneca',
        'Epictetus',
        'wisdom',
        'philosophy',
      ],
      'desc': 'Apply ancient Stoic wisdom to modern challenges.',
      'isCourse': true,
    },
    {
      'title': 'The Power of Now',
      'category': 'Spiritual',
      'section': 'Wisdom',
      'tags': [
        'Eckhart Tolle',
        'now',
        'present moment',
        'awareness',
        'ego',
        'spiritual',
      ],
      'desc': 'Live in the present moment as taught by Eckhart Tolle.',
      'isCourse': false,
    },

    // Personal Growth - Manifestation
    {
      'title': 'Personal Power Manifesting',
      'category': 'Personal Growth',
      'section': 'Manifestation',
      'tags': [
        'personal power',
        'empowerment',
        'manifesting',
        'confidence',
        'strength',
        'inner power',
      ],
      'desc': 'Reclaim your personal power and manifest your best life.',
      'isCourse': true,
    },
    {
      'title': 'Creating Your Best Future',
      'category': 'Personal Growth',
      'section': 'Manifestation',
      'tags': [
        'future',
        'visualization',
        'goals',
        'dreams',
        'aspirations',
        'intentions',
      ],
      'desc':
          'Design and manifest your ideal future through focused intention.',
      'isCourse': false,
    },
    // Personal Growth - Psychology
    {
      'title': 'Self-Compassion Practice',
      'category': 'Personal Growth',
      'section': 'Psychology',
      'tags': [
        'self-compassion',
        'Kristin Neff',
        'self-love',
        'kindness',
        ' Inner drill',
        'criticism',
      ],
      'desc': 'Develop unconditional self-acceptance and compassion.',
      'isCourse': true,
    },
    {
      'title': 'Fixed vs Growth Mindset',
      'category': 'Personal Growth',
      'section': 'Psychology',
      'tags': [
        'Carol Dweck',
        'mindset',
        'growth mindset',
        'fixed mindset',
        'learning',
        'intelligence',
      ],
      'desc': 'Transform your mindset to unlock unlimited potential.',
      'isCourse': true,
    },
    {
      'title': 'Limiting Beliefs Challenge',
      'category': 'Personal Growth',
      'section': 'Psychology',
      'tags': [
        'limiting beliefs',
        'beliefs',
        'limiting',
        'challenges',
        'overcoming',
        'growth',
      ],
      'desc': 'Identify and overcome the beliefs that limit your success.',
      'isCourse': false,
    },
    // Personal Growth - Mini Courses
    {
      'title': 'Habit Building Mastery',
      'category': 'Personal Growth',
      'section': 'Mini Course',
      'tags': [
        'habits',
        'routines',
        'behavior',
        'James Clear',
        'Atomic Habits',
        'productivity',
      ],
      'desc': 'Build habits that stick and transform your life.',
      'isCourse': true,
      'modules': [
        {
          'title': 'Start with Identity',
          'duration': '16 min',
          'content':
              'Lasting habits are easier when they connect to identity. Instead of asking only what you want to do, ask who you are becoming.\n\nIdentity-based habits:\n• I am becoming a person who trains consistently\n• I am becoming a person who keeps promises to myself\n• I am becoming a person who manages money calmly\n• I am becoming a person who reads daily\n\nThe habit becomes evidence for the identity. Every small repetition is a vote.\n\nYour action: choose one habit and write the identity it supports: I am becoming someone who...',
        },
        {
          'title': 'Design the Cue',
          'duration': '18 min',
          'content':
              'Habits need reliable cues. A cue is the trigger that tells your brain when to start. Without a cue, the habit depends on memory and motivation.\n\nStrong cues are:\n• Specific\n• Repeated daily\n• Attached to an existing routine\n• Visible in the environment\n• Easy to act on immediately\n\nExamples: after brushing my teeth, after making coffee, when I sit at my desk, after dinner.\n\nYour action: write your habit formula: After I..., I will...',
        },
        {
          'title': 'Make It Easy to Win',
          'duration': '20 min',
          'content':
              'Most people make habits too large at the start. The beginning goal is consistency, not intensity. Small habits build trust with yourself.\n\nReduce friction:\n• Prepare the environment\n• Lower the starting standard\n• Keep tools visible\n• Remove one obstacle\n• Track completion simply\n\nA two-minute version is not silly. It is how you teach the brain that showing up is normal.\n\nYour action: shrink your habit until it takes two minutes or less. Do that version for seven days.',
        },
        {
          'title': 'Recover Without Quitting',
          'duration': '18 min',
          'content':
              'Missing a day is not failure. The danger is turning one miss into an identity collapse. Growth requires recovery skill.\n\nRecovery rules:\n• Never miss twice when possible\n• Review the obstacle without shame\n• Lower the habit size if needed\n• Reconnect to the identity\n• Continue immediately\n\nConsistency is built by returning, not by being perfect.\n\nYour action: write your recovery plan now: If I miss, then I will...',
        },
      ],
    },
    {
      'title': 'Confidence Building 30 Days',
      'category': 'Personal Growth',
      'section': 'Mini Course',
      'tags': [
        'confidence',
        'self-esteem',
        'belief',
        'empowerment',
        '30 days',
        'self-worth',
      ],
      'desc': 'A 30-day program to dramatically increase your confidence.',
      'isCourse': true,
      'modules': [
        {
          'title': 'Confidence Comes from Evidence',
          'duration': '15 min',
          'content':
              'Confidence is not pretending you have no fear. It is the belief that you can act, learn, and handle outcomes. Real confidence grows from evidence.\n\nEvidence sources:\n• Kept promises\n• Skills practised\n• Difficult conversations survived\n• Small risks taken\n• Progress noticed\n\nDo not wait to feel confident before acting. Action creates confidence.\n\nYour action: write ten pieces of evidence that show you have handled hard things before.',
        },
        {
          'title': 'Challenge the Inner Critic',
          'duration': '20 min',
          'content':
              'The inner critic often sounds protective, but it can become a prison. Confidence grows when you stop treating every harsh thought as truth.\n\nQuestion the critic:\n• Is this fact or fear?\n• Would I say this to someone I love?\n• What evidence contradicts it?\n• What would be a fairer statement?\n\nYour action: write one self-critical thought and replace it with a truthful, balanced statement.',
        },
        {
          'title': 'Build Courage Repetitions',
          'duration': '22 min',
          'content':
              'Confidence grows through repeated manageable discomfort. You do not need one giant breakthrough. You need small courage reps.\n\nExamples:\n• Ask a question\n• Share an opinion\n• Say no clearly\n• Try something as a beginner\n• Let yourself be seen\n• Follow through when nervous\n\nYour action: choose one courage rep for today. Make it small enough to do and meaningful enough to feel.',
        },
        {
          'title': 'Carry Yourself Differently',
          'duration': '18 min',
          'content':
              'Your body and behaviour send signals to your mind. Posture, voice, pace, eye contact, preparation, and boundaries all reinforce identity.\n\nConfidence behaviours:\n• Stand or sit with steadiness\n• Speak at a calm pace\n• Prepare before important moments\n• Make clear requests\n• Keep one promise daily\n\nYour action: pick one confidence behaviour and practise it every day for the next week.',
        },
      ],
    },
    {
      'title': 'Emotional Mastery',
      'category': 'Personal Growth',
      'section': 'Mini Course',
      'tags': [
        'emotions',
        'emotional mastery',
        'regulation',
        'intelligence',
        'feelings',
        'control',
      ],
      'desc': 'Master your emotions instead of being controlled by them.',
      'isCourse': true,
      'modules': [
        {
          'title': 'Name the Emotion',
          'duration': '15 min',
          'content':
              'You cannot regulate what you cannot name. Many people say they feel bad when the real emotion is disappointment, shame, fear, grief, resentment, envy, or overwhelm.\n\nNaming creates space:\n• What am I feeling?\n• Where is it in the body?\n• What triggered it?\n• What does it want me to do?\n• What do I actually choose?\n\nYour action: use three specific emotion words today instead of fine, stressed, or bad.',
        },
        {
          'title': 'Regulate the Body First',
          'duration': '18 min',
          'content':
              'Emotions live in the body. Trying to think your way out of a flooded nervous system often fails. Start with physiology.\n\nRegulation tools:\n• Slow exhale breathing\n• Walking\n• Cold water on hands or face\n• Relaxing jaw and shoulders\n• Grounding through the senses\n• Taking a short pause before responding\n\nYour action: practise a 60-second regulation reset before replying to something that activates you.',
        },
        {
          'title': 'Understand the Message',
          'duration': '20 min',
          'content':
              'Emotions carry information, but they are not always instructions. Anger may point to a boundary. Sadness may point to loss. Anxiety may point to uncertainty or preparation.\n\nAsk:\n• What is this emotion trying to protect?\n• What need is underneath it?\n• Is the story accurate?\n• What action would be wise, not reactive?\n\nYour action: choose one strong emotion and write the need or value underneath it.',
        },
        {
          'title': 'Respond, Do Not React',
          'duration': '20 min',
          'content':
              'Reaction is automatic. Response is chosen. Emotional mastery is the pause where you can choose behaviour that matches your values.\n\nResponse process:\n• Pause\n• Breathe\n• Name the emotion\n• Check the story\n• Choose the next right action\n\nMastery does not mean never feeling intensely. It means your emotions no longer drive the car alone.\n\nYour action: write one sentence you can use to buy time: I need a moment to think before I answer.',
        },
      ],
    },
    // Personal Growth - Goals
    {
      'title': 'SMART Goals Workshop',
      'category': 'Personal Growth',
      'section': 'Goals',
      'tags': [
        'SMART goals',
        'goal setting',
        'achievement',
        'planning',
        'objectives',
        'targets',
      ],
      'desc': 'Set goals that you will actually achieve.',
      'isCourse': false,
    },
    {
      'title': 'Daily Routines for Success',
      'category': 'Personal Growth',
      'section': 'Goals',
      'tags': [
        'routines',
        'success',
        'daily habits',
        'morning routine',
        'evening routine',
        'discipline',
      ],
      'desc': 'Create daily routines that propel you toward success.',
      'isCourse': false,
    },
    {
      'title': 'Accountability Partnership',
      'category': 'Personal Growth',
      'section': 'Goals',
      'tags': [
        'accountability',
        'partnership',
        'goals',
        'support',
        'commitment',
        'motivation',
      ],
      'desc': 'Use accountability to achieve your biggest goals faster.',
      'isCourse': false,
    },
    // Personal Growth - Self-Discovery
    {
      'title': 'Values Discovery Exercise',
      'category': 'Personal Growth',
      'section': 'Self-Discovery',
      'tags': [
        'values',
        'core values',
        'beliefs',
        'identity',
        'self-knowledge',
        'purpose',
      ],
      'desc': 'Identify your core values for authentic living.',
      'isCourse': false,
    },
    {
      'title': 'StrengthsFinder Guide',
      'category': 'Personal Growth',
      'section': 'Self-Discovery',
      'tags': [
        'strengths',
        'talents',
        ' CliftonStrengths',
        'positive psychology',
        'potential',
        'abilities',
      ],
      'desc': 'Discover and leverage your natural strengths.',
      'isCourse': false,
    },
    {
      'title': 'Life Purpose Finding',
      'category': 'Personal Growth',
      'section': 'Self-Discovery',
      'tags': ['purpose', 'meaning', 'Ikigai', 'calling', 'mission', 'reason'],
      'desc': 'Find your life purpose using proven frameworks.',
      'isCourse': true,
    },
  ];

  List<Map<String, dynamic>> get _filteredContent {
    if (_query.isEmpty) return [];
    final lowerQuery = _query.toLowerCase();
    return _allContent.where((item) {
      final title = (item['title'] as String).toLowerCase();
      final desc = (item['desc'] as String).toLowerCase();
      final tags = (item['tags'] as List<String>)
          .map((t) => t.toLowerCase())
          .toList();
      final category = (item['category'] as String).toLowerCase();
      final section = (item['section'] as String).toLowerCase();
      return title.contains(lowerQuery) ||
          desc.contains(lowerQuery) ||
          tags.any((t) => t.contains(lowerQuery)) ||
          category.contains(lowerQuery) ||
          section.contains(lowerQuery);
    }).toList();
  }

  Color _getCategoryColor(String category) {
    // Brand color - emerald for uniform look
    return Theme.of(context).colorScheme.primary;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = _filteredContent;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          style: GoogleFonts.outfit(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 16,
          ),
          decoration: InputDecoration(
            hintText: 'Search lessons and courses...',
            hintStyle: GoogleFonts.outfit(
              color: Colors.grey[500],
              fontSize: 16,
            ),
            border: InputBorder.none,
          ),
          onChanged: (value) => setState(() => _query = value),
        ),
        actions: [
          if (_query.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, color: Colors.grey),
              onPressed: () {
                _searchController.clear();
                setState(() => _query = '');
              },
            ),
        ],
      ),
      body: SafeArea(
        child: _query.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.search,
                      color: Colors.grey[700],
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Search across all lessons and courses',
                      style: GoogleFonts.outfit(
                        color: Colors.grey[500],
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            [
                                  'manifesting',
                                  'affirmations',
                                  'relationships',
                                  'career',
                                  'meditation',
                                  'habits',
                                  'confidence',
                                  'goals',
                                ]
                                .map(
                                  (tag) => GestureDetector(
                                    onTap: () => setState(() => _query = tag),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[800],
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Text(
                                        tag,
                                        style: GoogleFonts.outfit(
                                          color: Colors.grey[300],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                      ),
                    ),
                  ],
                ),
              )
            : results.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.doc_text_search,
                      color: Colors.grey[700],
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No results found for "$_query"',
                      style: GoogleFonts.outfit(
                        color: Colors.grey[500],
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: results.length,
                itemBuilder: (context, index) {
                  final item = results[index];
                  final color = _getCategoryColor(item['category']);
                  return GestureDetector(
                    onTap: () {
                      final List<Map<String, String>>? modules =
                          (item['modules'] as List?)
                              ?.map((m) => Map<String, String>.from(m))
                              .toList();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => item['isCourse']
                              ? SelfHelpCourseView(
                                  title: item['title'],
                                  description: item['desc'],
                                  category: item['section'],
                                  color: color,
                                  modules: modules,
                                )
                              : SelfHelpArticleView(
                                  title: item['title'],
                                  description: item['desc'],
                                  category: item['section'],
                                  parentCategory: item['category'],
                                  color: color,
                                ),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(8),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(color: color.withAlpha(25)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: color.withAlpha(25),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  item['category'].toUpperCase(),
                                  style: GoogleFonts.outfit(
                                    color: color,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withAlpha(20),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  item['section'],
                                  style: GoogleFonts.outfit(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface.withAlpha(200),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Icon(
                                item['isCourse']
                                    ? CupertinoIcons.book_fill
                                    : CupertinoIcons.doc_text_fill,
                                color: color,
                                size: 18,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            item['title'],
                            style: GoogleFonts.outfit(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item['desc'],
                            style: GoogleFonts.outfit(
                              color: Colors.grey[400],
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: (item['tags'] as List<String>)
                                .take(4)
                                .map(
                                  (tag) => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[850],
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '#$tag',
                                      style: GoogleFonts.outfit(
                                        color: Colors.grey[500],
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

Color _readableCardForeground(Color color) {
  final luminance = color.computeLuminance();
  if (luminance > 0.62) {
    return Color.lerp(color, Colors.black, 0.68)!;
  }
  return Colors.white;
}

Color _badgeGlyphColor(Color color) {
  return color.computeLuminance() > 0.62
      ? Color.lerp(color, Colors.black, 0.5)!
      : color;
}

LinearGradient _cardGradient(Color color) {
  return LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color.lerp(color, Colors.white, 0.14)!,
      color,
      Color.lerp(color, Colors.black, 0.12)!,
    ],
    stops: const [0, 0.52, 1],
  );
}

Color _themeStackColor(BuildContext context, int index) {
  final base = Theme.of(context).colorScheme.primary;
  const strengths = [0.0, 0.09, 0.17, 0.24, 0.12, 0.29, 0.2, 0.34];
  final strength = strengths[index % strengths.length];
  return index.isEven
      ? Color.lerp(base, Colors.white, strength)!
      : Color.lerp(base, Colors.black, strength * 0.58)!;
}

class _StackedIndexCardList extends StatefulWidget {
  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final ValueChanged<int> onTap;
  final double cardHeight;
  final double collapsedStep;
  final double expandedStep;

  const _StackedIndexCardList({
    required this.itemCount,
    required this.itemBuilder,
    required this.onTap,
    this.cardHeight = 176,
    this.collapsedStep = 92,
    this.expandedStep = 132,
  });

  @override
  State<_StackedIndexCardList> createState() => _StackedIndexCardListState();
}

class _StackedIndexCardListState extends State<_StackedIndexCardList> {
  int? _activeIndex;

  @override
  Widget build(BuildContext context) {
    final height =
        widget.cardHeight + ((widget.itemCount - 1) * widget.collapsedStep) + 8;
    final expandedHeight =
        widget.cardHeight + ((widget.itemCount - 1) * widget.expandedStep) + 8;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      height: _activeIndex == null ? height : expandedHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: List.generate(widget.itemCount, (index) {
          final isActive = _activeIndex == index;
          final step = _activeIndex == null
              ? widget.collapsedStep
              : widget.expandedStep;

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
                child: _StackTapProxy(
                  onPressed: () async {
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

class _StackTapProxy extends StatelessWidget {
  final Widget child;
  final VoidCallback onPressed;

  const _StackTapProxy({required this.child, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onPressed,
      child: child,
    );
  }
}

class _WalletPreviewSheet extends StatelessWidget {
  final String title;
  final String subtitle;
  final String description;
  final Color color;
  final String glyph;
  final String actionLabel;
  final VoidCallback onAction;

  const _WalletPreviewSheet({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.color,
    required this.glyph,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final foreground = _readableCardForeground(color);

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
                Container(
                  constraints: const BoxConstraints(minHeight: 210),
                  padding: const EdgeInsets.all(20),
                  color: color,
                  child: Stack(
                    children: [
                      Align(
                        alignment: Alignment.bottomLeft,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _SolidGlyphBadge(
                              glyph: glyph,
                              color: _badgeGlyphColor(color),
                              background: Colors.white.withAlpha(225),
                              size: 54,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.outfit(
                                      color: foreground,
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    subtitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.outfit(
                                      color: foreground.withAlpha(185),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
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

class _SolidGlyphBadge extends StatelessWidget {
  final String glyph;
  final Color color;
  final Color background;
  final double size;

  const _SolidGlyphBadge({
    required this.glyph,
    required this.color,
    required this.background,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Center(
        child: _TopicGlyph(glyph: glyph, color: color, size: size * 0.56),
      ),
    );
  }
}

class _TopicGlyph extends StatelessWidget {
  final String glyph;
  final Color color;
  final double size;

  const _TopicGlyph({
    required this.glyph,
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _TopicGlyphPainter(glyph, color)),
    );
  }
}

class _TopicGlyphPainter extends CustomPainter {
  final String glyph;
  final Color color;

  const _TopicGlyphPainter(this.glyph, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.075
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    Offset p(double x, double y) => Offset(w * x, h * y);
    Rect r(double l, double t, double rr, double b) =>
        Rect.fromLTRB(w * l, h * t, w * rr, h * b);

    switch (glyph) {
      case 'health':
      case 'heart':
        final path = Path()
          ..moveTo(w * 0.5, h * 0.78)
          ..cubicTo(w * 0.16, h * 0.54, w * 0.16, h * 0.25, w * 0.38, h * 0.24)
          ..cubicTo(w * 0.48, h * 0.24, w * 0.5, h * 0.33, w * 0.5, h * 0.33)
          ..cubicTo(w * 0.5, h * 0.33, w * 0.52, h * 0.24, w * 0.62, h * 0.24)
          ..cubicTo(w * 0.84, h * 0.25, w * 0.84, h * 0.54, w * 0.5, h * 0.78);
        canvas.drawPath(path, fill);
        break;
      case 'wealth':
        canvas.drawCircle(p(0.5, 0.5), w * 0.29, stroke);
        canvas.drawLine(p(0.5, 0.26), p(0.5, 0.74), stroke);
        canvas.drawArc(r(0.34, 0.29, 0.66, 0.5), 1.2, 3.7, false, stroke);
        canvas.drawArc(r(0.34, 0.5, 0.66, 0.71), -1.9, 3.7, false, stroke);
        break;
      case 'relationships':
      case 'people':
        canvas.drawCircle(p(0.36, 0.36), w * 0.13, fill);
        canvas.drawCircle(p(0.64, 0.36), w * 0.13, fill);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            r(0.18, 0.54, 0.82, 0.76),
            Radius.circular(w * 0.11),
          ),
          fill,
        );
        break;
      case 'career':
      case 'hustle':
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            r(0.2, 0.34, 0.8, 0.72),
            Radius.circular(w * 0.07),
          ),
          stroke,
        );
        canvas.drawLine(p(0.38, 0.34), p(0.38, 0.25), stroke);
        canvas.drawLine(p(0.62, 0.34), p(0.62, 0.25), stroke);
        canvas.drawLine(p(0.38, 0.25), p(0.62, 0.25), stroke);
        canvas.drawLine(p(0.2, 0.48), p(0.8, 0.48), stroke);
        break;
      case 'spiritual':
      case 'spark':
        canvas.drawLine(p(0.5, 0.16), p(0.5, 0.84), stroke);
        canvas.drawLine(p(0.16, 0.5), p(0.84, 0.5), stroke);
        canvas.drawLine(p(0.28, 0.28), p(0.72, 0.72), stroke);
        canvas.drawLine(p(0.72, 0.28), p(0.28, 0.72), stroke);
        break;
      case 'growth':
      case 'trend':
        canvas.drawLine(p(0.2, 0.72), p(0.38, 0.55), stroke);
        canvas.drawLine(p(0.38, 0.55), p(0.52, 0.62), stroke);
        canvas.drawLine(p(0.52, 0.62), p(0.8, 0.28), stroke);
        canvas.drawLine(p(0.66, 0.28), p(0.8, 0.28), stroke);
        canvas.drawLine(p(0.8, 0.28), p(0.8, 0.42), stroke);
        break;
      case 'book':
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            r(0.18, 0.22, 0.49, 0.78),
            Radius.circular(w * 0.05),
          ),
          stroke,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            r(0.51, 0.22, 0.82, 0.78),
            Radius.circular(w * 0.05),
          ),
          stroke,
        );
        canvas.drawLine(p(0.5, 0.25), p(0.5, 0.78), stroke);
        break;
      case 'mind':
        canvas.drawCircle(p(0.43, 0.42), w * 0.2, stroke);
        canvas.drawCircle(p(0.62, 0.42), w * 0.2, stroke);
        canvas.drawLine(p(0.28, 0.68), p(0.72, 0.68), stroke);
        break;
      case 'nutrition':
        canvas.drawOval(r(0.25, 0.24, 0.72, 0.75), stroke);
        canvas.drawLine(p(0.6, 0.22), p(0.78, 0.16), stroke);
        canvas.drawLine(p(0.48, 0.5), p(0.34, 0.62), stroke);
        break;
      case 'bio':
        canvas.drawCircle(p(0.3, 0.66), w * 0.08, fill);
        canvas.drawCircle(p(0.5, 0.5), w * 0.08, fill);
        canvas.drawCircle(p(0.7, 0.34), w * 0.08, fill);
        canvas.drawLine(p(0.34, 0.62), p(0.46, 0.54), stroke);
        canvas.drawLine(p(0.54, 0.46), p(0.66, 0.38), stroke);
        break;
      case 'time':
      case 'timer':
      case 'calendar':
        canvas.drawCircle(p(0.5, 0.54), w * 0.3, stroke);
        canvas.drawLine(p(0.5, 0.54), p(0.5, 0.35), stroke);
        canvas.drawLine(p(0.5, 0.54), p(0.65, 0.62), stroke);
        break;
      case 'wallet':
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            r(0.18, 0.34, 0.82, 0.72),
            Radius.circular(w * 0.08),
          ),
          stroke,
        );
        canvas.drawCircle(p(0.66, 0.53), w * 0.045, fill);
        break;
      case 'bridge':
        canvas.drawArc(r(0.18, 0.34, 0.82, 0.94), 3.14, 3.14, false, stroke);
        canvas.drawLine(p(0.2, 0.62), p(0.8, 0.62), stroke);
        canvas.drawLine(p(0.34, 0.62), p(0.34, 0.78), stroke);
        canvas.drawLine(p(0.66, 0.62), p(0.66, 0.78), stroke);
        break;
      case 'star':
        final path = Path()
          ..moveTo(w * 0.5, h * 0.15)
          ..lineTo(w * 0.6, h * 0.4)
          ..lineTo(w * 0.86, h * 0.4)
          ..lineTo(w * 0.65, h * 0.56)
          ..lineTo(w * 0.73, h * 0.82)
          ..lineTo(w * 0.5, h * 0.66)
          ..lineTo(w * 0.27, h * 0.82)
          ..lineTo(w * 0.35, h * 0.56)
          ..lineTo(w * 0.14, h * 0.4)
          ..lineTo(w * 0.4, h * 0.4)
          ..close();
        canvas.drawPath(path, fill);
        break;
      case 'voice':
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            r(0.38, 0.18, 0.62, 0.58),
            Radius.circular(w * 0.12),
          ),
          stroke,
        );
        canvas.drawArc(r(0.25, 0.42, 0.75, 0.82), 0.2, 2.7, false, stroke);
        canvas.drawLine(p(0.5, 0.76), p(0.5, 0.88), stroke);
        break;
      case 'scroll':
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            r(0.25, 0.18, 0.75, 0.78),
            Radius.circular(w * 0.08),
          ),
          stroke,
        );
        canvas.drawLine(p(0.36, 0.38), p(0.64, 0.38), stroke);
        canvas.drawLine(p(0.36, 0.54), p(0.6, 0.54), stroke);
        break;
      case 'bolt':
        final path = Path()
          ..moveTo(w * 0.58, h * 0.12)
          ..lineTo(w * 0.28, h * 0.52)
          ..lineTo(w * 0.5, h * 0.52)
          ..lineTo(w * 0.4, h * 0.88)
          ..lineTo(w * 0.74, h * 0.43)
          ..lineTo(w * 0.52, h * 0.43)
          ..close();
        canvas.drawPath(path, fill);
        break;
      case 'shield':
        final path = Path()
          ..moveTo(w * 0.5, h * 0.14)
          ..lineTo(w * 0.78, h * 0.26)
          ..lineTo(w * 0.72, h * 0.68)
          ..lineTo(w * 0.5, h * 0.86)
          ..lineTo(w * 0.28, h * 0.68)
          ..lineTo(w * 0.22, h * 0.26)
          ..close();
        canvas.drawPath(path, stroke);
        break;
      case 'strength':
        canvas.drawLine(p(0.22, 0.56), p(0.78, 0.56), stroke);
        canvas.drawLine(p(0.32, 0.38), p(0.32, 0.74), stroke);
        canvas.drawLine(p(0.68, 0.38), p(0.68, 0.74), stroke);
        canvas.drawLine(p(0.18, 0.45), p(0.18, 0.67), stroke);
        canvas.drawLine(p(0.82, 0.45), p(0.82, 0.67), stroke);
        break;
      case 'person':
        canvas.drawCircle(p(0.5, 0.34), w * 0.14, stroke);
        canvas.drawArc(r(0.25, 0.5, 0.75, 0.95), 3.45, 2.54, false, stroke);
        break;
      default:
        canvas.drawCircle(p(0.5, 0.5), w * 0.26, stroke);
        canvas.drawLine(p(0.5, 0.2), p(0.5, 0.8), stroke);
    }
  }

  @override
  bool shouldRepaint(covariant _TopicGlyphPainter oldDelegate) {
    return oldDelegate.glyph != glyph || oldDelegate.color != color;
  }
}

class _CategoryCard extends StatelessWidget {
  final Map<String, dynamic> category;
  final Color color;

  const _CategoryCard({required this.category, required this.color});

  @override
  Widget build(BuildContext context) {
    final foreground = _readableCardForeground(color);

    return SizedBox(
      height: 176,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: _cardGradient(color),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: foreground.withAlpha(28),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
          border: Border.all(color: foreground.withAlpha(18)),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
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
                              category['title'],
                              textAlign: TextAlign.right,
                              style: GoogleFonts.outfit(
                                color: foreground,
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              category['subtitle'],
                              textAlign: TextAlign.right,
                              style: GoogleFonts.outfit(
                                color: foreground.withAlpha(185),
                                fontSize: 13,
                                height: 1.15,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryDetailPage extends StatelessWidget {
  final Map<String, dynamic> category;
  final Color color;
  final VoidCallback onBack;

  const _CategoryDetailPage({
    required this.category,
    required this.color,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final String id = category['id'];

    final Map<String, Map<String, dynamic>> categoryContent = {
      'health': {
        'intro':
            'True health encompasses physical vitality, mental clarity, and emotional balance. These resources help you create holistic wellbeing.',
        'manifestation': [
          {
            'title': 'Body Gratitude Meditation',
            'desc':
                'Appreciating what your body does can support kinder, more consistent self-care. Pair gratitude with one practical health-supporting choice today.',
          },
          {
            'title': 'Healthy Identity Visualization',
            'desc':
                'See yourself as a naturally healthy person. Your identity shapes your habits more than any willpower strategy.',
          },
          {
            'title': 'Future Self Letter',
            'desc':
                'Write a letter from your healthiest future self. What advice would they give you today?',
          },
          {
            'title': 'Cellular Healing Visualization',
            'desc':
                'Visualization can help you slow down and support recovery habits, but it does not replace medical care. Use the practice to notice what your body needs today.',
          },
        ],
        'psychology': [
          {
            'title': 'The Habits of Exceptionally Healthy People',
            'desc':
                'Research shows the #1 trait of healthy individuals isn\'t diet or exercise — it\'s consistency in small choices.',
          },
          {
            'title': 'Stress and Your Nervous System',
            'desc':
                'Stress changes sleep, attention, and recovery. Notice your early stress signals and use simple regulation tools before they build into overwhelm.',
          },
          {
            'title': 'The Mind-Body Connection',
            'desc':
                'How your thoughts and beliefs directly influence your physical health through measurable biological pathways.',
          },
          {
            'title': 'Psychological Resilience',
            'desc':
                'Learn the mental frameworks that allow you to maintain health habits even during times of high stress.',
          },
        ],
        'courses': [
          {
            'title': '21-Day Health Reset',
            'desc':
                'A structured program to establish foundational health habits. One small change per day for three weeks.',
            'modules': [
              {
                'title': 'Day 1: Intentions & The "Why"',
                'duration': '10 min',
                'content':
                    'Welcome to Day 1. Before we change what you do, we must change *why* you do it. Health is not a destination, but a state of maintenance and vitality.\n\nToday, your task is to write down three specific reasons why you want to improve your health. Is it for your children? For confidence? For longevity?\n\nSetting clear intentions creates a psychological anchor for when initial motivation fades.',
              },
              {
                'title': 'Day 2: The Hydration Foundation',
                'duration': '5 min',
                'content':
                    'Water is the solvent of life. It transports nutrients and flushes toxins. Most fatigue is actually mild dehydration.\n\nYour Goal: Drink 2-3 liters of water today. Start with a large glass first thing in the morning to kickstart your metabolism and brain function.',
              },
              {
                'title': 'Day 3: Strategic Micro-Movement',
                'duration': '8 min',
                'content':
                    'You don\'t need an hour at the gym to make a difference. Sedentary behavior is a metabolic silent killer.\n\nYour Goal: Every 60 minutes, stand up and stretch for 2 minutes. This keeps your lymphatic system moving and prevents metabolic slowdown.',
              },
              {
                'title': 'Day 4: Digital Sunset',
                'duration': '12 min',
                'content':
                    'Your eyes are windows to your internal clock. Blue light after sunset trick your brain into thinking it\'s noon, suppressing melatonin.\n\nYour Goal: Dim your lights after 8 PM and avoid screens for at least 60 minutes before bed. Let your nervous system down-regulate.',
              },
              {
                'title': 'Day 5: The Power of Breath',
                'duration': '10 min',
                'content':
                    'Breathing is the only part of your autonomic nervous system you can consciously control. Box breathing can flip the switch from "fight or flight" to "rest and digest."\n\nYour Goal: Practice 4-4-4-4 breathing (inhale 4, hold 4, exhale 4, hold 4) for five minutes when you feel stressed today.',
              },
              {
                'title': 'Day 6: Morning Sunlight',
                'duration': '15 min',
                'content':
                    'Sunlight in your eyes within 30 minutes of waking triggers a cortisol spike (for alertness) and sets the timer for melatonin release tonight.\n\nYour Goal: Get 10 minutes of direct outdoor light this morning. Even if it\'s cloudy, the photons are powerful.',
              },
              {
                'title': 'Day 7: Mindful Satiety',
                'duration': '15 min',
                'content':
                    'We often eat until the plate is empty, not until we are full. It takes 20 minutes for your brain to receive the "I\'m full" signal.\n\nYour Goal: Today, eat one meal in complete silence. Chew thoroughly and stop when you are 80% full (the Japanese concept of *Hara Hachi Bu*).',
              },
              {
                'title': 'Day 8: Protein & Satiety',
                'duration': '10 min',
                'content':
                    'Protein is the most satiating macronutrient. It supports muscle repair and stabilizes blood sugar.\n\nYour Goal: Ensure your first meal of the day contains at least 30g of protein. This will significantly reduce "junk food" cravings in the afternoon.',
              },
              {
                'title': 'Day 9: The Walking Meditation',
                'duration': '20 min',
                'content':
                    'Walking is the most underrated form of exercise. It clears cortisol and sparks creativity.\n\nYour Goal: Take a 20-minute walk without a phone or podcast. Just observe your surroundings and let your mind process the day\'s thoughts.',
              },
              {
                'title': 'Day 10: Cold Resilience',
                'duration': '5 min',
                'content':
                    'Short bursts of cold exposure trigger "hormetic stress," which strengthens the immune system and boosts dopamine.\n\nYour Goal: At the end of your warm shower today, turn it to full cold for just 30 seconds. Focus on controlling your breath.',
              },
              {
                'title': 'Day 11: Sleep Sanctuary',
                'duration': '15 min',
                'content':
                    'Your bedroom should be a sanctuary for sleep. Ideally cool, dark, and quiet.\n\nYour Goal: Audit your room. Remove glowing electronics, ensure the temperature is around 18°C (65°F), and use blackout curtains if possible.',
              },
              {
                'title': 'Day 12: Gratitude for Vitality',
                'duration': '10 min',
                'content':
                    'Health isn\'t just physical; it\'s psychological. Focusing on what your body *can* do changes your relationship with exercise.\n\nYour Goal: List three things you are grateful for regarding your physical body today. (e.g., "I am grateful for my legs that carry me.")',
              },
              {
                'title': 'Day 13: Functional Mobility',
                'duration': '12 min',
                'content':
                    'Longevity is tied to mobility. Stiff joints lead to less movement, which leads to more stiffness.\n\nYour Goal: Spend 10 minutes on the floor today. Get up and down 5 times using different techniques. This builds foundational functional strength.',
              },
              {
                'title': 'Day 14: Mid-Point Reflection',
                'duration': '15 min',
                'content':
                    'Two weeks down! Consistency is more important than perfection. You have already started rewiring your habits.\n\nYour Goal: Review your original Day 1 intentions. How have your feelings about your health changed in the last 14 days?',
              },
              {
                'title': 'Day 15: Clean Fuel Audit',
                'duration': '12 min',
                'content':
                    'Ultra-processed foods are designed to bypass your satiety signals. They create inflammation and brain fog.\n\nYour Goal: Today, try to eat only "single-ingredient" foods. If it has a long label of chemicals, skip it for 24 hours.',
              },
              {
                'title': 'Day 16: Consistency > Intensity',
                'duration': '8 min',
                'content':
                    'Sustainability is the key to legacy health. One perfect day followed by 10 bad ones is worse than 11 "good enough" days.\n\nYour Goal: Aim for the 80/20 rule. Focus on your core habits 80% of the time, and allow yourself grace for the other 20%.',
              },
              {
                'title': 'Day 17: Social Health',
                'duration': '15 min',
                'content':
                    'Health is contagious. We tend to mirror the habits of those we spend the most time with.\n\nYour Goal: Reach out to one friend today who inspires you to be better. Share one win you\'ve had during this 21-day reset.',
              },
              {
                'title': 'Day 18: Cognitive Rest',
                'duration': '10 min',
                'content':
                    'A tired brain makes poor health choices. Information overload is a form of stress that drives emotional eating.\n\nYour Goal: Spend 30 minutes today in "Input Zero." No podcasts, no news, no social media. Just let your brain rest.',
              },
              {
                'title': 'Day 19: Environment Optimization',
                'duration': '20 min',
                'content':
                    'Willpower is a finite resource. Don\'t rely on it—optimize your environment instead.\n\nYour Goal: Rearrange your kitchen or workspace to make healthy choices the "default." Put water on your desk and hide the snacks in a high cupboard.',
              },
              {
                'title': 'Day 20: Visualizing the Future Self',
                'duration': '15 min',
                'content':
                    'You are now a person who prioritizes their health. This is an identity shift, not just a temporary diet.\n\nYour Goal: Visualize yourself 5 years from now if you continue these habits. What does that person look like? How do they feel?',
              },
              {
                'title': 'Day 21: Graduation & The Path Forward',
                'duration': '20 min',
                'content':
                    'Congratulations! You have completed the 21-Day Health Reset. This isn\'t the end; it\'s the foundation for the rest of your life.\n\nYour Goal: Select the top 3 habits from this reset that felt the most impactful. Commit to keeping these as your "Non-Negotiables" for the next 90 days.',
              },
            ],
          },
          {
            'title': 'Sleep Optimization Mastery',
            'desc':
                'Learn the science of restorative sleep and create your perfect nightly routine.',
            'modules': [
              {
                'title': 'The Science of Circadian Rhythms',
                'duration': '20 min',
                'content':
                    'Your body has an internal clock that regulates everything from your hormones to your body temperature. This is your circadian rhythm. When this rhythm is disrupted — by blue light late at night or irregular wake times — your health suffers.\n\nTo optimize this, you must prioritize morning sunlight. Within 30 minutes of waking, try to get 10-15 minutes of direct sunlight. This sets your internal clock and triggers the release of cortisol (for alertness) and sets the timer for melatonin release 16 hours later.',
              },
              {
                'title': 'Optimizing Your Sleep Environment',
                'duration': '15 min',
                'content':
                    'Your bedroom should be a sanctuary for sleep. The ideal environment is cool, dark, and quiet.\n\n1. Temperature: Aim for roughly 18°C (65°F). Your body temperature needs to drop for deep sleep to occur.\n2. Light: Use blackout curtains or an eye mask. Even a small amount of light can disrupt melatonin production.\n3. Noise: Use white noise if you live in a noisy area. Remove all electronics that have glowing standby lights.',
              },
              {
                'title': 'The Perfect Evening Wind-down',
                'duration': '25 min',
                'content':
                    'The 90 minutes before bed are critical. If you are working or scrolling until the moment you close your eyes, your brain will remain in an active state.\n\nCreate a wind-down routine: Dim the lights in your home after sunset. Stop using screens at least 60 minutes before bed. Instead, read a physical book, listen to calming music, or engage in a light stretching routine. This signals to your nervous system that it is safe to down-regulate into sleep mode.',
              },
              {
                'title': 'Morning Routine for Better Nights',
                'duration': '15 min',
                'content':
                    'Good sleep starts the moment you wake up. Besides getting sunlight, avoid caffeine for the first 90 minutes of your day. This allows your body to naturally clear out adenosine, the chemical that makes you feel sleepy.\n\nBy following these principles consistently, you aren\'t just "sleeping better" — you are optimizing your cognitive function, emotional stability, and physical recovery. Sleep is the foundation of high performance.',
              },
            ],
          },
          {
            'title': 'The Resilience Protocol',
            'desc':
                'Build a nervous system that remains calm, clear, and focused under high-pressure situations.',
            'modules': [
              {'title': 'Nervous System Foundations', 'duration': '15 min'},
              {'title': 'State-Shifting Techniques', 'duration': '20 min'},
              {'title': 'Building Hormetic Stress', 'duration': '25 min'},
              {'title': 'The Recovery Requirement', 'duration': '15 min'},
            ],
          },
          {
            'title': 'Metabolic Health Mastery',
            'desc':
                'Optimize your nutrition and lifestyle to maintain stable energy, sharp focus, and long-term vitality.',
            'modules': [
              {'title': 'Glucose & Insulin 101', 'duration': '20 min'},
              {'title': 'Strategic Fasting Protocols', 'duration': '15 min'},
              {'title': 'Muscle as Metabolic Armor', 'duration': '25 min'},
              {'title': 'Microbiome Energy Flow', 'duration': '20 min'},
            ],
          },
        ],
        'nutrition': [
          {
            'title': 'The Anti-Inflammatory Diet',
            'desc':
                'Chronic inflammation is the root of many diseases. Learn which foods fight it effectively.',
          },
          {
            'title': 'Intermittent Fasting Guide',
            'desc':
                'Improve insulin sensitivity and trigger autophagy through strategic time-restricted eating.',
          },
          {
            'title': 'Metabolic Health 101',
            'desc':
                'Stable blood sugar is the secret to consistent energy and long-term health. Avoid the glucose roller coaster.',
          },
          {
            'title': 'The Gut-Brain Axis',
            'desc':
                'Understand how your microbiome influences your mood, cravings, and cognitive function.',
          },
        ],
        'biohacking': [
          {
            'title': 'Cold Exposure Protocols',
            'desc':
                'From ice baths to cold showers: the biological benefits of deliberate cold stress.',
          },
          {
            'title': 'Optimizing Your Microbiome',
            'desc':
                '70% of your immune system lives in your gut. Learn how to feed your inner ecosystem.',
          },
          {
            'title': 'Nervous System Regulation',
            'desc':
                'Master the art of flipping the switch between stress and recovery mode at will.',
          },
          {
            'title': 'Light & Mitochondrial Health',
            'desc':
                'Leverage red light and infrared therapy to boost energy production at the cellular level.',
          },
        ],
        'longevity': [
          {
            'title': 'The Science of Aging',
            'desc':
                'Understanding telomeres, mitochondrial health, and how to delay biological aging.',
          },
          {
            'title': 'Zone 2 Training for Life',
            'desc':
                'The specific heart rate zone that builds mitochondrial density and aerobic base for longevity.',
          },
          {
            'title': 'Blue Zones Lessons',
            'desc':
                'The common habits of the world\'s longest-living populations: diet, community, and purpose.',
          },
          {
            'title': 'Supplementation for Longevity',
            'desc':
                'A nuanced look at NAD+, Resveratrol, and Spermidine: separating science from marketing.',
          },
        ],
      },
      'wealth': {
        'intro':
            'Wealth is more than money — it\'s a mindset of abundance, smart financial habits, and helping you just understand prosperity.',
        'manifestation': [
          {
            'title': 'Abundance Visualization',
            'desc':
                'A daily practice to visualize yourself living in financial freedom. Feel the peace of having enough.',
          },
          {
            'title': 'Money Affirmations Practice',
            'desc':
                'Reprogram your relationship with money by replacing scarcity-based thoughts with abundant ones.',
          },
          {
            'title': 'Living in Abundance',
            'desc':
                'Shift from "I can\'t afford it" to "How can I afford it?" This one reframe opens creative possibilities.',
          },
          {
            'title': 'The Generosity Frequency',
            'desc':
                'Generosity is most sustainable when it fits your means. Give useful value without treating generosity as a guarantee of financial return.',
          },
        ],
        'psychology': [
          {
            'title': 'The Psychology of Money',
            'desc':
                'Financial choices are emotional as well as practical. A written plan and a pause before big decisions reduce impulsive money mistakes.',
          },
          {
            'title': 'Your Money Story',
            'desc':
                'Most people\'s financial behavior is shaped by childhood beliefs about money. Discover and rewrite yours.',
          },
          {
            'title': 'Delayed Gratification as a Skill',
            'desc':
                'Self-control is easier when your environment reduces temptation and makes the long-term choice convenient. Build systems instead of relying on willpower alone.',
          },
          {
            'title': 'Wealth Identity Shift',
            'desc':
                'Upgrade your internal thermostat. Stop sabotaging yourself when you reach new levels of success.',
          },
        ],
        'courses': [
          {
            'title': 'Financial Foundation Builder',
            'desc':
                'Create your first financial roadmap: budgeting, emergency funds, and debt payoff strategy.',
            'modules': [
              {
                'title': 'Know Your Numbers',
                'duration': '15 min',
                'content':
                    'Financial confidence begins with truth, not optimism. This module gives you a clean snapshot of where your money is going right now.\n\nWrite down:\n• Monthly take-home income\n• Fixed bills\n• Flexible spending\n• Debt balances and interest rates\n• Savings and emergency cash\n• Upcoming irregular costs\n\nDo not judge the numbers while collecting them. The first win is visibility. Once the numbers are visible, you can make intelligent decisions instead of emotional guesses.\n\nYour action: create a one-page money snapshot and circle the three numbers that need the most attention.',
              },
              {
                'title': 'Building Your Budget',
                'duration': '20 min',
                'content':
                    'A budget is a plan for your priorities. It should tell your money where to go without making your life feel like a punishment.\n\nUse four simple buckets:\n• Essentials: housing, food, transport, utilities\n• Protection: emergency fund, insurance, minimum debt payments\n• Growth: investing, learning, business building\n• Enjoyment: social life, hobbies, personal spending\n\nIf the budget only works on a perfect month, it is not finished. Add room for real life.\n\nYour action: build next month before it starts. Assign every pound to a bucket, then choose one automatic transfer you can set up on payday.',
              },
              {
                'title': 'Emergency Fund Strategy',
                'duration': '15 min',
                'content':
                    'An emergency fund is not dead money. It is protection from panic. It stops a broken appliance, car repair, job gap, or family issue from becoming debt.\n\nBuild it in stages:\n• Stage 1: starter buffer for small shocks\n• Stage 2: one month of essential expenses\n• Stage 3: three to six months, based on stability\n\nKeep emergency money boring, accessible, and separate from daily spending. Its job is safety, not growth.\n\nYour action: name your emergency fund and set a target. Then choose the weekly or monthly amount that starts the habit.',
              },
              {
                'title': 'Debt Payoff Blueprint',
                'duration': '25 min',
                'content':
                    'Debt strategy starts with knowing which debts are expensive, which are manageable, and which are emotionally draining.\n\nTwo common methods:\n• Avalanche: pay highest interest first to reduce total cost\n• Snowball: pay smallest balance first to build momentum\n\nKeep paying minimums on everything, then aim extra money at the chosen target. Avoid adding new debt while paying old debt down, or the plan becomes a treadmill.\n\nYour action: rank your debts, choose avalanche or snowball, and write your first payoff target with a date. If you feel overwhelmed, start with the smallest clear next payment.',
              },
            ],
          },
          {
            'title': 'Investment Mindset',
            'desc':
                'Understand the psychology behind investing and build confidence in growing your wealth.',
            'modules': [
              {
                'title': 'Mindset of Wealth',
                'duration': '20 min',
                'content':
                    'A wealth mindset is not pretending money does not matter. It is learning to make decisions from patience, value, and ownership rather than fear, comparison, or impulse.\n\nCore beliefs to practise:\n• I can learn the rules of money\n• Small consistent actions compound\n• Wealth is built by owning assets, not only earning wages\n• I can spend with joy and still protect my future\n\nYour action: write one scarcity belief you repeat often, then rewrite it into a practical wealth belief you can act on this week.',
              },
              {
                'title': 'Understanding Risk',
                'duration': '15 min',
                'content':
                    'Risk is not automatically bad. Risk is the price of growth, but unmanaged risk is chaos.\n\nCommon investing risks:\n• Market risk: values move up and down\n• Concentration risk: too much in one asset\n• Liquidity risk: needing cash when an asset is down\n• Behaviour risk: panic buying or panic selling\n• Knowledge risk: investing in what you do not understand\n\nYour action: choose a personal risk rule. Example: I will not invest money I need within three years, or I will not put more than a small percentage into one speculative idea.',
              },
              {
                'title': 'Building Passive Income',
                'duration': '25 min',
                'content':
                    'Passive income starts as active design. You build or buy something that can produce income with less direct effort over time.\n\nPaths include:\n• Dividend or fund income\n• Rental or property income\n• Digital products\n• Royalties and licensing\n• Automated business systems\n• Interest from savings or bonds\n\nEach path has trade-offs. Some need capital. Some need skill. Some need audience. Some need patience.\n\nYour action: pick one path and write the next learning step, the first action step, and the biggest risk to understand before starting.',
              },
              {
                'title': 'Long-term Wealth Strategy',
                'duration': '20 min',
                'content':
                    'Long-term wealth is built by repeating intelligent behaviour for longer than your emotions want to. The strategy is simple, but not always easy.\n\nYour wealth system:\n• Earn: increase skill and income capacity\n• Keep: manage spending and tax awareness\n• Protect: emergency fund and insurance where needed\n• Grow: invest consistently\n• Review: adjust without overreacting\n\nDo not measure progress only by today\'s balance. Measure habits, savings rate, debt reduction, asset ownership, and calm decision-making.\n\nYour action: write your five-year wealth statement in one paragraph. Include what you are building, why it matters, and what you will repeat monthly.',
              },
            ],
          },
          {
            'title': 'Side Hustle Accelerator',
            'desc':
                'Turn your skills into income streams. A practical guide to launching and scaling your first hustle.',
            'modules': [
              {
                'title': 'Identifying High-Value Skills',
                'duration': '15 min',
                'content':
                    'A strong side hustle begins where skill, demand, and willingness to pay overlap. Do not start with what sounds impressive. Start with what solves a real problem.\n\nLook for skills in:\n• Work people already ask you to help with\n• Problems you have solved for yourself\n• Tools you know better than beginners\n• Knowledge from your job or life experience\n• Creative skills that save time, money, or stress\n\nYour action: list ten skills or useful experiences. Mark the three that solve the clearest problem for another person.',
              },
              {
                'title': 'Market Validation & Testing',
                'duration': '20 min',
                'content':
                    'Validation means finding evidence that people want the result before you spend months building. Compliments are not validation. Payment, bookings, waitlists, repeated questions, and clear demand are stronger signals.\n\nSimple tests:\n• Ask ten target people what they struggle with\n• Offer a small paid pilot\n• Post a clear service offer\n• Build a landing page or message thread\n• Track replies, objections, and questions\n\nYour action: design one seven-day test. The goal is not perfection. The goal is evidence.',
              },
              {
                'title': 'The Art of the Offer',
                'duration': '25 min',
                'content':
                    'An offer is not just what you sell. It is the promise, outcome, delivery, price, and confidence a buyer feels before saying yes.\n\nA clear offer includes:\n• Who it is for\n• The painful problem\n• The desired result\n• What is included\n• How long it takes\n• The price or next step\n\nWeak offer: I do social media.\nStrong offer: I create a 30-day content plan for local service businesses so they know exactly what to post and why.\n\nYour action: write your offer in one sentence. Remove vague words until a stranger could understand the result.',
              },
              {
                'title': 'Scaling for Freedom',
                'duration': '20 min',
                'content':
                    'Scaling does not always mean getting bigger. It means making the hustle more useful, more repeatable, and less chaotic.\n\nWays to scale:\n• Create templates\n• Raise prices as proof improves\n• Productise a repeated service\n• Automate admin\n• Build referral systems\n• Turn common advice into digital assets\n\nProtect your energy. A side hustle that destroys your health is not freedom.\n\nYour action: choose one task you repeat and turn it into a checklist, template, or saved response this week.',
              },
            ],
          },
          {
            'title': 'Abundance Consciousness',
            'desc':
                'Rewire your brain to move from a scarcity-based survival mode to a world of endless opportunity.',
            'modules': [
              {
                'title': 'Dissolving Scarcity Loops',
                'duration': '20 min',
                'content':
                    'Scarcity loops are repeated thoughts and behaviours that keep you feeling trapped: I never have enough, people like me cannot build wealth, money always disappears, or success is for someone else.\n\nTo dissolve a loop, name it, challenge it, and replace it with evidence-based action.\n\nPractice:\n• Notice the thought\n• Ask what behaviour it creates\n• Find one example that proves growth is possible\n• Take one small wealth-building action immediately\n\nYour action: write your most common money fear and the action it usually blocks. Then take a five-minute action that moves against the fear.',
              },
              {
                'title': 'Gratitude as a Wealth Asset',
                'duration': '15 min',
                'content':
                    'Gratitude is not a replacement for strategy. It is a stabiliser. When you can recognise what is already working, you make fewer desperate decisions and more grounded ones.\n\nGratitude trains attention toward resources:\n• Skills you already have\n• People who support you\n• Opportunities nearby\n• Lessons from mistakes\n• Tools and time you can use today\n\nYour action: write five resources you already possess that could help you earn, save, learn, or create value.',
              },
              {
                'title': 'Living in the Future Self',
                'duration': '25 min',
                'content':
                    'Your future wealthy self is not only richer. They are calmer, clearer, more disciplined, and more intentional with attention.\n\nAsk future-you questions:\n• What do I stop tolerating?\n• What do I automate?\n• What do I learn next?\n• Who do I spend more time around?\n• What purchases no longer impress me?\n\nThen act from that identity before the bank balance catches up.\n\nYour action: choose one behaviour your future self already has. Practise it for the next seven days.',
              },
              {
                'title': 'Attracting Large-Scale Value',
                'duration': '20 min',
                'content':
                    'Money follows value, trust, and distribution. To attract larger opportunities, become more useful to more people or solve more expensive problems.\n\nValue expands when you improve:\n• Skill depth\n• Reliability\n• Communication\n• Network quality\n• Ownership of assets\n• Ability to solve painful problems\n\nAbundance is not waiting. It is participation. The more value you can create and deliver, the more wealth channels can open.\n\nYour action: choose one high-value skill to develop for 30 days. Define the practice, the proof, and the person or market it will help.',
              },
            ],
          },
        ],
        'investing': [
          {
            'title': 'Stock Market Basics',
            'desc':
                'The difference between stocks, bonds, and funds. Start with the foundational knowledge.',
          },
          {
            'title': 'The Power of Index Funds',
            'desc':
                'Why simple, low-cost index funds outperform active stock picking for most investors.',
          },
          {
            'title': 'Real Estate for Beginners',
            'desc':
                'An introduction to building wealth through physical assets and rental income.',
          },
          {
            'title': 'Compound Interest Mastery',
            'desc':
                'The mathematical "eighth wonder of the world." See how time is your greatest asset in wealth.',
          },
        ],
        'hustles': [
          {
            'title': 'Finding Your Side Hustle',
            'desc':
                'How to identify profitable skills you already possess and turn them into income.',
          },
          {
            'title': 'Scaling Small Projects',
            'desc':
                'Move from trading time for money to building systems that generate revenue.',
          },
          {
            'title': 'Passive Income Realities',
            'desc':
                'The truth about what it takes to build truly passive income streams in the digital age.',
          },
          {
            'title': 'Digital Product Blueprint',
            'desc':
                'Learn to package your knowledge into assets that sell while you sleep.',
          },
        ],
        'budgeting': [
          {
            'title': 'The 50/30/20 Rule',
            'desc':
                'A simple, effective framework for balancing needs, wants, and financial future.',
          },
          {
            'title': 'Automation for Wealth',
            'desc':
                'How to set up your banking so that saving and investing happens without willpower.',
          },
          {
            'title': 'Managing Debt Effectivly',
            'desc':
                'Strategies for paying off high-interest debt while still building your emergency fund.',
          },
          {
            'title': 'Strategic Tax Planning',
            'desc':
                'It\'s not how much you make, it\'s how much you keep. Essential basics of wealth protection.',
          },
        ],
      },
      'relationships': {
        'intro':
            'Quality relationships are the strongest predictor of happiness and longevity. These resources help you build deeper, more authentic connections.',
        'manifestation': [
          {
            'title': 'Ideal Relationship Visualization',
            'desc':
                'Define the behaviours, values, and boundaries that make a relationship healthy for you. Use that clarity to choose and communicate well.',
          },
          {
            'title': 'Loving-Kindness Meditation',
            'desc':
                'Metta meditation sends goodwill to yourself and others. This practice rewires your brain for connection.',
          },
          {
            'title': 'Heart Opening Practice',
            'desc':
                'Let go of past hurts by visualizing yourself giving and receiving love freely.',
          },
          {
            'title': 'Attracting Your Soul Circle',
            'desc':
                'Expand your focus beyond romance. Visualize a tribe that supports your highest self.',
          },
        ],
        'psychology': [
          {
            'title': 'The 5 Love Languages',
            'desc':
                'Understanding how you and others give and receive love prevents miscommunication and builds intimacy.',
          },
          {
            'title': 'Attachment Theory Explained',
            'desc':
                'Your early relationships shaped your adult attachment style. Understanding it helps you build secure bonds.',
          },
          {
            'title': 'Boundaries as Self-Love',
            'desc':
                'Healthy boundaries aren\'t walls — they\'re filters. Learn to protect your peace while staying open.',
          },
          {
            'title': 'The Shadow in Relationships',
            'desc':
                'Recurring relationship patterns become easier to change when you notice your triggers, assumptions, and familiar roles before reacting.',
          },
        ],
        'courses': [
          {
            'title': 'Communication Mastery',
            'desc':
                'Learn to speak so others listen, and listen so others speak. The foundation of all great relationships.',
            'modules': [
              {
                'title': 'Active Listening Skills',
                'duration': '15 min',
                'content':
                    'Active listening is not waiting for your turn to speak. It is showing the other person that their inner world matters enough for you to slow down.\n\nPractise listening in layers:\n• Words: what did they actually say?\n• Feeling: what emotion is underneath?\n• Need: what are they asking for directly or indirectly?\n• Meaning: why does this matter to them?\n\nUseful phrases:\n• What I am hearing is...\n• That makes sense because...\n• Did I understand that correctly?\n• Tell me more about that part.\n\nYour action: in your next important conversation, reflect back what you heard before giving your opinion.',
              },
              {
                'title': 'Expressing with Clarity',
                'duration': '20 min',
                'content':
                    'Clear expression reduces confusion, defensiveness, and resentment. The goal is not to say everything perfectly. The goal is to be honest enough to be understood and respectful enough to be received.\n\nClear expression includes:\n• One topic at a time\n• Specific examples\n• Ownership of your feelings\n• A clear request\n• No character attacks\n\nAvoid words like always and never unless they are literally true. They turn a solvable issue into a debate.\n\nYour action: choose one thing you have been hinting at and turn it into a direct, kind request.',
              },
              {
                'title': 'Nonviolent Communication',
                'duration': '25 min',
                'content':
                    'Nonviolent communication helps you separate what happened from the story you are telling about it. That separation creates space for understanding.\n\nThe four steps:\n• Observation: what happened without exaggeration?\n• Feeling: what emotion came up?\n• Need: what value or need is connected to that feeling?\n• Request: what specific action would help?\n\nExample: When I did not get a reply yesterday, I felt anxious because I value reassurance. Could you send a quick message when you are busy?\n\nYour action: write one difficult message using the four-step structure before you send it.',
              },
              {
                'title': 'Conflict Resolution',
                'duration': '20 min',
                'content':
                    'Conflict resolution is not about proving who is right. It is about protecting the relationship while solving the problem.\n\nResolution process:\n• Regulate first\n• Name the shared goal\n• Let each person explain their view\n• Identify the deeper needs\n• Brainstorm options\n• Choose one next experiment\n\nSome conflicts require compromise. Others require boundaries. The skill is knowing whether the issue asks for flexibility, repair, or a firm line.\n\nYour action: write a shared-goal sentence for a current tension: We both want...',
              },
            ],
          },
          {
            'title': 'Conflict to Connection',
            'desc':
                'Transform disagreements into opportunities for deeper understanding and intimacy.',
            'modules': [
              {
                'title': 'Understanding Conflict Styles',
                'duration': '15 min',
                'content':
                    'People tend to repeat conflict styles they learned early: pursuing, withdrawing, pleasing, controlling, explaining, shutting down, or attacking. These patterns are usually protective strategies, even when they cause harm.\n\nNotice your style:\n• Do you chase the conversation or avoid it?\n• Do you get louder or quieter?\n• Do you apologise too quickly or refuse to apologise?\n• Do you need immediate resolution or time to process?\n\nYour action: name your default conflict style and write what it is trying to protect.',
              },
              {
                'title': 'De-escalation Techniques',
                'duration': '20 min',
                'content':
                    'Escalation happens when the conversation stops being about the issue and starts being about threat. De-escalation brings safety back into the room.\n\nUse these tools:\n• Slow your pace\n• Lower your volume\n• Unclench your body\n• Use the person\'s name gently\n• Validate one true thing\n• Pause before replying\n\nValidation is not agreement. It means you can understand why something would matter to them.\n\nYour action: practise this sentence: I can see why that felt frustrating. I want to understand before I respond.',
              },
              {
                'title': 'Finding Common Ground',
                'duration': '15 min',
                'content':
                    'Common ground is often hidden beneath competing strategies. One person may want planning, the other wants freedom. Underneath, both may want peace, respect, or security.\n\nFind the shared layer:\n• What do we both care about?\n• What outcome would serve us both?\n• Where are our needs different but not enemies?\n• What small agreement can we test?\n\nYour action: for one disagreement, write both positions, then write the shared value underneath them.',
              },
              {
                'title': 'Rebuilding Trust',
                'duration': '20 min',
                'content':
                    'Trust is rebuilt through consistent evidence. Words open the door, but behaviour keeps it open.\n\nTrust repair requires:\n• Accountability without defensiveness\n• Clear understanding of the impact\n• Repeated reliable action\n• Transparency where appropriate\n• Patience with the other person\'s nervous system\n\nDo not demand instant trust after harm. Trust returns when safety becomes predictable again.\n\nYour action: choose one trust-building behaviour you can repeat for the next two weeks.',
              },
            ],
          },
          {
            'title': 'Emotional Intimacy Mastery',
            'desc':
                'Go beyond superficial talk and build a profound, vulnerable connection with your partner.',
            'modules': [
              {
                'title': 'The 4 Pillars of Intimacy',
                'duration': '20 min',
                'content':
                    'Intimacy is closeness with safety. It is built through emotional honesty, physical warmth, shared meaning, and reliable presence.\n\nThe four pillars:\n• Emotional: I can tell you the truth about my inner world\n• Physical: affection and presence feel welcome and respectful\n• Practical: we can depend on each other\n• Spiritual or meaningful: our lives point toward something shared\n\nA relationship may be strong in one pillar and weak in another. Awareness shows you where to grow.\n\nYour action: rate each pillar from 1 to 10 and choose the one that needs gentle attention.',
              },
              {
                'title': 'Shared Meaning & Values',
                'duration': '15 min',
                'content':
                    'Shared meaning gives a relationship depth beyond convenience. It includes values, rituals, dreams, family culture, priorities, and the story you are building together.\n\nExplore together:\n• What do we want our life to feel like?\n• What values guide our decisions?\n• What rituals matter to us?\n• What are we protecting from outside pressure?\n• What do we want to be proud of in five years?\n\nYour action: write three values you want your closest relationships to embody.',
              },
              {
                'title': 'Vulnerability as Strength',
                'duration': '25 min',
                'content':
                    'Vulnerability is not emotional dumping. It is honest sharing with self-respect. It lets people know the real you instead of only the managed version.\n\nHealthy vulnerability is:\n• Timed well\n• Shared with appropriate people\n• Connected to a clear feeling or need\n• Open to response, not demanding control\n• Balanced with boundaries\n\nStart small. Share one truth, one fear, one hope, or one appreciation.\n\nYour action: tell someone safe one thing you usually keep hidden because you fear seeming needy, weak, or too much.',
              },
              {
                'title': 'Daily Connection Rituals',
                'duration': '20 min',
                'content':
                    'Connection grows through repetition. A daily ritual gives love a reliable place to land.\n\nExamples:\n• Morning check-in\n• Phone-free meal\n• Evening gratitude exchange\n• Ten-minute walk\n• Goodnight repair question: Is there anything between us?\n• Weekly planning and appreciation\n\nKeep rituals small. The best ritual is the one you can still do when life is busy.\n\nYour action: choose one daily connection ritual and test it for seven days.',
              },
            ],
          },
          {
            'title': 'Social Circle Design',
            'desc':
                'Audit, curate, and grow a supportive community that inspires you to become your best self.',
            'modules': [
              {
                'title': 'The Law of Association',
                'duration': '15 min',
                'content':
                    'Your social circle shapes your standards, mood, habits, and sense of possibility. This does not mean judging people harshly. It means noticing influence.\n\nAsk:\n• Who makes me more honest?\n• Who encourages growth?\n• Who normalises drama or stagnation?\n• Who do I become around this person?\n• Where do I feel most myself?\n\nYour action: write the five people you spend the most energy on and note the direction each relationship pulls you.',
              },
              {
                'title': 'Finding Your Soul Tribe',
                'duration': '20 min',
                'content':
                    'Your people are usually found through shared values, repeated environments, and mutual contribution. Waiting passively keeps connection accidental.\n\nFind aligned people by:\n• Joining recurring spaces\n• Following your actual interests\n• Starting conversations with openness\n• Being consistent long enough to become familiar\n• Letting weak-fit connections stay light\n\nYour action: choose one community, class, group, or recurring event to attend at least three times.',
              },
              {
                'title': 'Setting Healthy Social Limits',
                'duration': '15 min',
                'content':
                    'Healthy limits protect your energy so your relationships stay clean. Without limits, resentment grows quietly.\n\nUseful limits:\n• Time limits\n• Topic limits\n• Emotional availability limits\n• Financial limits\n• Access limits\n\nA limit does not need a courtroom defence. It can be kind and brief.\n\nYour action: write one boundary sentence you need: I care about you, and I am not available for...',
              },
              {
                'title': 'Becoming a Value-Adder',
                'duration': '25 min',
                'content':
                    'A strong social circle is not only about what you receive. It is also about who you become for others. Value is presence, encouragement, honesty, reliability, humour, introductions, ideas, and practical help.\n\nWays to add value:\n• Remember what matters to people\n• Celebrate wins\n• Offer help without taking over\n• Share useful resources\n• Host or organise\n• Tell the truth kindly\n\nYour action: choose three people and add value this week in a specific way.',
              },
            ],
          },
        ],
        'resolution': [
          {
            'title': 'The Art of Apology',
            'desc':
                'Why "I\'m sorry you felt that way" isn\'t a real apology—and how to do it right.',
          },
          {
            'title': 'Active Listening Drills',
            'desc':
                'Practical exercises to ensure you are hearing the heart behind the words.',
          },
          {
            'title': 'Expressing Needs clearly',
            'desc':
                'How to state what you need without sounding demanding or critical.',
          },
          {
            'title': 'The De-escalation Protocol',
            'desc':
                'Learn the "Time-Out" technique to prevent discussions from turning into destructive arguments.',
          },
        ],
        'dating': [
          {
            'title': 'Authenticity in Attraction',
            'desc':
                'Why being yourself is the most sustainable and effective dating strategy.',
          },
          {
            'title': 'First Date Dynamics',
            'desc':
                'Shift your mindset from "Do they like me?" to "Do I like them?" for better connections.',
          },
          {
            'title': 'The Science of Charisma',
            'desc':
                'Presence, power, and warmth: the three pillars of magnetic personality.',
          },
          {
            'title': 'Intentional Dating Blueprint',
            'desc':
                'Stop "falling" and start choosing. Define your non-negotiables before you swipe.',
          },
        ],
        'social': [
          {
            'title': 'Masters of Conversation',
            'desc':
                'How to keep a conversation flowing naturally and make others feel seen.',
          },
          {
            'title': 'Reading Body Language',
            'desc':
                'Understanding the non-verbal cues that reveal more than spoken words.',
          },
          {
            'title': 'Network with Integrity',
            'desc':
                'Building a circle of influence while maintaining authenticity and value.',
          },
          {
            'title': 'The Art of Directness',
            'desc':
                'How to be honest without being harsh. Building trust through clear communication.',
          },
        ],
      },
      'career': {
        'intro':
            'Your career is a vehicle for expression, impact, and provision. These resources help you find work that fulfills and advances your purpose.',
        'manifestation': [
          {
            'title': 'Dream Career Visualization',
            'desc':
                'See yourself in your ideal work situation. What does a typical day feel like? Who do you serve?',
          },
          {
            'title': 'Calling vs Career',
            'desc':
                'Discover the difference between a job, a career, and a calling — and find which you\'re chasing.',
          },
          {
            'title': 'Abundant Work Mindset',
            'desc':
                'Focus on the value you can build instead of treating another person\'s success as proof that opportunity has disappeared. Develop skills, relationships, and evidence of your contribution.',
          },
          {
            'title': 'Professional Identity Shift',
            'desc':
                'Stop seeing yourself as your job title. Start seeing yourself as the value you provide.',
          },
        ],
        'psychology': [
          {
            'title': 'Imposter Syndrome Decoded',
            'desc':
                'Feeling uncertain does not prove you are a fraud. Compare the fear with evidence of your skills, preparation, and growth, then take the next useful step.',
          },
          {
            'title': 'Strengths-Based Leadership',
            'desc':
                'Use strengths deliberately while addressing weaknesses that affect your role, team, or wellbeing. Good leadership is not ignoring gaps; it is designing around them honestly.',
          },
          {
            'title': 'The Paradox of Choice in Careers',
            'desc':
                'Too many options can delay action. Set clear criteria, test a few realistic paths, and commit long enough to learn from the evidence.',
          },
          {
            'title': 'Growth vs Fixed Professionalism',
            'desc':
                'Learn why your current skills are less important than your capacity to learn new ones.',
          },
        ],
        'courses': [
          {
            'title': 'Personal Brand Builder',
            'desc':
                'Define and communicate your unique value proposition in any professional context.',
            'modules': [
              {
                'title': 'Discover Your Strengths',
                'duration': '20 min',
                'content':
                    'Your personal brand starts with evidence, not a slogan. Strengths are the patterns of value you repeatedly create: how you solve problems, communicate, organise, lead, create, analyse, or support others.\n\nLook for clues:\n• What do people ask you for help with?\n• What work feels natural but valuable?\n• What problems do you spot quickly?\n• What outcomes have you created more than once?\n• What feedback repeats across roles?\n\nYour action: write five strengths and one proof point for each. If you cannot prove it, keep refining it.',
              },
              {
                'title': 'Crafting Your Story',
                'duration': '15 min',
                'content':
                    'A professional story connects where you have been, what you are good at, and where you are going. It helps people understand your value quickly.\n\nStory structure:\n• I have experience in...\n• I am strongest at...\n• I create value by...\n• I am now focused on...\n\nKeep it specific. You are not trying to appeal to everyone. You are helping the right opportunities recognise you.\n\nYour action: write a four-sentence professional story and remove any vague phrases like hard-working, passionate, or motivated unless you attach proof.',
              },
              {
                'title': 'Online Presence',
                'duration': '25 min',
                'content':
                    'Your online presence should support your career direction. It does not need to be loud, but it should be coherent.\n\nReview:\n• Profile photo and headline\n• About section or bio\n• Featured work or portfolio\n• Skills and keywords\n• Posts, comments, or public signals\n• Consistency across platforms\n\nA good profile makes it easy to understand who you help, what you know, and why you are credible.\n\nYour action: update one public profile so the first five seconds communicate your target role or professional value.',
              },
              {
                'title': 'Networking Authentically',
                'duration': '20 min',
                'content':
                    'Networking is not collecting contacts. It is building professional trust through useful conversations over time.\n\nAuthentic networking looks like:\n• Asking thoughtful questions\n• Sharing relevant resources\n• Following up without pressure\n• Offering help where appropriate\n• Staying in touch before you need something\n\nYour action: contact one person with a specific, respectful message: mention what you appreciate, ask one clear question, or share something genuinely useful.',
              },
            ],
          },
          {
            'title': 'Network with Purpose',
            'desc':
                'Build meaningful professional relationships that create opportunities without feeling transactional.',
            'modules': [
              {
                'title': 'Quality Over Quantity',
                'duration': '15 min',
                'content':
                    'A powerful network is not the largest list of names. It is a set of real relationships with people who know your character, understand your value, and trust your follow-through.\n\nPrioritise:\n• People in your target field\n• People one or two steps ahead\n• Peers who are growing seriously\n• Former colleagues who know your work\n• Mentors, connectors, and collaborators\n\nYour action: list 20 people in your professional orbit and mark the 5 most worth nurturing this month.',
              },
              {
                'title': 'Giving First Value',
                'duration': '20 min',
                'content':
                    'Giving first does not mean overextending. It means entering professional relationships with usefulness instead of extraction.\n\nWays to give value:\n• Make a relevant introduction\n• Share a resource\n• Offer thoughtful feedback\n• Support their work publicly\n• Send a concise insight\n• Ask a question that respects their time\n\nYour action: choose one person and send something useful with no immediate ask.',
              },
              {
                'title': 'Following Up Effectively',
                'duration': '15 min',
                'content':
                    'Follow-up turns a moment into a relationship. Most opportunities are lost because people make one contact and disappear.\n\nGood follow-up is:\n• Prompt\n• Specific\n• Brief\n• Connected to the prior conversation\n• Clear about any next step\n\nExample: I appreciated your point about customer research. I found this lesson related to that idea and thought of our conversation.\n\nYour action: write a follow-up message to someone you have spoken with recently.',
              },
              {
                'title': 'Building Lasting Bonds',
                'duration': '20 min',
                'content':
                    'Lasting professional bonds are built through consistency. You do not need constant contact; you need reliable touchpoints and genuine interest.\n\nMaintain bonds with:\n• Periodic check-ins\n• Congratulations on wins\n• Useful updates\n• Shared opportunities\n• Honest appreciation\n• Respect for their time\n\nYour action: create a simple relationship tracker with names, last contact, context, and next useful touchpoint.',
              },
            ],
          },
          {
            'title': 'Leadership Presence',
            'desc':
                'Master the non-verbal and psychological traits that command respect and inspire action.',
            'modules': [
              {
                'title': 'The Pillars of Charisma',
                'duration': '20 min',
                'content':
                    'Charisma is not pretending to be louder than you are. It is the combination of presence, warmth, and conviction.\n\nThe pillars:\n• Presence: people feel you are actually with them\n• Warmth: people feel respected, not judged\n• Conviction: people sense clarity and steadiness\n\nYou can develop charisma through attention, body language, voice pace, and emotional regulation.\n\nYour action: in your next conversation, practise full presence: no phone, no interrupting, and one thoughtful follow-up question.',
              },
              {
                'title': 'Communicating with Vision',
                'duration': '15 min',
                'content':
                    'Vision gives direction. It helps people understand why the work matters, what success looks like, and how their contribution fits.\n\nVision communication includes:\n• The current reality\n• The desired future\n• Why it matters\n• What must happen next\n• How people can contribute\n\nAvoid empty inspiration. Tie vision to concrete priorities.\n\nYour action: explain one project in a vision format: where we are, where we are going, why it matters, and what happens next.',
              },
              {
                'title': 'Maintaining Poise in Crisis',
                'duration': '25 min',
                'content':
                    'People watch leaders most closely when things go wrong. Poise does not mean having no emotion. It means staying useful under pressure.\n\nCrisis poise:\n• Slow down enough to think\n• Separate facts from assumptions\n• Name the priority\n• Communicate calmly and frequently\n• Assign ownership clearly\n• Review lessons after the pressure passes\n\nYour action: write a personal crisis checklist you can use before reacting: breathe, facts, priority, people, next step.',
              },
              {
                'title': 'The Art of Influence',
                'duration': '20 min',
                'content':
                    'Influence is helping people move toward a useful decision or action. It works best when rooted in trust, clarity, and mutual benefit.\n\nInfluence tools:\n• Understand their incentives\n• Speak to shared goals\n• Make the next step easy\n• Use evidence and story\n• Invite ownership\n• Respect objections\n\nYour action: choose one idea you want support for and write it from the other person\'s perspective: why would this matter to them?',
              },
            ],
          },
          {
            'title': 'The High-Performance Routine',
            'desc':
                'Eliminate burnout and maximize output by strategically designing your workday flow.',
            'modules': [
              {
                'title': 'Deep Work Architecture',
                'duration': '25 min',
                'content':
                    'High performance depends on protected focus. Deep work is time spent on cognitively demanding tasks without distraction.\n\nDesign deep work by choosing:\n• A specific task\n• A time block\n• A distraction boundary\n• A clear definition of done\n• A recovery break afterwards\n\nDo not simply hope for focus. Architect it.\n\nYour action: schedule one 45-minute deep work block tomorrow and decide exactly what will be finished by the end.',
              },
              {
                'title': 'Energy-Based Scheduling',
                'duration': '15 min',
                'content':
                    'Not every hour has the same quality. Matching tasks to energy improves output without forcing constant intensity.\n\nMap your work:\n• High-energy: strategy, writing, problem solving, difficult conversations\n• Medium-energy: meetings, planning, collaboration\n• Low-energy: admin, sorting, simple replies\n\nProtect your best energy for your highest-value work.\n\nYour action: identify your best two-hour window and reserve it for important work three times this week.',
              },
              {
                'title': 'The Procrastination Cure',
                'duration': '20 min',
                'content':
                    'Procrastination is often emotional friction, not laziness. The task may feel unclear, too large, risky, boring, or tied to fear of judgment.\n\nReduce friction:\n• Define the next tiny action\n• Lower the starting standard\n• Set a timer for ten minutes\n• Remove one distraction\n• Make progress visible\n\nYour action: choose one avoided task and write the next physical action. Then do only ten minutes.',
              },
              {
                'title': 'Professional Recovery Flow',
                'duration': '15 min',
                'content':
                    'Recovery is part of performance. Without recovery, productivity becomes extraction until your attention, mood, and health start pushing back.\n\nRecovery practices:\n• End-of-day shutdown ritual\n• Movement after long focus blocks\n• Sleep protection\n• Clear boundaries after work\n• Weekly review and reset\n\nRecovery tells your brain that work has an edge. That edge makes focus easier tomorrow.\n\nYour action: create a shutdown ritual: review tasks, choose tomorrow\'s top priority, close work tools, and mark the day complete.',
              },
            ],
          },
        ],
        'leadership': [
          {
            'title': 'Servant Leadership Foundations',
            'desc':
                'Why the best leaders serve their teams first. Shift from authority to influence.',
          },
          {
            'title': 'Radical Candor in Teams',
            'desc':
                'How to give feedback that is both direct and deeply caring. The secret to high performance.',
          },
          {
            'title': 'Decision-Making Frameworks',
            'desc':
                'Master the mental models used by top executives to make fast, accurate decisions.',
          },
          {
            'title': 'Building Psychological Safety',
            'desc':
                'The #1 predictor of team success is trust. Learn how to foster an environment of high openness.',
          },
        ],
        'speaking': [
          {
            'title': 'Public Speaking Mastery',
            'desc':
                'Conquer your fear of the stage and learn to deliver messages that move and inspire.',
          },
          {
            'title': 'The Art of Storytelling',
            'desc':
                'Facts tell, but stories sell. Learn to wrap your ideas in compelling narrative arcs.',
          },
          {
            'title': 'Presentation Design',
            'desc':
                'How to create slides that support your message rather than distracting from it.',
          },
          {
            'title': 'Command the Room',
            'desc':
                'Learn the vocal tonality and presence techniques to speak with authority and warmth.',
          },
        ],
        'productivity': [
          {
            'title': 'Deep Work Strategies',
            'desc':
                'Cal Newport\'s framework for achieving extraordinary focus in a world full of distractions.',
          },
          {
            'title': 'The 80/20 of Workflow',
            'desc':
                'Identify the 20% of your tasks that drive 80% of your career results.',
          },
          {
            'title': 'Email & Slack Management',
            'desc':
                'Stop being a slave to your inbox. Learn to use communication tools without letting them use you.',
          },
          {
            'title': 'Energy Management Mastery',
            'desc':
                'Stop managing time. Start managing energy. Learn to match tasks to your biological peaks.',
          },
        ],
      },
      'spiritual': {
        'intro':
            'Spirituality is the search for meaning, connection, and purpose beyond the material. These practices help you tune into your inner wisdom.',
        'manifestation': [
          {
            'title': 'Morning Spiritual Practice',
            'desc':
                'Start each day by setting an intention and connecting to something larger than yourself.',
          },
          {
            'title': 'Gratitude as Spiritual Practice',
            'desc':
                'Gratitude can deepen attention to what is already meaningful. Name something specific, why it matters, and one way to care for it.',
          },
          {
            'title': 'Manifesting Your Purpose',
            'desc':
                'Clear the noise and listen for the whisper of your unique calling. Purpose is discovered, not designed.',
          },
          {
            'title': 'Ego vs Soul Alignment',
            'desc':
                'Learn to distinguish between the desires of your ego and the needs of your spirit.',
          },
        ],
        'psychology': [
          {
            'title': 'The Science of Flow States',
            'desc':
                'When you\'re in flow, time disappears and you perform at your peak. Here\'s how to access it intentionally.',
          },
          {
            'title': 'Transcendence and Well-Being',
            'desc':
                'Research confirms that experiences of awe and transcendence are among the most profound sources of happiness.',
          },
          {
            'title': 'The Power of Presence',
            'desc':
                'Presence brings attention back to the part of life you can respond to now. Notice the moment, then choose one grounded next action.',
          },
          {
            'title': 'The Psychology of Belief',
            'desc':
                'Understand how your spiritual framework influences your mental health and resilience.',
          },
        ],
        'courses': [
          {
            'title': 'Meditation Foundations',
            'desc':
                'Build a sustainable meditation practice from scratch. Even 5 minutes daily creates measurable change.',
            'modules': [
              {
                'title': 'Understanding Meditation',
                'duration': '10 min',
                'content':
                    'Meditation is attention training. You choose an anchor, notice when the mind moves away, and return without punishment. That return is the practice.\n\nWhat meditation builds:\n• Awareness of thought patterns\n• Emotional regulation\n• Patience with discomfort\n• More space before reaction\n• A deeper sense of presence\n\nYou do not need incense, silence, or a perfect mood. You need a repeatable moment of practice.\n\nYour action: choose one anchor for the week: breath, body sensation, sound, or a simple phrase.',
              },
              {
                'title': 'Breath Awareness Technique',
                'duration': '15 min',
                'content':
                    'Breath awareness is one of the simplest meditation methods because the breath is always present. You are not trying to breathe perfectly. You are learning to stay with what is already happening.\n\nPractice steps:\n• Sit comfortably\n• Notice the inhale\n• Notice the exhale\n• Count from one to ten if helpful\n• Start again when you lose count\n\nLosing count is not failure. It is the exact moment training happens.\n\nYour action: practise ten counted breaths before one daily transition, such as starting work or going to sleep.',
              },
              {
                'title': 'Body Scan Practice',
                'duration': '20 min',
                'content':
                    'A body scan reconnects you with direct experience. It helps you notice tension, numbness, restlessness, and ease without needing to change everything immediately.\n\nScan slowly:\n• Feet\n• Legs\n• Hips\n• Belly\n• Chest\n• Hands\n• Shoulders\n• Face\n\nWhen you find tension, breathe around it rather than forcing it away.\n\nYour action: do a three-minute body scan and write the strongest sensation you noticed.',
              },
              {
                'title': 'Building Your Routine',
                'duration': '15 min',
                'content':
                    'A meditation habit grows through identity and repetition. The routine should be small, specific, and protected from perfectionism.\n\nRoutine formula:\n• After I...\n• I will meditate for...\n• In this place...\n• Using this anchor...\n• Then I will record one word about how I feel.\n\nYour action: write your meditation formula and place a reminder where the habit will happen.',
              },
            ],
          },
          {
            'title': 'Journaling for Self-Discovery',
            'desc':
                'Use targeted prompts to uncover hidden beliefs, desires, and your deepest truths.',
            'modules': [
              {
                'title': 'Morning Pages Practice',
                'duration': '15 min',
                'content':
                    'Morning pages are uncensored writing used to clear mental noise and reveal what is underneath. You do not write to impress. You write to listen.\n\nGuidelines:\n• Write soon after waking if possible\n• Keep the pen moving\n• Do not edit while writing\n• Let complaints, hopes, fears, and ideas appear\n• Look for repeated themes after several days\n\nYour action: write for ten minutes tomorrow morning without stopping. Circle one sentence that feels true.',
              },
              {
                'title': 'Prompt-Based Journaling',
                'duration': '20 min',
                'content':
                    'Prompts help direct attention. The right question can reveal a belief, need, fear, or desire you have been moving around without naming.\n\nUseful prompts:\n• What am I avoiding because it feels uncomfortable?\n• What do I know but keep pretending not to know?\n• What would feel peaceful if I trusted myself?\n• What part of me needs compassion today?\n\nYour action: choose one prompt and write until you reach a sentence that surprises you.',
              },
              {
                'title': 'Shadow Work Exploration',
                'duration': '25 min',
                'content':
                    'Shadow work explores the parts of yourself you reject, hide, judge, or project onto others. The aim is integration, not self-attack.\n\nStart gently:\n• What traits in others trigger me strongly?\n• Where do I overreact?\n• What emotion do I judge in myself?\n• What did I learn was unacceptable growing up?\n• What part of me wants to be heard?\n\nShadow work can be intense. Move slowly and seek support for trauma-heavy material.\n\nYour action: write about one trigger and ask: what part of me is being mirrored here?',
              },
              {
                'title': 'Gratitude Integration',
                'duration': '15 min',
                'content':
                    'Gratitude becomes spiritual practice when it moves from list-making into perception. It trains you to recognise support, beauty, lessons, and grace in ordinary life.\n\nGo deeper than obvious items:\n• What challenged me but taught me?\n• What small kindness did I receive?\n• What part of my body supported me today?\n• What resource did I overlook?\n\nYour action: write three gratitudes and one sentence about how each one changes your perspective.',
              },
            ],
          },
          {
            'title': 'Stoic Life Mastery',
            'desc':
                'Apply ancient wisdom to modern chaos. Find peace in what you can control and let go of the rest.',
            'modules': [
              {
                'title': 'The Dichotomy of Control',
                'duration': '20 min',
                'content':
                    'Stoicism begins by separating what is within your control from what is not. You control your choices, effort, attention, values, and response. You do not fully control other people, outcomes, timing, reputation, or luck.\n\nThis is not passivity. It is disciplined focus.\n\nAsk:\n• What part is mine?\n• What part is not mine?\n• What action fits my values now?\n\nYour action: write one current stress and divide it into controllable and uncontrollable parts.',
              },
              {
                'title': 'Premeditation of Evils',
                'duration': '15 min',
                'content':
                    'Premeditation of evils means calmly imagining possible obstacles so you are less shocked by them. It is preparation, not pessimism.\n\nUse it for:\n• Difficult conversations\n• Delays\n• Criticism\n• Technical problems\n• Emotional triggers\n\nThen plan your response in advance. The point is to meet life with steadiness.\n\nYour action: choose one upcoming challenge and write three things that could go wrong, plus your best response to each.',
              },
              {
                'title': 'Amor Fati: Love of Fate',
                'duration': '25 min',
                'content':
                    'Amor fati means learning to work with reality instead of wasting life fighting what has already happened. It does not mean pretending pain is good. It means asking how this can become part of your strength.\n\nPractice questions:\n• What is reality asking of me now?\n• What virtue can I practise here?\n• How can this become material for growth?\n• What resistance is making this heavier?\n\nYour action: take one unwanted situation and write the lesson, the responsibility, and the next honourable action.',
              },
              {
                'title': 'Daily Stoic Rituals',
                'duration': '20 min',
                'content':
                    'Stoic practice works best as a rhythm. Morning prepares the mind. Evening reviews the day.\n\nMorning:\n• What matters today?\n• What obstacles may appear?\n• What virtue will I practise?\n\nEvening:\n• Where did I act well?\n• Where did I react poorly?\n• What will I improve tomorrow?\n\nYour action: complete one morning and one evening Stoic check-in today.',
              },
            ],
          },
          {
            'title': 'Quantum Achievement Blueprint',
            'desc':
                'Meaningful progress comes from aligning your environment, habits, and decisions with the outcome you want—not from waiting for a dramatic breakthrough.',
            'modules': [
              {
                'title': 'The Field of Possibility',
                'duration': '15 min',
                'content':
                    'Think of possibility as the set of futures your attention, beliefs, choices, relationships, and environment make available. Spiritual language can describe this as a field; practical action turns it into movement.\n\nPossibility expands when you:\n• See beyond old identity\n• Choose aligned action\n• Enter new environments\n• Learn new skills\n• Release stories that keep you small\n\nYour action: write three futures that are possible if you change your daily inputs and choices.',
              },
              {
                'title': 'Resonance & Entrainment',
                'duration': '20 min',
                'content':
                    'Resonance is alignment between inner state and outer action. Entrainment means your state is influenced by what you repeatedly spend time with: people, media, habits, spaces, and thoughts.\n\nAudit your inputs:\n• What makes me clearer?\n• What makes me anxious or distracted?\n• Who raises my standards?\n• What environment supports the future I want?\n\nYour action: remove one low-quality input for 48 hours and replace it with one aligned input.',
              },
              {
                'title': 'Jumping Timeline Intervals',
                'duration': '25 min',
                'content':
                    'A timeline shift happens through repeated identity-consistent choices. Instead of waiting for a dramatic breakthrough, create intervals where you live from the next version of yourself.\n\nInterval practice:\n• Choose a future identity\n• Pick a short window: one morning, one day, one week\n• Ask what that version would do now\n• Act in small concrete ways\n• Review evidence at the end\n\nYour action: design a 24-hour future-self interval and choose three behaviours to practise.',
              },
              {
                'title': 'Embodying the Future State',
                'duration': '15 min',
                'content':
                    'Embodiment means your desired future becomes visible in posture, speech, habits, boundaries, and choices before circumstances fully change.\n\nAsk:\n• How does future-me start the day?\n• What do they stop tolerating?\n• What do they practise?\n• How do they handle fear?\n• What decision would they make today?\n\nYour action: choose one future-state behaviour and make it physically real today.',
              },
            ],
          },
        ],
        'wisdom': [
          {
            'title': 'Ancient Wisdom for Modern Life',
            'desc':
                'Timeless principles from Eastern and Western philosophy applied to contemporary challenges.',
          },
          {
            'title': 'The Power of Ritual',
            'desc':
                'Why intentional rituals are the backbone of a meaningful and grounded life.',
          },
          {
            'title': 'Sacred Geometry Foundations',
            'desc':
                'An introduction to the mathematical patterns that underpin the natural and spiritual worlds.',
          },
          {
            'title': 'The Wisdom of Silence',
            'desc':
                'Learn why solitude and silence are the most powerful tools for discovering your truth.',
          },
        ],
        'quantum': [
          {
            'title': 'Quantum Manifestation',
            'desc':
                'Tap into the infinite quantum field of energy and potential. Align your consciousness and frequency to collapse your desired reality into physical form.',
          },
          {
            'title': 'The Observer Effect',
            'desc':
                'Learn how your conscious attention acts as the primary observer that shapes, collapses, and transforms the quantum matrix of your life.',
          },
          {
            'title': 'Quantum Achievement',
            'desc':
                'Unlock rapid timeline shifts and quantum leaps. Shift your identity and frequency to achieve extraordinary breakthroughs beyond linear expectations.',
          },
          {
            'title': 'Quantum Enlightenment',
            'desc':
                'Awaken to your profound cosmic connection with universal consciousness. Expand into high-frequency peace, divine wisdom, and unconditional love.',
          },
        ],
        'stoicism': [
          {
            'title': 'Stoic Mindset Training',
            'desc':
                'Focus only on what you can control. The ultimate antidote to anxiety and overwhelm.',
          },
          {
            'title': 'The Obstacle is the Way',
            'desc':
                'How to transform every challenge into an opportunity for growth and character building.',
          },
          {
            'title': 'Daily Stoic Reflections',
            'desc':
                'Short, powerful morning and evening reflections to keep you centered throughout the day.',
          },
          {
            'title': 'Memento Mori',
            'desc':
                'Understanding mortality not as something morbid, but as a catalyst for living fully now.',
          },
        ],
      },
      'personal': {
        'intro':
            'Personal growth is the deliberate commitment to becoming the highest expression of yourself. These resources support your evolution.',
        'manifestation': [
          {
            'title': 'Identity Bucket List',
            'desc':
                'Instead of experiences, list who you want to BECOME. Identity change precedes outcome change.',
          },
          {
            'title': 'Future Self Visualization',
            'desc':
                'Connect with the wisest version of yourself. What advice would they give you today?',
          },
          {
            'title': 'Limiting Belief Removal',
            'desc':
                'Identify and dissolve the false beliefs that keep you playing small in life.',
          },
          {
            'title': 'The Power of "As-If"',
            'desc':
                'Begin acting as the person you want to become. Action creates the evidence for the new identity.',
          },
        ],
        'psychology': [
          {
            'title': 'The Growth Mindset Advantage',
            'desc':
                'Carol Dweck\'s research proves that believing you can grow is the foundation of all achievement.',
          },
          {
            'title': 'Emotional Intelligence 101',
            'desc':
                'EQ predicts success more than IQ. Learn to recognize, understand, and manage emotions skillfully.',
          },
          {
            'title': 'The Power of Self-Compassion',
            'desc':
                'Why being gentle with yourself — not harder — creates lasting change and resilience.',
          },
          {
            'title': 'Cognitive Reframing',
            'desc':
                'Learn to change your perspective on any situation to find the opportunity hidden within.',
          },
        ],
        'courses': [
          {
            'title': 'Habit Transformation System',
            'desc':
                'The complete blueprint for creating new habits and dissolving old ones that no longer serve you.',
            'modules': [
              {
                'title': 'The Science of Habits',
                'duration': '20 min',
                'content':
                    'Habits are behaviours your brain automates to save energy. They form through repetition, reward, environment, and identity. This is why willpower alone is unreliable.\n\nA habit becomes easier when:\n• The cue is obvious\n• The action is simple\n• The reward is satisfying\n• The environment supports it\n• The identity matters to you\n\nYour action: choose one habit and identify why it matters to the person you are becoming.',
              },
              {
                'title': 'Cue-Routine-Reward Loop',
                'duration': '25 min',
                'content':
                    'Every habit has a loop: cue, routine, reward. To change a habit, study the loop instead of only judging the behaviour.\n\nMap it:\n• Cue: what starts it?\n• Routine: what do you do?\n• Reward: what do you get from it?\n• Craving: what are you really seeking?\n\nFor unwanted habits, keep the cue and reward in mind while replacing the routine with a better one.\n\nYour action: map one current habit loop, including the reward it gives you.',
              },
              {
                'title': 'Stacking New Habits',
                'duration': '15 min',
                'content':
                    'Habit stacking attaches a new behaviour to something you already do. This removes the need to remember from scratch.\n\nFormula:\n• After I do current habit...\n• I will do new habit...\n• For this many minutes or repetitions...\n\nExamples: after coffee, I journal one line. After lunch, I walk for five minutes. After brushing teeth, I stretch.\n\nYour action: create one habit stack and put the needed tool in the place where it will happen.',
              },
              {
                'title': 'Breaking Old Patterns',
                'duration': '20 min',
                'content':
                    'Old patterns survive because they meet a need, even if they cost you later. Change becomes easier when you keep the need but choose a cleaner route.\n\nBreak patterns by:\n• Making the cue less visible\n• Adding friction to the old behaviour\n• Replacing the routine\n• Getting support or accountability\n• Designing a recovery plan for slips\n\nYour action: choose one old pattern and add one point of friction today.',
              },
            ],
          },
          {
            'title': 'Goal Setting Mastery',
            'desc':
                'Go beyond SMART goals to create a compelling vision and actionable path to achievement.',
            'modules': [
              {
                'title': 'Vision Clarity Exercise',
                'duration': '15 min',
                'content':
                    'Goals work better when they are connected to a clear vision. A vision gives emotional direction before the plan gets practical.\n\nClarify:\n• What do I want my life to feel like?\n• What do I want to be proud of one year from now?\n• What identity does this goal support?\n• What pain am I no longer willing to repeat?\n\nYour action: write a one-paragraph vision for the area of life you most want to improve.',
              },
              {
                'title': 'Beyond SMART Goals',
                'duration': '20 min',
                'content':
                    'SMART goals are useful, but they can still feel lifeless. Strong goals are specific, emotionally meaningful, behaviour-linked, and reviewable.\n\nUpgrade a goal with:\n• Why it matters\n• What weekly behaviour drives it\n• What obstacle is predictable\n• What support or environment helps\n• How progress will be reviewed\n\nYour action: take one goal and add the weekly behaviour that makes it real.',
              },
              {
                'title': 'Reverse Planning Method',
                'duration': '25 min',
                'content':
                    'Reverse planning starts at the outcome and works backward. This turns a vague dream into milestones and next actions.\n\nSteps:\n• Define the end result\n• Set the final deadline\n• Identify monthly milestones\n• Break the first milestone into weekly actions\n• Choose the next physical step\n\nYour action: reverse plan one goal from the deadline back to what must happen this week.',
              },
              {
                'title': 'Accountability Systems',
                'duration': '15 min',
                'content':
                    'Accountability is not about being watched with shame. It is about creating support, visibility, and feedback so you do not disappear from your own intention.\n\nOptions:\n• Weekly review\n• Progress tracker\n• Accountability partner\n• Public commitment\n• Scheduled check-ins\n• Consequence or reward\n\nYour action: choose one accountability system and set the first check-in now.',
              },
            ],
          },
          {
            'title': 'The Confidence Blueprint',
            'desc':
                'Build unshakable self-belief through a series of tactical challenges and mindset shifts.',
            'modules': [
              {
                'title': 'Redlining Your Comfort Zone',
                'duration': '25 min',
                'content':
                    'Confidence grows at the edge of the comfort zone, not in panic. Redlining means choosing challenges that stretch you without overwhelming you.\n\nChallenge levels:\n• Green: easy and familiar\n• Yellow: uncomfortable but doable\n• Red: too much, likely to shut you down\n\nGrowth lives in yellow. Repeat yellow often enough and it becomes green.\n\nYour action: choose one yellow-zone challenge you can complete within 48 hours.',
              },
              {
                'title': 'The Competence-Confidence Loop',
                'duration': '20 min',
                'content':
                    'Confidence and competence feed each other. You act, learn, improve, and gain evidence. Waiting for confidence first delays the loop.\n\nBuild the loop:\n• Pick one skill\n• Practise deliberately\n• Get feedback\n• Track improvement\n• Use progress as evidence\n\nYour action: choose one confidence area and identify the skill behind it. Then schedule one practice session.',
              },
              {
                'title': 'Managing Internal Critic',
                'duration': '15 min',
                'content':
                    'The internal critic often uses harshness to prevent rejection, failure, or embarrassment. Thanking it for trying to protect you can create space to lead yourself differently.\n\nReframe:\n• Critic: You will fail.\n• Leader: I might struggle, and I can learn.\n• Critic: People will judge you.\n• Leader: Some might, but hiding costs me more.\n\nYour action: write a short response to your critic in the voice of a calm inner leader.',
              },
              {
                'title': 'Radical Self-Responsibility',
                'duration': '20 min',
                'content':
                    'Self-responsibility means owning your choices without blaming yourself for everything. It gives power back to the part of life you can influence.\n\nAsk:\n• What is mine to own?\n• What am I avoiding?\n• What choice would restore self-respect?\n• What support do I need?\n• What will I do next?\n\nYour action: choose one area where you have been waiting. Write the next responsible action and take it.',
              },
            ],
          },
          {
            'title': 'Unstoppable Discipline',
            'desc':
                'Move beyond motivation and build the systems of character that drive consistent action.',
            'modules': [
              {
                'title': 'Discipline as a Muscle',
                'duration': '15 min',
                'content':
                    'Discipline is not a fixed personality trait. It is trained through repeated promises kept under manageable resistance.\n\nTrain discipline by:\n• Starting small\n• Repeating daily\n• Recovering quickly after misses\n• Avoiding dramatic all-or-nothing plans\n• Connecting action to identity\n\nYour action: choose one small daily promise you can keep for the next seven days.',
              },
              {
                'title': 'Removing Friction Points',
                'duration': '20 min',
                'content':
                    'Discipline improves when the environment stops fighting you. Remove friction from good behaviours and add friction to bad ones.\n\nExamples:\n• Put workout clothes out\n• Block distracting apps\n• Prepare food ahead\n• Keep books visible\n• Move tempting habits further away\n• Create a clear workspace\n\nYour action: remove one friction point from a good habit and add one friction point to a habit you want less of.',
              },
              {
                'title': 'The 2-Minute Habit Rule',
                'duration': '15 min',
                'content':
                    'The two-minute rule says every habit should begin with a version so small it is easy to start. Read one page. Stretch for two minutes. Write one sentence. Open the project file.\n\nThe goal is to master showing up. Once started, you may continue, but the win is the start.\n\nYour action: define the two-minute version of one important habit and do it today.',
              },
              {
                'title': 'Long-term Integrity Bonds',
                'duration': '25 min',
                'content':
                    'Integrity bonds are commitments that connect your present actions to your future self. They turn discipline into self-respect.\n\nBuild integrity with:\n• Clear standards\n• Written commitments\n• Review rhythm\n• Honest repair after misses\n• A reason bigger than mood\n\nYour action: write one integrity statement: I am the kind of person who... Then choose the daily behaviour that proves it.',
              },
            ],
          },
        ],
        'discipline': [
          {
            'title': 'The Discipline Blueprint',
            'desc':
                'Why discipline is a muscle, not a trait. Learn the specific training plan to strengthen yours.',
          },
          {
            'title': 'Building Unbreakable Habits',
            'desc':
                'The neuroscience of habit formation and how to make 1% shifts that lead to massive results.',
          },
          {
            'title': 'Overcoming Procrastination',
            'desc':
                'Stop waiting for motivation. Learn the cognitive tools to start even when you don\'t feel like it.',
          },
          {
            'title': 'The 2-Minute Rule',
            'desc':
                'Master the art of showing up. How to make any habit so small that it\'s impossible to fail.',
          },
        ],
        'time': [
          {
            'title': 'Time Auditing for Growth',
            'desc':
                'Where is your time actually going? A brutal, honest audit to reclaim 10+ hours a week.',
          },
          {
            'title': 'The Eisenhower Matrix',
            'desc':
                'A simple prioritization framework to focus on what\'s important, not just what\'s urgent.',
          },
          {
            'title': 'Time Blocking Mastery',
            'desc':
                'How to schedule your day for maximum output and intentional rest.',
          },
          {
            'title': 'Productive Solitude',
            'desc':
                'Learn why checking out of the world is the secret to getting more done within it.',
          },
        ],
        'confidence': [
          {
            'title': 'Confidence from Competence',
            'desc':
                'Real confidence is built on a foundation of small, repeated wins. Start your streak today.',
          },
          {
            'title': 'The Power of "No"',
            'desc':
                'Every "no" to the trivial is a "yes" to the essential. Master the art of boundary setting.',
          },
          {
            'title': 'Self-Image Reconstruction',
            'desc':
                'How to update your internal script to match the person you are becoming.',
          },
          {
            'title': 'Radical Self-Acceptance',
            'desc':
                'True confidence isn\'t thinking you are perfect; it\'s being okay with your imperfections.',
          },
        ],
      },
    };

    final content = categoryContent[id]!;

    // Define the 6 sections for the grid
    final List<Map<String, dynamic>> sections = _getSectionsForCategory(
      id,
      content,
      color,
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: onBack,
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SolidGlyphBadge(
              glyph: category['glyph'],
              color: _readableCardForeground(color),
              background: color,
              size: 38,
            ),
            const SizedBox(width: 10),
            Text(
              category['title'],
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color.withAlpha(50)),
                ),
                child: Text(
                  content['intro'],
                  style: GoogleFonts.outfit(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withAlpha(200),
                    fontSize: 14,
                    height: 1.45,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _StackedIndexCardList(
                itemCount: sections.length,
                cardHeight: 164,
                collapsedStep: 70,
                expandedStep: 124,
                onTap: (index) => _showSectionPreview(context, sections[index]),
                itemBuilder: (context, index) {
                  final section = sections[index];
                  return _buildSubmenuGridCard(
                    context: context,
                    title: section['title'],
                    subtitle: section['subtitle'],
                    glyph: _glyphForSectionTitle(section['title']),
                    color: _topicShade(color, index),
                    isHighlighted: section['isCourse'] ?? false,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getSectionsForCategory(
    String id,
    Map<String, dynamic> content,
    Color color,
  ) {
    if (id == 'health') {
      return [
        {
          'title': 'Mini Courses',
          'subtitle': 'Guided Paths',
          'icon': CupertinoIcons.book_fill,
          'items': content['courses'],
          'isCourse': true,
        },
        {
          'title': 'Manifestation',
          'subtitle': 'Visualization',
          'icon': Icons.auto_awesome,
          'items': content['manifestation'],
        },
        {
          'title': 'Psychology',
          'subtitle': 'Mindset & EQ',
          'icon': CupertinoIcons.lightbulb_fill,
          'items': content['psychology'],
        },
        {
          'title': 'Nutrition',
          'subtitle': 'Clean Fuel',
          'icon': Icons.restaurant,
          'items': content['nutrition'],
        },
        {
          'title': 'Biohacking',
          'subtitle': 'Resilience',
          'icon': Icons.biotech,
          'items': content['biohacking'],
        },
        {
          'title': 'Longevity',
          'subtitle': 'Science of Aging',
          'icon': Icons.hourglass_bottom,
          'items': content['longevity'],
        },
      ];
    } else if (id == 'wealth') {
      return [
        {
          'title': 'Mini Courses',
          'subtitle': 'Guided Paths',
          'icon': CupertinoIcons.book_fill,
          'items': content['courses'],
          'isCourse': true,
        },
        {
          'title': 'Manifestation',
          'subtitle': 'Abundance',
          'icon': Icons.auto_awesome,
          'items': content['manifestation'],
        },
        {
          'title': 'Psychology',
          'subtitle': 'Money Story',
          'icon': CupertinoIcons.lightbulb_fill,
          'items': content['psychology'],
        },
        {
          'title': 'Investing',
          'subtitle': 'Asset Growth',
          'icon': Icons.trending_up,
          'items': content['investing'],
        },
        {
          'title': 'Side Hustles',
          'subtitle': 'Income Streams',
          'icon': Icons.work_outline,
          'items': content['hustles'],
        },
        {
          'title': 'Budgeting',
          'subtitle': 'Financial Control',
          'icon': Icons.account_balance_wallet,
          'items': content['budgeting'],
        },
      ];
    } else if (id == 'relationships') {
      return [
        {
          'title': 'Mini Courses',
          'subtitle': 'Guided Paths',
          'icon': CupertinoIcons.book_fill,
          'items': content['courses'],
          'isCourse': true,
        },
        {
          'title': 'Manifestation',
          'subtitle': 'Connection',
          'icon': Icons.auto_awesome,
          'items': content['manifestation'],
        },
        {
          'title': 'Psychology',
          'subtitle': 'Attachment',
          'icon': CupertinoIcons.lightbulb_fill,
          'items': content['psychology'],
        },
        {
          'title': 'Resolution',
          'subtitle': 'Conflict Skills',
          'icon': Icons.handshake,
          'items': content['resolution'],
        },
        {
          'title': 'Dating',
          'subtitle': 'Attraction',
          'icon': Icons.favorite_border,
          'items': content['dating'],
        },
        {
          'title': 'Social',
          'subtitle': 'Influence',
          'icon': Icons.groups_outlined,
          'items': content['social'],
        },
      ];
    } else if (id == 'career') {
      return [
        {
          'title': 'Mini Courses',
          'subtitle': 'Guided Paths',
          'icon': CupertinoIcons.book_fill,
          'items': content['courses'],
          'isCourse': true,
        },
        {
          'title': 'Manifestation',
          'subtitle': 'Vision',
          'icon': Icons.auto_awesome,
          'items': content['manifestation'],
        },
        {
          'title': 'Psychology',
          'subtitle': 'Performance',
          'icon': CupertinoIcons.lightbulb_fill,
          'items': content['psychology'],
        },
        {
          'title': 'Leadership',
          'subtitle': 'Team Dynamics',
          'icon': Icons.stars,
          'items': content['leadership'],
        },
        {
          'title': 'Speaking',
          'subtitle': 'Public Voice',
          'icon': Icons.mic_none,
          'items': content['speaking'],
        },
        {
          'title': 'Productivity',
          'subtitle': 'Deep Work',
          'icon': Icons.timer_outlined,
          'items': content['productivity'],
        },
      ];
    } else if (id == 'spiritual') {
      return [
        {
          'title': 'Mini Courses',
          'subtitle': 'Guided Paths',
          'icon': CupertinoIcons.book_fill,
          'items': content['courses'],
          'isCourse': true,
        },
        {
          'title': 'Manifestation',
          'subtitle': 'Purpose',
          'icon': Icons.auto_awesome,
          'items': content['manifestation'],
        },
        {
          'title': 'Psychology',
          'subtitle': 'Presence',
          'icon': CupertinoIcons.lightbulb_fill,
          'items': content['psychology'],
        },
        {
          'title': 'Wisdom',
          'subtitle': 'Foundations',
          'icon': Icons.history_edu,
          'items': content['wisdom'],
        },
        {
          'title': 'Quantum',
          'subtitle': 'Achievement',
          'icon': CupertinoIcons.bolt_fill,
          'items': content['quantum'],
        },
        {
          'title': 'Stoicism',
          'subtitle': 'Stoic Tools',
          'icon': Icons.shield_outlined,
          'items': content['stoicism'],
        },
      ];
    } else {
      // personal
      return [
        {
          'title': 'Mini Courses',
          'subtitle': 'Guided Paths',
          'icon': CupertinoIcons.book_fill,
          'items': content['courses'],
          'isCourse': true,
        },
        {
          'title': 'Manifestation',
          'subtitle': 'Identity',
          'icon': Icons.auto_awesome,
          'items': content['manifestation'],
        },
        {
          'title': 'Psychology',
          'subtitle': 'Mindset',
          'icon': CupertinoIcons.lightbulb_fill,
          'items': content['psychology'],
        },
        {
          'title': 'Discipline',
          'subtitle': 'Habit Mastery',
          'icon': Icons.fitness_center,
          'items': content['discipline'],
        },
        {
          'title': 'Time Mgmt',
          'subtitle': 'Schedule',
          'icon': Icons.calendar_today_outlined,
          'items': content['time'],
        },
        {
          'title': 'Confidence',
          'subtitle': 'Self-Image',
          'icon': Icons.person_outline,
          'items': content['confidence'],
        },
      ];
    }
  }

  String _glyphForSectionTitle(String title) {
    return switch (title) {
      'Mini Courses' => 'book',
      'Manifestation' => 'spark',
      'Psychology' => 'mind',
      'Nutrition' => 'nutrition',
      'Biohacking' => 'bio',
      'Longevity' => 'time',
      'Investing' => 'trend',
      'Side Hustles' => 'hustle',
      'Budgeting' => 'wallet',
      'Resolution' => 'bridge',
      'Dating' => 'heart',
      'Social' => 'people',
      'Leadership' => 'star',
      'Speaking' => 'voice',
      'Productivity' => 'timer',
      'Wisdom' => 'scroll',
      'Quantum' => 'bolt',
      'Stoicism' => 'shield',
      'Discipline' => 'strength',
      'Time Mgmt' => 'calendar',
      'Confidence' => 'person',
      _ => 'spark',
    };
  }

  Color _topicShade(Color base, int index) {
    const strengths = [0.0, 0.08, 0.15, 0.22, 0.12, 0.28];
    final strength = strengths[index % strengths.length];
    return index.isEven
        ? Color.lerp(base, Colors.white, strength)!
        : Color.lerp(base, Colors.black, strength * 0.55)!;
  }

  void _showSectionPreview(BuildContext context, Map<String, dynamic> section) {
    final items = (section['items'] as List?) ?? const [];
    final itemPreview = items
        .take(3)
        .map((item) => item['title'] as String? ?? '')
        .where((title) => title.isNotEmpty)
        .join(', ');
    final description = itemPreview.isEmpty
        ? 'Open this area to explore focused lessons and practical prompts.'
        : 'Includes $itemPreview.';
    final title = section['title'] as String;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _WalletPreviewSheet(
          title: title,
          subtitle: section['subtitle'],
          description: description,
          color: color,
          glyph: _glyphForSectionTitle(title),
          actionLabel: 'Open $title',
          onAction: () {
            Navigator.pop(sheetContext);
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => _SubCategoryDetailPage(
                  categoryTitle: category['title'],
                  subCategoryTitle: title,
                  icon: section['icon'],
                  glyph: _glyphForSectionTitle(title),
                  color: color,
                  items: section['items'],
                  isCourse: section['isCourse'] ?? false,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSubmenuGridCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String glyph,
    required Color color,
    bool isHighlighted = false,
  }) {
    final foreground = _readableCardForeground(color);

    return SizedBox(
      height: 164,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: _cardGradient(color),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: foreground.withAlpha(isHighlighted ? 32 : 24),
              blurRadius: isHighlighted ? 16 : 10,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(
            color: isHighlighted
                ? foreground.withAlpha(36)
                : foreground.withAlpha(18),
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SolidGlyphBadge(
                        glyph: glyph,
                        color: _badgeGlyphColor(color),
                        background: Colors.white.withAlpha(225),
                        size: 44,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (isHighlighted)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: Icon(
                                      CupertinoIcons.sparkles,
                                      color: foreground.withAlpha(150),
                                      size: 13,
                                    ),
                                  ),
                                Flexible(
                                  child: Text(
                                    title,
                                    textAlign: TextAlign.right,
                                    style: GoogleFonts.outfit(
                                      color: foreground,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              textAlign: TextAlign.right,
                              style: GoogleFonts.outfit(
                                color: foreground.withAlpha(185),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubCategoryDetailPage extends StatelessWidget {
  final String categoryTitle;
  final String subCategoryTitle;
  final IconData icon;
  final String glyph;
  final Color color;
  final List items;
  final bool isCourse;

  const _SubCategoryDetailPage({
    required this.categoryTitle,
    required this.subCategoryTitle,
    required this.icon,
    required this.glyph,
    required this.color,
    required this.items,
    this.isCourse = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          subCategoryTitle,
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Row(
              children: [
                _SolidGlyphBadge(
                  glyph: glyph,
                  color: _readableCardForeground(color),
                  background: color,
                  size: 42,
                ),
                const SizedBox(width: 12),
                Text(
                  categoryTitle.toUpperCase(),
                  style: GoogleFonts.outfit(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withAlpha(120),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _StackedIndexCardList(
              itemCount: items.length,
              cardHeight: 148,
              collapsedStep: 94,
              expandedStep: 116,
              onTap: (index) => _showItemPreview(context, items[index]),
              itemBuilder: (context, index) {
                final item = items[index];
                return _buildItemCard(
                  context: context,
                  title: item['title'],
                  glyph: glyph,
                  color: _itemTone(color, index),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showItemPreview(BuildContext context, dynamic item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _WalletPreviewSheet(
          title: item['title'],
          subtitle: subCategoryTitle,
          description: item['desc'],
          color: color,
          glyph: glyph,
          actionLabel: isCourse ? 'Open Course' : 'Read Lesson',
          onAction: () {
            Navigator.pop(sheetContext);
            _openItem(context, item);
          },
        );
      },
    );
  }

  void _openItem(BuildContext context, dynamic item) {
    if (isCourse) {
      final List<Map<String, String>>? modules = (item['modules'] as List?)
          ?.map((m) => Map<String, String>.from(m))
          .toList();
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => SelfHelpCourseView(
            title: item['title'],
            description: item['desc'],
            category: subCategoryTitle,
            color: color,
            modules: modules,
          ),
        ),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => SelfHelpArticleView(
            title: item['title'],
            description: item['desc'],
            category: subCategoryTitle,
            parentCategory: categoryTitle,
            color: color,
          ),
        ),
      );
    }
  }

  Color _itemTone(Color base, int index) {
    const strengths = [0.0, 0.08, 0.15, 0.22];
    final strength = strengths[index % strengths.length];
    return index.isEven
        ? Color.lerp(base, Colors.white, strength)!
        : Color.lerp(base, Colors.black, strength * 0.55)!;
  }

  Widget _buildItemCard({
    required BuildContext context,
    required String title,
    required String glyph,
    required Color color,
  }) {
    final foreground = _readableCardForeground(color);

    return SizedBox(
      height: 148,
      child: Container(
        padding: const EdgeInsets.all(16),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: foreground.withAlpha(18)),
          boxShadow: [
            BoxShadow(
              color: foreground.withAlpha(22),
              blurRadius: 12,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              top: 18,
              right: 16,
              left: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      color: foreground,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      height: 1.05,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 14,
              bottom: 14,
              child: Icon(
                Icons.chevron_right,
                color: foreground.withAlpha(150),
                size: 26,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
