String formatDianaLocalDate(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

DateTime endOfNextCalendarMonth(DateTime currentDate) {
  return DateTime(currentDate.year, currentDate.month + 2, 0);
}
