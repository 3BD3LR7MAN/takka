import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n.dart';
import '../../data/repositories.dart';
import '../../core/mascot/takka_mascot.dart';
import 'providers.dart';

class TaskChecklist extends ConsumerStatefulWidget {
  const TaskChecklist({super.key, required this.day});
  final DateTime day;

  @override
  ConsumerState<TaskChecklist> createState() => _TaskChecklistState();
}

class _TaskChecklistState extends ConsumerState<TaskChecklist> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _add([String? value]) {
    final text = (value ?? _ctrl.text).trim();
    if (text.isEmpty) return;
    ref
        .read(eventRepositoryProvider)
        .addTask(title: text, due: dayOnly(widget.day));
    _ctrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final async = ref.watch(dayTasksProvider(widget.day));
    final repo = ref.read(eventRepositoryProvider);
    final scheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.checklist, size: 18, color: scheme.primary),
                const SizedBox(width: 8),
                Text(s.tasks,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14)),
                const Spacer(),
                async.maybeWhen(
                  data: (tasks) => Text(
                      '${tasks.where((t) => t.done).length}/${tasks.length}',
                      style: TextStyle(
                          fontSize: 12, color: scheme.onSurfaceVariant)),
                  orElse: () => const SizedBox.shrink(),
                ),
              ],
            ),
            async.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (tasks) => Column(
                children: [
                  if (tasks.isNotEmpty && tasks.every((x) => x.done)) ...[
                    const Center(child: TakkaMascot(mood: TakkaMood.happy, size: 90)),
                    Center(child: Text(s.takkaHappy, style: const TextStyle(fontSize: 12, color: Colors.grey))),
                  ],
                  for (final t in tasks)
                    CheckboxListTile(
                      value: t.done,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      onChanged: (_) => repo.toggleTask(t),
                      title: Text(
                        t.title,
                        style: TextStyle(
                          decoration:
                              t.done ? TextDecoration.lineThrough : null,
                          color: t.done ? Colors.grey : null,
                        ),
                      ),
                      subtitle: t.dueDate == null
                          ? Text(s.noDate,
                              style: const TextStyle(fontSize: 11))
                          : null,
                      secondary: IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        onPressed: () => repo.removeTask(t.id),
                      ),
                    ),
                ],
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    decoration: InputDecoration(
                      hintText: s.addTaskHint,
                      isDense: true,
                      border: const OutlineInputBorder(),
                    ),
                    onSubmitted: _add,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: () => _add(),
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
