import 'dart:async';

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
import '../core/sound_service.dart';
import '../domain/event_engine.dart' show occurrencesOf;

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;
  Future<void>? _initializing;
  FutureOr<void> Function(String eventId, bool isAlarm)? _onOpenEvent;
  FutureOr<void> Function(String eventId)? _onSnoozeAlarm;
  String _initializationStage = 'Not started';
  String? _initializationError;
  bool _exactAlarms = true;
  String _lang = 'en';

  static const channels = {
    'normal': ('takka_reminders_normal_v2', 'Normal reminders'),
    'important': ('takka_reminders_important_v2', 'Important reminders'),
    'critical': ('takka_reminders_critical_v2', 'Critical reminders'),
  };
  static const _alarmChannelId = 'takka_event_alarm_v1';
  static const _activeAlarmChannelId = 'takka_active_alarm_v1';
  static const _activeAlarmNotificationId = 2147002;

  /// أنماط اهتزاز مختلفة لكل مستوى أهمية — على القناة وعلى كل إشعار.
  static final Map<String, Int64List> vibrationPatterns = {
    'normal': Int64List.fromList([0, 250]),
    'important': Int64List.fromList([0, 400, 150, 400]),
    'critical': Int64List.fromList([0, 700, 200, 700, 200, 700, 200, 1000]),
  };

  bool get exactAlarmsGranted => _exactAlarms;
  bool get isReady => _ready;
  String get initializationStatus =>
      _initializationError ?? _initializationStage;

  Future<void> init({
    FutureOr<void> Function(String eventId, bool isAlarm)? onOpenEvent,
    FutureOr<void> Function(String eventId)? onSnoozeAlarm,
  }) {
    if (onOpenEvent != null) _onOpenEvent = onOpenEvent;
    if (onSnoozeAlarm != null) _onSnoozeAlarm = onSnoozeAlarm;
    if (_ready) return Future<void>.value();
    final active = _initializing;
    if (active != null) return active;
    final future = _initialize();
    _initializing = future;
    return future.whenComplete(() {
      if (identical(_initializing, future)) _initializing = null;
    });
  }

  Future<void> _initialize() async {
    _initializationError = null;
    _initializationStage = 'Preparing notification service';
    try {
      await initializeDateFormatting().timeout(const Duration(seconds: 3));
    } catch (error) {
      debugPrint('[Notif] date formatting initialization failed: $error');
    }
    _initializationStage = 'Reading app settings';
    try {
      final saved = await const FlutterSecureStorage()
          .read(key: 'app_locale')
          .timeout(const Duration(seconds: 3));
      _lang = saved == 'ar' ? 'ar' : 'en';
    } catch (error) {
      debugPrint('[Notif] locale read skipped: $error');
    }

    if (kIsWeb) {
      _ready = true;
      _initializationStage = 'Ready';
      return;
    }

    _initializationStage = 'Loading timezone';
    tzdata.initializeTimeZones();
    try {
      tz.setLocalLocation(
        tz.getLocation(
          await FlutterTimezone.getLocalTimezone().timeout(
            const Duration(seconds: 3),
          ),
        ),
      );
    } catch (error) {
      debugPrint('[Notif] timezone lookup skipped: $error');
      try {
        tz.setLocalLocation(tz.getLocation('UTC'));
      } catch (_) {}
    }

    _initializationStage = 'Initializing Android notification plugin';
    try {
      await plugin.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('ic_notification'),
        ),
        onDidReceiveNotificationResponse: (response) {
          final payload = response.payload;
          if (payload == null || payload.isEmpty) return;
          final parts = payload.split('|');
          final eventId = parts.first;
          final isAlarm = parts.length > 1 && parts.last == 'alarm';
          final isActiveAlarmNotification =
              response.id == _activeAlarmNotificationId;
          if (eventId.isEmpty) return;
          if (response.notificationResponseType ==
              NotificationResponseType.selectedNotificationAction) {
            if (response.actionId == 'stop_alarm' ||
                (response.actionId == 'dismiss' &&
                    (isAlarm || isActiveAlarmNotification))) {
              SoundService.instance.dismissAlarm();
              unawaited(cancelActiveAlarmNotification());
              return;
            }
            if (response.actionId == 'dismiss') return;
            if (response.actionId == 'snooze_alarm') {
              final snooze = _onSnoozeAlarm;
              if (snooze != null) {
                unawaited(Future<void>.sync(() => snooze(eventId)));
              }
              return;
            }
          }
          final callback = _onOpenEvent;
          if (callback != null) {
            unawaited(Future<void>.sync(() => callback(eventId, isAlarm)));
          }
        },
      ).timeout(const Duration(seconds: 8));
    } catch (error, stackTrace) {
      _initializationError = 'Plugin initialization failed: $error';
      _initializationStage = 'Failed';
      debugPrint('[Notif] plugin initialization failed: $error\n$stackTrace');
      return;
    }

    _initializationStage = 'Creating Android notification channels';
    final android = plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      for (final entry in channels.entries) {
        try {
          await android
              .createNotificationChannel(
                AndroidNotificationChannel(
                  entry.value.$1,
                  entry.value.$2,
                  importance: entry.key == 'critical'
                      ? Importance.max
                      : Importance.high,
                  playSound: true,
                  enableVibration: true,
                  vibrationPattern: vibrationPatterns[entry.key],
                ),
              )
              .timeout(const Duration(seconds: 3));
        } catch (error) {
          debugPrint('[Notif] could not create channel ${entry.key}: $error');
        }
      }
      for (final channel in [
        AndroidNotificationChannel(
          _alarmChannelId,
          _tr('Event alarms', 'منبهات الأحداث'),
          description: _tr(
            'Alerts at the start of scheduled events',
            'تنبيهات عند بداية الأحداث المجدولة',
          ),
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          vibrationPattern: vibrationPatterns['critical'],
        ),
        AndroidNotificationChannel(
          _activeAlarmChannelId,
          _tr('Active alarm', 'المنبه النشط'),
          description: _tr(
            'Controls for an alarm that is currently ringing',
            'عناصر التحكم في المنبه الذي يرن الآن',
          ),
          importance: Importance.max,
          playSound: false,
          enableVibration: false,
        ),
      ]) {
        try {
          await android
              .createNotificationChannel(channel)
              .timeout(const Duration(seconds: 3));
        } catch (error) {
          debugPrint('[Notif] could not create alarm channel: $error');
        }
      }
      try {
        _exactAlarms = await android.canScheduleExactNotifications().timeout(
                  const Duration(seconds: 3),
                ) ??
            false;
      } catch (error) {
        _exactAlarms = false;
        debugPrint('[Notif] exact-alarm status query failed: $error');
      }
    }
    _ready = true;
    _initializationStage = 'Ready';
  }

  /// Must be called once the FlutterActivity is visible (Android 13+).
  Future<bool> ensureReady() async {
    try {
      if (!_ready) await init();
    } catch (error, stackTrace) {
      debugPrint('[Notif] initialization retry failed: $error\n$stackTrace');
    }
    return _ready;
  }

  Future<void> ensurePermissions() async {
    try {
      if (!await ensureReady()) return;
      final android = plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android == null) return;
      await android.requestNotificationsPermission();
      _exactAlarms = await android.canScheduleExactNotifications() ?? false;
    } catch (error, stackTrace) {
      debugPrint('[Notif] permission check failed: $error\n$stackTrace');
    }
  }

  Future<bool> notificationsEnabled() async {
    final android = plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return !kIsWeb;
    try {
      return await android.areNotificationsEnabled() ?? false;
    } catch (error) {
      debugPrint('[Notif] unable to read notification permission: $error');
      return false;
    }
  }

  Future<int> platformPendingCount() async {
    try {
      return (await plugin.pendingNotificationRequests()).length;
    } catch (error) {
      debugPrint(
        '[Notif] unable to read Android pending notifications: $error',
      );
      return 0;
    }
  }

  Future<void> scheduleSnoozeAlarm({
    required String eventId,
    required String title,
    required String? location,
    required String importance,
    required int minutes,
  }) async {
    if (kIsWeb || !await ensureReady()) {
      debugPrint(
        '[Notif] snooze alarm skipped: notification service not ready',
      );
      return;
    }
    final fire = DateTime.now().add(Duration(minutes: minutes));
    final notifId =
        '$eventId#snooze#${fire.millisecondsSinceEpoch}'.hashCode & 0x7fffffff;
    await _schedule(
      notifId: notifId,
      title: title,
      body:
          '${_tr('Snoozed alarm', 'منبه مؤجل')} • ${_range(fire, fire.add(const Duration(minutes: 1)))}${_loc(location)}',
      fire: fire,
      importance: importance,
      location: location,
      payload: '$eventId|alarm',
      isAlarm: true,
    );
  }

  /// جدولة كل تذكيرات الحدث — offset 0 = عند البدء تمامًا.
  Future<void> rescheduleEvent(String eventId, EventRepository repo) async {
    if (kIsWeb || !await ensureReady()) {
      debugPrint('[Notif] event=$eventId not scheduled: service not ready');
      return;
    }
    final event = await repo.getEvent(eventId);
    if (event == null) return;

    final reminders = await repo.db.remindersFor(eventId);
    if (reminders.isEmpty) {
      debugPrint(
        '[Notif] WARNING: no reminders stored for $eventId — nothing to schedule',
      );
      return;
    }
    final masterStart = DateTime.fromMillisecondsSinceEpoch(event.startDt);
    final duration = Duration(milliseconds: event.endDt - event.startDt);
    final now = DateTime.now();
    final starts = <DateTime>[];
    if (event.repeatRule == 'none' || event.repeatRule.isEmpty) {
      starts.add(masterStart);
    } else {
      starts.addAll(
        occurrencesOf(event, now, now.add(const Duration(days: 6))).map(
          (occurrence) =>
              DateTime.fromMillisecondsSinceEpoch(occurrence.startDt),
        ),
      );
    }

    for (final occurrenceStart in starts) {
      final occurrenceEnd = occurrenceStart.add(duration);
      for (final reminder in reminders) {
        var fire = occurrenceStart.subtract(
          Duration(minutes: reminder.offsetMinutes),
        );
        if (event.isAllDay) {
          fire = DateTime(
            occurrenceStart.year,
            occurrenceStart.month,
            occurrenceStart.day,
            9,
          ).subtract(Duration(minutes: reminder.offsetMinutes));
        }
        if (!fire.isAfter(now)) continue;

        final notifId = _occurrenceNotifId(
          eventId,
          reminder.offsetMinutes,
          occurrenceStart,
        );
        final isAtStart = reminder.offsetMinutes == 0;
        try {
          await _schedule(
            notifId: notifId,
            title: isAtStart
                ? '${_tr('Alarm', 'منبه')}: ${event.title}'
                : event.title,
            body: isAtStart
                ? '${_tr('Starting now', 'يبدأ الآن')} • ${_range(occurrenceStart, occurrenceEnd)}${_loc(event.location)}'
                : '${_tr('In', 'بعد')} ${_offsetLabel(reminder.offsetMinutes)} • ${_range(occurrenceStart, occurrenceEnd)}${_loc(event.location)}',
            fire: fire,
            importance: event.importance,
            location: event.location,
            payload: isAtStart ? '$eventId|alarm' : eventId,
            isAlarm: isAtStart,
          );
          debugPrint(
            '[Notif] SCHEDULED event=$eventId occurrence=$occurrenceStart offset=${reminder.offsetMinutes} at $fire id=$notifId mode=${_exactAlarms ? 'exact' : 'inexact'}',
          );
          await repo.db.insertScheduled(
            ScheduledNotificationsCompanion.insert(
              reminderId: reminder.id,
              triggerAt: fire.millisecondsSinceEpoch,
              androidNotifId: notifId,
            ),
          );
        } catch (error, stackTrace) {
          debugPrint(
            '[Notif] event=$eventId schedule failed: $error\n$stackTrace',
          );
        }
      }
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
      await SoundService.instance.cancelBackgroundAlarm(row.androidNotifId);
    }
    await repo.db.deleteScheduledForEvent(eventId);
  }

  /// BOOT_COMPLETED — إعادة جدولة كل المعلق.
  Future<void> reschedulePending(AppDatabase db) async {
    if (kIsWeb || !await ensureReady()) return;
    for (final p in await db.pendingReschedules()) {
      final start = DateTime.fromMillisecondsSinceEpoch(p.startDt);
      final end = DateTime.fromMillisecondsSinceEpoch(p.endDt);
      await _schedule(
        notifId: p.androidNotifId,
        title: p.title,
        body: '${_range(start, end)}${_loc(p.location)}',
        fire: DateTime.fromMillisecondsSinceEpoch(p.triggerAt),
        importance: p.importance,
        location: p.location,
        payload: p.offsetMinutes == 0 ? '${p.eventId}|alarm' : p.eventId,
        isAlarm: p.offsetMinutes == 0,
      );
    }
  }

  /// مواصفة R — تغيّرت المنطقة الزمنية → إعادة جدولة القادم.
  Future<bool> rescheduleIfTimezoneChanged(EventRepository repo) async {
    if (kIsWeb || !await ensureReady()) return false;
    try {
      final current = await FlutterTimezone.getLocalTimezone();
      const storage = FlutterSecureStorage();
      final saved = await storage.read(key: 'last_timezone');
      if (saved == current) return false;
      await storage.write(key: 'last_timezone', value: current);
      tz.setLocalLocation(tz.getLocation(current));
      if (saved == null) {
        return false; // First launch: just record the timezone.
      }

      final now = DateTime.now();
      final upcoming = await repo.mastersOverlapping(
        now,
        now.add(const Duration(days: 365)),
      );
      for (final e in upcoming) {
        try {
          await cancelForEvent(e.id, repo);
          await rescheduleEvent(e.id, repo);
        } catch (error, stackTrace) {
          debugPrint(
            '[Notif] timezone refresh failed for ${e.id}: $error\n$stackTrace',
          );
        }
      }
      return true;
    } catch (error, stackTrace) {
      debugPrint('[Notif] timezone refresh failed: $error\n$stackTrace');
      return false;
    }
  }

  /// اختبار فوري — بنفس قناة ونمط اهتزاز أهمية الحدث.
  Future<bool> showTest(String title, {String importance = 'normal'}) async {
    if (!await ensureReady() || kIsWeb) return false;
    final ch = channels[importance] ?? channels['normal']!;
    try {
      await plugin.show(
        2147000,
        title,
        _tr('Notifications are working ✓', 'الإشعارات تعمل ✓'),
        NotificationDetails(
          android: AndroidNotificationDetails(
            ch.$1,
            ch.$2,
            importance:
                importance == 'critical' ? Importance.max : Importance.high,
            priority: Priority.high,
            icon: 'ic_notification',
            playSound: true,
            enableVibration: true,
            vibrationPattern: vibrationPatterns[importance],
          ),
        ),
      );
      return true;
    } catch (error, stackTrace) {
      debugPrint('[Notif] immediate test failed: $error\n$stackTrace');
      return false;
    }
  }

  /// تشخيص: نفس مسار الجدولة الحقيقي، لكن بعد [seconds] ثوانٍ.
  Future<bool> scheduleDebugTest({int seconds = 15}) async {
    if (kIsWeb || !await ensureReady()) return false;
    try {
      await _schedule(
        notifId: 2147001,
        title: _tr('Scheduled test', 'اختبار الجدولة'),
        body: _tr(
          'If you see this, scheduling works ✓',
          'إذا رأيت هذا الإشعار فالجدولة تعمل ✓',
        ),
        fire: DateTime.now().add(Duration(seconds: seconds)),
        importance: 'important',
        payload: '',
      );
      debugPrint(
        '[Notif] DEBUG alarm scheduled in ${seconds}s (mode=${_exactAlarms ? 'exact' : 'inexact'})',
      );
      return true;
    } catch (error, stackTrace) {
      debugPrint('[Notif] scheduled test failed: $error\n$stackTrace');
      return false;
    }
  }

  Future<void> showActiveAlarmNotification(AlarmState alarm) async {
    if (kIsWeb || !await ensureReady()) return;
    try {
      await plugin.show(
        _activeAlarmNotificationId,
        _tr('Alarm is ringing', 'المنبه يرن الآن'),
        '${alarm.title}${_loc(alarm.location)} • ${_hm(alarm.time)}',
        NotificationDetails(
          android: AndroidNotificationDetails(
            _activeAlarmChannelId,
            _tr('Active alarm', 'المنبه النشط'),
            channelDescription: _tr(
              'Controls for an alarm that is currently ringing',
              'عناصر التحكم في المنبه الذي يرن الآن',
            ),
            importance: Importance.max,
            priority: Priority.max,
            category: AndroidNotificationCategory.alarm,
            icon: 'ic_notification',
            playSound: false,
            enableVibration: false,
            ongoing: true,
            autoCancel: false,
            onlyAlertOnce: true,
            actions: _alarmActions(),
          ),
        ),
        payload: '${alarm.eventId}|alarm',
      );
    } catch (error, stackTrace) {
      debugPrint(
          '[Notif] active alarm notification failed: $error\n$stackTrace');
    }
  }

  Future<void> cancelActiveAlarmNotification() async {
    if (kIsWeb || !await ensureReady()) return;
    try {
      await plugin.cancel(_activeAlarmNotificationId);
    } catch (error) {
      debugPrint('[Notif] active alarm notification cancel failed: $error');
    }
  }

  /// إعادة جدولة تنبيهات كل الأحداث القادمة.
  Future<void> rescheduleAll(EventRepository repo) async {
    if (kIsWeb || !await ensureReady()) {
      debugPrint('[Notif] rescheduleAll skipped: service not ready');
      return;
    }
    final now = DateTime.now();
    final upcoming = await repo.mastersOverlapping(
      now,
      now.add(const Duration(days: 365)),
    );
    for (final e in upcoming) {
      try {
        await cancelForEvent(e.id, repo);
        await rescheduleEvent(e.id, repo);
      } catch (error, stackTrace) {
        debugPrint(
          '[Notif] rescheduleAll failed for ${e.id}: $error\n$stackTrace',
        );
      }
    }
    debugPrint(
      '[Notif] rescheduleAll done for ${upcoming.length} upcoming events',
    );
  }

  List<AndroidNotificationAction> _alarmActions() {
    final minutes = SoundService.instance.snoozeDurationMinutes;
    return [
      AndroidNotificationAction(
        'snooze_alarm',
        _tr('Snooze ${minutes}m', 'غفوة $minutes د'),
        showsUserInterface: true,
      ),
      AndroidNotificationAction(
        'stop_alarm',
        _tr('Stop', 'إيقاف'),
        showsUserInterface: true,
      ),
    ];
  }

  // ────────────────────────── داخلي ──────────────────────────

  Future<void> _schedule({
    required int notifId,
    required String title,
    required String body,
    required DateTime fire,
    required String importance,
    String? location,
    required String payload,
    bool isAlarm = false,
  }) async {
    final android = plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;

    final channelId = isAlarm
        ? _alarmChannelId
        : (channels[importance]?.$1 ?? 'reminders_normal');
    final channelName = isAlarm
        ? _tr('Event alarms', 'منبهات الأحداث')
        : (channels[importance]?.$2 ?? 'Reminders');
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        importance: isAlarm || importance == 'critical'
            ? Importance.max
            : Importance.high,
        priority: isAlarm ? Priority.max : Priority.high,
        icon: 'ic_notification',
        playSound: true,
        enableVibration: true,
        vibrationPattern:
            vibrationPatterns[importance] ?? vibrationPatterns['normal'],
        category: isAlarm
            ? AndroidNotificationCategory.alarm
            : AndroidNotificationCategory.reminder,
        actions: isAlarm
            ? _alarmActions()
            : [
                AndroidNotificationAction(
                  'open',
                  _tr('Open', 'فتح'),
                  showsUserInterface: true,
                ),
                AndroidNotificationAction(
                  'dismiss',
                  _tr('Dismiss', 'إيقاف'),
                  showsUserInterface: true,
                ),
              ],
      ),
    );

    final scheduled = tz.TZDateTime.from(fire, tz.local);
    try {
      await plugin.zonedSchedule(
        notifId,
        title,
        body,
        scheduled,
        details,
        androidScheduleMode: _exactAlarms
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
      if (isAlarm) {
        await SoundService.instance.scheduleBackgroundAlarm(
          alarmId: notifId,
          eventId: payload.split('|').first,
          title: title,
          location: location,
          importance: importance,
          fireAt: fire,
        );
      }
    } catch (error) {
      debugPrint(
        '[Notif] exact schedule failed id=$notifId error=$error; retrying inexact',
      );
      try {
        await plugin.zonedSchedule(
          notifId,
          title,
          body,
          scheduled,
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: payload,
        );
        if (isAlarm) {
          await SoundService.instance.scheduleBackgroundAlarm(
            alarmId: notifId,
            eventId: payload.split('|').first,
            title: title,
            location: location,
            importance: importance,
            fireAt: fire,
          );
        }
      } catch (retryError) {
        debugPrint('[Notif] schedule failed id=$notifId error=$retryError');
        rethrow;
      }
    }
  }

  /// Stable per (master event, offset, occurrence) across rescheduling.
  int _occurrenceNotifId(String eventId, int offsetMinutes, DateTime start) =>
      '$eventId#$offsetMinutes#${start.millisecondsSinceEpoch}'.hashCode &
      0x7fffffff;

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
