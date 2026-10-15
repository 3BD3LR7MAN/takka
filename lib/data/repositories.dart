import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'db.dart';
import 'notification_service.dart';
import 'widget_updater.dart';
import '../core/sound_service.dart';
import '../domain/event_engine.dart';

final databaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError(),
);
final eventRepositoryProvider = Provider<EventRepository>(
  (ref) => throw UnimplementedError(),
);
final defaultEventAlarmProvider = StateProvider<bool>((_) => true);

const _uuid = Uuid();

DateTime dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

class EventRepository {
  EventRepository(this.db);
  final AppDatabase db;

  Stream<List<Event>> eventsForDay(DateTime day) {
    final s = dayOnly(day);
    final e = s.add(const Duration(days: 1));
    return watchExpanded(s, e);
  }

  Stream<List<Event>> watchExpanded(DateTime start, DateTime end) => db
      .watchMastersForRange(
        start.millisecondsSinceEpoch,
        end.millisecondsSinceEpoch,
      )
      .map((masters) => expandEvents(masters, start, end));

  Future<List<Event>> overlapping(DateTime start, DateTime end) async =>
      expandEvents(
        await db.getMastersForRange(
          start.millisecondsSinceEpoch,
          end.millisecondsSinceEpoch,
        ),
        start,
        end,
      );

  Future<List<Event>> mastersOverlapping(DateTime start, DateTime end) =>
      db.getMastersForRange(
        start.millisecondsSinceEpoch,
        end.millisecondsSinceEpoch,
      );

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
    String repeatRule = 'none',
    DateTime? repeatUntil,
  }) async {
    final eventId = id ?? _uuid.v4();

    // إلغاء الإشعارات القديمة قبل استبدال التذكيرات (منع التكرار)
    if (id != null) {
      await NotificationService.instance.cancelForEvent(eventId, this);
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    await db.upsertEvent(
      EventsCompanion(
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
        repeatRule: Value(repeatRule),
        repeatUntil: Value(repeatUntil?.toUtc().millisecondsSinceEpoch),
      ),
    );

    // Offset 0 is opt-in per event; critical events retain their extra reminders.
    final offsets = <int>{...reminderOffsets};
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
    SoundService.instance.playEventSaved();
    return eventId;
  }

  Future<void> remove(String id) async {
    await NotificationService.instance.cancelForEvent(id, this);
    await db.deleteEvent(id);
    await WidgetUpdater.refresh(this);
    SoundService.instance.playDelete();
  }

  // ── Tasks ─────────────────────────────────────────────────
  Stream<List<Task>> tasksForDay(DateTime day) {
    final s = dayOnly(day);
    final e = s.add(const Duration(days: 1));
    final isToday = s == dayOnly(DateTime.now());
    return db.watchTasksForDay(
      s.millisecondsSinceEpoch,
      e.millisecondsSinceEpoch,
      includeUndated: isToday,
    );
  }

  Future<void> addTask({required String title, DateTime? due}) async {
    await db.insertTask(
      TasksCompanion.insert(
        id: _uuid.v4(),
        title: title,
        dueDate: Value(due?.toUtc().millisecondsSinceEpoch),
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
    await WidgetUpdater.refresh(this);
    SoundService.instance.playClick();
  }

  Future<void> toggleTask(Task t) async {
    final newDone = !t.done;
    await db.setTaskDone(t.id, newDone);
    await WidgetUpdater.refresh(this);
    if (newDone) {
      SoundService.instance.playTaskDone();
    } else {
      SoundService.instance.playClick();
    }
  }

  Future<void> removeTask(String id) async {
    await db.deleteTask(id);
    await WidgetUpdater.refresh(this);
    SoundService.instance.playDelete();
  }

  Future<void> renameTask(String id, String title) async {
    await db.renameTask(id, title);
    await WidgetUpdater.refresh(this);
  }
}
