package com.awun.todo_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Paint
import android.net.Uri
import android.util.TypedValue
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONArray
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Home screen widget: a hero for the live hour, the next planned hour, then the
 * compact rows under it, and the day progress at the bottom.
 *
 * The app sends a JSON document through `home_widget` under the key
 * `hourly_payload`. The hero chip and each row chip toggle the item through a
 * Dart background callback; a tap on a row opens the app at that hour.
 */
class HourlyWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val payload = widgetData.getString(PAYLOAD_KEY, null)
        appWidgetIds.forEach { widgetId ->
            appWidgetManager.updateAppWidget(widgetId, buildViews(context, payload))
        }
    }

    private fun buildViews(context: Context, payload: String?): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.hourly_widget)
        views.removeAllViews(R.id.slot_container)

        val root = payload?.let {
            runCatching { JSONObject(it) }.getOrNull()
        }
        if (root == null) {
            return emptyViews(context, views)
        }

        val locale = Locale.getDefault()
        val dateKey = root.optString("date")
        val isToday = dateKey == todayKey()
        val dayLabel = root.optString("day")
        val done = root.optInt("done", 0)
        val total = root.optInt("total", 0)
        val dayPercent = root.optInt(
            "dayPercent",
            if (total == 0) 0 else done * 100 / total,
        )
        val minutesInto = root.optInt("minutesIntoHour", 0).coerceIn(0, 59)
        val minutesLeft = root.optInt("minutesLeft", 60 - minutesInto).coerceIn(0, 60)
        val slots = root.optJSONArray("slots") ?: JSONArray()

        views.setTextViewText(
            R.id.widget_day,
            if (isToday || dayLabel.isEmpty()) {
                dayLabel.uppercase(locale)
            } else {
                context.getString(R.string.widget_stale_day, dayLabel).uppercase(locale)
            },
        )
        views.setOnClickPendingIntent(R.id.widget_brand, openAppIntent(context, -1))
        views.setOnClickPendingIntent(R.id.widget_day, openAppIntent(context, -1))

        bindHero(context, views, slots.optJSONObject(0), isToday, minutesInto, minutesLeft)
        bindNext(context, views, root.optJSONObject("next"), isToday)
        bindRows(context, views, slots, isToday)

        views.setProgressBar(R.id.widget_day_progress, 100, dayPercent, false)
        views.setTextViewText(R.id.widget_progress, footerText(context, isToday, done, total))
        return views
    }

    /** No payload yet: a quiet card that opens the app. */
    private fun emptyViews(context: Context, views: RemoteViews): RemoteViews {
        views.setTextViewText(R.id.widget_day, "")
        views.setInt(R.id.hero_card, "setBackgroundResource", R.drawable.bg_widget_hero_empty)
        views.setTextViewText(R.id.hero_time, "--:--")
        views.setTextViewText(R.id.hero_chip, context.getString(R.string.widget_chip_free))
        views.setTextColor(R.id.hero_chip, context.getColor(R.color.widget_muted))
        views.setInt(R.id.hero_chip, "setBackgroundResource", R.drawable.bg_widget_chip_muted)
        views.setTextViewText(R.id.hero_text, context.getString(R.string.widget_empty_hint))
        views.setTextViewText(R.id.hero_meta, context.getString(R.string.widget_open_app))
        views.setProgressBar(R.id.hero_progress, 60, 0, false)
        views.setTextViewText(R.id.widget_next_label, context.getString(R.string.widget_next_empty_label))
        views.setTextViewText(R.id.widget_next_text, context.getString(R.string.widget_next_empty))
        views.setTextViewText(R.id.widget_progress, "")
        views.setProgressBar(R.id.widget_day_progress, 100, 0, false)
        views.setViewVisibility(R.id.widget_day_progress, View.INVISIBLE)
        val open = openAppIntent(context, -1)
        views.setOnClickPendingIntent(R.id.hero_card, open)
        views.setOnClickPendingIntent(R.id.hero_chip, open)
        views.setOnClickPendingIntent(R.id.widget_next, open)
        return views
    }

    /**
     * The hero: big time, state chip, the item, and how far the hour has run.
     */
    private fun bindHero(
        context: Context,
        views: RemoteViews,
        hero: JSONObject?,
        isToday: Boolean,
        minutesInto: Int,
        minutesLeft: Int,
    ) {
        val hour = hero?.optInt("hour", -1) ?: -1
        val status = hero?.optString("status") ?: "empty"
        val text = hero?.optString("text").orEmpty()

        views.setTextViewText(
            R.id.hero_time,
            hero?.optString("label").takeUnless { it.isNullOrEmpty() } ?: "--:--",
        )
        views.setProgressBar(R.id.hero_progress, 60, minutesInto, false)
        views.setViewVisibility(R.id.hero_chip, View.VISIBLE)
        views.setOnClickPendingIntent(R.id.hero_card, openAppIntent(context, hour))

        val chipClick = if (isToday && hour >= 0) {
            toggleIntent(context, status, hour)
        } else {
            openAppIntent(context, hour)
        }
        views.setOnClickPendingIntent(R.id.hero_chip, chipClick)

        when {
            !isToday -> {
                views.setInt(R.id.hero_card, "setBackgroundResource", R.drawable.bg_widget_hero_empty)
                setChip(
                    context,
                    views,
                    R.string.widget_chip_stale,
                    R.color.widget_muted,
                    R.drawable.bg_widget_chip_muted,
                )
                views.setTextViewText(
                    R.id.hero_text,
                    text.ifEmpty { context.getString(R.string.widget_empty_hint) },
                )
                views.setTextViewText(R.id.hero_meta, context.getString(R.string.widget_stale_hint))
            }

            status == "active" -> {
                views.setInt(R.id.hero_card, "setBackgroundResource", R.drawable.bg_widget_hero_active)
                setChip(
                    context,
                    views,
                    R.string.widget_chip_in_place,
                    R.color.widget_active_text,
                    R.drawable.bg_widget_chip_active,
                )
                views.setTextViewText(R.id.hero_text, text)
                views.setTextViewText(R.id.hero_meta, hourMeta(context, minutesInto, minutesLeft))
            }

            status == "completed" -> {
                views.setInt(R.id.hero_card, "setBackgroundResource", R.drawable.bg_widget_hero_done)
                setChip(
                    context,
                    views,
                    R.string.widget_done,
                    R.color.widget_done_text,
                    R.drawable.bg_widget_chip_done,
                )
                views.setTextViewText(R.id.hero_text, text)
                views.setTextViewText(R.id.hero_meta, hourMeta(context, minutesInto, minutesLeft))
            }

            else -> {
                views.setInt(R.id.hero_card, "setBackgroundResource", R.drawable.bg_widget_hero_empty)
                setChip(
                    context,
                    views,
                    R.string.widget_chip_free,
                    R.color.widget_muted,
                    R.drawable.bg_widget_chip_muted,
                )
                views.setTextViewText(R.id.hero_text, context.getString(R.string.widget_hero_empty))
                views.setTextViewText(R.id.hero_meta, context.getString(R.string.widget_hero_add))
            }
        }
    }

    /** The next planned hour, or a calm "nothing else" line. */
    private fun bindNext(
        context: Context,
        views: RemoteViews,
        next: JSONObject?,
        isToday: Boolean,
    ) {
        if (!isToday) {
            views.setTextViewText(R.id.widget_next_label, context.getString(R.string.widget_next_empty_label))
            views.setTextViewText(R.id.widget_next_text, context.getString(R.string.widget_stale_hint))
            views.setOnClickPendingIntent(R.id.widget_next, openAppIntent(context, -1))
            return
        }
        if (next == null) {
            views.setTextViewText(R.id.widget_next_label, context.getString(R.string.widget_next_empty_label))
            views.setTextViewText(R.id.widget_next_text, context.getString(R.string.widget_next_empty))
            views.setOnClickPendingIntent(R.id.widget_next, openAppIntent(context, -1))
            return
        }
        val label = next.optString("label")
        val text = next.optString("text")
        views.setTextViewText(R.id.widget_next_label, context.getString(R.string.widget_next, label))
        views.setTextViewText(
            R.id.widget_next_text,
            if (next.optString("status") == "completed") {
                context.getString(R.string.widget_next_done, text)
            } else {
                text
            },
        )
        views.setOnClickPendingIntent(R.id.widget_next, openAppIntent(context, next.optInt("hour", -1)))
    }

    /** Up to three compact rows under the hero. */
    private fun bindRows(
        context: Context,
        views: RemoteViews,
        slots: JSONArray,
        isToday: Boolean,
    ) {
        val last = minOf(slots.length() - 1, MAX_ROWS)
        for (index in 1..last) {
            val slot = slots.optJSONObject(index) ?: continue
            views.addView(R.id.slot_container, buildRow(context, slot, isToday))
        }
    }

    private fun buildRow(context: Context, slot: JSONObject, isToday: Boolean): RemoteViews {
        val hour = slot.optInt("hour", 0)
        val status = slot.optString("status")
        val text = slot.optString("text")
        val row = RemoteViews(context.packageName, R.layout.hourly_widget_row)

        row.setTextViewText(R.id.slot_hour, slot.optString("label"))
        row.setOnClickPendingIntent(R.id.slot_row, openAppIntent(context, hour))

        when (status) {
            "active" -> {
                row.setTextViewText(R.id.slot_text, text)
                row.setTextColor(R.id.slot_text, context.getColor(R.color.widget_text))
                row.setTextViewTextSize(R.id.slot_text, TypedValue.COMPLEX_UNIT_SP, 12.5f)
                row.setInt(R.id.slot_text, "setPaintFlags", Paint.ANTI_ALIAS_FLAG)
                row.setInt(R.id.slot_bar, "setBackgroundResource", R.drawable.bg_row_bar_active)
                applyRowChip(
                    context,
                    row,
                    R.string.widget_now,
                    R.color.widget_active_text,
                    R.drawable.bg_widget_chip_active,
                )
                if (isToday) {
                    row.setOnClickPendingIntent(R.id.slot_status, toggleIntent(context, status, hour))
                } else {
                    row.setOnClickPendingIntent(R.id.slot_status, openAppIntent(context, hour))
                }
            }

            "completed" -> {
                row.setTextViewText(R.id.slot_text, text)
                row.setTextColor(R.id.slot_text, context.getColor(R.color.widget_muted))
                row.setTextViewTextSize(R.id.slot_text, TypedValue.COMPLEX_UNIT_SP, 11.5f)
                row.setInt(
                    R.id.slot_text,
                    "setPaintFlags",
                    Paint.STRIKE_THRU_TEXT_FLAG or Paint.ANTI_ALIAS_FLAG,
                )
                row.setInt(R.id.slot_bar, "setBackgroundResource", R.drawable.bg_row_bar_done)
                applyRowChip(
                    context,
                    row,
                    R.string.widget_done,
                    R.color.widget_done_text,
                    R.drawable.bg_widget_chip_done,
                )
                if (isToday) {
                    row.setOnClickPendingIntent(R.id.slot_status, toggleIntent(context, status, hour))
                } else {
                    row.setOnClickPendingIntent(R.id.slot_status, openAppIntent(context, hour))
                }
            }

            else -> {
                row.setTextViewText(R.id.slot_text, context.getString(R.string.widget_free_hour))
                row.setTextColor(R.id.slot_text, context.getColor(R.color.widget_muted))
                row.setTextViewTextSize(R.id.slot_text, TypedValue.COMPLEX_UNIT_SP, 11.5f)
                row.setInt(R.id.slot_text, "setPaintFlags", Paint.ANTI_ALIAS_FLAG)
                row.setInt(R.id.slot_bar, "setBackgroundResource", R.drawable.bg_row_bar_empty)
                row.setViewVisibility(R.id.slot_status, View.GONE)
            }
        }
        return row
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
        views.setViewVisibility(R.id.hero_chip, View.VISIBLE)
    }

    private fun applyRowChip(
        context: Context,
        row: RemoteViews,
        textRes: Int,
        colorRes: Int,
        backgroundRes: Int,
    ) {
        row.setTextViewText(R.id.slot_status, context.getString(textRes))
        row.setTextColor(R.id.slot_status, context.getColor(colorRes))
        row.setInt(R.id.slot_status, "setBackgroundResource", backgroundRes)
        row.setViewVisibility(R.id.slot_status, View.VISIBLE)
    }

    private fun hourMeta(context: Context, minutesInto: Int, minutesLeft: Int): String {
        return when {
            minutesLeft <= 1 -> context.getString(R.string.widget_hour_ending)
            minutesInto == 0 -> context.getString(R.string.widget_hour_started)
            else -> context.getString(R.string.widget_minutes_left, minutesLeft)
        }
    }

    private fun footerText(context: Context, isToday: Boolean, done: Int, total: Int): String {
        return when {
            !isToday -> context.getString(R.string.widget_stale_hint)
            total == 0 -> context.getString(R.string.widget_no_items)
            done == total -> context.getString(R.string.widget_day_complete)
            else -> context.getString(R.string.widget_progress, done, total)
        }
    }

    private fun toggleIntent(context: Context, status: String, hour: Int): PendingIntent {
        // The Dart callback flips between in place and done.
        val uri = Uri.parse("hourly://toggle?date=${todayKey()}&hour=$hour&from=$status")
        return HomeWidgetBackgroundIntent.getBroadcast(context, uri)
    }

    private fun openAppIntent(context: Context, hour: Int): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            if (hour >= 0) {
                putExtra("hour", hour)
            }
        }
        val requestCode = if (hour >= 0) 100 + hour else 99
        return PendingIntent.getActivity(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun todayKey(): String =
        SimpleDateFormat("yyyy-MM-dd", Locale.getDefault()).format(Date())

    private companion object {
        const val PAYLOAD_KEY = "hourly_payload"
        const val MAX_ROWS = 3
    }
}
