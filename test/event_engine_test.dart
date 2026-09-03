import 'package:flutter_test/flutter_test.dart';
import 'package:time_manager/data/db.dart';
import 'package:time_manager/domain/event_engine.dart';
import 'package:time_manager/features/ai/ai_service.dart';
import 'package:time_manager/features/calendar/calendar_screen.dart';

Event ev(String id, DateTime s, DateTime e, {bool allDay = false}) => Event(
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
            dayEnd),
        isTrue);
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
    final b =
        ev('b', DateTime(2026, 8, 28, 9, 30), DateTime(2026, 8, 28, 10, 30));
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

  // مواصفة S — اختبارات تحليل ردود الـAI
  test('AI validation: timeMissing flagged, reminders clamped, tasks parsed',
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
    expect(e.timeMissing, isTrue);       // لا وقت → لا تخمين
    expect(e.reminders, [10]);           // القيم غير الصالحة مرفوضة
    expect(e.importance, 'critical');
    expect(result.tasks.first.title, 'Buy milk');
    expect(result.tasks.first.dueDate, isNull);
  });

  test('AI validation: invalid JSON does not crash', () {
    final result = validateAiJson('not json at all');
    expect(result.events, isEmpty);
    expect(result.ambiguities, isNotEmpty);
  });
}
