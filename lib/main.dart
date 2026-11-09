import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/l10n.dart';
import 'core/navigator.dart';
import 'core/router.dart';
import 'core/sound_service.dart';
import 'core/theme.dart';
import 'data/app_update_service.dart';
import 'data/db.dart';
import 'data/notification_service.dart';
import 'data/repositories.dart';
import 'data/widget_updater.dart';
import 'features/settings/settings_screen.dart';
import 'features/settings/update_dialog.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await initializeDateFormatting().timeout(const Duration(seconds: 3));
  } catch (error, stackTrace) {
    debugPrint(
      '[Startup] date locale initialization failed: $error\n$stackTrace',
    );
  }

  final db = AppDatabase();
  final repo = EventRepository(db);

  // اللغة المحفوظة (فارغ = لغة النظام)
  String? saved;
  String? savedTheme;
  String? savedDefaultEventAlarm;
  try {
    const storage = FlutterSecureStorage();
    final values = await Future.wait<String?>([
      storage.read(key: 'app_locale'),
      storage.read(key: 'theme_mode'),
      storage.read(key: 'default_event_alarm'),
    ]).timeout(const Duration(seconds: 3));
    saved = values[0];
    savedTheme = values[1];
    savedDefaultEventAlarm = values[2];
  } catch (error, stackTrace) {
    debugPrint('[Startup] saved preferences read failed: $error\n$stackTrace');
  }
  final initialLocale = switch (saved) {
    'ar' => const Locale('ar'),
    'en' => const Locale('en'),
    _ => null,
  };
  final initialThemeMode = switch (savedTheme) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };
  final initialDefaultEventAlarm = savedDefaultEventAlarm != 'false';

  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        eventRepositoryProvider.overrideWithValue(repo),
        if (initialLocale != null)
          appLocaleProvider.overrideWith((ref) => initialLocale),
        themeModeProvider.overrideWith((ref) => initialThemeMode),
        defaultEventAlarmProvider.overrideWith(
          (ref) => initialDefaultEventAlarm,
        ),
      ],
      child: TakkaApp(repo: repo),
    ),
  );

  // Plugins and notification rescheduling are nonessential to the first frame.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(_initializeAfterFirstFrame(repo));
  });
}

Future<void> _initializeAfterFirstFrame(EventRepository repo) async {
  // Optional audio/storage setup must never gate notification startup.
  unawaited(_initializeSoundService());

  // Keep the widget useful even if notification setup fails on this device.
  unawaited(WidgetUpdater.refresh(repo));
  Timer.periodic(
    const Duration(minutes: 1),
    (_) => unawaited(WidgetUpdater.refresh(repo)),
  );

  try {
    await NotificationService.instance.init(
      onOpenEvent: (eventId, isAlarm) async {
        final event = await repo.getEvent(eventId);
        if (event != null &&
            isAlarm &&
            SoundService.instance.activeAlarm.value?.eventId != event.id) {
          SoundService.instance.triggerAlarm(
            eventId: event.id,
            title: event.title,
            location: event.location,
            time: DateTime.fromMillisecondsSinceEpoch(event.startDt),
            importance: event.importance,
          );
        }
        rootNavigatorKey.currentContext?.push('/event/$eventId');
      },
      onSnoozeAlarm: (eventId) => _snoozeAlarmFromNotification(repo, eventId),
    );
    await NotificationService.instance.rescheduleAll(repo);
    // Ask after plugin startup and scheduling; readiness must not depend on a
    // permission dialog being answered.
    unawaited(NotificationService.instance.ensurePermissions());
  } catch (error, stackTrace) {
    debugPrint(
      '[Startup] notification initialization failed: $error\n$stackTrace',
    );
  }
}

Future<void> _initializeSoundService() async {
  try {
    await SoundService.instance.init();
  } catch (error, stackTrace) {
    debugPrint('[Startup] sound initialization failed: $error\n$stackTrace');
  }
}

