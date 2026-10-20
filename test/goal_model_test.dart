import 'package:ableritemobile/models/goal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Goal reads and writes SMART fields', () {
    final goal = Goal.fromJson({
      'id': 'goal-1',
      'text': 'Run a 10K',
      'user_id': 'user-1',
      'section': 'activeGoals',
      'specific': 'Complete the local 10K race',
      'measurable': 'Run 10 kilometres without stopping',
      'achievable': 'Follow a three-day weekly training plan',
      'relevant': 'Improve my stamina and confidence',
      'due_date': '2026-10-04',
    });

    expect(goal.specific, 'Complete the local 10K race');
    expect(goal.measurable, 'Run 10 kilometres without stopping');
    expect(goal.achievable, 'Follow a three-day weekly training plan');
    expect(goal.relevant, 'Improve my stamina and confidence');
    expect(goal.toJson()['specific'], goal.specific);
    expect(goal.toJson()['measurable'], goal.measurable);
    expect(goal.toJson()['achievable'], goal.achievable);
    expect(goal.toJson()['relevant'], goal.relevant);
  });

  test('Goal supports existing records without SMART fields', () {
    final goal = Goal.fromJson({
      'id': 'goal-2',
      'text': 'Existing goal',
      'user_id': 'user-1',
      'section': 'activeGoals',
    });

    expect(goal.specific, isNull);
    expect(goal.measurable, isNull);
    expect(goal.achievable, isNull);
    expect(goal.relevant, isNull);
  });
}
