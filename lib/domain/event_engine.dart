import '../data/db.dart';

class DaySegment {
  final DateTime start;
  final DateTime end;
  final bool continuesFromPrevDay;
  final bool continuesToNextDay;
  const DaySegment(this.start, this.end,
      {required this.continuesFromPrevDay,
      required this.continuesToNextDay});
}

bool eventOverlapsDay(DateTime start, DateTime end, DateTime dayStart, DateTime dayEnd) =>
    start.isBefore(dayEnd) && end.isAfter(dayStart);

List<DaySegment> segmentsForDay(Event e, DateTime dayStart, DateTime dayEnd) {
  final s = DateTime.fromMillisecondsSinceEpoch(e.startDt);
  final en = DateTime.fromMillisecondsSinceEpoch(e.endDt);
  final segStart = s.isBefore(dayStart) ? dayStart : s;
  final segEnd = en.isAfter(dayEnd) ? dayEnd : en;
  return [
    DaySegment(segStart, segEnd,
        continuesFromPrevDay: s.isBefore(dayStart),
        continuesToNextDay: en.isAfter(dayEnd)),
  ];
}

bool eventsOverlap(Event a, Event b) {
  if (a.isAllDay || b.isAllDay) return false;
  return a.startDt < b.endDt && a.endDt > b.startDt;
}

List<Event> conflictsFor(Event candidate, Iterable<Event> others) =>
    others
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
  final sorted = [...timedEvents]..sort((a, b) => a.startDt.compareTo(b.startDt));
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
