import 'package:flutter/material.dart';
import 'widgets/guide_page.dart';

class MBSGuidePage extends StatelessWidget {
  const MBSGuidePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const GuidePage(
      appBarTitle: 'Wellness Guide',
      heroImageAsset: 'assets/hub_headers/mbs.png',
      heroHeadline:
          'A practical guide to Mind, Body, and Spirit — and why you log it by hand.',
      sections: [
        GuideSectionData(
          icon: Icons.all_inclusive,
          title: 'Why three areas, not one',
          body:
              'Mind, Body, and Spirit are tracked separately because they are genuinely different kinds of work. Mind practice trains attention and mental clarity. Body practice trains physical capacity and energy. Spirit practice trains meaning, connection, and inner alignment. Progress in one does not automatically produce progress in the others.\n\nMost people naturally drift toward whichever area is easiest or most rewarded — often Body, because it is the most visible and measurable. This section exists to keep the other two from quietly going unattended.',
        ),
        GuideSectionData(
          icon: Icons.self_improvement,
          title: 'Mind: attention and clarity',
          body:
              'Mind practice covers meditation, focused thinking, and reflection — anything that trains you to notice your own mental state and steer it deliberately. This is the area most easily crowded out by busyness, because its absence is quiet; you rarely notice a scattered mind the way you notice a stiff body.\n\nShort, consistent sessions beat rare long ones. A few focused minutes logged today builds the habit faster than an occasional hour.',
          imageAsset: 'assets/guide_images/mbs_mind.png',
        ),
        GuideSectionData(
          icon: Icons.fitness_center,
          title: 'Body: energy and vitality',
          body:
              'Body practice covers exercise, movement, and physical care — the training that keeps you capable and resilient. It is usually the easiest area to stay motivated in, because the feedback is immediate: you feel it during and after.\n\nThe risk with Body is treating it as the whole picture. Physical training alone, without Mind and Spirit alongside it, tends to produce someone who is fit but scattered or disconnected.',
          imageAsset: 'assets/guide_images/mbs_body.png',
        ),
        GuideSectionData(
          icon: Icons.nights_stay,
          title: 'Spirit: meaning and connection',
          body:
              'Spirit practice covers prayer, worship, gratitude, and anything that builds a sense of meaning, peace, and connection beyond the day-to-day. This is the area most people log least often — not because it matters less, but because it is the hardest to schedule and the easiest to postpone.\n\nSpirit practice does not need to look dramatic. A few minutes of genuine reflection or gratitude, logged consistently, does more for long-term balance than an occasional intense retreat.',
          imageAsset: 'assets/guide_images/mbs_spirit.png',
        ),
        GuideSectionData(
          icon: Icons.edit_note_outlined,
          title: 'Why you log this by hand',
          body:
              'It would be easy to pull this data automatically from a wearable or a health app. This app deliberately does not do that, and the reason is not a technical limitation — it is the point.\n\nThe moment you open a habit, type a number, or tap Done, you are forced to actually notice what you did. An automated tracker records your steps or your heart rate whether or not you were paying attention to your training, your breath, or your prayer. Manual logging cannot happen on autopilot: it requires a small, deliberate pause where you register the practice as something you chose to do. That pause is where the habit actually forms.',
        ),
        GuideSectionData(
          icon: Icons.center_focus_strong_outlined,
          title: 'Focus over convenience',
          body:
              'Automated systems optimise for effortlessness — the whole appeal is that you don\'t have to think about it. But effortlessness is exactly what makes data easy to accumulate and easy to ignore. Most people with an automatic step counter or sleep tracker can\'t tell you their numbers from three days ago; the data exists, but it never had to pass through their attention.\n\nManual logging trades a little convenience for a lot of focus. Because you have to stop and log it, you stay engaged with what you are actually practising, session by session, instead of outsourcing the noticing to a device.',
        ),
        GuideSectionData(
          icon: Icons.balance,
          title: 'Manual logging and holistic balance',
          body:
              'Automated health tools are almost always single-domain: a fitness app tracks Body, a meditation app tracks Mind, and almost nothing tracks Spirit at all. Used separately, they reinforce whichever area was already easiest to instrument, and the others fall further behind without you noticing.\n\nLogging all three by hand, in one place, makes the imbalance visible. When you have to manually add an entry, you also see — right there in the Metrics view — which of the three you have been neglecting. That visibility is what turns three separate habits into one holistic practice.',
        ),
        GuideSectionData(
          icon: Icons.dashboard_outlined,
          title: 'Using Metrics and the weekly chart',
          body:
              'The Metrics page pulls Mind, Body, and Spirit together into one pie chart and a twelve-week bar chart. Use it as a mirror, not a scoreboard: the goal is not a perfect three-way split every week, but noticing when one colour disappears for too long.\n\nTap any week in the bar chart for its exact breakdown. If a colour keeps vanishing, that is your signal for where to place attention next, before the imbalance compounds.',
          imageAsset: 'assets/guide_images/mbs_metrics.png',
        ),
        GuideSectionData(
          icon: Icons.timer_outlined,
          title: 'Session Timer and Daily Habits',
          body:
              'Each area page has a Session Timer for focused, single sessions — meditate, train, or reflect with the clock running, then log the result when you finish. Daily Habits below it are for the smaller, recurring practices you want reminders for; toggle one on, set a reminder time and an active window, and it will nudge you without pestering you outside the hours you chose.\n\nMark a habit Done the moment you finish it, not later from memory. Logging in the moment is what keeps the record honest.',
        ),
        GuideSectionData(
          icon: Icons.auto_awesome,
          title: 'Text Coaching',
          body:
              'The sparkles icon in the header is a direct shortcut into a coaching conversation, without leaving Wellness first. Use it when you want to talk through what an imbalance means, or how to rebuild a practice you have let slip, rather than navigating to Action Center deliberately.\n\nIt opens the same conversation space as Action Center\'s Text Coaching, with the same context on your goals, tasks, and habits.',
        ),
        GuideSectionData(
          icon: Icons.calendar_month_outlined,
          title: 'Calendar',
          body:
              'The calendar icon in the header is the same shortcut you\'ll find in Action Center and Exploration — a single list of every goal and task with a due date, grouped into Overdue, Today, Tomorrow, and the days ahead. It\'s here so you can check what\'s due without leaving Wellness.',
        ),
        GuideSectionData(
          icon: Icons.tips_and_updates_outlined,
          title: 'A useful rhythm',
          body:
              'Log the practice as you finish it, not at the end of the day from memory. Check the Metrics view weekly, not daily — balance is visible over weeks, not single days. When you spot a colour that keeps vanishing, treat that as your next area of focus rather than a reason to feel behind.\n\nThe method only works if the logging stays honest and immediate. A short, real entry today is worth more than a perfect one you meant to add yesterday.',
        ),
      ],
    );
  }
}
