import 'models.dart';

String formatRating(double rating) {
  return rating == 0 ? 'New' : rating.toStringAsFixed(1);
}

String formatDate(DateTime value) {
  const months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  return '${months[value.month - 1]} ${value.day}, ${value.year}';
}

String formatReleaseDate(String rawDate) {
  final value = DateTime.tryParse(rawDate);
  if (value == null) {
    return rawDate.isEmpty ? 'TBA' : rawDate;
  }

  return formatDate(value);
}

String formatWeekdayShort(DateTime value) {
  const days = <String>['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return days[value.weekday - 1];
}

String formatWeekdayLong(DateTime value) {
  const days = <String>[
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  return days[value.weekday - 1];
}

String formatMonthDay(DateTime value) {
  const months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  return '${months[value.month - 1]} ${value.day}';
}

String formatShowtimeHeader(DateTime value) {
  return '${formatWeekdayShort(value)}, ${formatMonthDay(value)}';
}

List<ShowtimeDay> buildShowtimeSchedule(Movie movie) {
  final now = DateTime.now();
  final baseDate = DateTime(now.year, now.month, now.day);
  final slotTemplates = <({String time, String hall, String format, double price, int seats})>[
    (
      time: '3:30 PM',
      hall: 'Hall A',
      format: '2D',
      price: 12.50,
      seats: 89,
    ),
    (
      time: '7:30 PM',
      hall: 'Hall IMAX',
      format: 'IMAX',
      price: 18.00,
      seats: 89,
    ),
    (
      time: '12:30 AM',
      hall: 'Hall A',
      format: '2D',
      price: 12.50,
      seats: 89,
    ),
    (
      time: '2:00 AM',
      hall: 'Hall B',
      format: '3D',
      price: 14.00,
      seats: 100,
    ),
  ];

  return List<ShowtimeDay>.generate(7, (index) {
    final date = baseDate.add(Duration(days: index));
    final slots = slotTemplates.map((template) {
      final priceBoost = (movie.rating / 10).clamp(0, 1) * 0.5;
      return ShowtimeSlot(
        date: date,
        timeLabel: template.time,
        theater: index.isEven ? 'CineBook Downtown' : 'CineBook Westside',
        hall: template.hall,
        format: template.format,
        price: double.parse((template.price + priceBoost).toStringAsFixed(2)),
        seatsLeft: template.seats - (index * 2),
      );
    }).toList();

    return ShowtimeDay(date: date, slots: slots);
  });
}

String buildSeatLabel(Movie movie, int order) {
  const rows = <String>['A', 'B', 'C', 'D', 'E', 'F'];
  final hallCode = String.fromCharCode(65 + ((movie.id + order) % 3));
  final row = rows[(movie.id + order) % rows.length];
  final seat = ((movie.id + order) % 10) + 1;
  return 'Hall $hallCode | Row $row, Seat $seat';
}
