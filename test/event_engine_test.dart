import 'package:flutter_test/flutter_test.dart';
import 'package:takka/data/db.dart';
import 'package:takka/domain/event_engine.dart';
import 'package:takka/features/ai/ai_service.dart';
import 'package:takka/features/calendar/calendar_screen.dart';

Event ev(
  String id,
  DateTime s,
  DateTime e, {
  bool allDay = false,
  String repeatRule = 'none',
  DateTime? repeatUntil,
}) =>
    Event(
      id: id,
      title: 't',
      description: null,
      startDt: s.millisecondsSinceEpoch,
      endDt: e.millisecondsSinceEpoch,
      isAllDay: allDay,
      category: 'other',
      location: null,
      importance: 'normal',
      source: 'manual',
      createdAt: 0,
      updatedAt: 0,
      repeatRule: repeatRule,
      repeatUntil: repeatUntil?.millisecondsSinceEpoch,
    );

void main() {
  final dayStart = DateTime(2026, 8, 28);
  final dayEnd = DateTime(2026, 8, 29);

  test('single-day event overlaps its day', () {
    final e = ev('1', DateTime(2026, 8, 28, 10), DateTime(2026, 8, 28, 11));
    expect(
      eventOverlapsDay(
        DateTime.fromMillisecondsSinceEpoch(e.startDt),
        DateTime.fromMillisecondsSinceEpoch(e.endDt),
        dayStart,
        dayEnd,
      ),
      isTrue,
    );
  });

  test('overnight event is segmented at midnight', () {
    final e = ev('2', DateTime(2026, 8, 28, 22), DateTime(2026, 8, 29, 2));
    final seg = segmentsForDay(e, dayStart, dayEnd).first;
    expect(seg.end, dayEnd);
    expect(seg.continuesToNextDay, isTrue);
    expect(seg.continuesFromPrevDay, isFalse);
  });

  test('overlap detection is symmetric on timed events only', () {
    final a = ev('a', DateTime(2026, 8, 28, 9), DateTime(2026, 8, 28, 10));
    final b = ev(
      'b',
      DateTime(2026, 8, 28, 9, 30),
      DateTime(2026, 8, 28, 10, 30),
    );
    expect(eventsOverlap(a, b), isTrue);
    expect(eventsOverlap(b, a), isTrue);
    final allDay = ev('c', dayStart, dayEnd, allDay: true);
    expect(eventsOverlap(a, allDay), isFalse);
  });

  test('free slots found between events', () {
    final events = [
      ev('x', DateTime(2026, 8, 28, 9), DateTime(2026, 8, 28, 10)),
      ev('y', DateTime(2026, 8, 28, 12), DateTime(2026, 8, 28, 13)),
    ];
    final slots = freeSlotsForDay(events, dayStart, dayEnd);
    expect(slots.any((s) => s.start.hour == 10 && s.end.hour == 12), isTrue);
  });

  test('month counts: overnight/multi-day counted per intersected day', () {
    final month = DateTime(2026, 8);
    final events = [
      ev('1', DateTime(2026, 8, 28, 22), DateTime(2026, 8, 29, 2)),
      ev('2', DateTime(2026, 8, 10, 9), DateTime(2026, 8, 10, 10)),
      ev('3', DateTime(2026, 7, 30, 8), DateTime(2026, 8, 2, 9)),
    ];
    final counts = monthEventCounts(events, month);
    expect(counts[28], 1);
    expect(counts[29], 1);
    expect(counts[10], 1);
    expect(counts[1], 1);
    expect(counts[2], 1);
    expect(counts[31], null);
  });

  test('daily recurrence expands inside range and includes end date', () {
    final master = ev(
      'daily',
      DateTime(2026, 10, 12, 9),
      DateTime(2026, 10, 12, 10),
      repeatRule: 'daily',
      repeatUntil: DateTime(2026, 10, 14),
    );
    final result = occurrencesOf(
      master,
      DateTime(2026, 10, 12),
      DateTime(2026, 10, 17),
    );
    expect(
      result.map((e) => DateTime.fromMillisecondsSinceEpoch(e.startDt).day),
      [12, 13, 14],
    );
    expect(result.every((e) => e.id == master.id), isTrue);
  });

  test('biweekly recurrence stays anchored to the master week', () {
    final master = ev(
      'biweekly',
      DateTime(2026, 10, 12, 9),
      DateTime(2026, 10, 12, 10),
      repeatRule: 'biweekly',
    );
    final result = occurrencesOf(
      master,
      DateTime(2026, 10, 12),
      DateTime(2026, 11, 2),
    );
    expect(
      result.map((e) => DateTime.fromMillisecondsSinceEpoch(e.startDt).day),
      [12, 26],
    );
  });

  test('weekdays and weekend repeat on their respective days', () {
    final baseStart = DateTime(2026, 10, 9, 9); // Friday
    final weekdays = ev(
      'weekdays',
      baseStart,
      baseStart.add(const Duration(hours: 1)),
      repeatRule: 'weekdays',
    );
    final weekend = ev(
      'weekend',
      baseStart,
      baseStart.add(const Duration(hours: 1)),
      repeatRule: 'weekend',
    );
    final from = DateTime(2026, 10, 9);
    final to = DateTime(2026, 10, 14);
    expect(occurrencesOf(weekdays, from, to), hasLength(3));
    expect(occurrencesOf(weekend, from, to), hasLength(2));
  });

  // مواصفة S — اختبارات تحليل ردود الـAI
  test(
    'AI validation: timeMissing flagged, reminders clamped, tasks parsed',
    () {
      final result = validateAiJson('''
    {
      "events": [{
        "title": "Meeting",
        "startDate": "2026-08-28",
        "isAllDay": false,
        "category": "work",
        "reminders": [10, 99999, -5],
        "importance": "critical"
      }],
      "tasks": [{"title": "Buy milk", "dueDate": null}],
      "ambiguities": []
    }''');

      final e = result.events.first;
      expect(e.timeMissing, isTrue); // لا وقت → لا تخمين
      expect(e.reminders, [10]); // القيم غير الصالحة مرفوضة
      expect(e.importance, 'critical');
      expect(result.tasks.first.title, 'Buy milk');
      expect(result.tasks.first.dueDate, isNull);
    },
  );

  test('AI validation: invalid JSON does not crash', () {
    final result = validateAiJson('not json at all');
    expect(result.events, isEmpty);
    expect(result.ambiguities, isNotEmpty);
  });

  test('AI edit/delete proposals parse and match exact existing titles', () {
    final result = validateAiJson('''
    {
      "events": [], "tasks": [], "ambiguities": [],
      "updates": [{
        "matchTitle": "Doctor Visit", "kind": "event",
        "newTitle": "Dentist", "newStartDate": "2026-10-20",
        "newStartTime": "11:00", "newCategory": "work",
        "reminders": [10, 99999, -5]
      }],
      "deletes": [{"matchTitle": "Buy milk", "kind": "task"}]
    }''');
    final event = ev(
      'event-1',
      DateTime(2026, 10, 20, 9),
      DateTime(2026, 10, 20, 10),
    ).copyWith(title: 'Doctor Visit');
    const task = Task(
      id: 'task-1',
      title: 'Buy milk',
      done: false,
      dueDate: null,
      createdAt: 0,
    );
    resolveEdits(result, [event], [task]);

    expect(result.updates.single.matchedId, 'event-1');
    expect(result.updates.single.newTitle, 'Dentist');
    expect(result.updates.single.newStart, DateTime(2026, 10, 20, 11));
    expect(result.updates.single.reminders, [10]);
    expect(result.deletes.single.matchedId, 'task-1');
  });

  test('AI does not guess when titles are duplicated or only similar', () {
    final result = validateAiJson('''
    {"events": [], "tasks": [], "ambiguities": [],
     "updates": [{"matchTitle": "Meeting", "kind": "event", "newTitle": "Changed"}],
     "deletes": [{"matchTitle": "Buy milk", "kind": "task"}]}
    ''');
    final first = ev(
      'a',
      DateTime(2026, 10, 12, 9),
      DateTime(2026, 10, 12, 10),
    );
    final second = ev(
      'b',
      DateTime(2026, 10, 13, 9),
      DateTime(2026, 10, 13, 10),
    );
    const task = Task(
      id: 't1',
      title: 'Buy milk and bread',
      done: false,
      dueDate: null,
      createdAt: 0,
    );
    resolveEdits(
      result,
      [first.copyWith(title: 'Meeting'), second.copyWith(title: 'Meeting')],
      [task],
    );
    expect(result.updates.single.matched, isFalse);
    expect(result.deletes.single.matched, isFalse);
    expect(result.ambiguities, isNotEmpty);
  });
}
