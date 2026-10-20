import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'widgets/focus_app_bar_actions.dart';
import 'widgets/tablet_layout.dart';

class InsightsPage extends StatefulWidget {
  const InsightsPage({super.key});

  @override
  State<InsightsPage> createState() => _InsightsPageState();
}

class _InsightsHomePage extends StatelessWidget {
  final VoidCallback onStart;

  const _InsightsHomePage({required this.onStart});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: const FocusAwareBackButton(),
        title: FocusAwareAppBarTitle(
          child: Text(
            'Key Insights',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
        ),
        actions: const [
          FocusAppBarActions(guide: FocusHelpGuide.selfDevelopment),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 14, left: 8),
                child: Text(
                  'Quotes and reflections for daily clarity.',
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
                        'assets/images/app_banners/keyinsights.png',
                        fit: BoxFit.cover,
                        alignment: isTabletLandscape(context)
                            ? Alignment.topCenter
                            : Alignment.center,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Insightful reflection',
                            style: GoogleFonts.outfit(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Key Insights brings together quotes and reflective ideas that help you pause, think, and reconnect with what matters.\n\nUse them when you want a quick shift in perspective across health, wealth, connections, career, spirituality, and growth.\n\nEach reflection is short enough to revisit often, but meaningful enough to sit with. Let the words challenge your assumptions, steady your focus, and guide your next choice.',
                            style: GoogleFonts.outfit(
                              fontSize: 12.6,
                              height: 1.24,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withAlpha(180),
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
                      const Icon(
                        Icons.lightbulb,
                        color: Colors.white,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'View Insights',
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

class _InsightsPageState extends State<InsightsPage> {
  String _selectedCategory = 'all';
  bool _showHome = true;

  final List<Map<String, dynamic>> _categories = [
    {'id': 'all', 'title': 'All'},
    {'id': 'health', 'title': 'Health'},
    {'id': 'wealth', 'title': 'Wealth'},
    {'id': 'relationships', 'title': 'Relationships'},
    {'id': 'career', 'title': 'Career'},
    {'id': 'spiritual', 'title': 'Spiritual'},
    {'id': 'personal', 'title': 'Growth'},
  ];

  final List<Map<String, dynamic>> _quotes = [
    // Health
    {
      'text': 'Take care of your body. It\'s the only place you have to live.',
      'author': 'Jim Rohn',
      'category': 'health',
    },
    {
      'text': 'Health is not a condition of the body, it is a state of mind.',
      'author': 'Mary Arnold',
      'category': 'health',
    },
    {
      'text': 'The greatest wealth is health.',
      'author': 'Virgil',
      'category': 'health',
    },
    {
      'text': 'Your body hears everything your mind says. Stay positive.',
      'author': 'Unknown',
      'category': 'health',
    },
    {
      'text': 'A healthy outside starts from the inside.',
      'author': 'Robert Urich',
      'category': 'health',
    },
    {
      'text': 'The first wealth is health.',
      'author': 'Ralph Waldo Emerson',
      'category': 'health',
    },
    {
      'text': 'Moderation. We indulge a little, suffer a little, enjoy a lot.',
      'author': 'Unknown',
      'category': 'health',
    },
    {
      'text':
          'Fitness is not about being better than someone else. It\'s about being better than you used to be.',
      'author': 'Unknown',
      'category': 'health',
    },

    // Wealth
    {
      'text': 'The money you earn is a result of the value you create.',
      'author': 'T. Harv Eker',
      'category': 'wealth',
    },
    {
      'text': 'Wealth is not his that has it, but his that enjoys it.',
      'author': 'Samuel Johnson',
      'category': 'wealth',
    },
    {
      'text':
          'Money is a tool. It will take you wherever you wish, but it will not replace you as the driver.',
      'author': 'Robert Kiyosaki',
      'category': 'wealth',
    },
    {
      'text': 'Abundance is not about possession. It\'s about appreciation.',
      'author': 'Unknown',
      'category': 'wealth',
    },
    {
      'text': 'The more grateful you are, the more you receive.',
      'author': 'Unknown',
      'category': 'wealth',
    },
    {
      'text':
          'Rich is not about how much you have. Rich is about how much you give.',
      'author': 'Tony Robbins',
      'category': 'wealth',
    },
    {
      'text': 'An investment in knowledge pays the best interest.',
      'author': 'Benjamin Franklin',
      'category': 'wealth',
    },
    {
      'text': 'Don\'t work for money, make money work for you.',
      'author': 'Robert Kiyosaki',
      'category': 'wealth',
    },
    {
      'text': 'Wealth flows in proportion to gratitude.',
      'author': 'Unknown',
      'category': 'wealth',
    },

    // Relationships
    {
      'text':
          'The quality of your life depends on the quality of your relationships.',
      'author': 'Tony Robbins',
      'category': 'relationships',
    },
    {
      'text':
          'In the end, we only regret the chances we didn\'t take, the relationships we didn\'t fix, and the "I love you\'s" we didn\'t say.',
      'author': 'Unknown',
      'category': 'relationships',
    },
    {
      'text':
          'Relationships are like a garden. They need constant care to bloom.',
      'author': 'Unknown',
      'category': 'relationships',
    },
    {
      'text': 'Love is not about possession. It\'s about appreciation.',
      'author': 'Osho',
      'category': 'relationships',
    },
    {
      'text':
          'The meeting of two personalities is like the contact of two chemical substances.',
      'author': 'Carl Jung',
      'category': 'relationships',
    },
    {
      'text': 'A healthy relationship is one where both people grow.',
      'author': 'Unknown',
      'category': 'relationships',
    },
    {
      'text':
          'We are attached to what we think we need. We are open to what we choose to accept.',
      'author': 'Unknown',
      'category': 'relationships',
    },
    {
      'text':
          'People will forget what you said, people will forget what you did, but people will never forget how you made them feel.',
      'author': 'Maya Angelou',
      'category': 'relationships',
    },
    {
      'text':
          'The best relationship is one where your love for each other exceeds your need for each other.',
      'author': 'Unknown',
      'category': 'relationships',
    },

    // Career
    {
      'text':
          'Choose a job you love, and you will never have to work a day in your life.',
      'author': 'Confucius',
      'category': 'career',
    },
    {
      'text': 'The only way to do great work is to love what you do.',
      'author': 'Steve Jobs',
      'category': 'career',
    },
    {
      'text':
          'Your work is going to fill a large part of your life. The only way to be truly satisfied is to do what you believe is great work.',
      'author': 'Steve Jobs',
      'category': 'career',
    },
    {
      'text': 'Don\'t be afraid to give up the good to go for the great.',
      'author': 'John D. Rockefeller',
      'category': 'career',
    },
    {
      'text': 'Success is not what you have, but who you are.',
      'author': 'Bo Bennett',
      'category': 'career',
    },
    {
      'text':
          'The only limit to our realization of tomorrow is our doubts of today.',
      'author': 'Franklin D. Roosevelt',
      'category': 'career',
    },
    {
      'text': 'Opportunities don\'t happen. You create them.',
      'author': 'Chris Grosser',
      'category': 'career',
    },
    {
      'text':
          'Your career is a vehicle for expression, not just a means to a paycheck.',
      'author': 'Unknown',
      'category': 'career',
    },

    // Spiritual
    {
      'text': 'When you let go of what you are, you become what you might be.',
      'author': 'Lao Tzu',
      'category': 'spiritual',
    },
    {
      'text': 'The wound is the place where the Light enters you.',
      'author': 'Rumi',
      'category': 'spiritual',
    },
    {
      'text':
          'You are not a drop in the ocean. You are the entire ocean in a drop.',
      'author': 'Rumi',
      'category': 'spiritual',
    },
    {
      'text': 'What you seek is seeking you.',
      'author': 'Rumi',
      'category': 'spiritual',
    },
    {
      'text':
          'The soul always knows what to do to heal itself. The challenge is to silence the mind.',
      'author': 'Caroline Myss',
      'category': 'spiritual',
    },
    {
      'text': 'We are spiritual beings having a human experience.',
      'author': 'Pierre Teilhard de Chardin',
      'category': 'spiritual',
    },
    {
      'text': 'Peace comes from within. Do not seek it without.',
      'author': 'Buddha',
      'category': 'spiritual',
    },
    {
      'text':
          'The truth is like a lion. You don\'t have to defend it. Let it loose. It will defend itself.',
      'author': 'St. Augustine',
      'category': 'spiritual',
    },
    {
      'text': 'Every moment is a fresh beginning.',
      'author': 'T.S. Eliot',
      'category': 'spiritual',
    },

    // Personal Growth
    {
      'text':
          'The only person you are destined to become is the person you decide to be.',
      'author': 'Ralph Waldo Emerson',
      'category': 'personal',
    },
    {
      'text': 'Believe you can and you\'re halfway there.',
      'author': 'Theodore Roosevelt',
      'category': 'personal',
    },
    {
      'text':
          'It is not the strongest of the species that survives, nor the most intelligent. It is the one most adaptable to change.',
      'author': 'Charles Darwin',
      'category': 'personal',
    },
    {
      'text': 'The mind is everything. What you think you become.',
      'author': 'Buddha',
      'category': 'personal',
    },
    {
      'text': 'Your limitation—it\'s only your imagination.',
      'author': 'Unknown',
      'category': 'personal',
    },
    {
      'text':
          'Hard times don\'t create heroes. It is in the hard times where the hero within us is revealed.',
      'author': 'Bob Riley',
      'category': 'personal',
    },
    {
      'text':
          'People who are crazy enough to think they can change the world, are the ones who do.',
      'author': 'Rob Siltanen',
      'category': 'personal',
    },
    {
      'text': 'Dream it. Believe it. Achieve it.',
      'author': 'Unknown',
      'category': 'personal',
    },
    {
      'text': 'The only impossible journey is the one you never begin.',
      'author': 'Tony Robbins',
      'category': 'personal',
    },
    {
      'text':
          'Success is not final, failure is not fatal: it is the courage to continue that counts.',
      'author': 'Winston Churchill',
      'category': 'personal',
    },
    {
      'text': 'Everything you\'ve ever wanted is on the other side of fear.',
      'author': 'George Addair',
      'category': 'personal',
    },
    {
      'text':
          'The best time to plant a tree was 20 years ago. The second best time is now.',
      'author': 'Chinese Proverb',
      'category': 'personal',
    },
    {
      'text':
          'Your time is limited, don\'t waste it living someone else\'s life.',
      'author': 'Steve Jobs',
      'category': 'personal',
    },
    {
      'text':
          'The only way to achieve the impossible is to believe it is possible.',
      'author': 'Charles Kingsleigh',
      'category': 'personal',
    },
    {
      'text':
          'What lies behind us and what lies before us are tiny matters compared to what lies within us.',
      'author': 'Ralph Waldo Emerson',
      'category': 'personal',
    },
  ];

  List<Map<String, dynamic>> get _filteredQuotes {
    if (_selectedCategory == 'all') {
      return _quotes;
    }
    return _quotes.where((q) => q['category'] == _selectedCategory).toList();
  }

  Color _getCategoryColor(String category) {
    if (category == 'health') return Theme.of(context).colorScheme.primary;
    if (category == 'wealth') return Theme.of(context).colorScheme.secondary;
    if (category == 'relationships') {
      return Theme.of(context).colorScheme.tertiary;
    }
    if (category == 'career') {
      return Theme.of(context).colorScheme.primaryContainer;
    }
    if (category == 'spiritual') {
      return Theme.of(context).colorScheme.secondaryContainer;
    }
    if (category == 'personal') {
      return Theme.of(context).colorScheme.tertiaryContainer;
    }
    return Theme.of(context).colorScheme.primary; // Default color
  }

  @override
  Widget build(BuildContext context) {
    if (_showHome) {
      return _InsightsHomePage(
        onStart: () => setState(() => _showHome = false),
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
          onPressed: () => setState(() => _showHome = true),
        ),
        title: Text(
          'Key Insights',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 24),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Category filter chips
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isSelected = _selectedCategory == category['id'];
                  final color = category['id'] == 'all'
                      ? Theme.of(context).colorScheme.onSurface
                      : _getCategoryColor(category['id']);

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      selected: isSelected,
                      label: Text(
                        category['title'],
                        style: TextStyle(
                          color: isSelected
                              ? Theme.of(context).colorScheme.onPrimary
                              : Theme.of(
                                  context,
                                ).colorScheme.onSurface.withAlpha(150),
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest.withAlpha(100),
                      selectedColor: color,
                      checkmarkColor: Theme.of(context).colorScheme.onPrimary,
                      side: BorderSide(
                        color: isSelected
                            ? color
                            : Theme.of(context).dividerColor.withAlpha(50),
                      ),
                      onSelected: (selected) {
                        setState(() => _selectedCategory = category['id']);
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            // Quotes list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _filteredQuotes.length,
                itemBuilder: (context, index) {
                  final quote = _filteredQuotes[index];
                  final color = _getCategoryColor(quote['category']);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest.withAlpha(100),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: color.withAlpha(40)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Quote mark
                        Icon(
                          Icons.format_quote,
                          color: color.withAlpha(150),
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        // Quote text
                        Text(
                          quote['text'],
                          style: GoogleFonts.outfit(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 16,
                            height: 1.5,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Author and category
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: color.withAlpha(30),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                quote['category'].toString().toUpperCase(),
                                style: GoogleFonts.outfit(
                                  color: color,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '— ${quote['author']}',
                              style: GoogleFonts.outfit(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withAlpha(120),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
