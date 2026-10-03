// S05 Horários tab: day types, origin selector, next departure, time
// chips, disclaimer. Never hits the network. See PLAN.md S05.
import 'package:flutter/material.dart';
import 'package:pontual/data/static_data/static_data.dart';
import 'package:pontual/domain/schedule.dart';

/// Labels for the day-type selector in pt-BR.
const Map<DayType, String> dayTypeLabels = <DayType, String>{
  DayType.weekday: 'Dias úteis',
  DayType.saturday: 'Sábado',
  DayType.sundayHoliday: 'Dom/Fer',
};

/// Timetable tab for one line.
class ScheduleTab extends StatefulWidget {
  /// Creates a timetable tab.
  const ScheduleTab({required this.line, required this.now, super.key});

  /// Line with schedules.
  final StaticLine line;

  /// Current instant; converted to São Mateus time inside.
  final DateTime now;

  @override
  State<ScheduleTab> createState() => _ScheduleTabState();
}

class _ScheduleTabState extends State<ScheduleTab> {
  late DayType _day;
  late String _origin;

  @override
  void initState() {
    super.initState();
    _day = dayTypeFor(saoMateusTime(widget.now));
    final List<String> origins = _origins();
    _origin = origins.isEmpty ? '' : origins.first;
  }

  List<String> _origins() {
    final List<String> origins = widget.line.schedules
        .where((Map<String, dynamic> s) => s['day_type'] == _dayName(_day))
        .map((Map<String, dynamic> s) => s['origin'] as String)
        .toList();
    if (origins.isEmpty) {
      final Set<String> all = widget.line.schedules
          .map((Map<String, dynamic> s) => s['origin'] as String)
          .toSet();
      origins.addAll(all);
    }
    return origins;
  }

  String _dayName(DayType day) {
    switch (day) {
      case DayType.weekday:
        return 'weekday';
      case DayType.saturday:
        return 'saturday';
      case DayType.sundayHoliday:
        return 'sunday_holiday';
    }
  }

  List<String> _times() {
    for (final Map<String, dynamic> s in widget.line.schedules) {
      if (s['day_type'] == _dayName(_day) && s['origin'] == _origin) {
        return (s['times'] as List<dynamic>).cast<String>();
      }
    }
    return <String>[];
  }

  @override
  Widget build(BuildContext context) {
    final List<String> origins = _origins();
    if (origins.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          _daySelector(),
          const SizedBox(height: 24),
          const Text('Sem horários cadastrados para este dia.'),
          const SizedBox(height: 16),
          _disclaimer(context),
        ],
      );
    }
    if (!origins.contains(_origin)) {
      _origin = origins.first;
    }
    final List<String> times = _times();
    final DateTime local = saoMateusTime(widget.now);
    final int nowMinutes = local.hour * 60 + local.minute;
    final String? next = nextDeparture(times, nowMinutes);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        _daySelector(),
        if (origins.length > 1) ...<Widget>[
          const SizedBox(height: 12),
          Semantics(
            label: 'Saída de',
            child: DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Saída de:'),
              initialValue: _origin,
              items: origins
                  .map(
                    (String o) =>
                        DropdownMenuItem<String>(value: o, child: Text(o)),
                  )
                  .toList(),
              onChanged: (String? v) {
                if (v != null) {
                  setState(() => _origin = v);
                }
              },
            ),
          ),
        ],
        if (times.isEmpty) ...<Widget>[
          const SizedBox(height: 24),
          const Text('Sem horários cadastrados para este dia.'),
        ] else ...<Widget>[
          const SizedBox(height: 12),
          if (next != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'Próximo: $next (em ${minutesUntil(next, nowMinutes)} min)',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (final String t in times)
                Semantics(
                  label: t,
                  child: Chip(
                    label: Text(
                      t,
                      style: TextStyle(
                        color: minutesOf(t) <= nowMinutes
                            ? Theme.of(context).disabledColor
                            : null,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        _disclaimer(context),
      ],
    );
  }

  /// Day-type selector shared by the empty and content states.
  Widget _daySelector() {
    return Semantics(
      label: 'Tipo de dia',
      child: SegmentedButton<DayType>(
        segments: DayType.values
            .map(
              (DayType d) => ButtonSegment<DayType>(
                value: d,
                label: Text(dayTypeLabels[d]!),
              ),
            )
            .toList(),
        selected: <DayType>{_day},
        onSelectionChanged: (Set<DayType> v) {
          setState(() {
            _day = v.first;
            final List<String> origins = _origins();
            _origin = origins.isEmpty ? '' : origins.first;
          });
        },
      ),
    );
  }

  /// Unofficial-data disclaimer shown under every timetable.
  Widget _disclaimer(BuildContext context) {
    return Text(
      'Horários não oficiais, reunidos de fontes públicas. '
      'Podem estar desatualizados.',
      style: Theme.of(context).textTheme.bodySmall,
    );
  }
}
