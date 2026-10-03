// T18 router and scale tests. Screens are navigable and survive 200
// percent text scale on a narrow screen without clipping errors.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pontual/app/strings_pt.dart';
import 'package:pontual/main.dart';

void main() {
  testWidgets('boots on welcome with pt-BR copy', (WidgetTester tester) async {
    await tester.pumpWidget(const PontualApp());
    await tester.pumpAndSettle();
    expect(find.text(StringsPt.welcomeTitle), findsOneWidget);
    expect(find.text(StringsPt.start), findsOneWidget);
  });

  testWidgets('welcome navigates home', (WidgetTester tester) async {
    await tester.pumpWidget(const PontualApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text(StringsPt.start));
    await tester.pumpAndSettle();
    expect(find.text(StringsPt.homeAllLines), findsOneWidget);
  });

  testWidgets('survives 200 percent text scale', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(
          textScaler: TextScaler.linear(2),
          size: Size(360, 640),
        ),
        child: PontualApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
