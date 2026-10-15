package com.example.takka

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import org.json.JSONArray
import org.json.JSONObject

internal data class NativeAlarm(
    val id: Int,
    val eventId: String,
    val title: String,
    val location: String?,
    val importance: String,
    val fireAtMillis: Long,
)

internal object AlarmScheduler {
    const val ACTION_FIRE = "com.example.takka.action.FIRE_BACKGROUND_ALARM"
    const val EXTRA_ID = "alarm_id"
    const val EXTRA_EVENT_ID = "event_id"
    const val EXTRA_TITLE = "event_title"
    const val EXTRA_LOCATION = "event_location"
    const val EXTRA_IMPORTANCE = "event_importance"
    const val EXTRA_FIRE_AT = "fire_at_millis"

    const val PREFS_NAME = "takka_background_alarm_settings"
    const val KEY_ENABLED = "alarm_mode_enabled"
    const val KEY_RINGTONE = "ringtone_id"
    const val KEY_CUSTOM_PATH = "custom_alarm_path"
    const val KEY_SNOOZE_MINUTES = "snooze_minutes"
    const val KEY_ALARMS = "scheduled_alarms"
    const val KEY_ACTIVE_ALARM = "active_alarm"

    private fun preferences(context: Context) =
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    fun isEnabled(context: Context): Boolean =
        preferences(context).getBoolean(KEY_ENABLED, true)

    fun configure(
        context: Context,
        enabled: Boolean,
        ringtoneId: String,
        customPath: String?,
        snoozeMinutes: Int,
    ) {
        val editor = preferences(context).edit()
            .putBoolean(KEY_ENABLED, enabled)
            .putString(KEY_RINGTONE, ringtoneId)
            .putInt(KEY_SNOOZE_MINUTES, snoozeMinutes)
        if (customPath.isNullOrBlank()) {
            editor.remove(KEY_CUSTOM_PATH)
        } else {
            editor.putString(KEY_CUSTOM_PATH, customPath)
        }
        editor.apply()
        if (!enabled) {
            cancelAll(context)
            AlarmRingingService.stop(context)
        }
    }

    fun schedule(context: Context, alarm: NativeAlarm) {
        if (!isEnabled(context) || alarm.fireAtMillis <= System.currentTimeMillis()) return
        val alarms = readAlarms(context)
            .filterNot { it.optInt(EXTRA_ID) == alarm.id }
            .toMutableList()
        val data = alarm.toJson()
        alarms.add(data)
        writeAlarms(context, alarms)
        schedulePendingIntent(context, data)
    }

    fun cancel(context: Context, alarmId: Int) {
        val manager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager
        manager?.cancel(pendingIntent(context, alarmId))
        val active = preferences(context).getString(KEY_ACTIVE_ALARM, null)
        if (active != null) {
            try {
                if (JSONObject(active).optInt(EXTRA_ID, -1) == alarmId) {
                    AlarmRingingService.stop(context)
                }
            } catch (_: Exception) {}
        }
        writeAlarms(
            context,
            readAlarms(context).filterNot { it.optInt(EXTRA_ID) == alarmId },
        )
    }

    fun cancelAll(context: Context) {
        val manager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager
        readAlarms(context).forEach { data ->
            manager?.cancel(pendingIntent(context, data.optInt(EXTRA_ID)))
        }
        writeAlarms(context, mutableListOf())
    }

    /** Remove a fired alarm from persistent storage and return its saved payload. */
    fun consume(context: Context, alarmId: Int): NativeAlarm? {
        val alarms = readAlarms(context)
        val data = alarms.firstOrNull { it.optInt(EXTRA_ID) == alarmId }
        if (data != null) {
            writeAlarms(context, alarms.filterNot { it.optInt(EXTRA_ID) == alarmId })
            return data.toNativeAlarm()
        }
        return null
    }

    /** Recreate AlarmManager requests after reboot, app replacement, or clock changes. */
    fun restore(context: Context) {
        val now = System.currentTimeMillis()
        val retained = readAlarms(context).filter { it.optLong(EXTRA_FIRE_AT) > now }
        writeAlarms(context, retained)
        if (!isEnabled(context)) return
        retained.forEach { schedulePendingIntent(context, it) }
    }

