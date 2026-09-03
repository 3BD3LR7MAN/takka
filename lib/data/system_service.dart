import 'package:flutter/services.dart';

/// Native bridge for OS-level protections that decide whether alarms survive.
class SystemService {
  static const _channel = MethodChannel('com.timemanager/system');

  static Future<bool> isIgnoringBatteryOptimizations() async {
    try {
      return await _channel.invokeMethod<bool>('isIgnoringBatteryOptimizations') ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> requestBatteryExemption() async {
    try { await _channel.invokeMethod('requestBatteryExemption'); } catch (_) {}
  }

  static Future<void> openExactAlarmSettings() async {
    try { await _channel.invokeMethod('openExactAlarmSettings'); } catch (_) {}
  }

  static Future<void> openAutostartSettings() async {
    try { await _channel.invokeMethod('openAutostartSettings'); } catch (_) {}
  }
}
