package com.awun.todo_app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import java.util.Locale

/**
 * Posts the reminder notification when an [AlarmManager] alarm fires.
 *
 * No Dart engine is needed: the hour and the text travel in the alarm
 * intent. A tap opens the app; the "Mark done" button completes the hour
 * through [ReminderDoneReceiver], also without the engine.
 */
class ReminderPublishReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != ReminderScheduler.ACTION_PUBLISH) {
            return
        }
        val date = intent.getStringExtra("date") ?: return
        val hour = intent.getIntExtra("hour", -1)
        val text = intent.getStringExtra("text").orEmpty().trim()
        if (hour !in 0..23 || text.isEmpty()) {
            return
        }

        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            manager.createNotificationChannel(
                NotificationChannel(
                    ReminderScheduler.CHANNEL_ID,
                    "Hourly",
                    NotificationManager.IMPORTANCE_HIGH,
                ).apply {
                    description = "Reminders for each planned hour."
                },
            )
        }

        val open = PendingIntent.getActivity(
            context,
            hour,
            context.packageManager.getLaunchIntentForPackage(context.packageName)?.apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            } ?: Intent(context, MainActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val done = PendingIntent.getBroadcast(
            context,
            2000 + hour,
            Intent(context, ReminderDoneReceiver::class.java).apply {
                action = ReminderScheduler.ACTION_DONE
                putExtra("date", date)
                putExtra("hour", hour)
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val label = String.format(Locale.getDefault(), "%02d:00", hour)
        val notification = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(context, ReminderScheduler.CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(context).apply {
                @Suppress("DEPRECATION")
                setPriority(Notification.PRIORITY_HIGH)
            }
        }.apply {
            setContentTitle(label)
            setContentText(text)
            setSmallIcon(R.mipmap.ic_launcher)
            setContentIntent(open)
            setAutoCancel(true)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                addAction(
                    Notification.Action.Builder(null, "Mark done", done).build(),
                )
            }
        }.build()

        manager.notify(hour, notification)
    }
}
