import '../data/db.dart';

class DaySegment {
  final DateTime start;
  final DateTime end;
  final bool continuesFromPrevDay;
  final bool continuesToNextDay;
  const DaySegment(
    this.start,
    this.end, {
    required this.continuesFromPrevDay,
    required this.continuesToNextDay,
  });
}

bool eventOverlapsDay(
  DateTime start,
  DateTime end,
  DateTime dayStart,
  DateTime dayEnd,
) =>
    start.isBefore(dayEnd) && end.isAfter(dayStart);

List<DaySegment> segmentsForDay(Event e, DateTime dayStart, DateTime dayEnd) {
  final s = DateTime.fromMillisecondsSinceEpoch(e.startDt);
  final en = DateTime.fromMillisecondsSinceEpoch(e.endDt);
  final segStart = s.isBefore(dayStart) ? dayStart : s;
  final segEnd = en.isAfter(dayEnd) ? dayEnd : en;
  return [
    DaySegment(
      segStart,
      segEnd,
      continuesFromPrevDay: s.isBefore(dayStart),
      continuesToNextDay: en.isAfter(dayEnd),
    ),
  ];
}

bool eventsOverlap(Event a, Event b) {
  if (a.isAllDay || b.isAllDay) return false;
  return a.startDt < b.endDt && a.endDt > b.startDt;
}

List<Event> conflictsFor(Event candidate, Iterable<Event> others) => others
    .where((o) => o.id != candidate.id && eventsOverlap(candidate, o))
    .toList();

class FreeSlot {
  final DateTime start;
  final DateTime end;
  const FreeSlot(this.start, this.end);
  Duration get duration => end.difference(start);
}

/// الفجوات الحرة بين أحداث اليوم — تُحسب محليًا وليس عبر الـAI (قاعدة 23).
List<FreeSlot> freeSlotsForDay(
  List<Event> timedEvents,
  DateTime dayStart,
  DateTime dayEnd, {
  Duration minGap = const Duration(minutes: 15),
}) {
  final sorted = [...timedEvents]
    ..sort((a, b) => a.startDt.compareTo(b.startDt));
  final slots = <FreeSlot>[];
  var cursor = dayStart;
  for (final e in sorted) {
    final s = DateTime.fromMillisecondsSinceEpoch(e.startDt);
    final en = DateTime.fromMillisecondsSinceEpoch(e.endDt);
    if (s.isAfter(cursor) && s.difference(cursor) >= minGap) {
      slots.add(FreeSlot(cursor, s));
    }
    if (en.isAfter(cursor)) cursor = en;
  }
  if (dayEnd.isAfter(cursor) && dayEnd.difference(cursor) >= minGap) {
    slots.add(FreeSlot(cursor, dayEnd));
  }
  return slots;
}

/// توزيع الأحداث المتداخلة على مسارات جانبية للعرض.
Map<String, (int lane, int laneCount)> assignLanes(List<Event> timed) {
  final sorted = [...timed]..sort((a, b) => a.startDt.compareTo(b.startDt));
  final laneEnds = <int>[];
  final lane = <String, int>{};
  for (final e in sorted) {
    int placed = -1;
    for (var i = 0; i < laneEnds.length; i++) {
      if (laneEnds[i] <= e.startDt) {
        placed = i;
        break;
      }
    }
    if (placed == -1) {
      placed = laneEnds.length;
      laneEnds.add(0);
    }
    laneEnds[placed] = e.endDt;
    lane[e.id] = placed;
  }
  final total = laneEnds.isEmpty ? 1 : laneEnds.length;
  return {for (final e in sorted) e.id: (lane[e.id]!, total)};
}

DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

int _calendarDayDifference(DateTime a, DateTime b) => DateTime.utc(
      a.year,
      a.month,
      a.day,
    ).difference(DateTime.utc(b.year, b.month, b.day)).inDays;

