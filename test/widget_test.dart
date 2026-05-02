import 'package:flutter_test/flutter_test.dart';

import 'package:movie_booking_app/src/app.dart';

void main() {
  testWidgets('shows setup state without dotenv in tests', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const CineBookApp());

    expect(find.text('CineBook Setup'), findsOneWidget);
  });
}
