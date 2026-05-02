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

String buildSeatLabel(Movie movie, int order) {
  const rows = <String>['A', 'B', 'C', 'D', 'E', 'F'];
  final hallCode = String.fromCharCode(65 + ((movie.id + order) % 3));
  final row = rows[(movie.id + order) % rows.length];
  final seat = ((movie.id + order) % 10) + 1;
  return 'Hall $hallCode · Row $row, Seat $seat';
}
