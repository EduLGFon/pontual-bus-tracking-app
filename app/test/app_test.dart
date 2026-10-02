// T02 smoke test. Verifies the empty ProviderScope app boots.
import 'package:flutter_test/flutter_test.dart';
import 'package:pontual/main.dart';

void main() {
  testWidgets('boots empty app', (WidgetTester tester) async {
    await tester.pumpWidget(const PontualApp());
    expect(find.text('Pontual'), findsOneWidget);
  });
}