/// Expand recurring master records into occurrences intersecting [from, to).
/// Every occurrence retains its master ID so all copies edit/delete the series.
List<Event> expandEvents(List<Event> masters, DateTime from, DateTime to) {
  if (!to.isAfter(from)) return const [];
  final out = <Event>[];
  for (final event in masters) {
    if (event.repeatRule == 'none' || event.repeatRule.isEmpty) {
      if (event.startDt < to.millisecondsSinceEpoch &&
          event.endDt > from.millisecondsSinceEpoch) {
        out.add(event);
      }
    } else {
      out.addAll(occurrencesOf(event, from, to));
    }
  }
  out.sort((a, b) => a.startDt.compareTo(b.startDt));
  return out;
}

/// Return concrete copies of [event] for repeat dates intersecting [from, to).
List<Event> occurrencesOf(Event event, DateTime from, DateTime to) {
  if (!to.isAfter(from)) return const [];
  if (event.repeatRule == 'none' || event.repeatRule.isEmpty) {
    return event.startDt < to.millisecondsSinceEpoch &&
            event.endDt > from.millisecondsSinceEpoch
        ? [event]
        : const [];
  }

  final masterStart = DateTime.fromMillisecondsSinceEpoch(event.startDt);
  final duration = Duration(milliseconds: event.endDt - event.startDt);
  final until = event.repeatUntil == null
      ? null
      : DateTime.fromMillisecondsSinceEpoch(event.repeatUntil!);
  final overlapLookback = duration.isNegative ? Duration.zero : duration;
  final requestedFirstDay = _dayOnly(from.subtract(overlapLookback));
  var day = _dayOnly(
    masterStart.isAfter(requestedFirstDay) ? masterStart : requestedFirstDay,
  );
  final lastDay = _dayOnly(to.subtract(const Duration(microseconds: 1)));
  final masterDay = _dayOnly(masterStart);
  final masterWeekday = masterStart.weekday;
  final result = <Event>[];

  while (!day.isAfter(lastDay)) {
    if (until != null && day.isAfter(_dayOnly(until))) break;
    final daysFromMaster = _calendarDayDifference(day, masterDay);
    final hit = switch (event.repeatRule) {
      'daily' => true,
      'weekly' => day.weekday == masterWeekday,
      'biweekly' =>
        day.weekday == masterWeekday && ((daysFromMaster ~/ 7) % 2 == 0),
      'monthly' => day.day == masterDay.day,
      'weekdays' =>
        day.weekday >= DateTime.monday && day.weekday <= DateTime.friday,
      'weekend' =>
        day.weekday == DateTime.saturday || day.weekday == DateTime.sunday,
      _ => false,
    };
    if (hit) {
      final occurrenceStart = DateTime(
        day.year,
        day.month,
        day.day,
        masterStart.hour,
        masterStart.minute,
        masterStart.second,
        masterStart.millisecond,
      );
      final occurrenceEnd = occurrenceStart.add(duration);
      if (occurrenceEnd.isAfter(from) && occurrenceStart.isBefore(to)) {
        result.add(
          event.copyWith(
            startDt: occurrenceStart.millisecondsSinceEpoch,
            endDt: occurrenceEnd.millisecondsSinceEpoch,
          ),
        );
      }
    }
    day = day.add(const Duration(days: 1));
  }
  return result;
}

String repeatRuleLabel(String rule, bool ar) => switch (rule) {
      'daily' => ar ? 'يوميًا' : 'Daily',
      'weekly' => ar ? 'أسبوعيًا' : 'Weekly',
      'biweekly' => ar ? 'كل أسبوعين' : 'Every 2 weeks',
      'monthly' => ar ? 'شهريًا' : 'Monthly',
      'weekdays' => ar ? 'أيام العمل' : 'Weekdays',
      'weekend' => ar ? 'نهاية الأسبوع' : 'Weekend',
      _ => ar ? 'بدون تكرار' : 'Does not repeat',
    };
