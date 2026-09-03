import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n.dart';
import '../../data/db.dart';
import '../../data/notification_service.dart';
import '../../data/repositories.dart';
import 'providers.dart';

class EventDetailsScreen extends ConsumerWidget {
  const EventDetailsScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = AppStrings.of(context);
    final lang = langOf(context);
    final async = ref.watch(eventProvider(id));

    return async.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Error: $e')),
      ),
      data: (e) {
        if (e == null) {
          return Scaffold(
            appBar: AppBar(title: Text(s.today)),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.event_busy, size: 56, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text(s.eventNotFound),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => context.go('/today'),
                    child: Text(s.backToToday),
                  ),
                ],
              ),
            ),
          );
        }

        final start = DateTime.fromMillisecondsSinceEpoch(e.startDt);
        final end = DateTime.fromMillisecondsSinceEpoch(e.endDt);

        return Scaffold(
          appBar: AppBar(
            title: Text(e.title, overflow: TextOverflow.ellipsis),
            actions: [
              IconButton(
                tooltip: s.edit,
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => context.push('/event/${e.id}/edit'),
              ),
              IconButton(
                tooltip: s.delete,
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _confirmDelete(context, ref, e),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ListTile(
                leading: const Icon(Icons.schedule),
                title: Text(e.isAllDay
                    ? '${s.allDay} • ${fmtShortDate(start, lang)}'
                    : '${fmtDateTime(start, lang)} ← ${fmtDateTime(end, lang)}'),
              ),
              ListTile(
                leading: const Icon(Icons.category),
                title: Text(s.categoryName(e.category)),
              ),
              ListTile(
                leading: const Icon(Icons.flag),
                title: Text(
                    '${s.importance}: ${s.importanceName(e.importance)}'),
              ),
              if (e.location != null && e.location!.isNotEmpty)
                ListTile(
                    leading: const Icon(Icons.place), title: Text(e.location!)),
              if (e.description != null && e.description!.isNotEmpty)
                ListTile(
                    leading: const Icon(Icons.notes),
                    title: Text(e.description!)),
              ListTile(
                leading: const Icon(Icons.source),
                title: Text(e.source == 'ai' ? s.addedByAi : s.addedManually),
              ),
              const SizedBox(height: 8),
              Text('  ${s.remindersSection}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
              _RemindersList(event: e),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.notifications_active),
                  title: Text(s.testNotification),
                  subtitle: Text(s.testNotificationHint),
                  trailing: const Icon(Icons.play_arrow),
                  onTap: () => NotificationService.instance
                      .showTest(e.title, importance: e.importance),
                ),
              ),
              if (!NotificationService.instance.exactAlarmsGranted)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(s.exactAlarmWarning,
                      style: const TextStyle(
                          fontSize: 12, color: Colors.orange)),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('/event/${e.id}/edit'),
                      icon: const Icon(Icons.edit),
                      label: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(s.edit),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                          backgroundColor: Colors.red.shade700),
                      onPressed: () => _confirmDelete(context, ref, e),
                      icon: const Icon(Icons.delete),
                      label: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(s.delete),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, Event e) async {
    final s = AppStrings.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.deleteEventQuestion),
        content: Text(s.deleteEventBody(e.title)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(s.cancel)),
          FilledButton(
            style:
                FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.delete),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await ref.read(eventRepositoryProvider).remove(e.id);
    if (context.mounted) context.pop();
  }
}

class _RemindersList extends ConsumerWidget {
  const _RemindersList({required this.event});
  final Event event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = AppStrings.of(context);
    final lang = langOf(context);
    final async = ref.watch(remindersProvider(event.id));
    final start = DateTime.fromMillisecondsSinceEpoch(event.startDt);
    final now = DateTime.now();

    return async.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (reminders) {
        if (reminders.isEmpty) {
          return ListTile(
              leading: const Icon(Icons.alarm_off),
              title: Text(s.noReminders));
        }
        final sorted = [...reminders]
          ..sort((a, b) => b.offsetMinutes.compareTo(a.offsetMinutes));
        return Column(
          children: [
            for (final r in sorted)
              Builder(builder: (context) {
                var fire = start.subtract(Duration(minutes: r.offsetMinutes));
                if (event.isAllDay) {
                  fire = DateTime(start.year, start.month, start.day, 9)
                      .subtract(Duration(minutes: r.offsetMinutes));
                }
                final past = fire.isBefore(now);
                return ListTile(
                  leading: Icon(
                    r.offsetMinutes == 0 ? Icons.play_circle : Icons.alarm,
                    color: past ? Colors.grey : null,
                  ),
                  title: Text(r.offsetMinutes == 0
                      ? s.atStart
                      : s.reminderBefore(r.offsetMinutes)),
                  subtitle: Text(past
                      ? '${fmtDateTime(fire, lang)} • ${s.fired}'
                      : fmtDateTime(fire, lang)),
                  textColor: past ? Colors.grey : null,
                );
              }),
          ],
        );
      },
    );
  }
}
