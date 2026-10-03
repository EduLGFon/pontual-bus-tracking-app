// S13 system screens and the S14 offline banner. Blocking states never
// hide timetables that are already on screen; these widgets are the shells
// that later milestones fill with live retry actions. See PLAN.md 9.5.
import 'package:flutter/material.dart';
import 'package:pontual/app/strings_pt.dart';

/// Kinds of blocking system states.
enum SystemKind {
  /// Planned maintenance or kill switch.
  maintenance,

  /// Installed version below min_app_version.
  updateRequired,

  /// Server unreachable for about 60 seconds.
  unavailable,
}

/// Blocking system screen (S13).
class SystemScreen extends StatelessWidget {
  /// Creates a system screen for [kind] with an optional pt-BR [message].
  const SystemScreen({required this.kind, this.message = '', super.key});

  /// Which blocking state to show.
  final SystemKind kind;

  /// Optional message from config.json.
  final String message;

  /// Title per kind, in pt-BR.
  String title() {
    switch (kind) {
      case SystemKind.maintenance:
        return 'Em manutenção';
      case SystemKind.updateRequired:
        return 'Atualização necessária';
      case SystemKind.unavailable:
        return 'Servidor indisponível';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(StringsPt.systemTitle)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Semantics(
                label: title(),
                header: true,
                child: Text(
                  title(),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              if (message.isNotEmpty) ...<Widget>[
                const SizedBox(height: 12),
                Text(message, style: Theme.of(context).textTheme.bodyLarge),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Non-blocking offline banner (S14) shown above content when offline.
class OfflineBanner extends StatelessWidget {
  /// Creates an offline banner.
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Sem conexão. Mostrando dados salvos.',
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Text('Sem conexão. Mostrando dados salvos.'),
      ),
    );
  }
}
