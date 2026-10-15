package com.example.takka

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import androidx.core.app.NotificationCompat
import java.util.Locale

class AlarmRingingService : Service() {
    private val player by lazy { MobileAudioPlayer() }
    private var wakeLock: PowerManager.WakeLock? = null

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_STOP -> {
                finishAlarm()
                return START_NOT_STICKY
            }
            ACTION_SNOOZE -> {
                snoozeCurrentAlarm()
                return START_NOT_STICKY
            }
            else -> {
                val alarm = intent?.let(AlarmScheduler::alarmFromIntent)
                    ?: readPersistedAlarm()
                if (alarm == null || !AlarmScheduler.isEnabled(this)) {
                    finishAlarm()
                    return START_NOT_STICKY
                }
                startRinging(alarm)
                return START_STICKY
            }
        }
    }

    private fun startRinging(alarm: NativeAlarm) {
        val prefs = getSharedPreferences(AlarmScheduler.PREFS_NAME, MODE_PRIVATE)
        val ringtone = prefs.getString(AlarmScheduler.KEY_RINGTONE, "gentle_chime")
            ?: "gentle_chime"
        val customPath = prefs.getString(AlarmScheduler.KEY_CUSTOM_PATH, null)
        persistActiveAlarm(alarm)
        acquireWakeLock()
        val notification = buildAlarmNotification(alarm)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(
                NOTIFICATION_ID,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK,
            )
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
        player.startAlarm(ringtone, customPath)
    }

    private fun buildAlarmNotification(alarm: NativeAlarm): Notification {
        val isArabic = Locale.getDefault().language == "ar"
        val snoozeMinutes = getSharedPreferences(AlarmScheduler.PREFS_NAME, MODE_PRIVATE)
            .getInt(AlarmScheduler.KEY_SNOOZE_MINUTES, 5)
        val snoozeLabel = if (isArabic) "غفوة $snoozeMinutes د" else "Snooze ${snoozeMinutes}m"
        val stopLabel = if (isArabic) "إيقاف" else "Stop"
        val content = buildString {
            append(alarm.title)
            alarm.location?.takeIf { it.isNotBlank() }?.let { append(" • ").append(it) }
        }
        val openIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        val openPendingIntent = PendingIntent.getActivity(
            this,
            OPEN_REQUEST_CODE,
            openIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val snoozePendingIntent = actionPendingIntent(ACTION_SNOOZE, SNOOZE_REQUEST_CODE)
        val stopPendingIntent = actionPendingIntent(ACTION_STOP, STOP_REQUEST_CODE)

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle(if (isArabic) "المنبه يرن الآن" else "Alarm is ringing")
            .setContentText(content)
            .setStyle(NotificationCompat.BigTextStyle().bigText(content))
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setOngoing(true)
            .setAutoCancel(false)
            .setOnlyAlertOnce(true)
            .setSilent(true)
            .setContentIntent(openPendingIntent)
            .addAction(0, snoozeLabel, snoozePendingIntent)
            .addAction(0, stopLabel, stopPendingIntent)
            .build()
    }

    private fun actionPendingIntent(action: String, requestCode: Int): PendingIntent {
        val intent = Intent(this, AlarmRingingService::class.java).setAction(action)
        return PendingIntent.getService(
            this,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun snoozeCurrentAlarm() {
        val alarm = readPersistedAlarm()
        if (alarm != null && AlarmScheduler.isEnabled(this)) {
            val minutes = getSharedPreferences(AlarmScheduler.PREFS_NAME, MODE_PRIVATE)
                .getInt(AlarmScheduler.KEY_SNOOZE_MINUTES, 5).coerceIn(1, 60)
            val nextId = (alarm.id xor System.currentTimeMillis().toInt()) and 0x7fffffff
            AlarmScheduler.schedule(
                this,
                alarm.copy(
                    id = if (nextId == 0) 1 else nextId,
                    fireAtMillis = System.currentTimeMillis() + minutes * 60_000L,
                ),
            )
        }
        finishAlarm()
    }

    private fun persistActiveAlarm(alarm: NativeAlarm) {
        val json = org.json.JSONObject()
            .put(AlarmScheduler.EXTRA_ID, alarm.id)
            .put(AlarmScheduler.EXTRA_EVENT_ID, alarm.eventId)
            .put(AlarmScheduler.EXTRA_TITLE, alarm.title)
            .put(AlarmScheduler.EXTRA_LOCATION, alarm.location ?: "")
            .put(AlarmScheduler.EXTRA_IMPORTANCE, alarm.importance)
            .put(AlarmScheduler.EXTRA_FIRE_AT, alarm.fireAtMillis)
        getSharedPreferences(AlarmScheduler.PREFS_NAME, MODE_PRIVATE)
            .edit().putString(AlarmScheduler.KEY_ACTIVE_ALARM, json.toString()).apply()
    }

    private fun readPersistedAlarm(): NativeAlarm? {
        val raw = getSharedPreferences(AlarmScheduler.PREFS_NAME, MODE_PRIVATE)
            .getString(AlarmScheduler.KEY_ACTIVE_ALARM, null) ?: return null
        return try {
            val json = org.json.JSONObject(raw)
            NativeAlarm(
                id = json.optInt(AlarmScheduler.EXTRA_ID, -1),
                eventId = json.optString(AlarmScheduler.EXTRA_EVENT_ID),
                title = json.optString(AlarmScheduler.EXTRA_TITLE, "Takka alarm"),
                location = json.optString(AlarmScheduler.EXTRA_LOCATION).takeIf { it.isNotBlank() },
                importance = json.optString(AlarmScheduler.EXTRA_IMPORTANCE, "normal"),
                fireAtMillis = json.optLong(AlarmScheduler.EXTRA_FIRE_AT),
            ).takeIf { it.id >= 0 && it.eventId.isNotBlank() }
        } catch (_: Exception) {
            null
        }
    }

    private fun acquireWakeLock() {
        if (wakeLock?.isHeld == true) return
        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = powerManager.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK,
            "$packageName:AlarmRinging",
        ).apply {
            setReferenceCounted(false)
            acquire()
        }
    }

    private fun finishAlarm() {
        player.stopAlarm()
        wakeLock?.let { if (it.isHeld) it.release() }
        wakeLock = null
        getSharedPreferences(AlarmScheduler.PREFS_NAME, MODE_PRIVATE)
            .edit().remove(AlarmScheduler.KEY_ACTIVE_ALARM).apply()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
        stopSelf()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val isArabic = Locale.getDefault().language == "ar"
        val manager = getSystemService(NotificationManager::class.java)
        val channel = NotificationChannel(
            CHANNEL_ID,
            if (isArabic) "منبه تكّة" else "Takka alarm",
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = if (isArabic) "التحكم في المنبه أثناء الرنين" else "Controls while an alarm is ringing"
            setSound(null, null)
            enableVibration(false)
        }
        manager.createNotificationChannel(channel)
    }

    override fun onDestroy() {
        player.stopAlarm()
        wakeLock?.let { if (it.isHeld) it.release() }
        wakeLock = null
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    companion object {
        const val ACTION_START = "com.example.takka.action.START_RINGING_ALARM"
        const val ACTION_STOP = "com.example.takka.action.STOP_RINGING_ALARM"
        const val ACTION_SNOOZE = "com.example.takka.action.SNOOZE_RINGING_ALARM"
        private const val CHANNEL_ID = "takka_background_alarm_v1"
        private const val NOTIFICATION_ID = 2147003
        private const val OPEN_REQUEST_CODE = 2147004
        private const val SNOOZE_REQUEST_CODE = 2147005
        private const val STOP_REQUEST_CODE = 2147006

        internal fun start(context: Context, alarm: NativeAlarm) {
            val intent = Intent(context, AlarmRingingService::class.java).apply {
                action = ACTION_START
                putExtra(AlarmScheduler.EXTRA_ID, alarm.id)
                putExtra(AlarmScheduler.EXTRA_EVENT_ID, alarm.eventId)
                putExtra(AlarmScheduler.EXTRA_TITLE, alarm.title)
                putExtra(AlarmScheduler.EXTRA_LOCATION, alarm.location)
                putExtra(AlarmScheduler.EXTRA_IMPORTANCE, alarm.importance)
                putExtra(AlarmScheduler.EXTRA_FIRE_AT, alarm.fireAtMillis)
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        internal fun stop(context: Context) {
            context.getSharedPreferences(AlarmScheduler.PREFS_NAME, Context.MODE_PRIVATE)
                .edit().remove(AlarmScheduler.KEY_ACTIVE_ALARM).apply()
            context.stopService(Intent(context, AlarmRingingService::class.java))
        }
    }
}
