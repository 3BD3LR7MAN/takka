import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ai_models.dart';
import 'ai_providers.dart';
import 'ai_service.dart';

final aiConfigProvider = FutureProvider<AiConfig?>((_) => AiConfig.load());

final aiServiceProvider = Provider<AiService?>((ref) {
  final cfg = ref.watch(aiConfigProvider).valueOrNull;
  if (cfg == null || !cfg.isReady) return null;
  return createAiService(cfg);
});

final connectivityProvider = StreamProvider<List<ConnectivityResult>>(
    (ref) => Connectivity().onConnectivityChanged);

final proposedEventsProvider =
    StateNotifierProvider<ProposedEventsNotifier, List<ProposedEvent>>(
        (_) => ProposedEventsNotifier());

final proposedTasksProvider =
    StateNotifierProvider<ProposedTasksNotifier, List<ProposedTask>>(
        (_) => ProposedTasksNotifier());

class ProposedEventsNotifier extends StateNotifier<List<ProposedEvent>> {
  ProposedEventsNotifier() : super(const []);
  void set(List<ProposedEvent> events) => state = events;
  void toggle(int i) {
    final copy = [...state];
    copy[i].selected = !copy[i].selected;
    state = copy;
  }
  void replace(int i, ProposedEvent e) {
    final copy = [...state];
    copy[i] = e;
    state = copy;
  }
}

class ProposedTasksNotifier extends StateNotifier<List<ProposedTask>> {
  ProposedTasksNotifier() : super(const []);
  void set(List<ProposedTask> tasks) => state = tasks;
  void toggle(int i) {
    final copy = [...state];
    copy[i].selected = !copy[i].selected;
    state = copy;
  }
  void replace(int i, ProposedTask t) {
    final copy = [...state];
    copy[i] = t;
    state = copy;
  }
}
