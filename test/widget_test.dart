import 'package:flutter_test/flutter_test.dart';
import 'package:network_events/main.dart';

void main() {
  testWidgets('App should render without crashing', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const NetworkEventsApp());

    // Verify the app renders (WebView may not fully load in test environment)
    expect(find.byType(NetworkEventsApp), findsOneWidget);
  });
}
