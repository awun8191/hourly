package com.awun.todo_app

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale

/**
 * Arms one [AlarmManager] alarm per remaining hour item of today.
 *
 * The store is read straight from `FlutterSharedPreferences`, so no Dart
 * engine is needed. This runs on boot (alarms never survive a reboot) and
 * after every native edit from [QuickAddActivity]. Only active, non-blank
 * hours later than now are armed; everything else is cancelled.
 */
object ReminderScheduler {

    const val PREFS = "FlutterSharedPreferences"
    const val PREFIX = "flutter.hours.v1."
    const val CHANNEL_ID = "hourly_reminders"
    const val ACTION_PUBLISH = "com.awun.todo_app.action.PUBLISH_REMINDER"
    const val ACTION_DONE = "com.awun.todo_app.action.REMINDER_DONE"

    fun rescheduleAll(context: Context) {
        val alarm = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val todayKey = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault())
            .format(Calendar.getInstance().time)
        val raw = context
            .getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getString(PREFIX + todayKey, null)
        val day = raw?.let { runCatching { JSONObject(it) }.getOrNull() }

        for (hour in 0..23) {
            val item = day?.optJSONObject(hour.toString())
            val text = item?.optString("text").orEmpty().trim()
            val fireAt = Calendar.getInstance().apply {
                set(Calendar.HOUR_OF_DAY, hour)
                set(Calendar.MINUTE, 0)
                set(Calendar.SECOND, 0)
                set(Calendar.MILLISECOND, 0)
            }
            if (item == null || text.isEmpty() ||
                item.optString("status") == "completed" ||
                fireAt.timeInMillis <= System.currentTimeMillis()
            ) {
                alarm.cancel(publishPending(context, todayKey, hour, null))
                continue
            }
            val pending = publishPending(context, todayKey, hour, text)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && !alarm.canScheduleExactAlarms()) {
                alarm.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, fireAt.timeInMillis, pending)
            } else {
                runCatching {
                    alarm.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, fireAt.timeInMillis, pending)
                }.onFailure {
                    alarm.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, fireAt.timeInMillis, pending)
                }
            }
        }
    }

    fun cancelHour(context: Context, dateKey: String, hour: Int) {
        val alarm = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        alarm.cancel(publishPending(context, dateKey, hour, null))
    }

    /**
     * Alarm equality ignores extras, so the cancel path matches the armed
     * alarm even with a null [text].
     */
    private fun publishPending(context: Context, dateKey: String, hour: Int, text: String?): PendingIntent {
        val intent = Intent(context, ReminderPublishReceiver::class.java).apply {
            action = ACTION_PUBLISH
            putExtra("date", dateKey)
            putExtra("hour", hour)
            if (text != null) {
                putExtra("text", text)
            }
        }
        return PendingIntent.getBroadcast(
            context,
            1000 + hour,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }
}
