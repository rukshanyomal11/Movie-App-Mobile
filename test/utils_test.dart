import 'package:flutter_test/flutter_test.dart';
import 'package:movie_booking_app/src/models.dart';
import 'package:movie_booking_app/src/utils.dart';

void main() {
  group('showtime date helpers', () {
    test('formats Today only for the actual current day', () {
      final today = DateTime(2026, 5, 10);

      expect(
        formatShowtimeDayLabel(DateTime(2026, 5, 10), today: today),
        'Today',
      );
      expect(
        formatShowtimeDayLabel(DateTime(2026, 5, 11), today: today),
        'Mon',
      );
    });

    test('picks the first current or upcoming showtime day by default', () {
      final schedule = <ShowtimeDay>[
        ShowtimeDay(date: DateTime(2026, 5, 8), slots: const <ShowtimeSlot>[]),
        ShowtimeDay(date: DateTime(2026, 5, 9), slots: const <ShowtimeSlot>[]),
        ShowtimeDay(date: DateTime(2026, 5, 10), slots: const <ShowtimeSlot>[]),
        ShowtimeDay(date: DateTime(2026, 5, 12), slots: const <ShowtimeSlot>[]),
      ];

      expect(
        findDefaultShowtimeDayIndex(schedule, today: DateTime(2026, 5, 10)),
        2,
      );
      expect(
        findDefaultShowtimeDayIndex(schedule, today: DateTime(2026, 5, 11)),
        3,
      );
    });
  });
}
