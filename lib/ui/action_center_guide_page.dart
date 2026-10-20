import 'package:flutter/material.dart';
import 'widgets/guide_page.dart';

class ActionCenterGuidePage extends StatelessWidget {
  const ActionCenterGuidePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const GuidePage(
      appBarTitle: 'Action Center Guide',
      heroImageAsset: 'assets/hub_headers/action_center.png',
      heroHeadline:
          'A practical guide to turning intentions into tasks you actually finish.',
      sections: [
        GuideSectionData(
          icon: Icons.center_focus_strong_outlined,
          title: 'What this space is for',
          body:
              'Action Center is the central page — where goals, tasks, affirmations, and coaching live. Everything here exists to close the gap between deciding something matters and actually doing it: a goal without a task list stays an intention, and a task without a due date drifts indefinitely.\n\nThe four areas below are designed to be used together, not in isolation. A goal should produce tasks; tasks should have dates; affirmations reinforce the identity behind them; coaching is where you talk it through when you get stuck.',
        ),
        GuideSectionData(
          icon: Icons.adjust,
          title: 'Goals',
          body:
              'Define what you are working toward and track progress over time. Each goal can hold its own task board, linked goals, a target date, and — for active goals — be marked primary so it stays pinned to the top of your view.\n\nA goal on its own is just a sentence. Break it into tasks from the goal\'s detail page so it becomes something you can actually work on this week.',
          imageAsset: 'assets/guide_images/action_goals.png',
        ),
        GuideSectionData(
          icon: Icons.task_alt,
          title: 'Task Lists',
          body:
              'Quick Tasks and any custom boards you create live here — for the smaller, faster-moving to-dos that do not need a full goal wrapped around them. Give a task a due date when it genuinely has one; that date is what makes it show up in the Calendar.\n\nUse Task Lists for the operational layer of your day: the things you need to do regardless of which goal they serve.',
          imageAsset: 'assets/guide_images/action_tasklists.png',
        ),
        GuideSectionData(
          icon: Icons.format_quote_rounded,
          title: 'Affirmations',
          body:
              'Guided sessions that repeat a short, powerful statement multiple times with increasing conviction. This is not just repetition for its own sake — the aim is to reinforce the identity and intention behind a goal, especially when motivation is low and the work itself feels distant.\n\nRun a session before you start on something you have been avoiding. It is short, deliberate, and designed to shift how ready you feel, not just what you know.',
          imageAsset: 'assets/images/audio_covers/affirmations.png',
        ),
        GuideSectionData(
          icon: Icons.auto_awesome,
          title: 'Life Assistant',
          body:
              'Your personal AI assistant for reflection, planning, accountability, and coaching. Life Assistant uses context from your goals, tasks, and habits to offer relevant, practical support instead of generic replies.\n\nUse it when you want help reaching a goal, turning a desire into action, thinking through your options, getting unstuck, or finding a more enjoyable way forward. The sparkles icon in the header opens Life Assistant instantly.',
          imageAsset: 'assets/help_guide images/White/life_ai.png',
          imagePreviewAspectRatio: 16 / 10,
        ),
        GuideSectionData(
          icon: Icons.calendar_month_outlined,
          title: 'Calendar',
          body:
              'The calendar icon in the header opens a single list view of every goal and task that has a due date, grouped into Overdue, Today, Tomorrow, and the days ahead. It pulls from Goals, Task Lists, and any goal-linked task boards in one place, so nothing with a date attached can quietly disappear from view.\n\nTap any item to open it directly — the Calendar is a way in, not a separate to-do list of its own.',
          imageAsset: 'assets/guide_images/action_calendar.png',
        ),
        GuideSectionData(
          icon: Icons.tips_and_updates_outlined,
          title: 'A useful rhythm',
          body:
              'Start with Goals to decide what matters. Break each one into dated tasks. Use Affirmations before the sessions you are most likely to avoid. Use Life Assistant when you need to think out loud or want coaching support. Check the Calendar regularly so dates you set do not go quiet.\n\nThe method only works if the goal-to-task chain stays connected — a goal with no tasks, or a task with no date, is easy to lose.',
        ),
      ],
    );
  }
}
