// S04/S05 Line screen with Mapa and Horários tabs. The map tab lands in
// T26/T28; the timetable tab is fully functional here in T25.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pontual/app/providers.dart';
import 'package:pontual/data/static_data/static_data.dart';
import 'package:pontual/features/line/map_tab.dart';
import 'package:pontual/features/line/schedule_tab.dart';

/// Line screen for the line id in the route parameters.
class LineScreen extends ConsumerWidget {
  /// Creates a line screen.
  const LineScreen({required this.lineId, super.key});

  /// Line id from /line/:id.
  final int lineId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<StaticLine>> lines = ref.watch(linesProvider);
    return lines.when(
      data: (List<StaticLine> all) {
        StaticLine? found;
        for (final StaticLine l in all) {
          if (l.id == lineId) {
            found = l;
          }
        }
        if (found == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Linha não encontrada.')),
          );
        }
        final StaticLine line = found;
        final AsyncValue<String> tileUrl = ref.watch(tileUrlProvider);
        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              leading: BackButton(onPressed: () => context.go('/')),
              title: Text(line.name),
              bottom: const TabBar(
                tabs: <Widget>[
                  Tab(text: 'Mapa'),
                  Tab(text: 'Horários'),
                ],
              ),
            ),
            body: TabBarView(
              children: <Widget>[
                tileUrl.when(
                  data: (String url) => MapTab(line: line, tileUrl: url),
                  loading: () => const Center(child: Text('Conectando…')),
                  error: (_, _) => MapTab(
                    line: line,
                    tileUrl: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  ),
                ),
                ScheduleTab(line: line, now: DateTime.now()),
              ],
            ),
          ),
        );
      },
      loading: () => Scaffold(appBar: AppBar()),
      error: (_, _) => Scaffold(appBar: AppBar()),
    );
  }
}
