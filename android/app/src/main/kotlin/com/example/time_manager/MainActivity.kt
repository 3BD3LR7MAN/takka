package com.example.time_manager

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isIgnoringBatteryOptimizations" -> {
                    val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
                    result.success(pm.isIgnoringBatteryOptimizations(packageName))
                }
                "requestBatteryExemption" -> result.success(try {
                    startActivity(Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS, Uri.parse("package:$packageName"))); true
                } catch (_: Exception) { try { startActivity(Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)); true } catch (_: Exception) { false } })
                "openExactAlarmSettings" -> result.success(if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) try {
                    startActivity(Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM, Uri.parse("package:$packageName"))); true
                } catch (_: Exception) { false } else true)
                "openAutostartSettings" -> {
                    val targets = listOf(
                        ComponentName("com.miui.securitycenter", "com.miui.permcenter.autostart.AutoStartManagementActivity"),
                        ComponentName("com.huawei.systemmanager", "com.huawei.systemmanager.startupmgr.ui.StartupNormalAppListActivity"),
                        ComponentName("com.oppo.safe", "com.oppo.safe.permission.startup.StartupAppListActivity"),
                        ComponentName("com.coloros.safecenter", "com.coloros.safecenter.permission.startup.StartupAppListActivity"),
                        ComponentName("com.vivo.permissionmanager", "com.vivo.permissionmanager.activity.BgStartUpManagerActivity"),
                        ComponentName("com.samsung.android.lool", "com.samsung.android.sm.battery.ui.BatteryActivity")
                    )
                    var opened = false
                    for (cn in targets) try { startActivity(Intent().setComponent(cn).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)); opened = true; break } catch (_: Exception) {}
                    if (!opened) try { startActivity(Intent(Settings.ACTION_SETTINGS)); opened = true } catch (_: Exception) {}
                    result.success(opened)
                }
                else -> result.notImplemented()
            }
        }
    }
    companion object { private const val CHANNEL = "com.timemanager/system" }
}
