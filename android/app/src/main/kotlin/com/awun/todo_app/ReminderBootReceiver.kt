package com.awun.todo_app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * Re-arms today's remaining reminders after a reboot.
 *
 * [AlarmManager] alarms never survive a reboot, so this receiver reads the
 * day document straight from `FlutterSharedPreferences` and schedules the
 * alarms again. No Dart engine is started; publishing and completing hours
 * stay native until the user opens the app.
 */
class ReminderBootReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED,
            "android.intent.action.QUICKBOOT_POWERON",
            Intent.ACTION_MY_PACKAGE_REPLACED,
            -> ReminderScheduler.rescheduleAll(context)
        }
    }
}
