import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../core/l10n.dart';
import '../../core/mascot/takka_mascot.dart';
import '../../data/repositories.dart';
import 'ai_service.dart';
import 'providers.dart';

class AiInputScreen extends ConsumerStatefulWidget {
  const AiInputScreen({super.key});

  @override
  ConsumerState<AiInputScreen> createState() => _AiInputScreenState();
}

class _AiInputScreenState extends ConsumerState<AiInputScreen> {
  final _textCtrl = TextEditingController();
  final _stt = SpeechToText();
  bool _listening = false;
  bool _sending = false;

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  Future<void> _toggleVoice() async {
    if (_listening) {
      await _stt.stop();
      setState(() => _listening = false);
      return;
    }
    final ok = await _stt.initialize();
    if (!ok) {
      final s = AppStrings.of(context);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(s.micUnavailable)));
      }
      return;
    }
    setState(() => _listening = true);
    await _stt.listen(
      // النص الناتج قابل للتعديل قبل الإرسال (قاعدة 26)
      onResult: (r) => setState(() => _textCtrl.text = r.recognizedWords),
      listenFor: const Duration(seconds: 30),
    );
  }

  Future<void> _send() async {
    final s = AppStrings.of(context);
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;
    final svc = ref.read(aiServiceProvider);
    if (svc == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(s.configureAiFirst)));
      return;
    }

    setState(() => _sending = true);
    try {
      // سياق الحد الأدنى فقط — ليس الجدولة كاملة (مواصفة H)
      final existing = await ref.read(eventRepositoryProvider).overlapping(
          DateTime.now(), DateTime.now().add(const Duration(days: 2)));
      final ctx = existing.isEmpty
          ? 'No existing events in this range.'
          : 'Existing events (avoid overlaps): ${existing.map((e) => e.title).join(', ')}';

      final result = await svc.extractEvents(AiRequest(
        text: text,
        now: DateTime.now(),
        timezone: DateTime.now().timeZoneName,
        contextSummary: ctx,
      ));

      ref.read(proposedEventsProvider.notifier).set(result.events);
      ref.read(proposedTasksProvider.notifier).set(result.tasks);
      if (mounted) {
        _textCtrl.clear(); // يُحذف النص فقط عند النجاح (مواصفة R)
        context.push('/ai/confirm');
      }
    } on TimeoutException {
      _error(s.timeoutKept);
    } on AiProviderException catch (e) {
      _error(s.aiError(e.message));
    } catch (e) {
      _error(s.aiError('$e'));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _error(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), duration: const Duration(seconds: 4)));
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final conn = ref.watch(connectivityProvider).valueOrNull;
    final online = conn?.contains(ConnectivityResult.none) != true;
    final svc = ref.watch(aiServiceProvider);

    return Scaffold(
      appBar: AppBar(
          title:
              Text('${s.askAi}${svc == null ? '' : ' • ${svc.providerName}'}')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: TextField(
                controller: _textCtrl,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  hintText: s.aiHint,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_sending) const Padding(padding: EdgeInsets.only(bottom: 4), child: TakkaMascot(mood: TakkaMood.thinking, size: 90)),
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: _listening
                      ? Colors.red
                      : Theme.of(context).colorScheme.secondaryContainer,
                  child: IconButton(
                    icon: Icon(_listening ? Icons.stop : Icons.mic,
                        color: _listening ? Colors.white : null),
                    onPressed: _toggleVoice,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed:
                        (!online || svc == null || _sending) ? null : _send,
                    icon: _sending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child:
                                CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.auto_awesome),
                    label: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Text(svc == null
                          ? s.configureAiFirst
                          : !online
                              ? s.offlineAi
                              : s.sendToAi),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
