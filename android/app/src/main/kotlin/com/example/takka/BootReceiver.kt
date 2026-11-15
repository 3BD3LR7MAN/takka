package com.example.takka

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/** Restores only the native AlarmManager queue.
 * flutter_local_notifications has its own boot receiver for plugin notifications.
 */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
            Intent.ACTION_TIME_CHANGED,
            Intent.ACTION_TIMEZONE_CHANGED,
            "android.intent.action.QUICKBOOT_POWERON",
            "com.htc.intent.action.QUICKBOOT_POWERON" -> AlarmScheduler.restore(context)
            else -> return
        }
    }
}
