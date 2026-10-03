// T18 bootstrap. Runs the app immediately with bundled placeholders only.
// No network call may block first paint. See PLAN.md 8.4.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pontual/app/router.dart';
import 'package:pontual/app/theme.dart';

void main() {
  runApp(const ProviderScope(child: PontualApp()));
}

/// Minimal alpha shell. Real routes land in T18.
class PontualApp extends StatelessWidget {
  /// Creates the minimal alpha shell.
  const PontualApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Pontual',
      theme: lightTheme(),
      darkTheme: darkTheme(),
      themeMode: ThemeMode.system,
      routerConfig: buildRouter(),
    );
  }
}
