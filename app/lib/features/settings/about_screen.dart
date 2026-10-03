// S12 About and data sources: non-affiliation disclaimer, source list,
// OSM attribution, open-source licences, repository link. Offline-safe:
// every row works without network except the external links. See PLAN
// 9.5 S12.
import 'package:flutter/material.dart';
import 'package:pontual/app/strings_pt.dart';
import 'package:url_launcher/url_launcher.dart';

/// OSM copyright page.
const String osmCopyrightUrl = 'https://www.openstreetmap.org/copyright';

/// Public source repository.
const String repoUrl = 'https://github.com/EduLGFon/pontual-bus-tracking-app';

/// About and data sources screen.
class AboutScreen extends StatelessWidget {
  /// Creates the about screen.
  const AboutScreen({super.key});

  Future<void> _open(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {
      // Offline or no browser: the text stays readable.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(StringsPt.aboutTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          const Text(StringsPt.aboutDisclaimer),
          const SizedBox(height: 16),
          Text(
            StringsPt.aboutSourcesTitle,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          const Text(StringsPt.aboutSourceLines),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.map_outlined),
            title: const Text(StringsPt.aboutOsm),
            onTap: () => _open(osmCopyrightUrl),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text(StringsPt.aboutLicences),
            onTap: () => showLicensePage(context: context),
          ),
          ListTile(
            leading: const Icon(Icons.code),
            title: const Text(StringsPt.aboutRepo),
            subtitle: const Text(repoUrl),
            onTap: () => _open(repoUrl),
          ),
        ],
      ),
    );
  }
}
