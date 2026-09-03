import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/l10n.dart';
import '../../core/links.dart';
import '../../core/mascot/takka_mascot.dart';
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
                onPressed: () async { await NotificationService.instance.rescheduleAll(ref.read(eventRepositoryProvider)); await _loadDiag(); _toast(s.doneMsg); },
                icon: const Icon(Icons.refresh), label: Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(s.rescheduleAll))),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: () async { await NotificationService.instance.scheduleDebugTest(seconds: 15); _toast(s.testHint); },
                icon: const Icon(Icons.notifications_active), label: Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(s.testIn15))),
            ]),
          ),
          const Divider(),
          ListTile(
            leading: const TakkaMascot(mood: TakkaMood.idle, size: 52),
            title: Text('${s.appName} v1.0.0'),
            subtitle: Text('${s.appSubtitle}\n${s.takkaName}: ${s.takkaIdle}'),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(s.developer, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ),
          ListTile(
            leading: FaIcon(FontAwesomeIcons.github, size: 24, color: Theme.of(context).colorScheme.onSurface),
            title: Text(AppLinks.githubHandle),
            subtitle: Text(s.sourceCode, style: const TextStyle(fontSize: 12)),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => _open(AppLinks.github),
          ),
          ListTile(
            leading: const FaIcon(FontAwesomeIcons.linkedin, size: 24, color: Color(0xFF0A66C2)),
            title: Text(AppLinks.linkedinHandle),
            subtitle: Text(s.connectMe, style: const TextStyle(fontSize: 12)),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => _open(AppLinks.linkedin),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
