import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// null = لغة النظام
final appLocaleProvider = StateProvider<Locale?>((_) => null);

String langOf(BuildContext context) =>
    Localizations.localeOf(context).languageCode;

String fmtFullDate(DateTime d, String lang) =>
    DateFormat('EEEE, d MMMM yyyy', lang).format(d);
String fmtShortDate(DateTime d, String lang) =>
    DateFormat('EEE, d MMM', lang).format(d);
String fmtDateTime(DateTime d, String lang) =>
    DateFormat('EEE, d MMM • h:mm a', lang).format(d);
String fmtTime(DateTime d, String lang) =>
    DateFormat('h:mm a', lang).format(d);
String fmtMonthYear(DateTime d, String lang) =>
    DateFormat('MMMM yyyy', lang).format(d);
String fmtTimeOfDay(TimeOfDay t, String lang) =>
    DateFormat('h:mm a', lang).format(DateTime(2000, 1, 1, t.hour, t.minute));

class AppStrings {
  final bool ar;
  const AppStrings._(this.ar);

  static AppStrings of(BuildContext context) =>
      AppStrings._(Localizations.localeOf(context).languageCode == 'ar');

  String _t(String en, String a) => ar ? a : en;

  // Navigation
  String get today => _t('Today', 'اليوم');
  String get calendar => _t('Calendar', 'التقويم');
  String get settings => _t('Settings', 'الإعدادات');

  // Today
  String get previousDay => _t('Previous day', 'اليوم السابق');
  String get nextDay => _t('Next day', 'اليوم التالي');
  String get askAi => _t('Ask AI', 'اسأل الذكاء الاصطناعي');
  String get addEvent => _t('Add Event', 'إضافة حدث');
  String get nothingPlanned =>
      _t('Nothing planned for this day yet.', 'لا يوجد شيء مخطط لهذا اليوم بعد.');

  // Tasks
  String get tasks => _t('Tasks', 'المهام');
  String get addTaskHint => _t('Add a task…', 'أضف مهمة…');
  String get noDate => _t('No date', 'بدون تاريخ');

  // Calendar
  String get jumpToCurrentMonth => _t('Jump to current month', 'الانتقال إلى الشهر الحالي');
  String get noEventsThisMonth => _t(
      'No events this month — add one from the Today screen',
      'لا أحداث هذا الشهر — أضف حدثًا من شاشة اليوم');
  String scheduledCount(int n) => ar
      ? '$n ${n == 1 ? 'حدث مجدول' : n == 2 ? 'حدثان مجدولان' : 'أحداث مجدولة'} هذا الشهر'
      : '$n scheduled ${n == 1 ? 'event' : 'events'} this month';

  // Add/Edit
  String get editEvent => _t('Edit Event', 'تعديل الحدث');
  String get titleField => _t('Title *', 'العنوان *');
  String get titleRequired => _t('Title is required', 'العنوان مطلوب');
  String get allDay => _t('All-day', 'طوال اليوم');
  String get start => _t('Start', 'البداية');
  String get end => _t('End', 'النهاية');
  String get endAfterStart => _t('End must be after start', 'يجب أن تكون النهاية بعد البداية');
  String get typeTimeHint => _t('Type time (e.g. 9:30 ص / 9:30 pm)', 'اكتب الوقت (مثال: 9:30 ص / 9:30 م)');
  String get category => _t('Category', 'التصنيف');
  String get reminders => _t('Reminders', 'التذكيرات');
  String get importance => _t('Importance', 'الأهمية');
  String get locationOptional => _t('Location (optional)', 'الموقع (اختياري)');
  String get descriptionOptional => _t('Description (optional)', 'الوصف (اختياري)');
  String get save => _t('Save', 'حفظ');
  String get cancel => _t('Cancel', 'إلغاء');
  String get delete => _t('Delete', 'حذف');
  String get edit => _t('Edit', 'تعديل');
  String get keepBoth => _t('Keep Both', 'إبقاء الاثنين');
  String get deleteEventQuestion => _t('Delete event?', 'حذف الحدث؟');
  String deleteEventBody(String t) =>
      ar ? 'سيتم حذف «$t» نهائيًا.' : '"$t" will be permanently removed.';
  String get conflictTitle => _t('Time conflict', 'تعارض في الوقت');
  String get conflictsWith => _t('This overlaps with:', 'يتعارض مع:');
  String get atStart => _t('At start', 'عند البدء');
  String get autoAtStartNote => _t(
      'An at-start reminder is added automatically',
      'يُضاف تذكير عند البدء تلقائيًا');
  String reminderBefore(int minutes) {
    if (minutes < 60) return ar ? 'قبل $minutes دقيقة' : '$minutes min before';
    if (minutes < 1440) return ar ? 'قبل ${minutes ~/ 60} ساعة' : '${minutes ~/ 60} hour(s) before';
    return ar ? 'قبل ${minutes ~/ 1440} يوم' : '${minutes ~/ 1440} day(s) before';
  }

