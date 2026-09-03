import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';

import 'repositories.dart';

/// مزامنة ودجت "التالي" (2×1) — أفضل جهد، لا يكسر التطبيق أبدًا.
class WidgetUpdater {
  static const androidWidget = 'NextUpWidgetProvider';

  static Future<void> refresh(EventRepository repo) async {
    try {
      final lang = await _lang();
      final now = DateTime.now();
      final events = await repo.overlapping(
        now.subtract(const Duration(days: 1)),
        now.add(const Duration(days: 7)),
      );

      final timed = events.where((e) => !e.isAllDay).toList()
        ..sort((a, b) => a.startDt.compareTo(b.startDt));

      var badge = lang == 'ar' ? 'التالي' : 'NEXT';
      var title = lang == 'ar' ? 'لا شيء مخطط' : 'Nothing planned';
      var time = lang == 'ar' ? 'استمتع بوقتك ✨' : 'Enjoy your free time ✨';

      final ongoing = timed
          .where((e) =>
              e.startDt <= now.millisecondsSinceEpoch &&
              e.endDt > now.millisecondsSinceEpoch)
          .toList();

      if (ongoing.isNotEmpty) {
        final e = ongoing.first;
        badge = lang == 'ar' ? 'الآن' : 'NOW';
        title = e.title;
        time = '${_hm(e.startDt, lang)} – ${_hm(e.endDt, lang)}';
      } else {
        final upcoming = timed
            .where((e) => e.startDt > now.millisecondsSinceEpoch)
            .toList();
        if (upcoming.isNotEmpty) {
          final e = upcoming.first;
          final s = DateTime.fromMillisecondsSinceEpoch(e.startDt);
          title = e.title;
          time =
              '${_dayLabel(s, now, lang)} • ${_hm(e.startDt, lang)} – ${_hm(e.endDt, lang)}';
        }
      }

      await HomeWidget.saveWidgetData<String>('next_up_badge', badge);
      await HomeWidget.saveWidgetData<String>('next_up_title', title);
      await HomeWidget.saveWidgetData<String>('next_up_time', time);
      await HomeWidget.updateWidget(
        androidName: androidWidget,
        iOSName: 'NextUpWidget',
      );
    } catch (_) {
      // مزامنة الودجت أفضل جهد — صامتة عند الفشل
    }
  }

  static Future<String> _lang() async {
    try {
      final saved = await const FlutterSecureStorage().read(key: 'app_locale');
      return saved == 'ar' ? 'ar' : 'en';
    } catch (_) {
      return 'en';
    }
  }

  /// اليوم / غدًا بدل التاريخ الكامل.
  static String _dayLabel(DateTime target, DateTime now, String lang) {
    final t = DateTime(target.year, target.month, target.day);
    final today = DateTime(now.year, now.month, now.day);
    final diff = t.difference(today).inDays;
    if (diff == 0) return lang == 'ar' ? 'اليوم' : 'Today';
    if (diff == 1) return lang == 'ar' ? 'غدًا' : 'Tomorrow';
    if (diff < 0) return lang == 'ar' ? 'أمس' : 'Yesterday';
    return DateFormat('EEE d MMM', lang).format(t);
  }

  /// 12 ساعة — ص/م بالعربية، AM/PM بالإنجليزية.
  static String _hm(int ms, String lang) =>
      DateFormat('h:mm a', lang)
          .format(DateTime.fromMillisecondsSinceEpoch(ms));
}
