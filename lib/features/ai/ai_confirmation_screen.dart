import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/l10n.dart';
import '../../data/repositories.dart';
import 'ai_models.dart';
import 'providers.dart';

const _importances = ['normal', 'important', 'critical'];
final aiApplyInProgressProvider = StateProvider<bool>((_) => false);

class AiConfirmationScreen extends ConsumerWidget {
  const AiConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = AppStrings.of(context);
    final lang = langOf(context);
    final proposals = ref.watch(proposedEventsProvider);
    final tasks = ref.watch(proposedTasksProvider);
    final updates = ref.watch(proposedUpdatesProvider);
    final deletes = ref.watch(proposedDeletesProvider);
    final warnings = ref.watch(proposedAmbiguitiesProvider);
    final isApplying = ref.watch(aiApplyInProgressProvider);
    final defaultEventAlarm = ref.watch(defaultEventAlarmProvider);
    final hasAnything = proposals.isNotEmpty ||
        tasks.isNotEmpty ||
        updates.isNotEmpty ||
        deletes.isNotEmpty ||
        warnings.isNotEmpty;

    Future<void> saveSelected() async {
      final applyState = ref.read(aiApplyInProgressProvider.notifier);
      if (applyState.state) return;
      applyState.state = true;
      try {
        final repo = ref.read(eventRepositoryProvider);

        for (var i = 0; i < proposals.length; i++) {
          final proposal = proposals[i];
          if (!proposal.selected) continue;
          final noTime = proposal.timeMissing || proposal.start == null;
          await repo.save(
            title: proposal.title,
            start: proposal.start ?? DateTime.now(),
            end: proposal.end ??
                (proposal.start ?? DateTime.now())
                    .add(const Duration(hours: 1)),
            isAllDay: noTime ? true : proposal.isAllDay,
            category: proposal.category,
            location: proposal.location,
            description: proposal.description,
            importance: proposal.importance,
            reminderOffsets: {
              ...proposal.reminders,
              if (defaultEventAlarm) 0,
            }.toList(),
            source: 'ai',
          );
          ref.read(proposedEventsProvider.notifier).toggle(i);
        }
        for (var i = 0; i < tasks.length; i++) {
          final task = tasks[i];
          if (!task.selected) continue;
          await repo.addTask(title: task.title, due: task.dueDate);
          ref.read(proposedTasksProvider.notifier).toggle(i);
        }

        for (var i = 0; i < updates.length; i++) {
          final update = updates[i];
          if (!update.selected || !update.matched) continue;
          if (update.kind == 'task') {
            final title = update.newTitle?.trim();
            if (title == null || title.isEmpty) continue;
            await repo.renameTask(update.matchedId!, title);
            ref.read(proposedUpdatesProvider.notifier).toggle(i);
            continue;
          }

          final master = await repo.getEvent(update.matchedId!);
          if (master == null) continue;
          final oldStart = DateTime.fromMillisecondsSinceEpoch(master.startDt);
          final oldEnd = DateTime.fromMillisecondsSinceEpoch(master.endDt);
          final newStart = update.newStart ?? oldStart;
          final oldDuration = oldEnd.difference(oldStart);
          final newEnd = update.newEnd ??
              (update.newStart == null ? oldEnd : newStart.add(oldDuration));
          if (!newEnd.isAfter(newStart)) continue;

          final existingReminders = await repo.db.remindersFor(master.id);
          final savedReminders = update.reminders == null
              ? existingReminders
                  .map((reminder) => reminder.offsetMinutes)
                  .toList()
              : <int>{
                  ...update.reminders!,
                  if (existingReminders.any(
                    (reminder) => reminder.offsetMinutes == 0,
                  ))
                    0,
                }.toList();
          await repo.save(
            id: master.id,
            title: update.newTitle ?? master.title,
            start: newStart,
            end: newEnd,
            isAllDay: master.isAllDay,
            category: update.newCategory ?? master.category,
            location: update.newLocation ?? master.location,
            description: master.description,
            importance: update.newImportance ?? master.importance,
            source: master.source,
            reminderOffsets: savedReminders,
            repeatRule: master.repeatRule,
            repeatUntil: master.repeatUntil == null
                ? null
                : DateTime.fromMillisecondsSinceEpoch(master.repeatUntil!),
          );
          ref.read(proposedUpdatesProvider.notifier).toggle(i);
        }

        for (var i = 0; i < deletes.length; i++) {
          final deletion = deletes[i];
          if (!deletion.selected || !deletion.matched) continue;
          if (deletion.kind == 'task') {
            await repo.removeTask(deletion.matchedId!);
          } else {
            await repo.remove(deletion.matchedId!);
          }
          ref.read(proposedDeletesProvider.notifier).toggle(i);
        }

        ref.read(proposedEventsProvider.notifier).set(const []);
        ref.read(proposedTasksProvider.notifier).set(const []);
        ref.read(proposedUpdatesProvider.notifier).set(const []);
        ref.read(proposedDeletesProvider.notifier).set(const []);
        ref.read(proposedAmbiguitiesProvider.notifier).state = const [];
        if (context.mounted) context.go('/today');
      } catch (error, stackTrace) {
        debugPrint(
            '[AIConfirm] applying proposals failed: $error\n$stackTrace');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(s.applyFailed)),
          );
        }
      } finally {
        applyState.state = false;
      }
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
                      if (warnings.isNotEmpty)
                        Card(
                          color: Theme.of(context)
                              .colorScheme
                              .errorContainer
                              .withValues(alpha: .45),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.aiReviewWarnings,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                for (final warning in warnings)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Text('• $warning'),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      for (var i = 0; i < proposals.length; i++)
                        _EventCard(index: i, lang: lang),
                      if (tasks.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
                          child: Row(
                            children: [
                              const Icon(Icons.checklist, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                s.tasks,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        for (var i = 0; i < tasks.length; i++)
                          _TaskCard(index: i),
                      ],
                      if (updates.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
                          child: Text(
                            s.proposedUpdates,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        for (var i = 0; i < updates.length; i++)
                          Card(
                            child: CheckboxListTile(
                              value: updates[i].selected,
                              onChanged: updates[i].matched
                                  ? (_) => ref
                                      .read(proposedUpdatesProvider.notifier)
                                      .toggle(i)
                                  : null,
                              title: Text(
                                '${s.edit}: ${updates[i].matchTitle}',
                              ),
                              subtitle: Text(
                                updates[i].matched
                                    ? _updateSummary(updates[i], s, lang)
                                    : s.unmatched,
                              ),
                              controlAffinity: ListTileControlAffinity.leading,
                            ),
                          ),
                      ],
                      if (deletes.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
                          child: Text(
                            s.proposedDeletes,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        for (var i = 0; i < deletes.length; i++)
                          Card(
                            child: CheckboxListTile(
                              value: deletes[i].selected,
                              onChanged: deletes[i].matched
                                  ? (_) => ref
                                      .read(proposedDeletesProvider.notifier)
                                      .toggle(i)
                                  : null,
                              title: Text(
                                '${s.delete}: ${deletes[i].matchTitle}',
                              ),
                              subtitle:
                                  deletes[i].matched ? null : Text(s.unmatched),
                              controlAffinity: ListTileControlAffinity.leading,
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: FilledButton(
                      onPressed: isApplying ? null : saveSelected,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: isApplying
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(s.saving),
                                ],
                              )
                            : Text(s.applySelected),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

String _updateSummary(ProposedUpdate update, AppStrings s, String lang) {
  final parts = <String>[
    if (update.newTitle != null) update.newTitle!,
    if (update.newStart != null) fmtDateTime(update.newStart!, lang),
    if (update.newEnd != null) 'End: ${fmtDateTime(update.newEnd!, lang)}',
    if (update.newCategory != null) s.categoryName(update.newCategory!),
    if (update.newImportance != null) s.importanceName(update.newImportance!),
    if (update.newLocation != null) update.newLocation!,
    if (update.reminders != null)
      update.reminders!.isEmpty
          ? s.noReminders
          : update.reminders!.map(s.reminderBefore).join(', '),
  ];
  return parts.isEmpty ? '—' : parts.join(' • ');
}

class _EventCard extends ConsumerWidget {
  const _EventCard({required this.index, required this.lang});
  final int index;
  final String lang;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = AppStrings.of(context);
    final proposal = ref.watch(proposedEventsProvider)[index];
    final format = DateFormat('EEE d MMM • h:mm a', lang);

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CheckboxListTile(
              value: proposal.selected,
              onChanged: (_) =>
                  ref.read(proposedEventsProvider.notifier).toggle(index),
              title: Text(proposal.title),
              subtitle: Text(
                proposal.start == null
                    ? s.noTimeSpecified
                    : format.format(proposal.start!),
              ),
              secondary: proposal.timeMissing
                  ? IconButton(
                      icon: const Icon(Icons.access_time),
                      tooltip: s.setTime,
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: proposal.start ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (!context.mounted || date == null) return;
                        final time = await showTimePicker(
                          context: context,
                          initialTime: const TimeOfDay(hour: 9, minute: 0),
                        );
                        if (!context.mounted || time == null) return;
                        final start = DateTime(
                          date.year,
                          date.month,
                          date.day,
                          time.hour,
                          time.minute,
                        );
                        ref.read(proposedEventsProvider.notifier).replace(
                              index,
                              proposal
                                ..start = start
                                ..end = start.add(const Duration(hours: 1))
                                ..timeMissing = false,
                            );
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
                        Chip(label: Text(s.categoryName(proposal.category))),
                        if (proposal.suggested)
                          Chip(label: Text(s.aiSuggestedTime)),
                        if (proposal.reminders.isEmpty)
                          Text(
                            s.atStart,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        for (final reminder in proposal.reminders)
                          Chip(label: Text(s.reminderBefore(reminder))),
                      ],
                    ),
                  ),
                  DropdownButton<String>(
                    value: proposal.importance,
                    isDense: true,
                    items: [
                      for (final importance in _importances)
                        DropdownMenuItem(
                          value: importance,
                          child: Text(
                            s.importanceName(importance),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                    ],
                    onChanged: (value) =>
                        ref.read(proposedEventsProvider.notifier).replace(
                              index,
                              proposal..importance = value ?? 'normal',
                            ),
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
    final task = ref.watch(proposedTasksProvider)[index];

    return Card(
      child: CheckboxListTile(
        value: task.selected,
        onChanged: (_) =>
            ref.read(proposedTasksProvider.notifier).toggle(index),
        title: Text(task.title),
        subtitle: Text(
          task.dueDate == null ? s.noDate : fmtShortDate(task.dueDate!, lang),
        ),
        secondary: IconButton(
          icon: const Icon(Icons.calendar_month),
          tooltip: s.setTime,
          onPressed: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: task.dueDate ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (date == null) return;
            ref
                .read(proposedTasksProvider.notifier)
                .replace(index, task..dueDate = dayOnly(date));
          },
        ),
      ),
    );
  }
}
