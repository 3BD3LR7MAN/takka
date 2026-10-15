import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/l10n.dart';
import '../../data/db.dart';
import '../../data/repositories.dart';
import '../../domain/event_engine.dart' show eventOverlapsDay;
import '../events/event_card.dart' show categoryColors;
import 'calendar_screen.dart' show weekStartFor;

const double _hourHeight = 52;
const int _middlePage = 500;

final weekEventsProvider = StreamProvider.family<List<Event>, DateTime>((
  ref,
  weekStart,
) {
  final end = DateTime(weekStart.year, weekStart.month, weekStart.day + 7);
  return ref.watch(eventRepositoryProvider).watchExpanded(weekStart, end);
});

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

DateTime weekStartOf(DateTime date, Locale locale) {
  final daysBack = (date.weekday - weekStartFor(locale) + 7) % 7;
  return DateTime(date.year, date.month, date.day - daysBack);
}

class WeekViewScreen extends ConsumerStatefulWidget {
  const WeekViewScreen({super.key, this.dateParam});
  final String? dateParam;

  @override
  ConsumerState<WeekViewScreen> createState() => _WeekViewScreenState();
}

class _WeekViewScreenState extends ConsumerState<WeekViewScreen> {
  late final PageController _pages;
  late final DateTime _requestedDate;
  DateTime? _baseWeek;
  Locale? _locale;
  int _visiblePage = _middlePage;

  @override
  void initState() {
    super.initState();
    _requestedDate =
        DateTime.tryParse(widget.dateParam ?? '') ?? DateTime.now();
    _pages = PageController(initialPage: _middlePage);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.localeOf(context);
    if (_baseWeek == null) {
      _baseWeek = weekStartOf(_requestedDate, locale);
      _locale = locale;
    } else if (_locale?.languageCode != locale.languageCode) {
      final visibleWeek = _weekForPage(_visiblePage);
      _baseWeek = weekStartOf(visibleWeek, locale);
      _locale = locale;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _pages.hasClients) _pages.jumpToPage(_middlePage);
      });
    }
  }

  DateTime _weekForPage(int page) {
    final base = _baseWeek!;
    final dayOffset = 7 * (page - _middlePage);
    return DateTime(base.year, base.month, base.day + dayOffset);
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final lang = langOf(context);
    final locale = Localizations.localeOf(context);
    final rtl = Directionality.of(context) == ui.TextDirection.rtl;
    final base = _baseWeek ?? weekStartOf(_requestedDate, locale);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.weekView),
        actions: [
          IconButton(
            tooltip: s.previousWeek,
            icon: Icon(
              rtl ? Icons.chevron_right_rounded : Icons.chevron_left_rounded,
            ),
            onPressed: () => _pages.previousPage(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
            ),
          ),
          IconButton(
            tooltip: s.nextWeek,
            icon: Icon(
              rtl ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
            ),
            onPressed: () => _pages.nextPage(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
            ),
          ),
        ],
      ),
      body: PageView.builder(
        controller: _pages,
        onPageChanged: (page) => _visiblePage = page,
        itemBuilder: (_, page) => _WeekPage(
          weekStart: DateTime(
            base.year,
            base.month,
            base.day + 7 * (page - _middlePage),
          ),
          lang: lang,
        ),
      ),
    );
  }
}

class _WeekPage extends ConsumerWidget {
  const _WeekPage({required this.weekStart, required this.lang});
  final DateTime weekStart;
  final String lang;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = AppStrings.of(context);
    final locale = Localizations.localeOf(context);
    final days = List<DateTime>.generate(
      7,
      (i) => DateTime(weekStart.year, weekStart.month, weekStart.day + i),
    );
    final weekEnd = DateTime(
      weekStart.year,
      weekStart.month,
      weekStart.day + 7,
    );
    final today = _day(DateTime.now());
    final now = DateTime.now();
    final async = ref.watch(weekEventsProvider(weekStart));

