import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'db.g.dart';

class Events extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  IntColumn get startDt => integer()(); // epoch millis UTC
  IntColumn get endDt => integer()();
  BoolColumn get isAllDay => boolean().withDefault(const Constant(false))();
  TextColumn get category => text().withDefault(const Constant('other'))();
  TextColumn get location => text().nullable()();
  TextColumn get importance => text().withDefault(const Constant('normal'))();
  TextColumn get source => text().withDefault(const Constant('manual'))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Reminders extends Table {
  TextColumn get id => text()();
  TextColumn get eventId =>
      text().references(Events, #id, onDelete: KeyAction.cascade)();
  IntColumn get offsetMinutes => integer()(); // 0 = عند البدء
  BoolColumn get notified => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('ScheduledNotifRow')
class ScheduledNotifications extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get reminderId =>
      text().references(Reminders, #id, onDelete: KeyAction.cascade)();
  IntColumn get triggerAt => integer()();
  IntColumn get androidNotifId => integer()();
}

class Tasks extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  BoolColumn get done => boolean().withDefault(const Constant(false))();
  IntColumn get dueDate => integer().nullable()(); // epoch millis UTC — null = بدون تاريخ
  IntColumn get createdAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(tables: [Events, Reminders, ScheduledNotifications, Tasks])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_open());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_events_range ON events(start_dt, end_dt)');
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) await m.createAll(); // يُنشئ جدول tasks فقط
        },
      );

  // ── Events ────────────────────────────────────────────────
  Stream<List<Event>> watchOverlapping(int startMs, int endMs) =>
      (select(events)
            ..where((e) => e.startDt.isSmallerThanValue(endMs) &
                e.endDt.isBiggerThanValue(startMs))
            ..orderBy([(e) => OrderingTerm.asc(e.startDt)]))
          .watch();

  Future<List<Event>> getOverlapping(int startMs, int endMs) =>
      (select(events)
            ..where((e) => e.startDt.isSmallerThanValue(endMs) &
                e.endDt.isBiggerThanValue(startMs)))
          .get();

  Stream<Event?> watchById(String id) =>
      (select(events)..where((e) => e.id.equals(id))).watchSingleOrNull();

  Future<Event?> getById(String id) =>
      (select(events)..where((e) => e.id.equals(id))).getSingleOrNull();

  Future<void> upsertEvent(EventsCompanion e) =>
      into(events).insertOnConflictUpdate(e);

  Future<void> deleteEvent(String id) =>
      (delete(events)..where((e) => e.id.equals(id))).go();

  // ── Reminders ─────────────────────────────────────────────
  Future<List<Reminder>> remindersFor(String eventId) =>
      (select(reminders)..where((r) => r.eventId.equals(eventId))).get();

  Future<void> replaceReminders(
      String eventId, List<RemindersCompanion> list) async {
    await transaction(() async {
      await (delete(reminders)..where((r) => r.eventId.equals(eventId))).go();
      for (final r in list) {
        await into(reminders).insert(r);
      }
    });
  }

  // ── Scheduled notifications (إلغاء دقيق + إعادة جدولة بعد الإقلاع) ──
  Future<void> insertScheduled(ScheduledNotificationsCompanion row) =>
      into(scheduledNotifications).insert(row);

  Future<List<ScheduledNotifRow>> scheduledForEvent(String eventId) async {
    final query = select(scheduledNotifications).join([
      innerJoin(reminders,
          reminders.id.equalsExp(scheduledNotifications.reminderId)),
    ])
      ..where(reminders.eventId.equals(eventId));
    final rows = await query.get();
    return rows.map((r) => r.readTable(scheduledNotifications)).toList();
  }

  Future<void> deleteScheduledForEvent(String eventId) async {
    final rows = await scheduledForEvent(eventId);
    if (rows.isEmpty) return;
    await (delete(scheduledNotifications)
          ..where((t) => t.id.isIn(rows.map((r) => r.id).toList())))
        .go();
  }

  /// كل المعلق بعد إعادة التشغيل (مواصفة G — BOOT_COMPLETED).
  Future<List<PendingReschedule>> pendingReschedules() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final query = select(scheduledNotifications).join([
      innerJoin(reminders,
          reminders.id.equalsExp(scheduledNotifications.reminderId)),
      innerJoin(events, events.id.equalsExp(reminders.eventId)),
    ])
      ..where(scheduledNotifications.triggerAt.isBiggerThanValue(now));
    final rows = await query.get();
    return rows.map((row) {
      final n = row.readTable(scheduledNotifications);
      final e = row.readTable(events);
      return PendingReschedule(
        androidNotifId: n.androidNotifId,
        triggerAt: n.triggerAt,
        eventId: e.id,
        title: e.title,
        startDt: e.startDt,
        endDt: e.endDt,
        importance: e.importance,
        location: e.location,
      );
    }).toList();
  }

  /// كل التنبيهات المجدولة التي لم يحن وقتها بعد (للتشخيص).
  Future<List<ScheduledNotifRow>> pendingScheduled() {
    final now = DateTime.now().millisecondsSinceEpoch;
    return (select(scheduledNotifications)
          ..where((t) => t.triggerAt.isBiggerThanValue(now))
          ..orderBy([(t) => OrderingTerm.asc(t.triggerAt)]))
        .get();
  }

  // ── Tasks ─────────────────────────────────────────────────
  Stream<List<Task>> watchTasksForDay(int dayStartMs, int dayEndMs,
          {required bool includeUndated}) =>
      (select(tasks)
            ..where((t) => includeUndated
                ? (t.dueDate.isBiggerOrEqualValue(dayStartMs) &
                        t.dueDate.isSmallerThanValue(dayEndMs)) |
                    t.dueDate.isNull()
                : t.dueDate.isBiggerOrEqualValue(dayStartMs) &
                    t.dueDate.isSmallerThanValue(dayEndMs))
            ..orderBy([
              (t) => OrderingTerm.asc(t.done),
              (t) => OrderingTerm.asc(t.createdAt),
            ]))
          .watch();

  Future<void> insertTask(TasksCompanion t) => into(tasks).insert(t);

  Future<void> setTaskDone(String id, bool done) =>
      (update(tasks)..where((t) => t.id.equals(id)))
          .write(TasksCompanion(done: Value(done)));

  Future<void> deleteTask(String id) =>
      (delete(tasks)..where((t) => t.id.equals(id))).go();
}

LazyDatabase _open() => LazyDatabase(() async {
      final dir = await getApplicationDocumentsDirectory();
      return NativeDatabase.createInBackground(
          File(p.join(dir.path, 'time_manager.sqlite')));
    });

class PendingReschedule {
  final int androidNotifId;
  final int triggerAt;
  final String eventId;
  final String title;
  final int startDt;
  final int endDt;
  final String importance;
  final String? location;
  const PendingReschedule({
    required this.androidNotifId,
    required this.triggerAt,
    required this.eventId,
    required this.title,
    required this.startDt,
    required this.endDt,
    required this.importance,
    this.location,
  });
}
