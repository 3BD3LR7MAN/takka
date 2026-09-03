import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/l10n.dart';
import '../../data/db.dart';
import '../../data/repositories.dart';
import '../today/providers.dart';

final monthEventsProvider = StreamProvider.family<List<Event>, DateTime>(
  (ref, month) {
    final db = ref.watch(databaseProvider);
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1);
    return db.watchOverlapping(
        start.millisecondsSinceEpoch, end.millisecondsSinceEpoch);
  },
);

/// تقاطعات حدث-يوم (مواصفة C.2): حدث 3 أيام يُحسب 3.
Map<int, int> monthEventCounts(List<Event> events, DateTime month) {
  final firstOfMonth = DateTime(month.year, month.month, 1);
  final firstOfNext = DateTime(month.year, month.month + 1, 1);
  final counts = <int, int>{};
  for (final e in events) {
    final s = DateTime.fromMillisecondsSinceEpoch(e.startDt);
    final en = DateTime.fromMillisecondsSinceEpoch(e.endDt);
    var day = s.isBefore(firstOfMonth)
        ? firstOfMonth
        : DateTime(s.year, s.month, s.day);
    final cap = en.isAfter(firstOfNext) ? firstOfNext : en;
    while (day.isBefore(cap)) {
      counts[day.day] = (counts[day.day] ?? 0) + 1;
      day = DateTime(day.year, day.month, day.day + 1);
    }
  }
  return counts;
}

DateTime addMonths(DateTime m, int n) => DateTime(m.year, m.month + n);

/// العربية: الأسبوع يبدأ السبت — غيرها: الأحد.
int weekStartFor(Locale l) =>
    l.languageCode == 'ar' ? DateTime.saturday : DateTime.sunday;

const _middlePage = 10000;

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late final PageController _pages;
  late final DateTime _baseMonth;
  late DateTime _currentMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _baseMonth = DateTime(now.year, now.month);
    _currentMonth = _baseMonth;
    _pages = PageController(initialPage: _middlePage);
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _goToCurrentMonth() {
    final now = DateTime.now();
    final page = _middlePage +
        (now.year - _baseMonth.year) * 12 +
        (now.month - _baseMonth.month);
    final dist = (page - (_pages.page?.round() ?? _middlePage)).abs();
    if (dist > 6) {
      _pages.jumpToPage(page);
    } else {
      _pages.animateToPage(page,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final lang = langOf(context);
    final locale = Localizations.localeOf(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(fmtMonthYear(_currentMonth, lang)),
        actions: [
          IconButton(
            tooltip: s.jumpToCurrentMonth,
            icon: const Icon(Icons.today),
            onPressed: _goToCurrentMonth,
          ),
        ],
      ),
      body: Column(
        children: [
          _WeekdayHeader(locale: locale),
          const Divider(height: 1),
          Expanded(
            // التنقل بين الشهور بالسحب يمينًا/يسارًا
            child: PageView.builder(
              controller: _pages,
              onPageChanged: (p) => setState(
                  () => _currentMonth = addMonths(_baseMonth, p - _middlePage)),
              itemBuilder: (_, p) =>
                  _MonthPage(month: addMonths(_baseMonth, p - _middlePage)),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekdayHeader extends StatelessWidget {
  const _WeekdayHeader({required this.locale});
  final Locale locale;

  @override
  Widget build(BuildContext context) {
    final ws = weekStartFor(locale);
    final mondayRef = DateTime(2024, 1, 1); // الاثنين
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          for (var k = 0; k < 7; k++)
            SizedBox(
              width: 44,
              child: Center(
                child: Text(
                  DateFormat.E(locale.languageCode).format(
                      mondayRef.add(Duration(days: (ws - 1 + k) % 7))),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MonthPage extends ConsumerWidget {
  const _MonthPage({required this.month});
  final DateTime month;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = AppStrings.of(context);
    final locale = Localizations.localeOf(context);
    final scheme = Theme.of(context).colorScheme;

    final eventsAsync = ref.watch(monthEventsProvider(month));
    final events = eventsAsync.valueOrNull ?? const <Event>[];
    final counts = monthEventCounts(events, month);
    final total = counts.values.fold<int>(0, (a, b) => a + b);

    final firstOfMonth = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final ws = weekStartFor(locale);
    final leading = (firstOfMonth.weekday - ws + 7) % 7;
    final today = DateTime.now();

    return Column(
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: total == 0
                ? Colors.grey.withOpacity(.12)
                : scheme.primaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(total == 0 ? Icons.event_available : Icons.event_note,
                  size: 18, color: scheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  total == 0 ? s.noEventsThisMonth : s.scheduledCount(total),
                  style: TextStyle(
                      fontSize: 13, color: scheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: eventsAsync.isLoading
              ? const Center(child: CircularProgressIndicator())
              : GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7, childAspectRatio: 0.9),
                  itemCount: leading + daysInMonth,
                  itemBuilder: (context, i) {
                    if (i < leading) return const SizedBox.shrink();

                    final dayNum = i - leading + 1;
                    final day = DateTime(month.year, month.month, dayNum);
                    final count = counts[dayNum] ?? 0;
                    final isToday = day.year == today.year &&
                        day.month == today.month &&
                        day.day == today.day;

                    return InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        ref.read(selectedDateProvider.notifier).state = day;
                        context.go(
                            '/today?date=${DateFormat('yyyy-MM-dd').format(day)}');
                      },
                      child: Container(
                        margin: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: count > 0
                              ? scheme.primaryContainer.withOpacity(.45)
                              : null,
                          border: isToday
                              ? Border.all(color: scheme.primary, width: 1.5)
                              : null,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '$dayNum',
                              style: TextStyle(
                                fontWeight: isToday
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isToday ? scheme.primary : null,
                              ),
                            ),
                            const SizedBox(height: 3),
                            count > 0
                                ? Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: scheme.primary,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '$count',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  )
                                : const SizedBox(height: 18),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