  String categoryName(String key) => switch (key) {
        'study' => ar ? 'دراسة' : 'study',
        'work' => ar ? 'عمل' : 'work',
        'personal' => ar ? 'شخصي' : 'personal',
        'university' => ar ? 'جامعة' : 'university',
        'exercise' => ar ? 'تمرين' : 'exercise',
        'meeting' => ar ? 'اجتماع' : 'meeting',
        'important' => ar ? 'مهم' : 'important',
        _ => ar ? 'أخرى' : 'other',
      };

  String importanceName(String key) => switch (key) {
        'important' => ar ? 'مهم' : 'IMPORTANT',
        'critical' => ar ? 'حاسم' : 'CRITICAL',
        _ => ar ? 'عادي' : 'NORMAL',
      };

  // Details
  String get remindersSection => _t('REMINDERS', 'التذكيرات');
  String get noReminders => _t('No reminders', 'لا تذكيرات');
  String get fired => _t('fired', 'تم');
  String get testNotification => _t('Test notification', 'تجربة الإشعار');
  String get testNotificationHint => _t('Fires one instantly to verify', 'يرسل إشعارًا فوريًا للتحقق');
  String get exactAlarmWarning => _t(
      '⚠️ Exact-alarm permission is off — reminders may arrive slightly late. Enable it in Android Settings → Apps → Takka → Alarms & reminders.',
      '⚠️ إذن المنبه الدقيق معطّل — قد تصل التذكيرات متأخرة قليلًا. فعّله من: إعدادات أندرويد ← التطبيقات ← مدير الوقت ← المنبهات والتذكيرات.');
  String get addedByAi => _t('Added by AI', 'أُضيف بواسطة الذكاء الاصطناعي');
  String get addedManually => _t('Added manually', 'أُضيف يدويًا');
  String get eventNotFound => _t('This event no longer exists.', 'هذا الحدث لم يعد موجودًا.');
  String get backToToday => _t('Back to Today', 'العودة إلى اليوم');

  // AI
  String get sendToAi => _t('Send to AI', 'إرسال إلى الذكاء الاصطناعي');
  String get offlineAi => _t('Offline — AI unavailable', 'غير متصل — الذكاء الاصطناعي غير متاح');
  String get configureAiFirst => _t('Configure AI in Settings', 'اضبط الذكاء الاصطناعي من الإعدادات');
  String get aiHint => _t(
      'e.g. "Tomorrow I have a meeting at 10am, then gym at 6pm for an hour. Remind me 15 min before. Tasks: buy milk"',
      'مثال: «غدًا اجتماع 10 صباحًا ثم الجيم 6 مساءً لمدة ساعة، ذكرني قبلها بـ15 دقيقة. مهام: شراء حليب»');
  String get micUnavailable => _t('Microphone unavailable', 'الميكروفون غير متاح');
  String get timeoutKept => _t(
      'AI request timed out. Your text was kept — try again.',
      'انتهت مهلة الطلب. تم الاحتفاظ بنصك — حاول مجددًا.');
  String aiError(String m) => ar ? 'خطأ في الذكاء الاصطناعي: $m' : 'AI error: $m';
  String get confirmSuggestions => _t('Confirm AI suggestions', 'تأكيد اقتراحات الذكاء الاصطناعي');
  String get noExtractions => _t('No events were extracted.', 'لم يتم استخراج أي أحداث.');
  String get noTimeSpecified => _t('⚠️ No time specified', '⚠️ لم يُحدد وقت');
  String get setTime => _t('Set time', 'تحديد الوقت');
  String get addSelected => _t('Add Selected', 'إضافة المحدد');
  String get aiSuggestedTime => _t('AI-suggested time', 'وقت مقترح من الذكاء الاصطناعي');

  // Takka the mascot
  String get takkaName => _t('Takka', 'تكّة');
  String get takkaIdle => _t("Hi! I'm Takka — your day, on time.", 'أهلًا! أنا تكّة — يومك في وقته.');
  String get takkaSleepy => _t('Nothing planned… enjoy the calm ☕', 'لا شيء مخطط… استمتع بالهدوء ☕');
  String get takkaHappy => _t('Amazing! Everything is done ✓', 'رائع! كل شيء منجز ✓');
  String get takkaThinking => _t('Thinking…', 'أفكّر…');
  String get takkaAlert => _t("Careful — there's a time conflict!", 'انتبه — يوجد تعارض في الوقت!');

