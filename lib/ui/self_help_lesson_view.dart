import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/cupertino.dart';

class SelfHelpLessonView extends StatelessWidget {
  final String title;
  final String content;
  final String category;
  final Color color;
  final int moduleIndex;
  final VoidCallback onComplete;

  const SelfHelpLessonView({
    super.key,
    required this.title,
    required this.content,
    required this.category,
    required this.color,
    required this.moduleIndex,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120.0,
            floating: false,
            pinned: true,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            leading: IconButton(
              icon: Icon(
                Icons.close,
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
                      color.withAlpha((0.2 * 255).toInt()),
                      Theme.of(context).scaffoldBackgroundColor,
                    ],
                  ),
                ),
                child: Center(
                  child: Opacity(
                    opacity: 0.5,
                    child: Icon(
                      CupertinoIcons.book_fill,
                      size: 40,
                      color: color,
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 16.0,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color.withAlpha((0.1 * 255).toInt()),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'MODULE ${moduleIndex + 1}',
                        style: GoogleFonts.outfit(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      category.toUpperCase(),
                      style: GoogleFonts.outfit(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withAlpha(150),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
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
                const SizedBox(height: 32),
                Text(
                  content,
                  style: GoogleFonts.outfit(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 17,
                    height: 1.8,
                  ),
                ),
                const SizedBox(height: 48),
                Padding(
                  padding: const EdgeInsets.only(bottom: 60),
                  child: ElevatedButton(
                    onPressed: () {
                      onComplete();
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color == Colors.black
                          ? Theme.of(context).colorScheme.primary
                          : (color == Colors.white
                                ? Theme.of(context).colorScheme.primary
                                : color),
                      foregroundColor: Theme.of(context).colorScheme.surface,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          CupertinoIcons.checkmark_circle_fill,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'COMPLETE LESSON',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
