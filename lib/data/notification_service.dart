import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'db.dart';
import 'repositories.dart';

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;
  bool _exactAlarms = true;
  String _lang = 'en';

  static const channels = {
    'normal': ('reminders_normal', 'Normal reminders'),
    'important': ('reminders_important', 'Important reminders'),
    'critical': ('reminders_critical', 'Critical reminders'),
  };

  /// أنماط اهتزاز مختلفة لكل مستوى أهمية — على القناة وعلى كل إشعار.
  static final Map<String, Int64List> vibrationPatterns = {
    'normal': Int64List.fromList([0, 250]),
    'important': Int64List.fromList([0, 400, 150, 400]),
    'critical':
        Int64List.fromList([0, 700, 200, 700, 200, 700, 200, 1000]),
  };

  bool get exactAlarmsGranted => _exactAlarms;

  Future<void> init({void Function(String eventId)? onOpenEvent}) async {
    await initializeDateFormatting(); // بيانات ص/م للعربية
    try {
      final saved = await const FlutterSecureStorage().read(key: 'app_locale');
      _lang = saved == 'ar' ? 'ar' : 'en';
    } catch (_) {}

    tzdata.initializeTimeZones();
    try {
      tz.setLocalLocation(
          tz.getLocation(await FlutterTimezone.getLocalTimezone()));
    } catch (_) {
      try {
        tz.setLocalLocation(tz.getLocation('UTC'));
      } catch (_) {}
    }

    await plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: (response) {
        final eventId = response.payload;
        if (eventId == null || eventId.isEmpty) return;
        // زر "تجاهل": لا تفتح التطبيق
        if (response.notificationResponseType ==
                NotificationResponseType.selectedNotificationAction &&
            response.actionId == 'dismiss') {
          return;
        }
        onOpenEvent?.call(eventId);
      },
    );

    final android = plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      for (final entry in channels.entries) {
        await android.createNotificationChannel(AndroidNotificationChannel(
          entry.value.$1,
          entry.value.$2,
          importance: entry.key == 'critical' ? Importance.max : Importance.high,
          enableVibration: true,
          vibrationPattern: vibrationPatterns[entry.key],
        ));
      }
      // The first permission request can run before a Flutter Activity is attached
      // when init() is called from main(). Re-check it after the first frame too.
      await android.requestNotificationsPermission();
      _exactAlarms = await android.canScheduleExactNotifications() ?? false;
    }
    _ready = true;
  }

  /// Must be called once the FlutterActivity is visible (Android 13+).
  Future<void> ensurePermissions() async {
    final android = plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;
    await android.requestNotificationsPermission();
    _exactAlarms = await android.canScheduleExactNotifications() ?? false;
  }

  /// جدولة كل تذكيرات الحدث — offset 0 = عند البدء تمامًا.
  Future<void> rescheduleEvent(String eventId, EventRepository repo) async {
    if (!_ready) return;
    final event = await repo.getEvent(eventId);
    if (event == null) return;

    final reminders = await repo.db.remindersFor(eventId);
    if (reminders.isEmpty) {
      debugPrint('[Notif] WARNING: no reminders stored for $eventId — nothing to schedule');
      return;
    }
    final start = DateTime.fromMillisecondsSinceEpoch(event.startDt);
    final end = DateTime.fromMillisecondsSinceEpoch(event.endDt);

    for (final r in reminders) {
      var fire = start.subtract(Duration(minutes: r.offsetMinutes));
      if (event.isAllDay) {
        fire = DateTime(start.year, start.month, start.day, 9)
            .subtract(Duration(minutes: r.offsetMinutes));
      }
      if (!fire.isAfter(DateTime.now())) {
        debugPrint('[Notif] skipped past reminder: event=$eventId offset=${r.offsetMinutes}');
        continue;
      }

      final notifId = _notifId(eventId, r.offsetMinutes);
      final isAtStart = r.offsetMinutes == 0;

      await _schedule(
        notifId: notifId,
        title: event.title,
        body: isAtStart
            ? '${_tr('Starting now', 'يبدأ الآن')} • ${_range(start, end)}${_loc(event.location)}'
            : '${_tr('In', 'بعد')} ${_offsetLabel(r.offsetMinutes)} • ${_range(start, end)}${_loc(event.location)}',
        fire: fire,
        importance: event.importance,
        payload: eventId,
      );
      debugPrint('[Notif] SCHEDULED event=$eventId offset=${r.offsetMinutes} at $fire id=$notifId mode=${_exactAlarms ? 'exact' : 'inexact'}');

      await repo.db.insertScheduled(ScheduledNotificationsCompanion.insert(
        reminderId: r.id,
        triggerAt: fire.millisecondsSinceEpoch,
        androidNotifId: notifId,
      ));
    }
  }

  /// إلغاء بمعرّفات Android المخزّنة بالضبط.
  Future<void> cancelForEvent(String eventId, EventRepository repo) async {
    final android = plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;
    final rows = await repo.db.scheduledForEvent(eventId);
    for (final row in rows) {
      await android.cancel(row.androidNotifId);
    }
    await repo.db.deleteScheduledForEvent(eventId);
  }

  /// BOOT_COMPLETED — إعادة جدولة كل المعلق.
  Future<void> reschedulePending(AppDatabase db) async {
    if (!_ready) return;
    for (final p in await db.pendingReschedules()) {
      final start = DateTime.fromMillisecondsSinceEpoch(p.startDt);
      final end = DateTime.fromMillisecondsSinceEpoch(p.endDt);
      await _schedule(
        notifId: p.androidNotifId,
        title: p.title,
        body: '${_range(start, end)}${_loc(p.location)}',
        fire: DateTime.fromMillisecondsSinceEpoch(p.triggerAt),
        importance: p.importance,
        payload: p.eventId,
      );
    }
  }

  /// مواصفة R — تغيّرت المنطقة الزمنية → إعادة جدولة القادم.
  Future<void> rescheduleIfTimezoneChanged(EventRepository repo) async {
    try {
      final current = await FlutterTimezone.getLocalTimezone();
      const storage = FlutterSecureStorage();
      final saved = await storage.read(key: 'last_timezone');
      if (saved == current) return;
      await storage.write(key: 'last_timezone', value: current);
      tz.setLocalLocation(tz.getLocation(current));
      if (saved == null) return; // أول تشغيل — لا شيء للترحيل

      final now = DateTime.now();
      final upcoming =
          await repo.overlapping(now, now.add(const Duration(days: 365)));
      for (final e in upcoming) {
        await cancelForEvent(e.id, repo);
        await rescheduleEvent(e.id, repo);
      }
    } catch (_) {}
  }

  /// اختبار فوري — بنفس قناة ونمط اهتزاز أهمية الحدث.
  Future<void> showTest(String title, {String importance = 'normal'}) async {
    if (!_ready) return;
    final ch = channels[importance] ?? channels['normal']!;
    await plugin.show(
      2147000,
      title,
      _tr('Notifications are working ✓', 'الإشعارات تعمل ✓'),
      NotificationDetails(
        android: AndroidNotificationDetails(
          ch.$1,
          ch.$2,
          importance: importance == 'critical' ? Importance.max : Importance.high,
          priority: Priority.high,
          enableVibration: true,
          vibrationPattern: vibrationPatterns[importance],
        ),
      ),
    );
  }

  /// تشخيص: نفس مسار الجدولة الحقيقي، لكن بعد [seconds] ثوانٍ.
  Future<void> scheduleDebugTest({int seconds = 15}) async {
    if (!_ready) return;
    await _schedule(
      notifId: 2147001,
      title: _tr('Scheduled test', 'اختبار الجدولة'),
      body: _tr('If you see this, scheduling works ✓', 'إذا رأيت هذا الإشعار فالجدولة تعمل ✓'),
      fire: DateTime.now().add(Duration(seconds: seconds)),
      importance: 'important',
      payload: '',
    );
    debugPrint('[Notif] DEBUG alarm scheduled in ${seconds}s (mode=${_exactAlarms ? 'exact' : 'inexact'})');
  }

  /// إعادة جدولة تنبيهات كل الأحداث القادمة.
  Future<void> rescheduleAll(EventRepository repo) async {
    if (!_ready) return;
    final now = DateTime.now();
    final upcoming = await repo.overlapping(now, now.add(const Duration(days: 365)));
    for (final e in upcoming) {
      await cancelForEvent(e.id, repo);
      await rescheduleEvent(e.id, repo);
    }
    debugPrint('[Notif] rescheduleAll done for ${upcoming.length} upcoming events');
  }

  // ────────────────────────── داخلي ──────────────────────────

  Future<void> _schedule({
    required int notifId,
    required String title,
    required String body,
    required DateTime fire,
    required String importance,
    required String payload,
  }) async {
    final android = plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        channels[importance]?.$1 ?? 'reminders_normal',
        channels[importance]?.$2 ?? 'Reminders',
        importance: importance == 'critical' ? Importance.max : Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        vibrationPattern:
            vibrationPatterns[importance] ?? vibrationPatterns['normal'],
        actions: const [
          // Actions without showsUserInterface are delivered only to the
          // background callback. Open must bring the Flutter Activity forward.
          AndroidNotificationAction('open', 'Open', showsUserInterface: true),
          // cancelNotification=true (the default) removes it immediately.
          AndroidNotificationAction('dismiss', 'Dismiss'),
        ],
      ),
    );

    final scheduled = tz.TZDateTime.from(fire, tz.local);
    try {
      await plugin.zonedSchedule(
        notifId, title, body, scheduled, details,
        androidScheduleMode: _exactAlarms
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
    } catch (error) {
      debugPrint('[Notif] exact schedule failed id=$notifId error=$error; retrying inexact');
      try {
        await plugin.zonedSchedule(
          notifId, title, body, scheduled, details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: payload,
        );
      } catch (retryError) {
        debugPrint('[Notif] schedule failed id=$notifId error=$retryError');
        rethrow;
      }
    }
  }

  /// معرّف ثابت لكل (حدث، إزاحة) — ينجو من إعادة التشغيل بلا تصادمات.
  int _notifId(String eventId, int offsetMinutes) =>
      '$eventId#$offsetMinutes'.hashCode & 0x7fffffff;

  String _tr(String en, String ar) => _lang == 'ar' ? ar : en;
  String _range(DateTime s, DateTime e) => '${_hm(s)} – ${_hm(e)}';
  String _loc(String? l) => (l == null || l.isEmpty) ? '' : ' • $l';

  /// 12 ساعة دائمًا — ص/م بالعربية، AM/PM بالإنجليزية.
  String _hm(DateTime d) => DateFormat('h:mm a', _lang).format(d);

  String _offsetLabel(int minutes) {
    if (_lang == 'ar') {
      if (minutes < 60) return '$minutes دقيقة';
      if (minutes == 60) return 'ساعة';
      if (minutes < 1440) return '${minutes ~/ 60} ساعات';
      if (minutes == 1440) return 'يوم';
      return '${minutes ~/ 1440} أيام';
    }
    if (minutes < 60) return '$minutes min';
    if (minutes == 60) return '1 hour';
    if (minutes < 1440) return '${minutes ~/ 60} hours';
    if (minutes == 1440) return '1 day';
    return '${minutes ~/ 1440} days';
  }
}
