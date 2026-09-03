import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db.dart';
import '../../data/repositories.dart';

final selectedDateProvider =
    StateProvider<DateTime>((_) => dayOnly(DateTime.now()));

final dayEventsProvider =
    StreamProvider.family<List<Event>, DateTime>((ref, day) {
  return ref.watch(eventRepositoryProvider).eventsForDay(day);
});

final dayTasksProvider = StreamProvider.family<List<Task>, DateTime>((ref, day) {
  return ref.watch(eventRepositoryProvider).tasksForDay(day);
});

/// يُزاد عند الضغط المزدوج على تبويب "اليوم" → TodayScreen تستمع له.
final jumpToTodayProvider = StateProvider<int>((_) => 0);
