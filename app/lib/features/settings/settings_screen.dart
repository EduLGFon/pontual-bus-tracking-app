// S10 Settings: theme, privacy entry, about entry, help, contact,
// timetable version. No network calls. See PLAN.md 9.5 S10.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pontual/app/providers.dart';
import 'package:pontual/app/strings_pt.dart';
import 'package:pontual/core/config/contact.dart';
import 'package:pontual/data/prefs/theme_store.dart';
import 'package:url_launcher/url_launcher.dart';

/// Settings screen.
class SettingsScreen extends ConsumerWidget {
  /// Creates the settings screen.
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeMode mode = ref.watch(themeModeProvider);
    final AsyncValue<String> date = ref.watch(timetableDateProvider);
    return Scaffold(
      appBar: AppBar(title: const Text(StringsPt.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text(
            StringsPt.themeTitle,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Semantics(
            label: StringsPt.themeTitle,
            child: SegmentedButton<ThemeMode>(
              segments: const <ButtonSegment<ThemeMode>>[
                ButtonSegment<ThemeMode>(
                  value: ThemeMode.system,
                  label: Text(StringsPt.themeSystem),
                ),
                ButtonSegment<ThemeMode>(
                  value: ThemeMode.light,
                  label: Text(StringsPt.themeLight),
                ),
                ButtonSegment<ThemeMode>(
                  value: ThemeMode.dark,
                  label: Text(StringsPt.themeDark),
                ),
              ],
              selected: <ThemeMode>{mode},
              onSelectionChanged: (Set<ThemeMode> next) async {
                final ThemeMode chosen = next.single;
                ref.read(themeModeProvider.notifier).set(chosen);
                try {
                  await const ThemeStore().write(chosen);
                } catch (_) {
                  // Theme still applies for this run.
                }
              },
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text(StringsPt.privacyData),
            onTap: () => context.go('/privacy'),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text(StringsPt.aboutSources),
            onTap: () => context.go('/about'),
          ),
          const SizedBox(height: 16),
          Text(
            StringsPt.helpTitle,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          const Text(StringsPt.helpShare),
          const SizedBox(height: 8),
          const Text(StringsPt.helpBattery),
          const SizedBox(height: 8),
          const Text(StringsPt.helpWeb),
          if (supportEmail.isNotEmpty) ...<Widget>[
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.mail_outline),
              title: const Text(StringsPt.contactUs),
              subtitle: const Text(supportEmail),
              onTap: () async {
                final Uri uri = Uri(scheme: 'mailto', path: supportEmail);
                try {
                  await launchUrl(uri);
                } catch (_) {
                  // No mail client: the address is visible to copy.
                }
              },
            ),
          ],
          const SizedBox(height: 16),
          date.when(
            data: (String d) =>
                Text('${StringsPt.timetablesPrefix}${d.isEmpty ? '—' : d}'),
            loading: () => const Text('${StringsPt.timetablesPrefix}—'),
            error: (_, _) => const Text('${StringsPt.timetablesPrefix}—'),
          ),
        ],
      ),
    );
  }
}
