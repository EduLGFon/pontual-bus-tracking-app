// T39 tests: the install hint shows once, only to unseen iOS web.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pontual/platform/web/install_hint.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('shouldShowInstallHint', () {
    test('only unseen iOS web', () {
      expect(
        shouldShowInstallHint(isWeb: true, isIos: true, seen: false),
        isTrue,
      );
      expect(
        shouldShowInstallHint(isWeb: true, isIos: true, seen: true),
        isFalse,
      );
      expect(
        shouldShowInstallHint(isWeb: true, isIos: false, seen: false),
        isFalse,
      );
      expect(
        shouldShowInstallHint(isWeb: false, isIos: true, seen: false),
        isFalse,
      );
    });
  });

  group('InstallHintStore', () {
    test('round-trips the dismissal', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      const InstallHintStore store = InstallHintStore();
      expect(await store.seen(), isFalse);
      await store.markSeen();
      expect(await store.seen(), isTrue);
    });
  });

  group('InstallHintCard', () {
    testWidgets('shows Safari steps and dismisses', (
      WidgetTester tester,
    ) async {
      bool dismissed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InstallHintCard(onDismiss: () => dismissed = true),
          ),
        ),
      );
      expect(find.textContaining('Adicionar à Tela de Início'), findsOneWidget);
      await tester.tap(find.text('Entendi'));
      expect(dismissed, isTrue);
    });
  });

  group('InstallHintSlot', () {
    testWidgets('stays hidden off iOS web test platform', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: InstallHintSlot())),
      );
      await tester.pumpAndSettle();
      expect(find.byType(InstallHintCard), findsNothing);
    });
  });
}
