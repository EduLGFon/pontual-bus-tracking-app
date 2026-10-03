// S11 Privacy center: bundled policy/terms, collection summary,
// delete-my-data, revoke consent, contact. Offline delete fails
// honestly without pretending success. See PLAN.md 9.5 S11.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pontual/app/providers.dart';
import 'package:pontual/app/strings_pt.dart';
import 'package:pontual/core/config/contact.dart';
import 'package:pontual/features/settings/privacy_actions.dart';
import 'package:pontual/features/settings/privacy_texts.dart';
import 'package:url_launcher/url_launcher.dart';

/// Six-line collection summary mirroring PLAN.md 13.2.
const List<String> collectsSummary = <String>[
  'Aparelho anônimo: um código aleatório, sem nome ou e-mail.',
  'Versão do consentimento que você aceitou e quando.',
  'Durante a viagem: posição, velocidade e bateria (só na memória).',
  'Ao descer, a posição some na hora. Sem histórico.',
  'Quem só olha o mapa não cria registro nenhum.',
  'Nunca: nome, e-mail, telefone, fotos ou microfone.',
];

/// Privacy center screen.
class PrivacyScreen extends ConsumerWidget {
  /// Creates the privacy center.
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text(StringsPt.privacyTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          ListTile(
            leading: const Icon(Icons.policy_outlined),
            title: const Text(StringsPt.privacyPolicy),
            onTap: () => context.go('/privacy/policy'),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text(StringsPt.privacyTerms),
            onTap: () => context.go('/privacy/terms'),
          ),
          const SizedBox(height: 8),
          Text(
            StringsPt.privacyCollectsTitle,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          for (final String line in collectsSummary) _bullet(line),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.restart_alt),
            title: const Text(StringsPt.privacyRevoke),
            onTap: () => _revoke(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: const Text(
              StringsPt.privacyDelete,
              style: TextStyle(color: Colors.red),
            ),
            onTap: () => _delete(context, ref),
          ),
          if (supportEmail.isNotEmpty)
            ListTile(
              leading: const Icon(Icons.mail_outline),
              title: const Text(StringsPt.privacyContact),
              subtitle: const Text(supportEmail),
              onTap: () async {
                try {
                  await launchUrl(Uri(scheme: 'mailto', path: supportEmail));
                } catch (_) {
                  // The address is visible to copy.
                }
              },
            ),
        ],
      ),
    );
  }

  Widget _bullet(String line) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text('• $line'),
    );
  }

  Future<void> _revoke(BuildContext context, WidgetRef ref) async {
    await PrivacyActions(api: ref.read(busApiProvider)).revokeConsent();
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text(StringsPt.privacyRevoked)));
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(StringsPt.privacyDeleteTitle),
          content: const Text(StringsPt.privacyDeleteBody),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(StringsPt.privacyCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(StringsPt.privacyConfirmDelete),
            ),
          ],
        );
      },
    );
    if (confirm != true || !context.mounted) {
      return;
    }
    final DeleteOutcome outcome = await PrivacyActions(
      api: ref.read(busApiProvider),
    ).deleteMyData();
    if (!context.mounted) {
      return;
    }
    if (outcome == DeleteOutcome.offline) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text(StringsPt.privacyOffline)));
      return;
    }
    ref.read(themeModeProvider.notifier).set(ThemeMode.system);
    context.go('/welcome');
  }
}

/// Bundled policy/terms text screen. Works offline; the canonical web
/// link appears once the static domain lands.
class PolicyTextScreen extends StatelessWidget {
  /// Creates the text screen for [kind] (`policy` or `terms`).
  const PolicyTextScreen({required this.kind, super.key});

  /// Which text to show.
  final String kind;

  @override
  Widget build(BuildContext context) {
    final bool policy = kind == 'policy';
    return Scaffold(
      appBar: AppBar(
        title: Text(policy ? StringsPt.privacyPolicy : StringsPt.privacyTerms),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text(policy ? bundledPolicy : bundledTerms),
          if ((policy ? policyUrl : termsUrl).isNotEmpty)
            TextButton(
              onPressed: () async {
                try {
                  await launchUrl(
                    Uri.parse(policy ? policyUrl : termsUrl),
                    mode: LaunchMode.externalApplication,
                  );
                } catch (_) {
                  // Offline: the bundled text stays readable.
                }
              },
              child: const Text('Ver na web'),
            ),
        ],
      ),
    );
  }
}
