import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/ai/ai_confirmation_screen.dart';
import '../features/ai/ai_input_screen.dart';
import '../features/calendar/calendar_screen.dart';
import '../features/events/add_edit_sheet.dart';
import '../features/events/details_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/today/providers.dart';
import '../features/today/today_screen.dart';
import 'l10n.dart';
import 'navigator.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/today',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => HomeShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/today',
              builder: (c, s) =>
                  TodayScreen(dateParam: s.uri.queryParameters['date']),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/calendar', builder: (_, __) => const CalendarScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/settings', builder: (_, __) => const SettingsScreen()),
          ]),
        ],
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
          path: '/ai/confirm', builder: (_, __) => const AiConfirmationScreen()),
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
      body: shell,
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
              icon: const Icon(Icons.timeline), label: s.today),
          NavigationDestination(
              icon: const Icon(Icons.calendar_month), label: s.calendar),
          NavigationDestination(
              icon: const Icon(Icons.settings), label: s.settings),
        ],
      ),
    );
  }
}
