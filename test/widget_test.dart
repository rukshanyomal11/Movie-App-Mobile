import 'package:flutter_test/flutter_test.dart';

import 'package:movie_booking_app/src/app.dart';

void main() {
  testWidgets('shows auth entry screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const CineBookApp());

    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Register'), findsOneWidget);
  });
}
