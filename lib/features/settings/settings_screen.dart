import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/l10n.dart';
import '../../core/links.dart';
import '../../core/mascot/takka_mascot.dart';
import '../../core/sound_service.dart';
import '../../data/app_update_service.dart';
import '../../data/notification_service.dart';
import '../../data/repositories.dart';
import '../../data/system_service.dart';
import '../ai/ai_providers.dart';
import '../ai/providers.dart';
import 'update_dialog.dart';

final themeModeProvider = StateProvider<ThemeMode>((_) => ThemeMode.system);

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with WidgetsBindingObserver {
  AiProviderKind _kind = AiProviderKind.gemini;
  final _modelCtrl = TextEditingController();
  final _baseCtrl = TextEditingController();
  final _keyCtrl = TextEditingController();
  bool _saving = false;
  bool _checkingUpdates = false;
  bool _exactAlarms = true;
  bool _notificationsEnabled = false;
  bool _batteryExempt = false;
  int _pendingCount = 0;
  int _platformPendingCount = 0;
  DateTime? _nextTrigger;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadAi();
    _loadDiag();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _modelCtrl.dispose();
    _baseCtrl.dispose();
    _keyCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _loadDiag();
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
    });
  }

  Future<void> _loadDiag() async {
    await NotificationService.instance.ensureReady();
    final pending = await ref.read(databaseProvider).pendingScheduled();
    final notificationsEnabled =
        await NotificationService.instance.notificationsEnabled();
    final platformPendingCount =
        await NotificationService.instance.platformPendingCount();
    if (!mounted) return;
    setState(() {
      _exactAlarms = NotificationService.instance.exactAlarmsGranted;
      _notificationsEnabled = notificationsEnabled;
      _pendingCount = pending.length;
      _platformPendingCount = platformPendingCount;
      _nextTrigger = pending.isEmpty
          ? null
          : DateTime.fromMillisecondsSinceEpoch(pending.first.triggerAt);
    });
    final exempt = await SystemService.isIgnoringBatteryOptimizations();
    if (mounted) setState(() => _batteryExempt = exempt);
  }

  Future<void> _requestNotificationPermission() async {
    await NotificationService.instance.ensureReady();
    try {
      await NotificationService.instance.ensurePermissions();
    } catch (_) {
      await SystemService.openNotificationSettings();
    }
    await Future.delayed(const Duration(milliseconds: 400));
    if (!await NotificationService.instance.notificationsEnabled()) {
      await SystemService.openNotificationSettings();
      await Future.delayed(const Duration(seconds: 1));
    }
    await _loadDiag();
  }

  Future<void> _pickLocalAlarmSound() async {
    try {
      final selected = await SoundService.instance.pickLocalAlarmSound();
      if (!mounted) return;
      setState(() {});
      _toast(
        selected
            ? AppStrings.of(context).alarmSoundSaved
            : AppStrings.of(context).alarmSoundPickerFailed,
      );
    } catch (_) {
      if (mounted) _toast(AppStrings.of(context).alarmSoundPickerFailed);
    }
  }

  Future<void> _clearLocalAlarmSound() async {
    await SoundService.instance.clearCustomAlarmSound();
    if (!mounted) return;
    setState(() {});
    _toast(AppStrings.of(context).alarmSoundCleared);
  }

  Future<void> _setDefaultEventAlarm(bool enabled) async {
    final previous = ref.read(defaultEventAlarmProvider);
    ref.read(defaultEventAlarmProvider.notifier).state = enabled;
    try {
      await const FlutterSecureStorage().write(
        key: 'default_event_alarm',
        value: enabled.toString(),
      );
    } catch (error, stackTrace) {
      debugPrint(
        '[Settings] default event alarm save failed: $error\n$stackTrace',
      );
      if (!mounted) return;
      ref.read(defaultEventAlarmProvider.notifier).state = previous;
      _toast(AppStrings.of(context).saveFailed);
    }
  }

  Future<void> _testNotificationNow() async {
    final strings = AppStrings.of(context);
    final ready = await NotificationService.instance.ensureReady();
    if (!ready) {
      if (mounted) {
        _toast(strings.notificationServiceNotReady);
      }
      return;
    }
    await NotificationService.instance.ensurePermissions();
    if (!await NotificationService.instance.notificationsEnabled()) {
      await SystemService.openNotificationSettings();
      if (!mounted) return;
      await _loadDiag();
      if (mounted) _toast(strings.notificationPermissionOff);
      return;
    }
    final sent = await NotificationService.instance.showTest(
      strings.testNotification,
      importance: 'important',
    );
    if (!mounted) return;
    await _loadDiag();
    if (mounted) {
      _toast(sent ? strings.doneMsg : strings.testNotificationFailed);
    }
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

  Future<void> _setThemeMode(ThemeMode mode) async {
    ref.read(themeModeProvider.notifier).state = mode;
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    try {
      await const FlutterSecureStorage().write(key: 'theme_mode', value: value);
    } catch (error) {
      debugPrint('[Settings] theme preference could not be saved: $error');
    }
  }

  Widget _sectionHeading(String text) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Text(
          text,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w700,
                letterSpacing: .6,
              ),
        ),
      ),
    );
  }

  Future<void> _saveAi() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final cfg = AiConfig(
        kind: _kind,
        apiKey: _keyCtrl.text.trim(),
        model: _modelCtrl.text.trim(),
        baseUrl: _baseCtrl.text.trim(),
      );
      await cfg.save();
      ref.invalidate(aiConfigProvider);
      ref.invalidate(aiServiceProvider);
      if (mounted) _toast(AppStrings.of(context).aiSettingsSaved);
    } catch (error) {
      debugPrint('[Settings] AI settings save failed: $error');
      if (mounted) _toast(AppStrings.of(context).aiSettingsFailed);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _checkForUpdates() async {
    if (_checkingUpdates) return;
    setState(() => _checkingUpdates = true);
    try {
      final service = AppUpdateService.instance;
      final release = await service.fetchLatestRelease();
      final current = await service.currentVersion();
      if (!mounted) return;
      if (AppUpdateService.compareVersions(release.version, current) > 0) {
        await showUpdateAvailableDialog(context, release);
      } else {
        _toast(AppStrings.of(context).upToDate);
      }
    } catch (error, stackTrace) {
      debugPrint('[Update] manual release check failed: $error\n$stackTrace');
      if (mounted) _toast(AppStrings.of(context).updateCheckFailed);
    } finally {
      if (mounted) setState(() => _checkingUpdates = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final mode = ref.watch(themeModeProvider);
    final currentLang = ref.watch(appLocaleProvider)?.languageCode;
    final defaultEventAlarm = ref.watch(defaultEventAlarmProvider);

    return Scaffold(
      appBar: AppBar(title: Text(s.settings)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _sectionHeading(s.appearance),
          RadioGroup<ThemeMode>(
            groupValue: mode,
            onChanged: (value) {
              if (value != null) _setThemeMode(value);
            },
            child: Column(
              children: [
                RadioListTile<ThemeMode>(
                  title: Text(s.systemTheme),
                  value: ThemeMode.system,
                ),
                RadioListTile<ThemeMode>(
                  title: Text(s.light),
                  value: ThemeMode.light,
                ),
                RadioListTile<ThemeMode>(
                  title: Text(s.dark),
                  value: ThemeMode.dark,
                ),
              ],
            ),
          ),
          const Divider(),
          _sectionHeading(s.language),
          RadioGroup<String?>(
            groupValue: currentLang,
            onChanged: _setLocale,
            child: Column(
              children: [
                RadioListTile<String?>(
                  title: Text(s.langSystem),
                  value: null,
                ),
                RadioListTile<String?>(
                  title: Text(s.langEnglish),
                  value: 'en',
                ),
                RadioListTile<String?>(
                  title: Text(s.langArabic),
                  value: 'ar',
                ),
              ],
            ),
          ),
          const Divider(),
          // ── Sounds & Alarm Mode ──
          _sectionHeading(s.soundAndAlerts),
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
                initialValue: SoundService.instance.soundTheme,
                decoration: InputDecoration(
                  labelText: s.soundThemeTitle,
                  prefixIcon: const Icon(Icons.music_note_rounded),
                  isDense: true,
                ),
                items: SoundService.availableThemes.map((item) {
                  final name =
                      currentLang == 'ar' ? item['nameAr']! : item['nameEn']!;
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
                      initialValue: SoundService.instance.ringtone,
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
                              SoundService.instance.previewRingtone(
                                SoundService.instance.ringtone,
                              );
                            }
                          },
                        ),
                      ),
                      items: SoundService.availableRingtones.map((item) {
                        final name = currentLang == 'ar'
                            ? item['nameAr']!
                            : item['nameEn']!;
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
          ListTile(
            leading: const Icon(Icons.audio_file_rounded),
            title: Text(s.localAlarmSound),
            subtitle: Text(
              SoundService.instance.customRingtoneName ?? s.noLocalAlarmSound,
            ),
            trailing: IconButton(
              tooltip: SoundService.instance.customRingtonePath == null
                  ? s.chooseAlarmSound
                  : s.clearLocalAlarmSound,
              icon: Icon(
                SoundService.instance.customRingtonePath == null
                    ? Icons.folder_open_rounded
                    : Icons.clear_rounded,
              ),
              onPressed: SoundService.instance.customRingtonePath == null
                  ? _pickLocalAlarmSound
                  : _clearLocalAlarmSound,
            ),
            onTap: _pickLocalAlarmSound,
          ),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_active_rounded),
            title: Text(s.defaultEventAlarm),
            subtitle: Text(s.defaultEventAlarmSubtitle),
            value: defaultEventAlarm,
            onChanged: _setDefaultEventAlarm,
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            secondary: const Icon(Icons.alarm_rounded),
            title: Text(s.alarmMode),
            subtitle: Text(s.alarmModeSubtitle),
            value: SoundService.instance.alarmModeEnabled,
            onChanged: (v) async {
              await SoundService.instance.setAlarmModeEnabled(v);
              if (v) {
                await NotificationService.instance.rescheduleAll(
                  ref.read(eventRepositoryProvider),
                );
              }
              if (!mounted) return;
              setState(() {});
            },
          ),
          if (SoundService.instance.alarmModeEnabled) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: DropdownButtonFormField<int>(
                initialValue: SoundService.instance.snoozeDurationMinutes,
                decoration: InputDecoration(
                  labelText: s.snoozeDuration,
                  prefixIcon: const Icon(Icons.snooze_rounded),
                  isDense: true,
                ),
                items: [5, 10, 15].map((mins) {
                  return DropdownMenuItem<int>(
                    value: mins,
                    child: Text(
                      '$mins ${currentLang == 'ar' ? 'دقائق' : 'minutes'}',
                    ),
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
                    title: currentLang == 'ar'
                        ? 'اختبار وضع المنبه'
                        : 'Alarm Mode Test',
                    location:
                        currentLang == 'ar' ? 'مدير الوقت' : 'Takka Schedule',
                    time: DateTime.now(),
                    importance: 'critical',
                  );
                },
              ),
            ),
          ],
          const Divider(),
          _sectionHeading(s.aiProvider),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                DropdownButtonFormField<AiProviderKind>(
                  key: ValueKey(_kind),
                  initialValue: _kind,
                  decoration: InputDecoration(labelText: s.provider),
                  items: AiProviderKind.values
                      .map(
                        (k) => DropdownMenuItem(
                          value: k,
                          child: Text(providerDisplayName(k)),
                        ),
                      )
                      .toList(),
                  onChanged: (k) {
                    if (k == null) return;
                    final d = AiConfig.defaultsFor(k);
                    setState(() {
                      _kind = k;
                      _modelCtrl.text = d.model;
                      _baseCtrl.text = d.baseUrl;
                    });
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _baseCtrl,
                  enabled: _kind == AiProviderKind.compatible,
                  decoration: InputDecoration(
                    labelText: s.baseUrl,
                    helperText: _kind == AiProviderKind.compatible
                        ? s.baseUrlHint
                        : s.baseUrlAutoFilled,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _modelCtrl,
                  decoration: InputDecoration(
                    labelText: s.model,
                    helperText: _kind == AiProviderKind.compatible
                        ? s.modelHint
                        : s.modelAutoFilled,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _keyCtrl,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: s.apiKey,
                    helperText: s.apiKeyHint,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _saving ? null : _saveAi,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Text(_saving ? s.saving : s.saveAiSettings),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          _sectionHeading(s.notifDiagnostics),
          ListTile(
            leading: const Icon(Icons.notifications_active_outlined),
            title: Text(s.notificationPermission),
            subtitle: Text(
              _notificationsEnabled ? s.enabled : s.notificationPermissionOff,
            ),
            trailing: TextButton(
              onPressed: _requestNotificationPermission,
              child: Text(_notificationsEnabled ? s.openAction : s.fixAction),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.alarm),
            title: Text(s.exactAlarms),
            subtitle: Text(_exactAlarms ? s.enabled : s.disabledFix),
            trailing: _exactAlarms
                ? null
                : TextButton(
                    onPressed: () async {
                      await SystemService.openExactAlarmSettings();
                      await Future.delayed(const Duration(seconds: 1));
                      _loadDiag();
                    },
                    child: Text(s.fixAction),
                  ),
          ),
          ListTile(
            leading: const Icon(Icons.battery_saver),
            title: Text(s.batteryOptimization),
            subtitle: Text(_batteryExempt ? s.exempted : s.notExempted),
            trailing: _batteryExempt
                ? null
                : TextButton(
                    onPressed: () async {
                      await SystemService.requestBatteryExemption();
                      await Future.delayed(const Duration(seconds: 1));
                      _loadDiag();
                    },
                    child: Text(s.requestExemption),
                  ),
          ),
          ListTile(
            leading: const Icon(Icons.rocket_launch),
            title: Text(s.autostart),
            trailing: TextButton(
              onPressed: SystemService.openAutostartSettings,
              child: Text(s.openAction),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.upcoming_outlined),
            title: Text(s.pendingAlarms),
            subtitle: Text(
              '${s.pendingCounts(_pendingCount, _platformPendingCount)}${_nextTrigger == null ? '' : ' • ${fmtDateTime(_nextTrigger!, langOf(context))}'}',
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                OutlinedButton.icon(
                  onPressed: () async {
                    SoundService.instance.playClick();
                    final ready =
                        await NotificationService.instance.ensureReady();
                    if (!ready) {
                      if (mounted) _toast(s.notificationServiceNotReady);
                      return;
                    }
                    await NotificationService.instance.rescheduleAll(
                      ref.read(eventRepositoryProvider),
                    );
                    await _loadDiag();
                    _toast(s.doneMsg);
                  },
                  icon: const Icon(Icons.sync_rounded),
                  label: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(s.rescheduleAll),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _testNotificationNow,
                  icon: const Icon(Icons.notifications_active_outlined),
                  label: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(s.testNotificationNow),
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: () async {
                    SoundService.instance.playClick();
                    await NotificationService.instance.ensurePermissions();
                    if (!await NotificationService.instance
                        .notificationsEnabled()) {
                      await SystemService.openNotificationSettings();
                      if (mounted) _toast(s.notificationPermissionOff);
                      return;
                    }
                    final scheduled = await NotificationService.instance
                        .scheduleDebugTest(seconds: 15);
                    if (mounted) {
                      _toast(scheduled ? s.testHint : s.scheduledTestFailed);
                    }
                  },
                  icon: const Icon(Icons.notifications_active_rounded),
                  label: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(s.testIn15),
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          ListTile(
            leading: const TakkaMascot(mood: TakkaMood.idle, size: 52),
            title: Text('${s.appName} v1.0.14'),
            subtitle: Text('${s.appSubtitle}\n${s.takkaName}: ${s.takkaIdle}'),
          ),
          ListTile(
            leading: const Icon(Icons.system_update_alt_rounded),
            title: Text(s.checkForUpdates),
            subtitle: Text(
              _checkingUpdates ? s.checkingForUpdates : 'v1.0.14',
            ),
            trailing: _checkingUpdates
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.chevron_right_rounded),
            onTap: _checkingUpdates ? null : _checkForUpdates,
          ),
          _sectionHeading(s.developer),
          ListTile(
            leading: Icon(
              Icons.code_rounded,
              size: 24,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: const Text(AppLinks.githubHandle),
            subtitle: Text(s.sourceCode, style: const TextStyle(fontSize: 12)),
            trailing: const Icon(Icons.open_in_new_rounded, size: 18),
            onTap: () => _open(AppLinks.github),
          ),
          ListTile(
            leading: const Icon(
              Icons.link_rounded,
              size: 24,
              color: Color(0xFF0A66C2),
            ),
            title: const Text(AppLinks.linkedinHandle),
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
