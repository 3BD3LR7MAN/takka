import 'package:flutter/material.dart';

/// يقبل: "9:30 ص" • "9:30 م" • "9:30 صباحا" • "9:30 مساء" • "9:30pm" • "9:30 am" • "21:30"
TimeOfDay? parseTimeInput(String raw) {
  final t = raw
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[\u064B-\u0652]'), ''); // إزالة التشكيل
  final m = RegExp(
          r'^(\d{1,2})[:.](\d{2})\s*(ص|م|صباحا|مساء|ام|بي|a\.?m\.?|p\.?m\.?)?$')
      .firstMatch(t);
  if (m == null) return null;

  var hour = int.parse(m.group(1)!);
  final minute = int.parse(m.group(2)!);
  final suffix = m.group(3);
  if (minute > 59) return null;
  if (suffix == null && hour > 23) return null;
  if (suffix != null && hour > 12) return null;

  if (suffix != null) {
    final isPm = suffix.startsWith('م') || suffix.startsWith('p');
    if (hour == 12) hour = 0;
    if (isPm) hour += 12;
  }
  return TimeOfDay(hour: hour, minute: minute);
}

/// يفرض عرض 12 ساعة (ص/م) في منتقي الوقت حتى لو الجهاز على 24 ساعة.
Future<TimeOfDay?> showTimePicker12(BuildContext context,
    {required TimeOfDay initialTime}) {
  return showTimePicker(
    context: context,
    initialTime: initialTime,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
      child: child!,
    ),
  );
}
