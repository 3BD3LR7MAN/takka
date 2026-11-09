package com.example.takka

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

class AlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != AlarmScheduler.ACTION_FIRE || !AlarmScheduler.isEnabled(context)) {
            return
        }
        val alarmId = intent.getIntExtra(AlarmScheduler.EXTRA_ID, -1)
        val alarm = AlarmScheduler.consume(context, alarmId)
            ?: AlarmScheduler.alarmFromIntent(intent)
            ?: return
        AlarmRingingService.start(context, alarm)
    }
}
