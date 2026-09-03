import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'db.dart';
import 'notification_service.dart';
import 'widget_updater.dart';

final databaseProvider =
    Provider<AppDatabase>((ref) => throw UnimplementedError());
final eventRepositoryProvider =
    Provider<EventRepository>((ref) => throw UnimplementedError());

const _uuid = Uuid();

DateTime dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

class EventRepository {
  EventRepository(this.db);
  final AppDatabase db;

  Stream<List<Event>> eventsForDay(DateTime day) {
    final s = dayOnly(day);
    final e = s.add(const Duration(days: 1));
    return db.watchOverlapping(
        s.millisecondsSinceEpoch, e.millisecondsSinceEpoch);
  }

  Future<List<Event>> overlapping(DateTime start, DateTime end) =>
      db.getOverlapping(
          start.millisecondsSinceEpoch, end.millisecondsSinceEpoch);

  Stream<Event?> watchEvent(String id) => db.watchById(id);
  Future<Event?> getEvent(String id) => db.getById(id);

  /// مسار الحفظ الوحيد — يدوي وAI يمران من هنا (مواصفة B).
  Future<String> save({
    String? id,
    required String title,
    required DateTime start,
    required DateTime end,
    bool isAllDay = false,
    String category = 'other',
    String? location,
    String? description,
    String importance = 'normal',
    String source = 'manual',
    List<int> reminderOffsets = const [],
  }) async {
    final eventId = id ?? _uuid.v4();

    // إلغاء الإشعارات القديمة قبل استبدال التذكيرات (منع التكرار)
    if (id != null) {
      await NotificationService.instance.cancelForEvent(eventId, this);
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    await db.upsertEvent(EventsCompanion(
      id: Value(eventId),
      title: Value(title),
      description: Value(description),
      startDt: Value(start.toUtc().millisecondsSinceEpoch),
      endDt: Value(end.toUtc().millisecondsSinceEpoch),
      isAllDay: Value(isAllDay),
      category: Value(category),
      location: Value(location),
      importance: Value(importance),
      source: Value(source),
      createdAt: Value(now),
      updatedAt: Value(now),
    ));

    // "عند البدء" مضمون دائمًا + الحرج يحصل على 1س + 15د إجباريًا (مواصفة G)
    final offsets = <int>{0, ...reminderOffsets};
    if (importance == 'critical') offsets.addAll({60, 15});

    await db.replaceReminders(eventId, [
      for (final off in offsets)
        RemindersCompanion(
          id: Value(_uuid.v4()),
          eventId: Value(eventId),
          offsetMinutes: Value(off),
        ),
    ]);

    await NotificationService.instance.rescheduleEvent(eventId, this);
    await WidgetUpdater.refresh(this);
    return eventId;
  }

  Future<void> remove(String id) async {
    await NotificationService.instance.cancelForEvent(id, this);
    await db.deleteEvent(id);
    await WidgetUpdater.refresh(this);
  }

  // ── Tasks ─────────────────────────────────────────────────
  Stream<List<Task>> tasksForDay(DateTime day) {
    final s = dayOnly(day);
    final e = s.add(const Duration(days: 1));
    final isToday = s == dayOnly(DateTime.now());
    return db.watchTasksForDay(
        s.millisecondsSinceEpoch, e.millisecondsSinceEpoch,
        includeUndated: isToday);
  }

  Future<void> addTask({required String title, DateTime? due}) =>
      db.insertTask(TasksCompanion.insert(
        id: _uuid.v4(),
        title: title,
        dueDate: Value(due?.toUtc().millisecondsSinceEpoch),
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ));

  Future<void> toggleTask(Task t) => db.setTaskDone(t.id, !t.done);

  Future<void> removeTask(String id) => db.deleteTask(id);
}
