// Pure schedule helpers. No Flutter imports. Day-type default follows the
// São Mateus calendar: Saturday maps to saturday, Sunday to
// sunday_holiday; public holidays are not auto-detected in alpha and the
// user switches manually. Times are HH:mm on a fixed UTC-3 offset.
// See PLAN.md S05.
library;

/// Day types used by timetables.
enum DayType {
  /// Monday to Friday.
  weekday,

  /// Saturday.
  saturday,

  /// Sunday and holidays.
  sundayHoliday,
}

/// Day type for a São Mateus local date.
DayType dayTypeFor(DateTime local) {
  if (local.weekday == DateTime.saturday) {
    return DayType.saturday;
  }
  if (local.weekday == DateTime.sunday) {
    return DayType.sundayHoliday;
  }
  return DayType.weekday;
}

/// São Mateus wall time for an instant. Fixed UTC-3, no DST in alpha.
DateTime saoMateusTime(DateTime instant) {
  return instant.toUtc().add(const Duration(hours: -3));
}

/// Minutes since midnight for an HH:mm time.
int minutesOf(String hhmm) {
  final List<String> parts = hhmm.split(':');
  return int.parse(parts[0]) * 60 + int.parse(parts[1]);
}

/// First departure strictly after [nowMinutes], or null when none remains.
String? nextDeparture(List<String> times, int nowMinutes) {
  for (final String t in times) {
    if (minutesOf(t) > nowMinutes) {
      return t;
    }
  }
  return null;
}

/// Minutes from [nowMinutes] until an HH:mm departure.
int minutesUntil(String hhmm, int nowMinutes) {
  return minutesOf(hhmm) - nowMinutes;
}

/// Groups times by hour preserving order, e.g. {"05": ["05:30"]}.
Map<String, List<String>> groupByHour(List<String> times) {
  final Map<String, List<String>> groups = <String, List<String>>{};
  for (final String t in times) {
    final String hour = t.split(':').first;
    groups.putIfAbsent(hour, () => <String>[]).add(t);
  }
  return groups;
}
