package com.awun.todo_app

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONArray
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale

/**
 * Home screen widget: the live hour as a card, then the whole of today as a
 * scrolling list of hour cards.
 *
 * The widget picks the live hour from the device clock, so it stays correct
 * when the app has not run for a while. The payload carries today's items; the
 * clock decides which item is live. The list resets at midnight by itself.
 */
class HourlyWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val payload = widgetData.getString("hourly_payload", null)
        appWidgetIds.forEach { id ->
            appWidgetManager.updateAppWidget(id, buildViews(context, payload))
            appWidgetManager.notifyAppWidgetViewDataChanged(id, R.id.widget_list)
        }
        scheduleNextHour(context, appWidgetIds)
    }

    /**
     * Repaints just after the next hour starts, so the hero card always shows
     * the live hour. The system's own update period is 30 minutes at best.
     */
    private fun scheduleNextHour(context: Context, ids: IntArray) {
        if (ids.isEmpty()) {
            return
        }
        val alarm = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(context, HourlyWidgetProvider::class.java).apply {
            action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
        }
        val pending = PendingIntent.getBroadcast(
            context,
            400,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val next = Calendar.getInstance().apply {
            add(Calendar.HOUR_OF_DAY, 1)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 10)
            set(Calendar.MILLISECOND, 0)
        }
        alarm.setAndAllowWhileIdle(AlarmManager.RTC, next.timeInMillis, pending)
    }

    private fun buildViews(context: Context, payload: String?): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.hourly_widget)
        views.setRemoteAdapter(
            R.id.widget_list,
            Intent(context, HourlyWidgetService::class.java),
        )
        views.setPendingIntentTemplate(R.id.widget_list, editTemplate(context))

        val now = Calendar.getInstance()
        val nowKey = keyOf(now.time)
        val nowHour = now.get(Calendar.HOUR_OF_DAY)
        val root = payload?.let { runCatching { JSONObject(it) }.getOrNull() }
        val slot = findSlot(root?.optJSONArray("slots"), nowKey, nowHour)

        views.setTextViewText(R.id.hero_time, label(nowHour))

        if (slot == null) {
            bindEmpty(context, views, nowHour, nowKey, "")
            return views
        }

        val text = slot.optString("text")
        val status = slot.optString("status").ifEmpty { "empty" }
        when (status) {
            "active" -> {
                views.setInt(R.id.hero_card, "setBackgroundResource", R.drawable.bg_widget_hero_active)
                setChip(context, views, R.string.widget_chip_in_place, R.color.widget_active_text, R.drawable.bg_widget_chip_active)
                views.setTextViewText(R.id.hero_text, text)
                views.setOnClickPendingIntent(R.id.hero_card, quickAddIntent(context, nowKey, nowHour))
                views.setOnClickPendingIntent(R.id.hero_chip, toggleIntent(context, nowKey, nowHour))
            }

            "completed" -> {
                views.setInt(R.id.hero_card, "setBackgroundResource", R.drawable.bg_widget_hero_done)
                setChip(context, views, R.string.widget_done, R.color.widget_done_text, R.drawable.bg_widget_chip_done)
                views.setTextViewText(R.id.hero_text, text)
                views.setOnClickPendingIntent(R.id.hero_card, quickAddIntent(context, nowKey, nowHour))
                views.setOnClickPendingIntent(R.id.hero_chip, toggleIntent(context, nowKey, nowHour))
            }

            else -> bindEmpty(context, views, nowHour, nowKey, text)
        }
        return views
    }

    private fun bindEmpty(context: Context, views: RemoteViews, hour: Int, date: String, text: String) {
        views.setInt(R.id.hero_card, "setBackgroundResource", R.drawable.bg_widget_hero_empty)
        setChip(context, views, R.string.widget_chip_add, R.color.widget_muted, R.drawable.bg_widget_chip_muted)
        views.setTextViewText(
            R.id.hero_text,
            text.ifEmpty { context.getString(R.string.widget_hero_empty) },
        )
        views.setOnClickPendingIntent(R.id.hero_card, quickAddIntent(context, date, hour))
        views.setOnClickPendingIntent(R.id.hero_chip, quickAddIntent(context, date, hour))
    }

    private fun findSlot(slots: JSONArray?, date: String, hour: Int): JSONObject? {
        if (slots == null) {
            return null
        }
        for (index in 0 until slots.length()) {
            val slot = slots.optJSONObject(index) ?: continue
            if (slot.optString("date") == date && slot.optInt("hour", -1) == hour) {
                return slot
            }
        }
        return null
    }

    private fun setChip(
        context: Context,
        views: RemoteViews,
        textRes: Int,
        colorRes: Int,
        backgroundRes: Int,
    ) {
        views.setTextViewText(R.id.hero_chip, context.getString(textRes))
        views.setTextColor(R.id.hero_chip, context.getColor(colorRes))
        views.setInt(R.id.hero_chip, "setBackgroundResource", backgroundRes)
    }

    private fun toggleIntent(context: Context, date: String, hour: Int): PendingIntent {
        val uri = Uri.parse("hourly://toggle?date=$date&hour=$hour")
        return HomeWidgetBackgroundIntent.getBroadcast(context, uri)
    }

    private fun quickAddIntent(context: Context, date: String, hour: Int): PendingIntent {
        val intent = Intent(context, QuickAddActivity::class.java).apply {
            putExtra(QuickAddActivity.EXTRA_DATE, date)
            putExtra(QuickAddActivity.EXTRA_HOUR, hour)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_EXCLUDE_FROM_RECENTS)
        }
        return PendingIntent.getActivity(
            context,
            100 + hour,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    /** Template for the list rows. Each row fills in its own date and hour. */
    private fun editTemplate(context: Context): PendingIntent {
        val intent = Intent(context, QuickAddActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_EXCLUDE_FROM_RECENTS)
        }
        return PendingIntent.getActivity(
            context,
            300,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE,
        )
    }

    private fun label(hour: Int): String = String.format(Locale.getDefault(), "%02d:00", hour)

    private fun keyOf(date: Date): String =
        SimpleDateFormat("yyyy-MM-dd", Locale.getDefault()).format(date)
}
