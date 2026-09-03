import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/l10n.dart';
import '../../data/db.dart';
import '../../data/repositories.dart' show dayOnly;
import '../../domain/event_engine.dart';
import '../../core/mascot/takka_mascot.dart';
import '../events/event_card.dart';
import 'providers.dart';
import 'task_checklist.dart';

const _middlePage = 10000;

class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key, this.dateParam});
  final String? dateParam;

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen> {
  late final PageController _pages;
  late DateTime _base;

  @override
  void initState() {
    super.initState();
    final initial = (widget.dateParam != null
            ? DateTime.tryParse(widget.dateParam!)
            : null) ??
        dayOnly(DateTime.now());
    _base = dayOnly(initial);
    _pages = PageController(initialPage: _middlePage);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(selectedDateProvider.notifier).state = _base;
    });
  }

  /// اختيار يوم من التقويم يغيّر dateParam بينما الـState موجودة —
  /// ننقل الـPageView مباشرة بدل انتظار إعادة التهيئة.
  @override
  void didUpdateWidget(covariant TodayScreen old) {
    super.didUpdateWidget(old);
    final p = widget.dateParam;
    if (p != null && p != old.dateParam) {
      final target = DateTime.tryParse(p);
      if (target != null) _goToDate(dayOnly(target));
    }
  }

  void _goToDate(DateTime target) {
    final page = _middlePage + dayOnly(target).difference(_base).inDays;
    final current = _pages.page?.round() ?? _middlePage;
    if ((page - current).abs() > 90) {
      _pages.jumpToPage(page);
    } else {
      _pages.animateToPage(page,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic);
    }
  }

  void _jumpBy(int deltaDays) => _pages.animateToPage(
      _pages.page!.round() + deltaDays,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut);

  @override
  Widget build(BuildContext context) {
    // زر Today مرتين → اليوم الحالي
    ref.listen(jumpToTodayProvider, (_, __) {
      _goToDate(dayOnly(DateTime.now()));
    });

    final s = AppStrings.of(context);
    final lang = langOf(context);
    final date = ref.watch(selectedDateProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(fmtFullDate(date, lang),
                style: const TextStyle(fontSize: 16)),
            if (dayOnly(DateTime.now()) == date)
              Text(s.today,
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          IconButton(
              tooltip: s.previousDay,
              icon: const Icon(Icons.chevron_left),
              onPressed: () => _jumpBy(-1)),
          IconButton(
              tooltip: s.nextDay,
              icon: const Icon(Icons.chevron_right),
              onPressed: () => _jumpBy(1)),
          IconButton(
              tooltip: s.calendar,
              icon: const Icon(Icons.calendar_month),
              onPressed: () => context.go('/calendar')),
          IconButton(
              tooltip: s.askAi,
              icon: const Icon(Icons.auto_awesome),
              onPressed: () => context.push('/ai')),
          const SizedBox(width: 4),
        ],
      ),
      body: PageView.builder(
        controller: _pages,
        onPageChanged: (page) {
          final d = _base.add(Duration(days: page - _middlePage));
          ref.read(selectedDateProvider.notifier).state = d;
        },
        itemBuilder: (_, page) =>
            DayTimeline(day: _base.add(Duration(days: page - _middlePage))),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(
            '/event/add?date=${DateFormat('yyyy-MM-dd').format(date)}'),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class DayTimeline extends ConsumerStatefulWidget {
  const DayTimeline({super.key, required this.day});
  final DateTime day;

  @override
  ConsumerState<DayTimeline> createState() => _DayTimelineState();
}

class _DayTimelineState extends ConsumerState<DayTimeline> {
  static const hourHeight = 64.0;
  final _scroll = ScrollController();
  Timer? _ticker;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToNow());
  }

  void _scrollToNow() {
    if (!_scroll.hasClients) return;
    final isToday = dayOnly(widget.day) == dayOnly(DateTime.now());
    final target = isToday ? _now.hour * hourHeight - 120 : 0.0;
    _scroll.jumpTo(target.clamp(0.0, _scroll.position.maxScrollExtent));
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final asyncEvents = ref.watch(dayEventsProvider(widget.day));
    final dayStart = dayOnly(widget.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    final isToday = dayStart == dayOnly(DateTime.now());

    return asyncEvents.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (events) {
        if (events.isEmpty) return _emptyState(context, s);

        final allDay = events.where((e) => e.isAllDay).toList();
        final timed = events.where((e) => !e.isAllDay).toList();
        final nowOffset = (_now.hour * 60 + _now.minute) / 60 * hourHeight;

        return Stack(
          children: [
            ListView(
              controller: _scroll,
              children: [
                TaskChecklist(day: widget.day),
                if (allDay.isNotEmpty) _allDayStrip(allDay),
                SizedBox(
                  height: 24 * hourHeight,
                  // شبكة الوقت تبقى LTR دائمًا حتى داخل الواجهة العربية
                  child: Directionality(
                    textDirection: ui.TextDirection.ltr,
                    child: Stack(
                      children: [
                        for (var h = 0; h < 24; h++)
                          Positioned(
                            top: h * hourHeight,
                            left: 0,
                            right: 0,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 52,
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      '${h.toString().padLeft(2, '0')}:00',
                                      style: const TextStyle(
                                          fontSize: 11, color: Colors.grey),
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                ),
                                Expanded(
                                    child: Divider(
                                        height: 1,
                                        color: Theme.of(context)
                                            .dividerColor
                                            .withOpacity(.35))),
                              ],
                            ),
                          ),
                        ..._buildTimed(timed, dayStart, dayEnd),
                        if (isToday)
                          Positioned(
                            top: nowOffset - 1,
                            left: 48,
                            right: 0,
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle),
                                ),
                                const Expanded(
                                    child:
                                        Divider(height: 2, color: Colors.red)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (isToday) _jumpToNow(s),
          ],
        );
      },
    );
  }

  List<Widget> _buildTimed(
      List<Event> timed, DateTime dayStart, DateTime dayEnd) {
    final lanes = assignLanes(timed);
    final width = MediaQuery.sizeOf(context).width;
    final widgets = <Widget>[];
    for (final e in timed) {
      final seg = segmentsForDay(e, dayStart, dayEnd).first;
      final top = (seg.start.hour * 60 + seg.start.minute) / 60 * hourHeight;
      final endMinutes =
          seg.end == dayEnd ? 24 * 60 : seg.end.hour * 60 + seg.end.minute;
      final height =
          ((endMinutes / 60 * hourHeight) - top).clamp(28.0, 24 * hourHeight);
      final (lane, total) = lanes[e.id] ?? (0, 1);
      widgets.add(
        Positioned(
          top: top,
          height: height,
          left: 56 + (width - 72) / total * lane,
          width: (width - 72) / total,
          child: EventCard(
            event: e,
            segment: seg,
            onTap: () => context.push('/event/${e.id}'),
          ),
        ),
      );
    }
    return widgets;
  }

  Widget _allDayStrip(List<Event> allDay) => Container(
        margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
        child: Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            for (final e in allDay)
              ActionChip(
                label: Text(e.title),
                onPressed: () => context.push('/event/${e.id}'),
              ),
          ],
        ),
      );

  Widget _jumpToNow(AppStrings s) => Align(
        alignment: AlignmentDirectional.bottomEnd,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FloatingActionButton.small(
            heroTag: 'jump-now',
            tooltip: s.today,
            onPressed: _scrollToNow,
            child: const Icon(Icons.my_location),
          ),
        ),
      );

  Widget _emptyState(BuildContext context, AppStrings s) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TaskChecklist(day: widget.day),
            const SizedBox(height: 24),
            const TakkaMascot(mood: TakkaMood.sleepy, size: 150),
            const SizedBox(height: 4),
            Text(s.takkaSleepy, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => context.push('/event/add'),
              icon: const Icon(Icons.add),
              label: Text(s.addEvent),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => context.push('/ai'),
              icon: const Icon(Icons.auto_awesome),
              label: Text(s.askAi),
            ),
          ],
        ),
      );
}
