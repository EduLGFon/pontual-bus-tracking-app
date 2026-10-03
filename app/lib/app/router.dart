// Flat routes per PLAN.md 9.3. Screens are placeholders until their
// milestone tasks land; navigation and text scale are verified here in T18.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pontual/app/strings_pt.dart';
import 'package:pontual/features/home/home_screen.dart';
import 'package:pontual/features/line/line_screen.dart';
import 'package:pontual/features/settings/about_screen.dart';
import 'package:pontual/features/settings/privacy_screen.dart';
import 'package:pontual/features/settings/settings_screen.dart';
import 'package:pontual/features/trip/trip_controller.dart';
import 'package:pontual/features/trip/trip_screen.dart';

/// Builds a placeholder scaffold with semantics labels in pt-BR.
Widget placeholder(String title, String semanticsLabel) {
  return Scaffold(
    appBar: AppBar(title: Text(title)),
    body: Center(
      child: Semantics(
        label: semanticsLabel,
        header: true,
        child: const Text(StringsPt.placeholderBody),
      ),
    ),
  );
}

/// Application router with all alpha routes as placeholders.
GoRouter buildRouter() {
  return GoRouter(
    initialLocation: '/welcome',
    routes: <GoRoute>[
      GoRoute(
        path: '/welcome',
        builder: (BuildContext context, GoRouterState state) {
          return const WelcomePlaceholder();
        },
      ),
      GoRoute(
        path: '/',
        builder: (BuildContext context, GoRouterState state) {
          return const HomeScreen();
        },
      ),
      GoRoute(
        path: '/line/:id',
        builder: (BuildContext context, GoRouterState state) {
          return LineScreen(
            lineId: int.tryParse(state.pathParameters['id'] ?? '') ?? -1,
          );
        },
      ),
      GoRoute(
        path: '/trip',
        builder: (BuildContext context, GoRouterState state) {
          final Object? extra = state.extra;
          if (extra is TripController) {
            return TripRoute(controller: extra);
          }
          return const TripPlaceholder();
        },
      ),
      GoRoute(
        path: '/settings',
        builder: (BuildContext context, GoRouterState state) {
          return const SettingsScreen();
        },
      ),
      GoRoute(
        path: '/privacy',
        builder: (BuildContext context, GoRouterState state) {
          return const PrivacyScreen();
        },
        routes: <GoRoute>[
          GoRoute(
            path: 'policy',
            builder: (BuildContext context, GoRouterState state) {
              return const PolicyTextScreen(kind: 'policy');
            },
          ),
          GoRoute(
            path: 'terms',
            builder: (BuildContext context, GoRouterState state) {
              return const PolicyTextScreen(kind: 'terms');
            },
          ),
        ],
      ),
      GoRoute(
        path: '/about',
        builder: (BuildContext context, GoRouterState state) {
          return const AboutScreen();
        },
      ),
      GoRoute(
        path: '/system',
        builder: (BuildContext context, GoRouterState state) {
          return const SystemPlaceholder();
        },
      ),
    ],
  );
}

/// Welcome screen skeleton with the final pt-BR copy.
class WelcomePlaceholder extends StatelessWidget {
  /// Creates the welcome skeleton.
  const WelcomePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  StringsPt.welcomeTitle,
                  style: Theme.of(context).textTheme.headlineSmall,
                  semanticsLabel: StringsPt.welcomeTitle,
                ),
                const SizedBox(height: 16),
                Text(
                  '• ${StringsPt.welcomeBullet1}\n'
                  '• ${StringsPt.welcomeBullet2}\n'
                  '• ${StringsPt.welcomeBullet3}',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 32),
                Text(
                  StringsPt.unofficialNotice,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => context.go('/'),
                  child: const Text(StringsPt.start),
                ),
                TextButton(
                  onPressed: () => context.go('/privacy'),
                  child: const Text(StringsPt.privacyHow),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Trip screen fallback for deep links without an active controller.
/// The share flow always navigates with a started TripController.
class TripPlaceholder extends StatelessWidget {
  /// Creates the trip skeleton.
  const TripPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return placeholder(StringsPt.tripTitle, StringsPt.tripTitle);
  }
}

/// System screen skeleton.
class SystemPlaceholder extends StatelessWidget {
  /// Creates the system skeleton.
  const SystemPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return placeholder(StringsPt.systemTitle, StringsPt.systemTitle);
  }
}
