class CashPlannerMetrics {
  final double totalSurplus;
  final double activeSpend;
  final double plannedAllocations;
  final double remainingCash;
  final double remainingAfterPlans;

  const CashPlannerMetrics({
    required this.totalSurplus,
    required this.activeSpend,
    required this.plannedAllocations,
    required this.remainingCash,
    required this.remainingAfterPlans,
  });
}

CashPlannerMetrics calculateCashPlannerMetrics({
  required double monthlyIncome,
  required double monthlyExpenses,
  required Iterable<Map<String, dynamic>> cashPlannerItems,
}) {
  var activeSpend = 0.0;
  var plannedAllocations = 0.0;

  for (final item in cashPlannerItems) {
    final value = (item['value'] as num?)?.toDouble() ?? 0.0;
    if (item['is_completed'] == true) {
      activeSpend += value;
    } else {
      plannedAllocations += value;
    }
  }

  final totalSurplus = monthlyIncome - monthlyExpenses;
  final remainingCash = totalSurplus - activeSpend;
  final remainingAfterPlans = remainingCash - plannedAllocations;

  return CashPlannerMetrics(
    totalSurplus: totalSurplus,
    activeSpend: activeSpend,
    plannedAllocations: plannedAllocations,
    remainingCash: remainingCash,
    remainingAfterPlans: remainingAfterPlans,
  );
}
