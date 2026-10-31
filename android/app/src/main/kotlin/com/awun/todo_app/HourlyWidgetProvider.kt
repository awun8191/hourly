package com.awun.todo_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale

/**
 * Home screen widget: a card for the live hour, then every later hour of the
 * day as a tappable card in a scrolling list.
 *
 * The list is a ListView backed by [HourlyWidgetService], because RemoteViews
 * cannot scroll without a collection view. The payload arrives under
 * `hourly_payload` through `home_widget`.
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
    }

    private fun buildViews(context: Context, payload: String?): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.hourly_widget)
        views.setRemoteAdapter(
            R.id.widget_list,
            Intent(context, HourlyWidgetService::class.java),
        )
        views.setPendingIntentTemplate(R.id.widget_list, editTemplate(context))

        val root = payload?.let { runCatching { JSONObject(it) }.getOrNull() }
        if (root == null) {
            views.setTextViewText(R.id.hero_time, "--:--")
            bindEmpty(context, views, currentHour(), "", "")
            return views
        }

        val date = root.optString("date")
        val isToday = date == todayKey()
        val hour = root.optInt("hour", currentHour()).coerceIn(0, HOURS - 1)
        val label = root.optString("label").ifEmpty {
            String.format(Locale.getDefault(), "%02d:00", hour)
        }
        val text = root.optString("text")
        val status = root.optString("status").ifEmpty { "empty" }
        val minutesLeft = root.optInt("minutesLeft", 60).coerceIn(0, 60)

        views.setTextViewText(R.id.hero_time, label)

        when {
            !isToday -> {
                views.setInt(R.id.hero_card, "setBackgroundResource", R.drawable.bg_widget_hero_empty)
                setChip(context, views, R.string.widget_chip_stale, R.color.widget_muted, R.drawable.bg_widget_chip_muted)
                views.setTextViewText(R.id.hero_text, text.ifEmpty { context.getString(R.string.widget_empty_hint) })
                views.setTextViewText(R.id.hero_meta, context.getString(R.string.widget_stale_hint))
                views.setOnClickPendingIntent(R.id.hero_card, quickAddIntent(context, date, hour))
                views.setOnClickPendingIntent(R.id.hero_chip, quickAddIntent(context, date, hour))
            }

            status == "active" -> {
                views.setInt(R.id.hero_card, "setBackgroundResource", R.drawable.bg_widget_hero_active)
                setChip(context, views, R.string.widget_chip_in_place, R.color.widget_active_text, R.drawable.bg_widget_chip_active)
                views.setTextViewText(R.id.hero_text, text)
                views.setTextViewText(R.id.hero_meta, hourMeta(context, minutesLeft))
                views.setOnClickPendingIntent(R.id.hero_card, quickAddIntent(context, date, hour))
                views.setOnClickPendingIntent(R.id.hero_chip, toggleIntent(context, date, hour))
            }

            status == "completed" -> {
                views.setInt(R.id.hero_card, "setBackgroundResource", R.drawable.bg_widget_hero_done)
                setChip(context, views, R.string.widget_done, R.color.widget_done_text, R.drawable.bg_widget_chip_done)
                views.setTextViewText(R.id.hero_text, text)
                views.setTextViewText(R.id.hero_meta, context.getString(R.string.widget_meta_done))
                views.setOnClickPendingIntent(R.id.hero_card, quickAddIntent(context, date, hour))
                views.setOnClickPendingIntent(R.id.hero_chip, toggleIntent(context, date, hour))
            }

            else -> bindEmpty(context, views, hour, date, text)
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
        views.setTextViewText(R.id.hero_meta, context.getString(R.string.widget_meta_add))
        val target = date.ifEmpty { todayKey() }
        views.setOnClickPendingIntent(R.id.hero_card, quickAddIntent(context, target, hour))
        views.setOnClickPendingIntent(R.id.hero_chip, quickAddIntent(context, target, hour))
    }

    private fun hourMeta(context: Context, minutesLeft: Int): String = when {
        minutesLeft <= 1 -> context.getString(R.string.widget_hour_ending)
        minutesLeft >= 60 -> context.getString(R.string.widget_hour_started)
        else -> context.getString(R.string.widget_hour_ends_in, minutesLeft)
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

    private fun todayKey(): String =
        SimpleDateFormat("yyyy-MM-dd", Locale.getDefault()).format(Date())

    private fun currentHour(): Int = Calendar.getInstance().get(Calendar.HOUR_OF_DAY)

    private companion object {
        const val HOURS = 24
    }
}