    return Column(
      children: [
        Row(
          children: [
            const SizedBox(width: 44),
            for (final day in days)
              Expanded(
                child: InkWell(
                  onTap: () => context.go(
                    '/today?date=${DateFormat('yyyy-MM-dd').format(day)}',
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    child: Column(
                      children: [
                        Text(
                          DateFormat.E(locale.languageCode).format(day),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          '${day.day}',
                          style: TextStyle(
                            fontWeight: _day(day) == today
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: _day(day) == today
                                ? Theme.of(context).colorScheme.primary
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
        const Divider(height: 1),
        Expanded(
          child: async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(s.loadFailed),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () =>
                        ref.invalidate(weekEventsProvider(weekStart)),
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(s.retry),
                  ),
                ],
              ),
            ),
            data: (events) => LayoutBuilder(
              builder: (context, constraints) {
                final columnWidth = (constraints.maxWidth - 44) / 7;
                final allDayEvents = events.where((e) => e.isAllDay).toList();
                final timedEvents = events.where((e) => !e.isAllDay).toList();
                final tiles = <Widget>[];

                for (final event in timedEvents) {
                  final start = DateTime.fromMillisecondsSinceEpoch(
                    event.startDt,
                  );
                  final end = DateTime.fromMillisecondsSinceEpoch(event.endDt);
                  var day =
                      _day(start).isBefore(weekStart) ? weekStart : _day(start);
                  while (day.isBefore(weekEnd) && day.isBefore(end)) {
                    final dayEnd = DateTime(day.year, day.month, day.day + 1);
                    if (start.isBefore(dayEnd) && end.isAfter(day)) {
                      final segmentStart = start.isAfter(day) ? start : day;
                      final segmentEnd = end.isBefore(dayEnd) ? end : dayEnd;
                      final dayIndex = _day(day).difference(weekStart).inDays;
                      if (dayIndex >= 0 && dayIndex < 7) {
                        final top =
                            (segmentStart.hour * 60 + segmentStart.minute) /
                                60 *
                                _hourHeight;
                        final bottomMinutes = segmentEnd == dayEnd
                            ? 24 * 60
                            : segmentEnd.hour * 60 + segmentEnd.minute;
                        final height = (bottomMinutes / 60 * _hourHeight - top)
                            .clamp(22.0, 24 * _hourHeight);
                        final color = categoryColors[event.category] ??
                            categoryColors['other']!;
                        tiles.add(
                          Positioned(
                            top: top,
                            height: height,
                            left: 44 + columnWidth * dayIndex + 1,
                            width: columnWidth - 2,
                            child: InkWell(
                              onTap: () => context.push('/event/${event.id}'),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: .2),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border(
                                    left: BorderSide(color: color, width: 3),
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 3,
                                ),
                                child: Text(
                                  event.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: color,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }
                    }
                    day = dayEnd;
                  }
                }

                return Column(
                  children: [
                    if (allDayEvents.isNotEmpty)
                      SizedBox(
                        height: 42,
                        child: Row(
                          children: [
                            const SizedBox(width: 44),
                            for (final day in days)
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(2),
                                  child: _AllDayCell(
                                    events: allDayEvents.where((event) {
                                      final start =
                                          DateTime.fromMillisecondsSinceEpoch(
                                        event.startDt,
                                      );
                                      final end =
                                          DateTime.fromMillisecondsSinceEpoch(
                                        event.endDt,
                                      );
                                      return eventOverlapsDay(
                                        start,
                                        end,
                                        day,
                                        DateTime(
                                          day.year,
                                          day.month,
                                          day.day + 1,
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    Expanded(
                      child: Directionality(
                        textDirection: ui.TextDirection.ltr,
                        child: SingleChildScrollView(
                          child: SizedBox(
                            height: 24 * _hourHeight,
                            child: Stack(
                              children: [
                                for (var hour = 0; hour < 24; hour++)
                                  Positioned(
                                    top: hour * _hourHeight,
                                    left: 0,
                                    right: 0,
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(
                                          width: 42,
                                          child: Text(
                                            '${hour.toString().padLeft(2, '0')}:00',
                                            style: const TextStyle(
                                              fontSize: 9,
                                              color: Colors.grey,
                                            ),
                                            textAlign: TextAlign.right,
                                          ),
                                        ),
                                        const Expanded(
                                          child: Divider(height: 1),
                                        ),
                                      ],
                                    ),
                                  ),
                                for (var i = 1; i < 7; i++)
                                  Positioned(
                                    top: 0,
                                    bottom: 0,
                                    left: 44 + columnWidth * i,
                                    child: const VerticalDivider(width: 1),
                                  ),
                                ...tiles,
                                if (days.any((day) => _day(day) == today))
                                  Positioned(
                                    top: (now.hour * 60 + now.minute) /
                                        60 *
                                        _hourHeight,
                                    left: 44,
                                    right: 0,
                                    child: const Divider(
                                      height: 2,
                                      color: Colors.red,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _AllDayCell extends StatelessWidget {
  const _AllDayCell({required this.events});
  final List<Event> events;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) return const SizedBox.shrink();
    final event = events.first;
    return Tooltip(
      message: events.map((e) => e.title).join('\n'),
      child: InkWell(
        onTap: () => context.push('/event/${event.id}'),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(5),
          ),
          child: Text(
            events.length == 1
                ? event.title
                : '${event.title} +${events.length - 1}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 9),
          ),
        ),
      ),
    );
  }
}