Future<void> _snoozeAlarmFromNotification(
  EventRepository repo,
  String eventId,
) async {
  final event = await repo.getEvent(eventId);
  if (event == null) return;
  final minutes = SoundService.instance.snoozeDurationMinutes;
  try {
    await NotificationService.instance.scheduleSnoozeAlarm(
      eventId: event.id,
      title: event.title,
      location: event.location,
      importance: event.importance,
      minutes: minutes,
    );
  } catch (error, stackTrace) {
    debugPrint(
      '[Notif] snooze action could not schedule alarm: $error\n$stackTrace',
    );
  }
  if (SoundService.instance.activeAlarm.value?.eventId == event.id) {
    SoundService.instance.snoozeAlarm(minutes: minutes);
  } else {
    await NotificationService.instance.cancelActiveAlarmNotification();
  }
}

/// مدخل headless — يستدعيه BootReceiver بعد إعادة تشغيل الجهاز (مواصفة G).
@pragma('vm:entry-point')
Future<void> rescheduleNotifications() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = AppDatabase();
  await NotificationService.instance.init();
  await NotificationService.instance.reschedulePending(db);
}

class TakkaApp extends ConsumerStatefulWidget {
  const TakkaApp({super.key, required this.repo});
  final EventRepository repo;

  @override
  ConsumerState<TakkaApp> createState() => _TakkaAppState();
}

class _TakkaAppState extends ConsumerState<TakkaApp>
    with WidgetsBindingObserver {
  AlarmState? _lastAlarm;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lastAlarm = SoundService.instance.activeAlarm.value;
    SoundService.instance.activeAlarm.addListener(_syncActiveAlarmNotification);
    if (_lastAlarm != null) {
      unawaited(
        NotificationService.instance.showActiveAlarmNotification(_lastAlarm!),
      );
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_checkForUpdatesAutomatically());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    SoundService.instance.activeAlarm.removeListener(
      _syncActiveAlarmNotification,
    );
    super.dispose();
  }

  void _syncActiveAlarmNotification() {
    final alarm = SoundService.instance.activeAlarm.value;
    if (alarm == null) {
      if (_lastAlarm != null) {
        unawaited(NotificationService.instance.cancelActiveAlarmNotification());
      }
    } else {
      unawaited(
          NotificationService.instance.showActiveAlarmNotification(alarm));
    }
    _lastAlarm = alarm;
  }

  Future<void> _checkForUpdatesAutomatically() async {
    try {
      final release = await AppUpdateService.instance.checkAutomatically();
      if (release == null || !mounted) return;
      final context = rootNavigatorKey.currentContext;
      if (context == null || !context.mounted) return;
      await AppUpdateService.instance
          .markAutomaticallyPrompted(release.tagName);
      if (!mounted || !context.mounted) return;
      await showUpdateAvailableDialog(context, release);
    } catch (error, stackTrace) {
      // Automatic update checks are best-effort; never interrupt normal use.
      debugPrint(
          '[Update] automatic release check failed: $error\n$stackTrace');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      WidgetUpdater.refresh(widget.repo);
      unawaited(_refreshNotificationsOnResume());
    }
  }

  Future<void> _refreshNotificationsOnResume() async {
    // Timezone refresh also reschedules events when the zone actually changed.
    // Run the ordinary refresh only otherwise, so the two passes never race.
    final timezoneChanged = await NotificationService.instance
        .rescheduleIfTimezoneChanged(widget.repo);
    if (!timezoneChanged) {
      await NotificationService.instance.rescheduleAll(widget.repo);
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final mode = ref.watch(themeModeProvider);
    final locale = ref.watch(appLocaleProvider);
    return MaterialApp.router(
      title: 'Takka',
      debugShowCheckedModeBanner: false,
      locale: locale,
      supportedLocales: const [Locale('en'), Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: mode,
      routerConfig: router,
    );
  }
}
