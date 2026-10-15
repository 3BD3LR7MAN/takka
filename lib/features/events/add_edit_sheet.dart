import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n.dart';
import '../../core/mascot/takka_mascot.dart';
import '../../core/sound_service.dart';
import '../../core/time_utils.dart';
import '../../data/db.dart';
import '../../data/repositories.dart';
import '../../domain/event_engine.dart';
import 'event_card.dart';

const categories = [
  'study',
  'work',
  'personal',
  'university',
  'exercise',
  'meeting',
  'important',
  'other',
];
const reminderOffsets = [10, 15, 30, 60, 1440];
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
  String _repeat = 'none';
  DateTime? _repeatUntil;
  final Set<int> _reminders = {10};
  Event? _existing;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final parsed =
        widget.dateParam != null ? DateTime.tryParse(widget.dateParam!) : null;
    final base = parsed ?? DateTime.now();
    final startHour =
        parsed != null ? 9 : (base.hour + 1 > 23 ? 23 : base.hour + 1);
    _start = DateTime(base.year, base.month, base.day, startHour);
    _end = _start.add(const Duration(hours: 1));
    if (ref.read(defaultEventAlarmProvider)) _reminders.add(0);
    _load();
  }

  @override
  void dispose() {
    for (final c in [
      _titleCtrl,
      _descCtrl,
      _locCtrl,
      _startTimeCtrl,
      _endTimeCtrl,
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
        _repeat = e.repeatRule;
        _repeatUntil = e.repeatUntil == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(e.repeatUntil!);
        final rs = await ref.read(databaseProvider).remindersFor(e.id);
        _reminders
          ..clear()
          ..addAll(rs.map((r) => r.offsetMinutes));
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _pickStart() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _start,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (!mounted || d == null) return;
    final t = await showTimePicker12(
      context,
      initialTime: TimeOfDay.fromDateTime(_start),
    );
    if (!mounted || t == null) return;
    setState(() {
      final dur = _end.difference(_start);
      _start = DateTime(d.year, d.month, d.day, t.hour, t.minute);
      _end = _start.add(dur);
      _startTimeCtrl.clear();
      _endTimeCtrl.clear();
    });
  }

  Future<void> _pickEnd() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _end,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (!mounted || d == null) return;
    final t = await showTimePicker12(
      context,
      initialTime: TimeOfDay.fromDateTime(_end),
    );
    if (!mounted || t == null) return;
    setState(() {
      _end = DateTime(d.year, d.month, d.day, t.hour, t.minute);
      _startTimeCtrl.clear();
      _endTimeCtrl.clear();
    });
  }

  /// كتابة الوقت مباشرة: "9:30 ص" / "9:30 م" / "21:30"
  bool _applyTypedTime(bool isStart, String value) {
    if (value.trim().isEmpty) return true;
    final t = parseTimeInput(value);
    if (t == null) return false;
    setState(() {
      if (isStart) {
        final dur = _end.difference(_start);
        _start = DateTime(
          _start.year,
          _start.month,
          _start.day,
          t.hour,
          t.minute,
        );
        _end = _start.add(dur);
      } else {
        _end = DateTime(_end.year, _end.month, _end.day, t.hour, t.minute);
      }
    });
    return true;
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    final s = AppStrings.of(context);
    final repo = ref.read(eventRepositoryProvider);
    setState(() => _saving = true);
    try {
      if (!_allDay &&
          (!_applyTypedTime(true, _startTimeCtrl.text) ||
              !_applyTypedTime(false, _endTimeCtrl.text))) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(s.invalidTime)));
        return;
      }

      if (!_end.isAfter(_start)) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(s.endAfterStart)));
        return;
      }

      if (!_allDay) {
        final dayEvents = await repo.overlapping(
          _start.subtract(const Duration(days: 1)),
          _end.add(const Duration(days: 1)),
        );
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
          repeatRule: _repeat,
          repeatUntil: _repeatUntil?.millisecondsSinceEpoch,
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
        repeatRule: _repeat,
        repeatUntil: _repeatUntil,
      );
      if (mounted) context.pop();
    } catch (error, stackTrace) {
      debugPrint('[EventForm] save failed: $error\n$stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(s.saveFailed)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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
                '• ${c.title} (${fmtTime(DateTime.fromMillisecondsSinceEpoch(c.startDt), lang)})',
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'cancel'),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'edit'),
            child: Text(s.edit),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, 'keep'),
            child: Text(s.keepBoth),
          ),
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
            child: Text(s.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_rounded),
            label: Text(_saving ? s.saving : s.save),
          ),
        ),
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
                          labelText: s.startTimeInput,
                          hintText: s.typeTimeHint,
                          isDense: true,
                        ),
                        keyboardType: TextInputType.datetime,
                        onSubmitted: (v) {
                          if (!_applyTypedTime(true, v)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(s.invalidTime)),
                            );
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _endTimeCtrl,
                        decoration: InputDecoration(
                          labelText: s.endTimeInput,
                          hintText: s.typeTimeHint,
                          isDense: true,
                        ),
                        keyboardType: TextInputType.datetime,
                        onSubmitted: (v) {
                          if (!_applyTypedTime(false, v)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(s.invalidTime)),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            Text(
              s.category,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Wrap(
              spacing: 8,
              children: [
                for (final c in categories)
                  ChoiceChip(
                    avatar: Icon(
                      getCategoryIcon(c),
                      size: 16,
                      color: _category == c
                          ? (categoryColors[c] ?? Colors.blue)
                          : Colors.grey,
                    ),
                    label: Text(s.categoryName(c)),
                    selected: _category == c,
                    selectedColor:
                        (categoryColors[c] ?? Colors.blue).withValues(alpha: .3),
                    onSelected: (_) {
                      SoundService.instance.playClick();
                      setState(() => _category = c);
                    },
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              s.reminders,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.alarm_rounded),
              title: Text(s.eventAlarm),
              subtitle: Text(s.eventAlarmSubtitle),
              value: _reminders.contains(0),
              onChanged: (enabled) {
                SoundService.instance.playClick();
                setState(() {
                  if (enabled) {
                    _reminders.add(0);
                  } else {
                    _reminders.remove(0);
                  }
                });
              },
            ),
            Wrap(
              spacing: 8,
              children: [
                for (final r in reminderOffsets)
                  FilterChip(
                    avatar: Icon(
                      Icons.notifications_outlined,
                      size: 16,
                      color: _reminders.contains(r) ? Colors.blue : Colors.grey,
                    ),
                    label: Text(s.reminderBefore(r)),
                    selected: _reminders.contains(r),
                    onSelected: (on) {
                      SoundService.instance.playClick();
                      setState(
                        () => on ? _reminders.add(r) : _reminders.remove(r),
                      );
                    },
                  ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _importance,
              decoration: InputDecoration(
                labelText: s.importance,
                prefixIcon: Icon(
                  _importance == 'critical'
                      ? Icons.alarm
                      : (_importance == 'important'
                          ? Icons.star_rounded
                          : Icons.flag_rounded),
                  color: _importance == 'critical'
                      ? Colors.red
                      : (_importance == 'important'
                          ? Colors.orange
                          : Colors.grey),
                ),
              ),
              items: [
                DropdownMenuItem(
                  value: 'normal',
                  child: Row(
                    children: [
                      const Icon(Icons.flag_outlined, size: 18),
                      const SizedBox(width: 8),
                      Text(s.importanceName('normal')),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'important',
                  child: Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 18,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Text(s.importanceName('important')),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'critical',
                  child: Row(
                    children: [
                      const Icon(Icons.alarm, size: 18, color: Colors.red),
                      const SizedBox(width: 8),
                      Text('${s.importanceName('critical')} (${s.alarmMode})'),
                    ],
                  ),
                ),
              ],
              onChanged: (v) => setState(() => _importance = v ?? 'normal'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _repeat,
              decoration: InputDecoration(labelText: s.repeat),
              items: [
                for (final rule in const [
                  'none',
                  'daily',
                  'weekly',
                  'biweekly',
                  'monthly',
                  'weekdays',
                  'weekend',
                ])
                  DropdownMenuItem(
                    value: rule,
                    child: Text(repeatRuleLabel(rule, s.ar)),
                  ),
              ],
              onChanged: (value) => setState(() {
                _repeat = value ?? 'none';
                if (_repeat == 'none') _repeatUntil = null;
              }),
            ),
            if (_repeat != 'none') ...[
              ListTile(
                leading: const Icon(Icons.event_busy),
                title: Text(
                  _repeatUntil == null
                      ? s.repeatUntil
                      : fmtShortDate(_repeatUntil!, lang),
                ),
                trailing: _repeatUntil == null
                    ? null
                    : IconButton(
                        tooltip: s.cancel,
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _repeatUntil = null),
                      ),
                onTap: () async {
                  final firstDate = DateTime(
                    _start.year,
                    _start.month,
                    _start.day,
                  );
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _repeatUntil ?? firstDate,
                    firstDate: firstDate,
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setState(
                      () => _repeatUntil = DateTime(
                        picked.year,
                        picked.month,
                        picked.day,
                      ),
                    );
                  }
                },
              ),
            ],
            const SizedBox(height: 12),
            TextFormField(
              controller: _locCtrl,
              decoration: InputDecoration(labelText: s.locationOptional),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descCtrl,
              maxLines: 3,
              decoration: InputDecoration(labelText: s.descriptionOptional),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
