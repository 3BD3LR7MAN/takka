import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/l10n.dart';
import '../../core/mascot/takka_mascot.dart';
import '../../core/time_utils.dart';
import '../../data/db.dart';
import '../../data/repositories.dart';
import '../../domain/event_engine.dart';
import 'event_card.dart';

const categories = [
  'study', 'work', 'personal', 'university',
  'exercise', 'meeting', 'important', 'other'
];
const reminderOffsets = [0, 10, 15, 30, 60, 1440];
const importances = ['normal', 'important', 'critical'];

class AddEditEventSheet extends ConsumerStatefulWidget {
  const AddEditEventSheet({super.key, this.eventId, this.dateParam});
  final String? eventId;
  final String? dateParam;

  @override
  ConsumerState<AddEditEventSheet> createState() => _AddEditEventSheetState();
}

class _AddEditEventSheetState extends ConsumerState<AddEditEventSheet> {
  final _form = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locCtrl = TextEditingController();
  final _startTimeCtrl = TextEditingController();
  final _endTimeCtrl = TextEditingController();

  late DateTime _start;
  late DateTime _end;
  bool _allDay = false;
  String _category = 'other';
  String _importance = 'normal';
  final Set<int> _reminders = {0, 10};
  Event? _existing;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final parsed = widget.dateParam != null
        ? DateTime.tryParse(widget.dateParam!)
        : null;
    final base = parsed ?? DateTime.now();
    final startHour =
        parsed != null ? 9 : (base.hour + 1 > 23 ? 23 : base.hour + 1);
    _start = DateTime(base.year, base.month, base.day, startHour);
    _end = _start.add(const Duration(hours: 1));
    _load();
  }

  @override
  void dispose() {
    for (final c in [
      _titleCtrl, _descCtrl, _locCtrl, _startTimeCtrl, _endTimeCtrl
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    if (widget.eventId != null) {
      final e =
          await ref.read(eventRepositoryProvider).getEvent(widget.eventId!);
      if (e != null) {
        _existing = e;
        _titleCtrl.text = e.title;
        _descCtrl.text = e.description ?? '';
        _locCtrl.text = e.location ?? '';
        _start = DateTime.fromMillisecondsSinceEpoch(e.startDt);
        _end = DateTime.fromMillisecondsSinceEpoch(e.endDt);
        _allDay = e.isAllDay;
        _category = e.category;
        _importance = e.importance;
        final rs = await ref.read(databaseProvider).remindersFor(e.id);
        _reminders..clear()..addAll(rs.map((r) => r.offsetMinutes));
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _pickStart() async {
    final d = await showDatePicker(
        context: context,
        initialDate: _start,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100));
    if (d == null) return;
    final t = await showTimePicker12(context,
        initialTime: TimeOfDay.fromDateTime(_start));
    if (t == null) return;
    setState(() {
      final dur = _end.difference(_start);
      _start = DateTime(d.year, d.month, d.day, t.hour, t.minute);
      _end = _start.add(dur);
    });
  }

  Future<void> _pickEnd() async {
    final d = await showDatePicker(
        context: context,
        initialDate: _end,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100));
    if (d == null) return;
    final t = await showTimePicker12(context,
        initialTime: TimeOfDay.fromDateTime(_end));
    if (t == null) return;
    setState(() => _end = DateTime(d.year, d.month, d.day, t.hour, t.minute));
  }

  /// كتابة الوقت مباشرة: "9:30 ص" / "9:30 م" / "21:30"
  void _applyTypedTime(bool isStart, String value) {
    final t = parseTimeInput(value);
    if (t == null) return;
    setState(() {
      if (isStart) {
        final dur = _end.difference(_start);
        _start =
            DateTime(_start.year, _start.month, _start.day, t.hour, t.minute);
        _end = _start.add(dur);
      } else {
        _end = DateTime(_end.year, _end.month, _end.day, t.hour, t.minute);
      }
    });
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final s = AppStrings.of(context);
    final repo = ref.read(eventRepositoryProvider);

    if (_end.isBefore(_start)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(s.endAfterStart)));
      return;
    }

    if (!_allDay) {
      final dayEvents = await repo.overlapping(
          _start.subtract(const Duration(days: 1)),
          _end.add(const Duration(days: 1)));
      final candidate = Event(
        id: _existing?.id ?? 'tmp',
        title: _titleCtrl.text,
        description: null,
        startDt: _start.millisecondsSinceEpoch,
        endDt: _end.millisecondsSinceEpoch,
        isAllDay: false,
        category: _category,
        location: null,
        importance: _importance,
        source: 'manual',
        createdAt: 0,
        updatedAt: 0,
      );
      final conflicts = conflictsFor(candidate, dayEvents);
      if (conflicts.isNotEmpty && mounted) {
        final action = await _conflictDialog(conflicts);
        if (action != 'keep') return;
      }
    }

    await repo.save(
      id: _existing?.id,
      title: _titleCtrl.text.trim(),
      start: _start,
      end: _end,
      isAllDay: _allDay,
      category: _category,
      location: _locCtrl.text.isEmpty ? null : _locCtrl.text,
      description: _descCtrl.text.isEmpty ? null : _descCtrl.text,
      importance: _importance,
      source: _existing?.source ?? 'manual',
      reminderOffsets: _reminders.toList(),
    );
    if (mounted) context.pop();
  }

  Future<String?> _conflictDialog(List<Event> conflicts) {
    final s = AppStrings.of(context);
    final lang = langOf(context);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.conflictTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const TakkaMascot(mood: TakkaMood.alert, size: 84),
            const SizedBox(height: 8),
            Text(s.takkaAlert, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 8),
            Text(s.conflictsWith),
            const SizedBox(height: 8),
            for (final c in conflicts)
              Text(
                  '• ${c.title} (${fmtTime(DateTime.fromMillisecondsSinceEpoch(c.startDt), lang)})'),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, 'cancel'),
              child: Text(s.cancel)),
          TextButton(
              onPressed: () => Navigator.pop(ctx, 'edit'),
              child: Text(s.edit)),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, 'keep'),
              child: Text(s.keepBoth)),
        ],
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final e = _existing;
    if (e == null) return;
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
    if (ok != true || !mounted) return;

    final nav = Navigator.of(context, rootNavigator: true);
    await ref.read(eventRepositoryProvider).remove(e.id);
    nav.pop(); // إغلاق شاشة التعديل
    if (nav.canPop()) nav.pop(); // إغلاق شاشة التفاصيل تحتها إن وجدت
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }
    final s = AppStrings.of(context);
    final lang = langOf(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_existing == null ? s.addEvent : s.editEvent),
        actions: [
          if (_existing != null)
            IconButton(
              tooltip: s.delete,
              icon: const Icon(Icons.delete_outline),
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleCtrl,
              decoration: InputDecoration(labelText: s.titleField),
              autofocus: _existing == null,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? s.titleRequired : null,
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: Text(s.allDay),
              value: _allDay,
              onChanged: (v) => setState(() => _allDay = v),
            ),
            ListTile(
              leading: const Icon(Icons.schedule),
              title: Text(fmtDateTime(_start, lang)),
              subtitle: Text(s.start),
              trailing: const Icon(Icons.edit),
              onTap: _pickStart,
            ),
            ListTile(
              leading: const Icon(Icons.stop_circle_outlined),
              title: Text(fmtDateTime(_end, lang)),
              subtitle: Text(s.end),
              trailing: const Icon(Icons.edit),
              onTap: _pickEnd,
            ),
            if (!_allDay)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _startTimeCtrl,
                        decoration: InputDecoration(
                            hintText: s.typeTimeHint, isDense: true),
                        onChanged: (v) => _applyTypedTime(true, v),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _endTimeCtrl,
                        decoration: InputDecoration(
                            hintText: s.typeTimeHint, isDense: true),
                        onChanged: (v) => _applyTypedTime(false, v),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            Text(s.category,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            Wrap(
              spacing: 8,
              children: [
                for (final c in categories)
                  ChoiceChip(
                    label: Text(s.categoryName(c)),
                    selected: _category == c,
                    selectedColor: categoryColors[c]?.withOpacity(.3),
                    onSelected: (_) => setState(() => _category = c),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(s.reminders,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            Wrap(
              spacing: 8,
              children: [
                for (final r in reminderOffsets)
                  FilterChip(
                    label: Text(r == 0 ? s.atStart : s.reminderBefore(r)),
                    selected: _reminders.contains(r),
                    onSelected: (on) => setState(
                        () => on ? _reminders.add(r) : _reminders.remove(r)),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _importance,
              decoration: InputDecoration(labelText: s.importance),
              items: [
                for (final i in importances)
                  DropdownMenuItem(value: i, child: Text(s.importanceName(i))),
              ],
              onChanged: (v) => setState(() => _importance = v ?? 'normal'),
            ),
            const SizedBox(height: 12),
            TextFormField(
                controller: _locCtrl,
                decoration: InputDecoration(labelText: s.locationOptional)),
            const SizedBox(height: 12),
            TextFormField(
                controller: _descCtrl,
                maxLines: 3,
                decoration:
                    InputDecoration(labelText: s.descriptionOptional)),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _save,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Text(s.save),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
