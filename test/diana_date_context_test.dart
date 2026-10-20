import 'package:ableritemobile/services/diana_date_context.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('end of next month is anchored to the current calendar month', () {
    final today = DateTime(2026, 7, 17);

    expect(formatDianaLocalDate(today), '2026-07-17');
    expect(formatDianaLocalDate(endOfNextCalendarMonth(today)), '2026-08-31');
  });

  test('end of next month crosses the year boundary correctly', () {
    expect(
      formatDianaLocalDate(endOfNextCalendarMonth(DateTime(2026, 12, 20))),
      '2027-01-31',
    );
  });
}
