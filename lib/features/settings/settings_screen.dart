import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/l10n.dart';
import '../../core/links.dart';
import '../../core/mascot/takka_mascot.dart';
import '../../core/sound_service.dart';
import '../../data/notification_service.dart';
import '../../data/repositories.dart';
import '../../data/system_service.dart';
import '../ai/ai_providers.dart';
import '../ai/providers.dart';

final themeModeProvider = StateProvider<ThemeMode>((_) => ThemeMode.system);

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  AiProviderKind _kind = AiProviderKind.gemini;
  final _modelCtrl = TextEditingController();
  final _baseCtrl = TextEditingController();
  final _keyCtrl = TextEditingController();
  String _lastDefaultModel = '';
  bool _saving = false;
  bool _exactAlarms = true;
  bool _batteryExempt = false;
  int _pendingCount = 0;
  DateTime? _nextTrigger;

  @override
  void initState() {
    super.initState();
    _loadAi();
    _loadDiag();
  }

  @override
  void dispose() {
    _modelCtrl.dispose();
    _baseCtrl.dispose();
    _keyCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAi() async {
    final cfg = await AiConfig.load();
    if (!mounted) return;
    final effective = cfg ?? AiConfig.defaultsFor(_kind);
    setState(() {
      _kind = effective.kind;
      _modelCtrl.text = effective.model;
      _baseCtrl.text = effective.baseUrl;
      _keyCtrl.text = effective.apiKey;
      _lastDefaultModel = effective.model;
    });
  }

  Future<void> _loadDiag() async {
    final pending = await ref.read(databaseProvider).pendingScheduled();
    if (!mounted) return;
    setState(() {
      _exactAlarms = NotificationService.instance.exactAlarmsGranted;
      _pendingCount = pending.length;
      _nextTrigger = pending.isEmpty ? null : DateTime.fromMillisecondsSinceEpoch(pending.first.triggerAt);
    });
    final exempt = await SystemService.isIgnoringBatteryOptimizations();
    if (mounted) setState(() => _batteryExempt = exempt);
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _open(String url) async {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  void _setLocale(String? code) {
    ref.read(appLocaleProvider.notifier).state =
        code == null ? null : Locale(code);
    const FlutterSecureStorage().write(key: 'app_locale', value: code ?? '');
  }

  Future<void> _saveAi() async {
    setState(() => _saving = true);
    final cfg = AiConfig(
      kind: _kind,
      apiKey: _keyCtrl.text.trim(),
      model: _modelCtrl.text.trim(),
      baseUrl: _baseCtrl.text.trim(),
    );
    await cfg.save();
    ref.invalidate(aiConfigProvider);
    ref.invalidate(aiServiceProvider);
    setState(() => _saving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.of(context).aiSettingsSaved)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final mode = ref.watch(themeModeProvider);
    final currentLang = ref.watch(appLocaleProvider)?.languageCode;

    return Scaffold(
      appBar: AppBar(title: Text(s.settings)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(s.appearance,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ),
          RadioListTile<ThemeMode>(
            title: Text(s.systemTheme),
            value: ThemeMode.system,
            groupValue: mode,
            onChanged: (v) =>
                ref.read(themeModeProvider.notifier).state = v!,
          ),
          RadioListTile<ThemeMode>(
            title: Text(s.light),
            value: ThemeMode.light,
            groupValue: mode,
            onChanged: (v) =>
                ref.read(themeModeProvider.notifier).state = v!,
          ),
          RadioListTile<ThemeMode>(
            title: Text(s.dark),
            value: ThemeMode.dark,
            groupValue: mode,
            onChanged: (v) =>
                ref.read(themeModeProvider.notifier).state = v!,
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(s.language,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ),
          RadioListTile<String?>(
            title: Text(s.langSystem),
            value: null,
            groupValue: currentLang,
            onChanged: (_) => _setLocale(null),
          ),
          RadioListTile<String?>(
            title: Text(s.langEnglish),
            value: 'en',
            groupValue: currentLang,
            onChanged: (_) => _setLocale('en'),
          ),
          RadioListTile<String?>(
            title: Text(s.langArabic),
            value: 'ar',
            groupValue: currentLang,
            onChanged: (_) => _setLocale('ar'),
          ),
          const Divider(),
          // ── Sounds & Alarm Mode ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(s.soundAndAlerts,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.volume_up_rounded),
            title: Text(s.soundEffects),
            subtitle: Text(s.soundEffectsSubtitle),
            value: SoundService.instance.soundEffectsEnabled,
            onChanged: (v) async {
              await SoundService.instance.setSoundEffectsEnabled(v);
              setState(() {});
            },
          ),
          if (SoundService.instance.soundEffectsEnabled)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: DropdownButtonFormField<String>(
                value: SoundService.instance.soundTheme,
                decoration: InputDecoration(
                  labelText: s.soundThemeTitle,
                  prefixIcon: const Icon(Icons.music_note_rounded),
                  isDense: true,
                ),
                items: SoundService.availableThemes.map((item) {
                  final name = currentLang == 'ar' ? item['nameAr']! : item['nameEn']!;
                  return DropdownMenuItem<String>(
                    value: item['id'],
                    child: Text(name),
                  );
                }).toList(),
                onChanged: (theme) async {
                  if (theme != null) {
                    await SoundService.instance.setSoundTheme(theme);
                    setState(() {});
                  }
                },
              ),
            ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ValueListenableBuilder<String?>(
              valueListenable: SoundService.instance.playingPreviewRingtone,
              builder: (context, playingId, _) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<String>(
                      value: SoundService.instance.ringtone,
                      decoration: InputDecoration(
                        labelText: s.reminderRingtone,
                        prefixIcon: const Icon(Icons.ring_volume_rounded),
                        helperText: s.ringtoneSubtitle,
                        isDense: true,
                        suffixIcon: IconButton(
                          tooltip: playingId != null ? s.stop : s.preview,
                          icon: Icon(
                            playingId != null
                                ? Icons.stop_circle_rounded
                                : Icons.play_circle_fill_rounded,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          onPressed: () {
                            if (playingId != null) {
                              SoundService.instance.stopRingtonePreview();
                            } else {
                              SoundService.instance.previewRingtone(SoundService.instance.ringtone);
                            }
                          },
                        ),
                      ),
                      items: SoundService.availableRingtones.map((item) {
                        final name = currentLang == 'ar' ? item['nameAr']! : item['nameEn']!;
                        return DropdownMenuItem<String>(
                          value: item['id'],
                          child: Text(name),
                        );
                      }).toList(),
                      onChanged: (ring) async {
                        if (ring != null) {
                          await SoundService.instance.setRingtone(ring);
                          setState(() {});
                        }
                      },
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            secondary: const Icon(Icons.alarm_rounded),
            title: Text(s.alarmMode),
            subtitle: Text(s.alarmModeSubtitle),
            value: SoundService.instance.alarmModeEnabled,
            onChanged: (v) async {
              await SoundService.instance.setAlarmModeEnabled(v);
              setState(() {});
            },
          ),
          if (SoundService.instance.alarmModeEnabled) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: DropdownButtonFormField<int>(
                value: SoundService.instance.snoozeDurationMinutes,
                decoration: InputDecoration(
                  labelText: s.snoozeDuration,
                  prefixIcon: const Icon(Icons.snooze_rounded),
                  isDense: true,
                ),
                items: [5, 10, 15].map((mins) {
                  return DropdownMenuItem<int>(
                    value: mins,
                    child: Text('$mins ${currentLang == 'ar' ? 'دقائق' : 'minutes'}'),
                  );
                }).toList(),
                onChanged: (mins) async {
                  if (mins != null) {
                    await SoundService.instance.setSnoozeDuration(mins);
                    setState(() {});
                  }
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
              child: OutlinedButton.icon(
                icon: const Icon(Icons.notification_important_rounded),
                label: Text(s.testAlarmNow),
                onPressed: () {
                  SoundService.instance.triggerAlarm(
                    eventId: 'test_alarm_preview',
                    title: currentLang == 'ar' ? 'اختبار وضع المنبه' : 'Alarm Mode Test',
                    location: currentLang == 'ar' ? 'مدير الوقت' : 'Takka Schedule',
                    time: DateTime.now(),
                    importance: 'critical',
                  );
                },
              ),
            ),
          ],
          const Divider(),
          Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 4), child: Text(s.aiProvider, style: const TextStyle(fontSize: 12, color: Colors.grey))),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Column(children: [
            DropdownButtonFormField<AiProviderKind>(
              value: _kind, decoration: InputDecoration(labelText: s.provider),
              items: AiProviderKind.values.map((k) => DropdownMenuItem(value: k, child: Text(providerDisplayName(k)))).toList(),
              onChanged: (k) { if (k == null) return; final d = AiConfig.defaultsFor(k); setState(() { _kind = k; _modelCtrl.text = d.model; _baseCtrl.text = d.baseUrl; }); },
            ),
            const SizedBox(height: 12),
            TextField(controller: _baseCtrl, enabled: _kind == AiProviderKind.compatible, decoration: InputDecoration(labelText: s.baseUrl, helperText: _kind == AiProviderKind.compatible ? s.baseUrlHint : s.baseUrlAutoFilled)),
            const SizedBox(height: 12),
            TextField(controller: _modelCtrl, decoration: InputDecoration(labelText: s.model, helperText: _kind == AiProviderKind.compatible ? s.modelHint : s.modelAutoFilled)),
            const SizedBox(height: 12),
            TextField(controller: _keyCtrl, obscureText: true, decoration: InputDecoration(labelText: s.apiKey, helperText: s.apiKeyHint)),
            const SizedBox(height: 12),
            SizedBox(width: double.infinity, child: FilledButton(onPressed: _saving ? null : _saveAi, child: Padding(padding: const EdgeInsets.symmetric(vertical: 14), child: Text(_saving ? s.saving : s.saveAiSettings)))),
          ])),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(s.notifDiagnostics, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ),
          ListTile(
            leading: const Icon(Icons.alarm),
            title: Text(s.exactAlarms),
            subtitle: Text(_exactAlarms ? s.enabled : s.disabledFix),
            trailing: _exactAlarms ? null : TextButton(
              onPressed: () async { await SystemService.openExactAlarmSettings(); await Future.delayed(const Duration(seconds: 1)); _loadDiag(); },
              child: Text(s.fixAction)),
          ),
          ListTile(
            leading: const Icon(Icons.battery_saver),
            title: Text(s.batteryOptimization),
            subtitle: Text(_batteryExempt ? s.exempted : s.notExempted),
            trailing: _batteryExempt ? null : TextButton(
              onPressed: () async { await SystemService.requestBatteryExemption(); await Future.delayed(const Duration(seconds: 1)); _loadDiag(); },
              child: Text(s.requestExemption)),
          ),
          ListTile(
            leading: const Icon(Icons.rocket_launch),
            title: Text(s.autostart),
            trailing: TextButton(onPressed: SystemService.openAutostartSettings, child: Text(s.openAction)),
          ),
          ListTile(
            leading: const Icon(Icons.upcoming_outlined),
            title: Text(s.pendingAlarms),
            subtitle: Text(_nextTrigger == null ? '0' : '$_pendingCount — ${fmtDateTime(_nextTrigger!, langOf(context))}'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(children: [
              OutlinedButton.icon(
                onPressed: () async {
                  SoundService.instance.playClick();
                  await NotificationService.instance.rescheduleAll(ref.read(eventRepositoryProvider));
                  await _loadDiag();
                  _toast(s.doneMsg);
                },
                icon: const Icon(Icons.sync_rounded),
                label: Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(s.rescheduleAll))),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: () async {
                  SoundService.instance.playClick();
                  await NotificationService.instance.scheduleDebugTest(seconds: 15);
                  _toast(s.testHint);
                },
                icon: const Icon(Icons.notifications_active_rounded),
                label: Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(s.testIn15))),
            ]),
          ),
          const Divider(),
          ListTile(
            leading: const TakkaMascot(mood: TakkaMood.idle, size: 52),
            title: Text('${s.appName} v1.0.1'),
            subtitle: Text('${s.appSubtitle}\n${s.takkaName}: ${s.takkaIdle}'),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(s.developer, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ),
          ListTile(
            leading: Icon(Icons.code_rounded, size: 24, color: Theme.of(context).colorScheme.primary),
            title: Text(AppLinks.githubHandle),
            subtitle: Text(s.sourceCode, style: const TextStyle(fontSize: 12)),
            trailing: const Icon(Icons.open_in_new_rounded, size: 18),
            onTap: () => _open(AppLinks.github),
          ),
          ListTile(
            leading: const Icon(Icons.link_rounded, size: 24, color: Color(0xFF0A66C2)),
            title: Text(AppLinks.linkedinHandle),
            subtitle: Text(s.connectMe, style: const TextStyle(fontSize: 12)),
            trailing: const Icon(Icons.open_in_new_rounded, size: 18),
            onTap: () => _open(AppLinks.linkedin),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
