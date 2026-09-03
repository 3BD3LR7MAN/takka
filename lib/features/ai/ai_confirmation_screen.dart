import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/l10n.dart';
import '../../data/repositories.dart';
import 'providers.dart';

const _importances = ['normal', 'important', 'critical'];

class AiConfirmationScreen extends ConsumerWidget {
  const AiConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = AppStrings.of(context);
    final lang = langOf(context);
    final proposals = ref.watch(proposedEventsProvider);
    final tasks = ref.watch(proposedTasksProvider);
    final hasAnything = proposals.isNotEmpty || tasks.isNotEmpty;

    Future<void> saveSelected() async {
      final repo = ref.read(eventRepositoryProvider);
      for (final p in proposals.where((p) => p.selected)) {
        final noTime = p.timeMissing || p.start == null;
        await repo.save(
          title: p.title,
          start: p.start ?? DateTime.now(),
          end: p.end ??
              (p.start ?? DateTime.now()).add(const Duration(hours: 1)),
          isAllDay: noTime ? true : p.isAllDay,
          category: p.category,
          location: p.location,
          description: p.description,
          importance: p.importance,
          reminderOffsets: p.reminders,
          source: 'ai',
        );
      }
      for (final t in tasks.where((t) => t.selected)) {
        await repo.addTask(title: t.title, due: t.dueDate);
      }
      if (context.mounted) context.go('/today');
    }

    return Scaffold(
      appBar: AppBar(title: Text(s.confirmSuggestions)),
      body: !hasAnything
          ? Center(child: Text(s.noExtractions))
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      for (var i = 0; i < proposals.length; i++)
                        _EventCard(index: i, lang: lang),
                      if (tasks.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
                          child: Row(
                            children: [
                              const Icon(Icons.checklist, size: 18),
                              const SizedBox(width: 8),
                              Text(s.tasks,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                        for (var i = 0; i < tasks.length; i++)
                          _TaskCard(index: i),
                      ],
                    ],
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: FilledButton(
                      onPressed: saveSelected,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Text(s.addSelected),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _EventCard extends ConsumerWidget {
  const _EventCard({required this.index, required this.lang});
  final int index;
  final String lang;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = AppStrings.of(context);
    final p = ref.watch(proposedEventsProvider)[index];
    final f = DateFormat('EEE d MMM • h:mm a', lang);

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CheckboxListTile(
              value: p.selected,
              onChanged: (_) =>
                  ref.read(proposedEventsProvider.notifier).toggle(index),
              title: Text(p.title),
              subtitle: Text(
                  p.start == null ? s.noTimeSpecified : f.format(p.start!)),
              secondary: p.timeMissing
                  ? IconButton(
                      icon: const Icon(Icons.access_time),
                      tooltip: s.setTime,
                      onPressed: () async {
                        final d = await showDatePicker(
                            context: context,
                            initialDate: p.start ?? DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100));
                        if (d == null) return;
                        final t = await showTimePicker(
                            context: context,
                            initialTime:
                                const TimeOfDay(hour: 9, minute: 0));
                        if (t == null) return;
                        final st =
                            DateTime(d.year, d.month, d.day, t.hour, t.minute);
                        ref.read(proposedEventsProvider.notifier).replace(
                            index,
                            p
                              ..start = st
                              ..end = st.add(const Duration(hours: 1))
                              ..timeMissing = false);
                      },
                    )
                  : null,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 12, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Chip(label: Text(s.categoryName(p.category))),
                        if (p.suggested)
                          Chip(label: Text(s.aiSuggestedTime)),
                        if (p.reminders.isEmpty)
                          Text(s.atStart,
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.grey)),
                        for (final r in p.reminders)
                          Chip(label: Text(s.reminderBefore(r))),
                      ],
                    ),
                  ),
                  // تعديل الأهمية قبل الحفظ
                  DropdownButton<String>(
                    value: p.importance,
                    isDense: true,
                    items: [
                      for (final i in _importances)
                        DropdownMenuItem(
                          value: i,
                          child: Text(s.importanceName(i),
                              style: const TextStyle(fontSize: 12)),
                        ),
                    ],
                    onChanged: (v) => ref
                        .read(proposedEventsProvider.notifier)
                        .replace(index, p..importance = v ?? 'normal'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskCard extends ConsumerWidget {
  const _TaskCard({required this.index});
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = AppStrings.of(context);
    final lang = langOf(context);
    final t = ref.watch(proposedTasksProvider)[index];

    return Card(
      child: CheckboxListTile(
        value: t.selected,
        onChanged: (_) =>
            ref.read(proposedTasksProvider.notifier).toggle(index),
        title: Text(t.title),
        subtitle: Text(
            t.dueDate == null ? s.noDate : fmtShortDate(t.dueDate!, lang)),
        secondary: IconButton(
          icon: const Icon(Icons.calendar_month),
          tooltip: s.setTime,
          onPressed: () async {
            final d = await showDatePicker(
                context: context,
                initialDate: t.dueDate ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100));
            if (d == null) return;
            ref
                .read(proposedTasksProvider.notifier)
                .replace(index, t..dueDate = dayOnly(d));
          },
        ),
      ),
    );
  }
}
