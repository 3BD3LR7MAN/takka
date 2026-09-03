import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db.dart';
import '../../data/repositories.dart';

/// عائلة مستقرة — تنجو من إعادة البناء وتُصدر null بعد الحذف.
final eventProvider = StreamProvider.family<Event?, String>(
  (ref, id) => ref.watch(databaseProvider).watchById(id),
);

/// التذكيرات المفعّلة لشاشة التفاصيل (مواصفة C.4).
final remindersProvider = FutureProvider.family<List<Reminder>, String>(
  (ref, eventId) => ref.watch(databaseProvider).remindersFor(eventId),
);
