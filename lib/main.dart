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
import 'core/theme.dart';
import 'data/db.dart';
import 'data/notification_service.dart';
import 'data/repositories.dart';
import 'data/widget_updater.dart';
import 'features/settings/settings_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting(); // بيانات التواريخ العربية (ص/م)

  final db = AppDatabase();
  final repo = EventRepository(db);

  await NotificationService.instance.init(
    onOpenEvent: (eventId) =>
        rootNavigatorKey.currentContext?.push('/event/$eventId'),
  );
  // Repair OS alarms for existing upcoming events after process death or reinstall.
  await NotificationService.instance.rescheduleAll(repo);

  // ودجت "التالي": مزامنة أولية + تحديث دوري أثناء فتح التطبيق
  await WidgetUpdater.refresh(repo);
  Timer.periodic(const Duration(minutes: 1), (_) => WidgetUpdater.refresh(repo));

  // اللغة المحفوظة (فارغ = لغة النظام)
  final saved = await const FlutterSecureStorage().read(key: 'app_locale');
  final initialLocale = switch (saved) {
    'ar' => const Locale('ar'),
    'en' => const Locale('en'),
    _ => null,
  };

  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        eventRepositoryProvider.overrideWithValue(repo),
        if (initialLocale != null)
          appLocaleProvider.overrideWith((ref) => initialLocale),
      ],
      child: TakkaApp(repo: repo),
    ),
  );
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await NotificationService.instance.ensurePermissions();
      await NotificationService.instance.rescheduleAll(widget.repo);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      WidgetUpdater.refresh(widget.repo);
      NotificationService.instance.rescheduleAll(widget.repo);
      // مواصفة R — تغيّرت المنطقة الزمنية → إعادة جدولة التنبيهات القادمة
      NotificationService.instance.rescheduleIfTimezoneChanged(widget.repo);
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
