import 'package:flutter/material.dart';
import 'widgets/guide_page.dart';

class ExplorationGuidePage extends StatelessWidget {
  const ExplorationGuidePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const GuidePage(
      appBarTitle: 'Exploration Guide',
      heroImageAsset: 'assets/hub_headers/exploration.png',
      heroHeadline:
          'A practical guide to imagining, discovering, and reflecting.',
      sections: [
        GuideSectionData(
          icon: Icons.explore_outlined,
          title: 'What this space is for',
          body:
              'Exploration is for the reflective, imaginative side of the app — visualising what you are moving toward, capturing raw ideas before they are lost, and reviewing your days honestly enough to notice patterns. None of this produces an immediate task, and that is deliberate: it is where clarity forms before it becomes a plan somewhere else in the app.\n\nThe four areas below work at different timescales — vision boards are long-range, journals are daily — but all of them exist to keep you in contact with what actually matters to you.',
        ),
        GuideSectionData(
          icon: Icons.remove_red_eye_outlined,
          title: 'Visualization',
          body:
              'Vision boards and Focus Vision give you a visual, always-available reminder of what you are working toward. A board full of text goals is easy to skim past; a board full of images you chose is much harder to ignore.\n\nRevisit your boards regularly, not just when you build them. The value is in repeated exposure, not the one afternoon spent arranging images.',
          imageAsset: 'assets/guide_images/exploration_visionboard.png',
        ),
        GuideSectionData(
          icon: Icons.rocket_launch_outlined,
          title: 'Manifestation',
          body:
              'Expectations tracking and cosmic ordering live here — space for desires that matter emotionally but do not fit neatly into a goal with a deadline: meeting the right person, an unexpected opportunity, a new kind of peace. Place them here, review them, and take the aligned action that gives them somewhere to land.\n\nThis is not passive wishing. The practice works because naming something clearly changes what you notice and how you act, not because writing it down alone produces the result.',
          imageAsset: 'assets/guide_images/exploration_cosmicordering.png',
        ),
        GuideSectionData(
          icon: Icons.folder_outlined,
          title: 'Notebooks',
          body:
              'Free-form space for ideas, plans, and research that do not belong in a goal or a journal entry — the place for a half-formed thought you want to keep without committing to it yet.\n\nUse Notebooks as a capture tool, not a to-do list. If an idea in a notebook turns into something you are actually going to do, give it a home as a goal or task instead.',
          imageAsset: 'assets/guide_images/exploration_notebooks.png',
        ),
        GuideSectionData(
          icon: Icons.book_outlined,
          title: 'Journals',
          body:
              'Daily reflection and gratitude, organised into folders so you can separate different threads of your life if you want to. A single honest paragraph a day, over months, becomes a record you can actually learn from — patterns are far easier to see in writing than in memory.\n\nWrite for yourself, not for anyone reading it later. The value of a journal drops the moment it becomes a performance.',
          imageAsset: 'assets/guide_images/exploration_journals.png',
        ),
        GuideSectionData(
          icon: Icons.auto_awesome,
          title: 'Text Coaching',
          body:
              'The sparkles icon in the header is a direct shortcut into a coaching conversation, without leaving Exploration first. Use it the moment reflection turns into something you want to think out loud, rather than navigating to Action Center deliberately.\n\nIt opens the same conversation space as Action Center\'s Text Coaching, with the same context on your goals, tasks, and habits.',
        ),
        GuideSectionData(
          icon: Icons.calendar_month_outlined,
          title: 'Calendar',
          body:
              'The calendar icon in the header is the same shortcut you\'ll find in Action Center and Wellness — a single list of every goal and task with a due date, grouped into Overdue, Today, Tomorrow, and the days ahead. It\'s here so you can check what\'s due without leaving Exploration.',
        ),
        GuideSectionData(
          icon: Icons.tips_and_updates_outlined,
          title: 'A useful rhythm',
          body:
              'Look at your vision board more often than you edit it. Log expectations and orders when they are genuinely on your mind, not on a schedule. Use notebooks freely — capture first, sort later. Journal at the same time each day so it becomes automatic rather than another decision.\n\nExploration works best as a quiet, regular habit in the background, not an occasional deep session.',
        ),
      ],
    );
  }
}
