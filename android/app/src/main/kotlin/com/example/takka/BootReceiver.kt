package com.example.takka

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.FlutterInjector

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_BOOT_COMPLETED) return

        // Dart headless → rescheduleNotifications() في main.dart
        val engine = FlutterEngine(context.applicationContext)
        heldEngines.add(engine) // منع الـGC قبل انتهاء العمل
        engine.dartExecutor.executeDartEntrypoint(
            DartExecutor.DartEntrypoint(
                FlutterInjector.instance().flutterLoader().findAppBundlePath(),
                "rescheduleNotifications",
            )
        )
    }

    companion object {
        private val heldEngines = mutableListOf<FlutterEngine>()
    }
}
