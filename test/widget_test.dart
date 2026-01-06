import 'package:flutter_test/flutter_test.dart';
import 'package:emergency_medicine_finder/main.dart';

void main() {
  testWidgets('App loads', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(EmergencyMedicineFinder());

    // Verify that login screen is shown.
    expect(find.text('Login'), findsOneWidget);
  });
}