  // Settings
  String get appearance => _t('APPEARANCE', 'المظهر');
  String get systemTheme => _t('System theme', 'مظهر النظام');
  String get light => _t('Light', 'فاتح');
  String get dark => _t('Dark', 'داكن');
  String get language => _t('LANGUAGE', 'اللغة');
  String get langSystem => _t('System', 'النظام');
  String get langEnglish => _t('English', 'English');
  String get langArabic => _t('العربية', 'العربية');
  String get aiProvider => _t('AI PROVIDER', 'مزوّد الذكاء الاصطناعي');
  String get provider => _t('Provider', 'المزوّد');
  String get model => _t('Model', 'النموذج');
  String get baseUrl => _t('Base URL', 'عنوان الأساس');
  String get baseUrlHint => _t(
      'Ollama emulator: http://10.0.2.2:11434/v1 • device: http://<PC-IP>:11434/v1',
      'محاكي Ollama: http://10.0.2.2:11434/v1 • الجهاز: http://<PC-IP>:11434/v1');
  String get apiKey => _t('API Key', 'مفتاح API');
  String get apiKeyOptional => _t('API Key (optional for local)', 'مفتاح API (اختياري للمحلي)');
  String get apiKeyHint => _t(
      'Stored in Android Keystore. MVP only — production needs a backend proxy.',
      'يُخزَّن في Android Keystore. مناسب للتجربة — للإنتاج يلزم وسيط خلفي.');
  String get saveAiSettings => _t('Save AI Settings', 'حفظ إعدادات الذكاء الاصطناعي');
  String get saving => _t('Saving…', 'جارٍ الحفظ…');
  String get aiSettingsSaved => _t('AI settings saved.', 'تم حفظ إعدادات الذكاء الاصطناعي.');
  String get appName => _t('Takka', 'Takka');
  String get appSubtitle =>
      _t('Local-first schedule engine with AI layer', 'محرك جدولة محلي مع طبقة ذكاء اصطناعي');
  String get developer => _t('DEVELOPER', 'المطوّر');
  String get sourceCode => _t('Source code', 'الكود المصدري');
  String get connectMe => _t('Connect with me', 'تواصل معي');
  String get baseUrlAutoFilled => _t('Auto-filled for this provider. Edit if you use a proxy.', 'مُعبّأ تلقائيًا لهذا المزوّد. عدّله لو تستخدم وسيطًا.');
  String get modelAutoFilled => _t('Default model for this provider. You can change it.', 'النموذج الافتراضي لهذا المزوّد. يمكنك تغييره.');
  String get modelHint => _t('Enter the model identifier supplied by the endpoint.', 'أدخل معرّف النموذج الذي يقدمه الـendpoint.');

  // Notification diagnostics
  String get notifDiagnostics => _t('Notification diagnostics', 'تشخيص الإشعارات');
  String get exactAlarms => _t('Exact alarms', 'المنبهات الدقيقة');
  String get enabled => _t('Enabled ✓', 'مفعّلة ✓');
  String get disabledFix => _t('Disabled — tap Fix', 'معطّلة — اضغط إصلاح');
  String get fixAction => _t('Fix', 'إصلاح');
  String get batteryOptimization => _t('Battery optimization', 'تحسين البطارية');
  String get exempted => _t('Exempted ✓', 'مستثنى ✓');
  String get notExempted => _t('Not exempted — alarms may be killed', 'غير مستثنى — قد تُلغى التنبيهات');
  String get requestExemption => _t('Request', 'طلب');
  String get autostart => _t('Autostart (Xiaomi/Huawei/Oppo/Vivo/Samsung)', 'التشغيل التلقائي (شاومي/هواوي/أوبو/فيفو/سامسونج)');
  String get openAction => _t('Open', 'فتح');
  String get pendingAlarms => _t('Pending scheduled alarms', 'التنبيهات المجدولة القادمة');
  String get rescheduleAll => _t('Reschedule all notifications', 'إعادة جدولة كل التنبيهات');
  String get testIn15 => _t('Test scheduling (fires in 15 seconds)', 'اختبار الجدولة (يظهر بعد 15 ثانية)');
  String get testHint => _t('Minimize the app (do NOT close it) and wait 15–20 seconds.', 'صغّر التطبيق (لا تُغلقه) وانتظر 15–20 ثانية.');
  String get doneMsg => _t('Done', 'تم');
}
