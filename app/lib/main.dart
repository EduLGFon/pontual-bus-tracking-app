// T18 bootstrap. Runs the app immediately with bundled placeholders only.
// No network call may block first paint. See PLAN.md 8.4.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pontual/app/providers.dart';
import 'package:pontual/app/router.dart';
import 'package:pontual/app/theme.dart';
import 'package:pontual/data/prefs/theme_store.dart';

void main() {
  runApp(const ProviderScope(child: PontualApp()));
}

/// Minimal alpha shell. Real routes land in T18.
class PontualApp extends ConsumerStatefulWidget {
  /// Creates the minimal alpha shell.
  const PontualApp({super.key});

  @override
  ConsumerState<PontualApp> createState() => _PontualAppState();
}

class _PontualAppState extends ConsumerState<PontualApp> {
  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final ThemeMode saved = await const ThemeStore().read();
      if (mounted) {
        ref.read(themeModeProvider.notifier).set(saved);
      }
    } catch (_) {
      // System default stands.
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeMode mode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: 'Pontual',
      theme: lightTheme(),
      darkTheme: darkTheme(),
      themeMode: mode,
      routerConfig: buildRouter(),
    );
  }
}
