import 'package:ableritemobile/services/financial_context_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('calculateCashPlannerMetrics', () {
    test('keeps active and planned allocations separate', () {
      final metrics = calculateCashPlannerMetrics(
        monthlyIncome: 1000,
        monthlyExpenses: 805,
        cashPlannerItems: const [
          {'text': 'Cash Retention', 'value': 70, 'is_completed': true},
          {'text': 'Business Investment', 'value': 127, 'is_completed': false},
        ],
      );

      expect(metrics.totalSurplus, 195);
      expect(metrics.activeSpend, 70);
      expect(metrics.plannedAllocations, 127);
      expect(metrics.remainingCash, 125);
      expect(metrics.remainingAfterPlans, -2);
      expect(metrics.remainingCash, isNot(68));
    });

    test('treats missing values as zero', () {
      final metrics = calculateCashPlannerMetrics(
        monthlyIncome: 200,
        monthlyExpenses: 50,
        cashPlannerItems: const [
          {'text': 'Unpriced plan', 'is_completed': false},
        ],
      );

      expect(metrics.totalSurplus, 150);
      expect(metrics.activeSpend, 0);
      expect(metrics.plannedAllocations, 0);
      expect(metrics.remainingCash, 150);
      expect(metrics.remainingAfterPlans, 150);
    });
  });
}