    fun alarmFromIntent(intent: Intent): NativeAlarm? {
        val id = intent.getIntExtra(EXTRA_ID, -1)
        val eventId = intent.getStringExtra(EXTRA_EVENT_ID) ?: return null
        if (id < 0) return null
        return NativeAlarm(
            id = id,
            eventId = eventId,
            title = intent.getStringExtra(EXTRA_TITLE) ?: "Takka alarm",
            location = intent.getStringExtra(EXTRA_LOCATION)?.takeIf { it.isNotBlank() },
            importance = intent.getStringExtra(EXTRA_IMPORTANCE) ?: "normal",
            fireAtMillis = intent.getLongExtra(EXTRA_FIRE_AT, System.currentTimeMillis()),
        )
    }

    fun intentFor(context: Context, alarm: NativeAlarm): Intent =
        Intent(context, AlarmReceiver::class.java).apply {
            action = ACTION_FIRE
            putExtra(EXTRA_ID, alarm.id)
            putExtra(EXTRA_EVENT_ID, alarm.eventId)
            putExtra(EXTRA_TITLE, alarm.title)
            putExtra(EXTRA_LOCATION, alarm.location)
            putExtra(EXTRA_IMPORTANCE, alarm.importance)
            putExtra(EXTRA_FIRE_AT, alarm.fireAtMillis)
        }

    private fun pendingIntent(context: Context, alarmId: Int): PendingIntent {
        val intent = Intent(context, AlarmReceiver::class.java).apply {
            action = ACTION_FIRE
            putExtra(EXTRA_ID, alarmId)
        }
        return PendingIntent.getBroadcast(
            context,
            alarmId,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun schedulePendingIntent(context: Context, data: JSONObject) {
        val manager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
        val alarm = data.toNativeAlarm() ?: return
        val pending = PendingIntent.getBroadcast(
            context,
            alarm.id,
            intentFor(context, alarm),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                manager.setExactAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    alarm.fireAtMillis,
                    pending,
                )
            } else {
                manager.setExact(AlarmManager.RTC_WAKEUP, alarm.fireAtMillis, pending)
            }
        } catch (_: SecurityException) {
            // Exact-alarm access may be revoked later; keep a best-effort alarm.
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                manager.setAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    alarm.fireAtMillis,
                    pending,
                )
            } else {
                manager.set(AlarmManager.RTC_WAKEUP, alarm.fireAtMillis, pending)
            }
        }
    }

    private fun readAlarms(context: Context): MutableList<JSONObject> {
        val raw = preferences(context).getString(KEY_ALARMS, "[]") ?: "[]"
        return try {
            val array = JSONArray(raw)
            MutableList(array.length()) { index -> array.getJSONObject(index) }
        } catch (_: Exception) {
            mutableListOf()
        }
    }

    private fun writeAlarms(context: Context, alarms: List<JSONObject>) {
        val array = JSONArray()
        alarms.forEach(array::put)
        preferences(context).edit().putString(KEY_ALARMS, array.toString()).apply()
    }

    private fun NativeAlarm.toJson() = JSONObject()
        .put(EXTRA_ID, id)
        .put(EXTRA_EVENT_ID, eventId)
        .put(EXTRA_TITLE, title)
        .put(EXTRA_LOCATION, location ?: "")
        .put(EXTRA_IMPORTANCE, importance)
        .put(EXTRA_FIRE_AT, fireAtMillis)

    private fun JSONObject.toNativeAlarm(): NativeAlarm? {
        val id = optInt(EXTRA_ID, -1)
        val eventId = optString(EXTRA_EVENT_ID).takeIf { it.isNotBlank() } ?: return null
        if (id < 0) return null
        return NativeAlarm(
            id = id,
            eventId = eventId,
            title = optString(EXTRA_TITLE, "Takka alarm"),
            location = optString(EXTRA_LOCATION).takeIf { it.isNotBlank() },
            importance = optString(EXTRA_IMPORTANCE, "normal"),
            fireAtMillis = optLong(EXTRA_FIRE_AT),
        )
    }
}
