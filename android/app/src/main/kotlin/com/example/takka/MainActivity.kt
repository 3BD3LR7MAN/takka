package com.example.takka

import android.app.Activity
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.OpenableColumns
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.IOException

class MainActivity : FlutterActivity() {
    private val mobileAudioPlayer by lazy { MobileAudioPlayer() }
    private var pendingAlarmSoundPick: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, AUDIO_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "playEffect" -> {
                        mobileAudioPlayer.playEffect(
                            call.argument<String>("effect") ?: "click",
                            call.argument<String>("theme") ?: "chimes",
                        )
                        result.success(null)
                    }
                    "playRingtone" -> {
                        mobileAudioPlayer.playRingtone(
                            call.argument<String>("ringtoneId") ?: "gentle_chime",
                            call.argument<String>("customPath"),
                        )
                        result.success(null)
                    }
                    "startAlarm" -> {
                        val alarmId = call.argument<Int>("alarmId")
                            ?: (System.currentTimeMillis().toInt() and 0x7fffffff)
                        AlarmRingingService.start(
                            this,
                            NativeAlarm(
                                id = alarmId,
                                eventId = call.argument<String>("eventId") ?: "active_alarm",
                                title = call.argument<String>("title") ?: "Takka alarm",
                                location = call.argument<String>("location"),
                                importance = call.argument<String>("importance") ?: "normal",
                                fireAtMillis = call.argument<Long>("fireAtMillis")
                                    ?: System.currentTimeMillis(),
                            ),
                        )
                        result.success(null)
                    }
                    "stopRingtone" -> {
                        mobileAudioPlayer.stopRingtone()
                        result.success(null)
                    }
                    "stopAlarm" -> {
                        AlarmRingingService.stop(this)
                        result.success(null)
                    }
                    "configureAlarm" -> {
                        AlarmScheduler.configure(
                            this,
                            enabled = call.argument<Boolean>("enabled") ?: true,
                            ringtoneId = call.argument<String>("ringtoneId") ?: "gentle_chime",
                            customPath = call.argument<String>("customPath"),
                            snoozeMinutes = call.argument<Int>("snoozeMinutes") ?: 5,
                        )
                        result.success(null)
                    }
                    "scheduleBackgroundAlarm" -> {
                        val alarmId = call.argument<Int>("alarmId") ?: -1
                        val eventId = call.argument<String>("eventId")
                        if (alarmId >= 0 && eventId != null) {
                            AlarmScheduler.schedule(
                                this,
                                NativeAlarm(
                                    id = alarmId,
                                    eventId = eventId,
                                    title = call.argument<String>("title") ?: "Takka alarm",
                                    location = call.argument<String>("location"),
                                    importance = call.argument<String>("importance") ?: "normal",
                                    fireAtMillis = call.argument<Long>("fireAtMillis")
                                        ?: System.currentTimeMillis(),
                                ),
                            )
                        } else if (eventId == null) {
                            result.error(
                                "MISSING_EVENT_ID",
                                "A background alarm must include an event id",
                                null,
                            )
                            return@setMethodCallHandler
                        }
                        result.success(null)
                    }
                    "cancelBackgroundAlarm" -> {
                        call.argument<Int>("alarmId")?.let {
                            AlarmScheduler.cancel(this, it)
                        }
                        result.success(null)
                    }
                    "pickAlarmSound" -> {
                        if (pendingAlarmSoundPick != null) {
                            result.error("PICK_IN_PROGRESS", "An audio picker is already open", null)
                            return@setMethodCallHandler
                        }
                        pendingAlarmSoundPick = result
                        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                            addCategory(Intent.CATEGORY_OPENABLE)
                            type = "audio/*"
                            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                        }
                        try {
                            startActivityForResult(intent, PICK_ALARM_SOUND_REQUEST)
                        } catch (error: Exception) {
                            pendingAlarmSoundPick = null
                            result.error("PICK_FAILED", error.message, null)
                        }
                    }
                    "clearCustomAlarmSound" -> {
                        File(filesDir, "alarm-sounds").deleteRecursively()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isIgnoringBatteryOptimizations" -> {
                        val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
                        result.success(pm.isIgnoringBatteryOptimizations(packageName))
                    }
                    "requestBatteryExemption" -> result.success(try {
                        startActivity(
                            Intent(
                                Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS,
                                Uri.parse("package:$packageName"),
                            ),
                        )
                        true
                    } catch (_: Exception) {
                        try {
                            startActivity(Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS))
                            true
                        } catch (_: Exception) {
                            false
                        }
                    })
                    "openExactAlarmSettings" -> result.success(
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                            try {
                                startActivity(
                                    Intent(
                                        Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM,
                                        Uri.parse("package:$packageName"),
                                    ),
                                )
                                true
                            } catch (_: Exception) {
                                false
                            }
                        } else {
                            true
                        },
                    )
                    "openNotificationSettings" -> result.success(try {
                        val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).putExtra(
                                Settings.EXTRA_APP_PACKAGE,
                                packageName,
                            )
                        } else {
                            Intent(
                                Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                                Uri.parse("package:$packageName"),
                            )
                        }
                        startActivity(intent)
                        true
                    } catch (_: Exception) {
                        false
                    })
                    "openAutostartSettings" -> {
                        val targets = listOf(
                            ComponentName("com.miui.securitycenter", "com.miui.permcenter.autostart.AutoStartManagementActivity"),
                            ComponentName("com.huawei.systemmanager", "com.huawei.systemmanager.startupmgr.ui.StartupNormalAppListActivity"),
                            ComponentName("com.oppo.safe", "com.oppo.safe.permission.startup.StartupAppListActivity"),
                            ComponentName("com.coloros.safecenter", "com.coloros.safecenter.permission.startup.StartupAppListActivity"),
                            ComponentName("com.vivo.permissionmanager", "com.vivo.permissionmanager.activity.BgStartUpManagerActivity"),
                            ComponentName("com.samsung.android.lool", "com.samsung.android.sm.battery.ui.BatteryActivity"),
                        )
                        var opened = false
                        for (component in targets) {
                            try {
                                startActivity(
                                    Intent().setComponent(component)
                                        .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
                                )
                                opened = true
                                break
                            } catch (_: Exception) {
                                // Try the next manufacturer's settings screen.
                            }
                        }
                        if (!opened) {
                            opened = try {
                                startActivity(Intent(Settings.ACTION_SETTINGS))
                                true
                            } catch (_: Exception) {
                                false
                            }
                        }
                        result.success(opened)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    @Deprecated("Deprecated in Android; document picker result is still supported by FlutterActivity")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != PICK_ALARM_SOUND_REQUEST) return
        val pending = pendingAlarmSoundPick ?: return
        pendingAlarmSoundPick = null
        if (resultCode != Activity.RESULT_OK) {
            pending.success(null)
            return
        }
        val uri = data?.data
        if (uri == null) {
            pending.success(null)
            return
        }
        try {
            pending.success(copyPickedAlarmSound(uri))
        } catch (error: Exception) {
            pending.error("PICK_FAILED", error.message, null)
        }
    }

    private fun copyPickedAlarmSound(uri: Uri): Map<String, String> {
        val mime = contentResolver.getType(uri)
        if (mime != null && !mime.startsWith("audio/")) {
            throw IOException("Please choose an audio file")
        }
        val displayName = contentResolver.query(
            uri,
            arrayOf(OpenableColumns.DISPLAY_NAME),
            null,
            null,
            null,
        )?.use { cursor ->
            if (cursor.moveToFirst()) cursor.getString(0) else null
        }?.takeIf { it.isNotBlank() } ?: "Custom alarm sound"
        val rawExtension = displayName.substringAfterLast('.', "audio").lowercase()
        val extension = if (rawExtension.matches(Regex("[a-z0-9]{1,8}"))) rawExtension else "audio"
        val directory = File(filesDir, "alarm-sounds").apply { mkdirs() }
        val destination = File(directory, "alarm_sound.$extension")
        try {
            val input = contentResolver.openInputStream(uri)
                ?: throw IOException("Could not read the selected file")
            input.use { source ->
                destination.outputStream().buffered().use { output ->
                    val buffer = ByteArray(8192)
                    var total = 0L
                    while (true) {
                        val count = source.read(buffer)
                        if (count < 0) break
                        total += count
                        if (total > MAX_ALARM_FILE_BYTES) {
                            throw IOException("Alarm audio must be 25 MB or smaller")
                        }
                        output.write(buffer, 0, count)
                    }
                }
            }
            directory.listFiles()?.filter { it != destination }?.forEach { it.delete() }
            return mapOf("path" to destination.absolutePath, "name" to displayName)
        } catch (error: Exception) {
            destination.delete()
            throw error
        }
    }

    override fun onDestroy() {
        mobileAudioPlayer.stopAll()
        super.onDestroy()
    }

    companion object {
        private const val CHANNEL = "com.timemanager/system"
        private const val AUDIO_CHANNEL = "com.example.takka/audio"
        private const val PICK_ALARM_SOUND_REQUEST = 48127
        private const val MAX_ALARM_FILE_BYTES = 25L * 1024L * 1024L
    }
}
