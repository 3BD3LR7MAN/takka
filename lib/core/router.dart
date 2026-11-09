import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/ai/ai_confirmation_screen.dart';
import '../features/ai/ai_input_screen.dart';
import '../features/calendar/calendar_screen.dart';
import '../features/calendar/week_view_screen.dart';
import '../features/events/add_edit_sheet.dart';
import '../features/events/details_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/today/providers.dart';
import '../features/today/today_screen.dart';
import '../data/notification_service.dart';
import 'l10n.dart';
import 'navigator.dart';
import 'sound_service.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/today',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => HomeShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/today',
                builder: (c, s) =>
                    TodayScreen(dateParam: s.uri.queryParameters['date']),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/calendar',
                builder: (_, __) => const CalendarScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (_, __) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/week',
        builder: (c, s) =>
            WeekViewScreen(dateParam: s.uri.queryParameters['date']),
      ),
      GoRoute(
        path: '/event/add',
        builder: (c, s) =>
            AddEditEventSheet(dateParam: s.uri.queryParameters['date']),
      ),
      GoRoute(
        path: '/event/:id',
        builder: (c, s) => EventDetailsScreen(id: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/event/:id/edit',
        builder: (c, s) => AddEditEventSheet(eventId: s.pathParameters['id']),
      ),
      GoRoute(path: '/ai', builder: (_, __) => const AiInputScreen()),
      GoRoute(
        path: '/ai/confirm',
        builder: (_, __) => const AiConfirmationScreen(),
      ),
    ],
  );
});

class HomeShell extends ConsumerWidget {
  const HomeShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = AppStrings.of(context);
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(child: shell),
          ValueListenableBuilder<AlarmState?>(
            valueListenable: SoundService.instance.activeAlarm,
            builder: (context, alarm, _) {
              if (alarm == null) return const SizedBox.shrink();
              final scheme = Theme.of(context).colorScheme;
              return Align(
                alignment: Alignment.bottomCenter,
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: Semantics(
                        liveRegion: true,
                        container: true,
                        child: Material(
                          color: scheme.error,
                          elevation: 10,
                          shadowColor: Colors.black54,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: .16),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: const Icon(
                                        Icons.alarm_on_rounded,
                                        color: Colors.white,
                                        size: 27,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            s.alarmActiveBanner,
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 1,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            alarm.title,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            fmtDateTime(
                                              alarm.time,
                                              langOf(context),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.white,
                                          side: const BorderSide(
                                            color: Colors.white70,
                                          ),
                                          minimumSize:
                                              const Size.fromHeight(48),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(14),
                                          ),
                                        ),
                                        onPressed: () async {
                                          final current = SoundService
                                              .instance.activeAlarm.value;
                                          if (current == null) return;
                                          final minutes = SoundService
                                              .instance.snoozeDurationMinutes;
                                          try {
                                            await NotificationService.instance
                                                .scheduleSnoozeAlarm(
                                              eventId: current.eventId,
                                              title: current.title,
                                              location: current.location,
                                              importance: current.importance,
                                              minutes: minutes,
                                            );
                                          } catch (error) {
                                            debugPrint(
                                              '[Alarm] notification snooze failed: $error',
                                            );
                                          }
                                          SoundService.instance.snoozeAlarm(
                                            minutes: minutes,
                                          );
                                        },
                                        icon: const Icon(Icons.snooze_rounded),
                                        label: Text(s.snoozeAction),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: FilledButton.icon(
                                        style: FilledButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          foregroundColor: scheme.error,
                                          minimumSize:
                                              const Size.fromHeight(48),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(14),
                                          ),
                                        ),
                                        onPressed:
                                            SoundService.instance.dismissAlarm,
                                        icon: const Icon(
                                          Icons.stop_circle_rounded,
                                        ),
                                        label: Text(s.stop),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (i) {
          // الضغط على "اليوم" وهو مفتوح بالفعل → القفز إلى اليوم الحالي
          if (i == 0 && shell.currentIndex == 0) {
            ref.read(jumpToTodayProvider.notifier).state++;
            return;
          }
          shell.goBranch(i, initialLocation: i == shell.currentIndex);
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.today_outlined),
            selectedIcon: const Icon(Icons.today_rounded),
            label: s.today,
          ),
          NavigationDestination(
            icon: const Icon(Icons.calendar_month_outlined),
            selectedIcon: const Icon(Icons.calendar_month_rounded),
            label: s.calendar,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings_rounded),
            label: s.settings,
          ),
        ],
      ),
    );
  }
}
