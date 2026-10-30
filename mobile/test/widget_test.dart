import 'package:flutter_test/flutter_test.dart';
import 'package:urja/main.dart';

void main() {
  testWidgets('UrjaApp onboarding loads properly', (WidgetTester tester) async {
    await tester.pumpWidget(const UrjaApp());
    expect(find.text('URJA ONE'), findsOneWidget);
    expect(find.text('Welcome to'), findsOneWidget);
  });
}
