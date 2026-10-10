// S03 Home: line search plus list plus live indicators. Lines paint from
// cached data first; live dots fill in without spinners. See PLAN.md 9.5.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pontual/app/providers.dart';
import 'package:pontual/app/strings_pt.dart';
import 'package:pontual/app/theme.dart';
import 'package:pontual/data/api/dto.dart';
import 'package:pontual/data/static_data/static_data.dart';
import 'package:pontual/platform/web/install_hint.dart';

/// Home screen with search, live section, and the full line list.
class HomeScreen extends ConsumerStatefulWidget {
  /// Creates the home screen.
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _query = '';
  Timer? _liveRefresh;

  @override
  void initState() {
    super.initState();
    // Live dots would freeze after first paint otherwise; 60 s is
    // plenty for line-level presence.
    _liveRefresh = Timer.periodic(const Duration(seconds: 60), (_) {
      if (mounted) {
        ref.invalidate(liveProvider);
      }
    });
  }

  @override
  void dispose() {
    _liveRefresh?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<StaticLine>> lines = ref.watch(linesProvider);
    final AsyncValue<LiveLines> live = ref.watch(liveProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text(StringsPt.homeTitle),
        actions: <Widget>[
          Semantics(
            label: StringsPt.settingsTitle,
            button: true,
            child: IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () => context.go('/settings'),
            ),
          ),
        ],
      ),
      body: lines.when(
        data: (List<StaticLine> all) => _body(context, all, live),
        loading: () => const SizedBox.shrink(),
        error: (_, _) => const SizedBox.shrink(),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    List<StaticLine> all,
    AsyncValue<LiveLines> live,
  ) {
    final String q = _query.trim().toLowerCase();
    final List<StaticLine> shown = q.isEmpty
        ? all
        : all
              .where(
                (StaticLine l) =>
                    l.name.toLowerCase().contains(q) ||
                    l.short.toLowerCase().contains(q),
              )
              .toList();
    final Map<int, int> counts = <int, int>{};
    live.whenData((LiveLines l) {
      for (final List<int> row in l.rows) {
        counts[row[0]] = row[1];
      }
    });
    final List<StaticLine> liveLines = shown
        .where((StaticLine l) => (counts[l.id] ?? 0) > 0)
        .toList();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        const InstallHintSlot(),
        Semantics(
          label: StringsPt.homeSearchHint,
          textField: true,
          child: SearchBar(
            hintText: StringsPt.homeSearchHint,
            onChanged: (String v) => setState(() => _query = v),
          ),
        ),
        if (liveLines.isNotEmpty) ...<Widget>[
          const SizedBox(height: 12),
          Text(
            StringsPt.homeLiveNow,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          for (final StaticLine l in liveLines)
            _row(context, l, counts[l.id] ?? 0),
        ],
        const SizedBox(height: 12),
        Text(
          StringsPt.homeAllLines,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        for (final StaticLine l in shown) _row(context, l, counts[l.id] ?? 0),
        const SizedBox(height: 12),
        Text(
          StringsPt.homeUnofficial,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _row(BuildContext context, StaticLine line, int liveCount) {
    final bool live = liveCount > 0;
    return Semantics(
      label: '${line.name}, ${live ? 'ao vivo' : StringsPt.homeTimetableOnly}',
      button: true,
      child: ListTile(
        leading: Container(
          width: 40,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: badgeColorFor(line.id),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            line.short,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
        title: Text(line.name),
        subtitle: Text(
          live ? '$liveCount ônibus ao vivo' : StringsPt.homeTimetableOnly,
        ),
        trailing: live
            ? const Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(Icons.circle, color: liveColor, size: 12),
                  SizedBox(width: 4),
                  Text('Ao vivo'),
                ],
              )
            : null,
        onTap: () => context.go('/line/${line.id}'),
      ),
    );
  }
}
