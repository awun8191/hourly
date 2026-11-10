package com.awun.todo_app

import android.app.NotificationManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.net.Uri
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Completes the hour when the notification's "Mark done" button is tapped.
 *
 * Writes straight into the same store the Flutter app reads
 * (`FlutterSharedPreferences`, key `flutter.hours.v1.<date>`), drops the
 * notification and its alarm, then asks the widget to repaint. No Dart
 * engine is needed: the state change is native, and the repaint reuses the
 * widget's own background refresh.
 */
class ReminderDoneReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != ReminderScheduler.ACTION_DONE) {
            return
        }
        val date = intent.getStringExtra("date") ?: return
        val hour = intent.getIntExtra("hour", -1)
        if (hour !in 0..23) {
            return
        }

        val saved = context
            .getSharedPreferences(ReminderScheduler.PREFS, Context.MODE_PRIVATE)
            .getString(ReminderScheduler.PREFIX + date, null)
        val day = saved?.let { runCatching { JSONObject(it) }.getOrNull() }
        val item = day?.optJSONObject(hour.toString())
        if (item != null && item.optString("text").isNotEmpty()) {
            item.put("status", "completed")
            item.put("updatedAt", stamp())
            context.getSharedPreferences(ReminderScheduler.PREFS, Context.MODE_PRIVATE)
                .edit()
                .putString(ReminderScheduler.PREFIX + date, day.toString())
                .apply()
        }

        ReminderScheduler.cancelHour(context, date, hour)
        (context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager)
            .cancel(hour)

        runCatching {
            HomeWidgetBackgroundIntent
                .getBroadcast(context, Uri.parse("hourly://refresh"))
                .send()
        }
    }

    private fun stamp(): String =
        SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS", Locale.US).format(Date())
}
