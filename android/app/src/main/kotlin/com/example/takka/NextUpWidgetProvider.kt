package com.example.takka

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Build
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONArray
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class NextUpWidgetProvider : HomeWidgetProvider() {

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        val action = intent.action ?: return
        if (action in listOf(
                ACTION_WIDGET_TICK,
                Intent.ACTION_BOOT_COMPLETED,
                Intent.ACTION_TIME_SET,
                Intent.ACTION_TIMEZONE_CHANGED
            )
        ) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val thisWidget = ComponentName(context, NextUpWidgetProvider::class.java)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(thisWidget)
            val prefs = getSharedPreferences(context)
            onUpdate(context, appWidgetManager, appWidgetIds, prefs)
        }
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val prefs = if (widgetData.all.isNotEmpty()) widgetData else getSharedPreferences(context)
        val now = System.currentTimeMillis()
        val lang = prefs.getString("app_locale", null)
            ?: prefs.getString("flutter.app_locale", null)
            ?: "en"
        val isAr = lang == "ar"

        var badge = prefs.getString("next_up_badge", null)
            ?: prefs.getString("flutter.next_up_badge", null)
            ?: if (isAr) "التالي" else "NEXT"
        var title = prefs.getString("next_up_title", null)
            ?: prefs.getString("flutter.next_up_title", null)
            ?: if (isAr) "لا شيء مخطط" else "Nothing planned"
        var time = prefs.getString("next_up_time", null)
            ?: prefs.getString("flutter.next_up_time", null)
            ?: if (isAr) "استمتع بوقتك ✨" else "Enjoy your free time ✨"

        var nextTransitionMs = 0L

        // Dynamically recalculate state from stored JSON when available
        val eventsJsonStr = prefs.getString("next_events_json", null)
            ?: prefs.getString("flutter.next_events_json", null)
            ?: getSharedPreferences(context).getString("next_events_json", null)

        if (!eventsJsonStr.isNullOrEmpty()) {
            try {
                val array = JSONArray(eventsJsonStr)
                var ongoingTitle: String? = null
                var ongoingStart = 0L
                var ongoingEnd = 0L

                var upcomingTitle: String? = null
                var upcomingStart = Long.MAX_VALUE
                var upcomingEnd = 0L

                for (i in 0 until array.length()) {
                    val obj = array.getJSONObject(i)
                    val s = obj.optLong("start", 0L)
                    val e = obj.optLong("end", 0L)
                    val t = obj.optString("title", "")
                    val isAllDay = obj.optBoolean("isAllDay", false)
                    if (isAllDay || s == 0L || e == 0L) continue

                    if (s <= now && now < e) {
                        if (ongoingTitle == null || s < ongoingStart) {
                            ongoingTitle = t
                            ongoingStart = s
                            ongoingEnd = e
                        }
                    } else if (s > now) {
                        if (s < upcomingStart) {
                            upcomingTitle = t
                            upcomingStart = s
                            upcomingEnd = e
                        }
                    }
                }

                if (ongoingTitle != null) {
                    badge = if (isAr) "الآن" else "NOW"
                    title = ongoingTitle
                    time = formatTimeRange(ongoingStart, ongoingEnd, isAr)
                    nextTransitionMs = ongoingEnd
                } else if (upcomingTitle != null) {
                    badge = if (isAr) "التالي" else "NEXT"
                    title = upcomingTitle
                    time = formatRelativeTime(upcomingStart, upcomingEnd, now, isAr)
                    nextTransitionMs = upcomingStart
                } else {
                    badge = if (isAr) "التالي" else "NEXT"
                    title = if (isAr) "لا شيء مخطط" else "Nothing planned"
                    time = if (isAr) "استمتع بوقتك ✨" else "Enjoy your free time ✨"
                }
            } catch (_: Exception) {}
        }

        for (widgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.next_up_widget).apply {
                setTextViewText(R.id.widget_badge, badge)
                setTextViewText(R.id.widget_title, title)
                setTextViewText(R.id.widget_time, time)
                setOnClickPendingIntent(
                    R.id.widget_root,
                    HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
                )
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }

        // Schedule next exact alarm so widget refreshes the instant an event starts or finishes
        scheduleNextRefresh(context, nextTransitionMs, now)
    }

    private fun getSharedPreferences(context: Context): SharedPreferences {
        val hwPrefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        if (hwPrefs.all.isNotEmpty()) return hwPrefs
        return context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
    }

    private fun scheduleNextRefresh(context: Context, nextTransitionMs: Long, now: Long) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
        val targetMs = if (nextTransitionMs > now) {
            nextTransitionMs + 1000L // 1 second after transition
        } else {
            now + 5 * 60 * 1000L // Periodic 5 min fallback
        }

        val intent = Intent(context, NextUpWidgetProvider::class.java).apply {
            action = ACTION_WIDGET_TICK
        }
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            ALARM_REQUEST_CODE,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, targetMs, pendingIntent)
            } else {
                alarmManager.setExact(AlarmManager.RTC_WAKEUP, targetMs, pendingIntent)
            }
        } catch (_: SecurityException) {
            alarmManager.set(AlarmManager.RTC_WAKEUP, targetMs, pendingIntent)
        }
    }

    private fun formatTimeRange(startMs: Long, endMs: Long, isAr: Boolean): String {
        val locale = if (isAr) Locale("ar") else Locale.ENGLISH
        val fmt = SimpleDateFormat("h:mm a", locale)
        return "${fmt.format(Date(startMs))} – ${fmt.format(Date(endMs))}"
    }

    private fun formatRelativeTime(startMs: Long, endMs: Long, nowMs: Long, isAr: Boolean): String {
        val locale = if (isAr) Locale("ar") else Locale.ENGLISH
        val timeFmt = SimpleDateFormat("h:mm a", locale)
        val dayFmt = SimpleDateFormat("EEE d MMM", locale)
        val sDate = Date(startMs)
        val sDay = SimpleDateFormat("yyyyMMdd", Locale.US).format(sDate)
        val nDay = SimpleDateFormat("yyyyMMdd", Locale.US).format(Date(nowMs))

        val dayLabel = when {
            sDay == nDay -> if (isAr) "اليوم" else "Today"
            sDay.toIntOrNull() == nDay.toIntOrNull()?.plus(1) -> if (isAr) "غدًا" else "Tomorrow"
            else -> dayFmt.format(sDate)
        }
        return "$dayLabel • ${timeFmt.format(sDate)} – ${timeFmt.format(Date(endMs))}"
    }

    companion object {
        const val ACTION_WIDGET_TICK = "com.example.takka.ACTION_WIDGET_TICK"
        private const val ACTION_TIME_SET = "android.intent.action.TIME_SET"
        private const val ALARM_REQUEST_CODE = 44211
    }
}
