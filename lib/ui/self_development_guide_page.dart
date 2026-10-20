import 'package:flutter/material.dart';
import 'widgets/guide_page.dart';

class SelfDevelopmentGuidePage extends StatelessWidget {
  const SelfDevelopmentGuidePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const GuidePage(
      appBarTitle: 'Media Guide',
      heroImageAsset: 'assets/hub_headers/self_development.png',
      heroHeadline:
          'A practical guide to the learning, training, and insight media available to you.',
      sections: [
        GuideSectionData(
          icon: Icons.school_outlined,
          title: 'What this space is for',
          body:
              'Media brings Ablerite\'s learning, brain training, critical frameworks, and short insights into one place. Use it to strengthen your attention, judgement, and the ideas you rely on when making decisions.\n\nYou do not need to use every format at once. Choose the media that matches the time and focus you have available, then return consistently.',
        ),
        GuideSectionData(
          icon: Icons.psychology_alt_outlined,
          title: 'Brain Training',
          body:
              'Short focus, memory, and mental-sharpness games. These are not entertainment breaks — they are deliberate reps for the same attention muscle you rely on for deep work, difficult conversations, and follow-through on goals.\n\nUse Brain Training when you notice your focus has been scattered for a few days. A short session is a quick, measurable way to reset it.',
        ),
        GuideSectionData(
          icon: Icons.school,
          title: 'Knowledge',
          body:
              'A learning library covering goals, habits, mindset, and practical personal growth. Knowledge is the "why" and "how" behind the rest of the app — it explains the reasoning so the habits you build elsewhere are not just mechanical.\n\nRead a little often rather than binging occasionally. Ideas that are spaced out are the ones that actually change behaviour.',
        ),
        GuideSectionData(
          icon: Icons.adjust,
          title: 'Critical Learning',
          body:
              'Focused frameworks for goals, habits, and mindset, distilled down to what is actually actionable. Where Knowledge is broader reading, Critical Learning is the condensed version you return to when you need a clear framework fast, not a full article.\n\nUse this when you are about to set a new goal or restart a stalled habit — it is built for exactly that moment.',
        ),
        GuideSectionData(
          icon: Icons.lightbulb_outline,
          title: 'Key Insights',
          body:
              'Short, concise prompts and perspective shifts for when you need a quick reset rather than a full lesson. These are deliberately small: something to read in under a minute that reframes how you are looking at a problem.\n\nKey Insights work best as a check-in, not a study session — open it when you feel stuck, not when you have an hour to spare.',
        ),
        GuideSectionData(
          icon: Icons.tips_and_updates_outlined,
          title: 'Why this area matters',
          body:
              'Media gives you several ways to learn without forcing every idea into the same format. A quick insight can reset your perspective, a focused framework can unblock a goal, and brain training can sharpen your attention.\n\nTreat this area as a flexible library: open the format that fits what you need today.',
        ),
      ],
    );
  }
}
