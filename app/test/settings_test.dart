// T40 tests: theme store round-trip, settings rows and theme switch,
// about disclaimer, sources, and external rows.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pontual/app/providers.dart';
import 'package:pontual/core/config/contact.dart';
import 'package:pontual/data/prefs/theme_store.dart';
import 'package:pontual/features/settings/about_screen.dart';
import 'package:pontual/features/settings/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('ThemeStore', () {
    test('defaults to system and round-trips', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      const ThemeStore store = ThemeStore();
      expect(await store.read(), ThemeMode.system);
      await store.write(ThemeMode.dark);
      expect(await store.read(), ThemeMode.dark);
      await store.write(ThemeMode.light);
      expect(await store.read(), ThemeMode.light);
    });
  });

  group('SettingsScreen', () {
    testWidgets('shows theme, nav, help, and timetable rows', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: SettingsScreen())),
      );
      await tester.pumpAndSettle();
      expect(find.text('Tema'), findsOneWidget);
      expect(find.text('Privacidade e dados'), findsOneWidget);
      expect(find.text('Sobre e fontes de dados'), findsOneWidget);
      expect(find.textContaining('Estou no ônibus'), findsOneWidget);
      expect(find.textContaining('Horários:'), findsOneWidget);
      // Contact row hidden until the owner decides the address.
      expect(supportEmail, isEmpty);
      expect(find.text('Falar com a gente'), findsNothing);
    });

    testWidgets('theme switch updates the provider', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: SettingsScreen())),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Escuro'));
      await tester.pumpAndSettle();
      final BuildContext ctx = tester.element(find.byType(SettingsScreen));
      final ThemeMode mode = ProviderScope.containerOf(ctx)
          .read(themeModeProvider);
      expect(mode, ThemeMode.dark);
    });
  });

  group('AboutScreen', () {
    testWidgets('shows disclaimer, sources, and link rows', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: AboutScreen()));
      expect(find.textContaining('não oficial'), findsOneWidget);
      expect(find.textContaining('onibus.online'), findsOneWidget);
      expect(find.textContaining('OpenStreetMap'), findsOneWidget);
      expect(find.text('Licenças de código aberto'), findsOneWidget);
      expect(find.text('Código-fonte'), findsOneWidget);
    });
  });
}
