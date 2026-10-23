
import 'package:flutter_test/flutter_test.dart';
import 'package:service_hub/app.dart';

void main() {
  testWidgets('ServiceHub app loads successfully', (
      WidgetTester tester,
      ) async {
    await tester.pumpWidget(const ServiceHubApp());

    expect(find.text('ServiceHub'), findsOneWidget);
    expect(find.text('Your Home, Our Care'), findsOneWidget);
  });
}
