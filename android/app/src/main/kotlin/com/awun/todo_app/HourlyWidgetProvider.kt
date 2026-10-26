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
 * Home screen widget: the current hour and the four hours after it.
 *
 * The app sends a JSON document through `home_widget` under the key
 * `hourly_payload`. Each row shows the hour, the item, and a state chip.
 * A tap on the chip toggles the item through a Dart background callback.
 */
class HourlyWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val payload = widgetData.getString("hourly_payload", null)
        appWidgetIds.forEach { widgetId ->
            appWidgetManager.updateAppWidget(widgetId, buildViews(context, payload))
        }
    }

    private fun buildViews(context: Context, payload: String?): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.hourly_widget)
        views.removeAllViews(R.id.slot_container)

        if (payload == null) {
            views.setTextViewText(R.id.widget_day, context.getString(R.string.app_name))
            views.setTextViewText(R.id.widget_progress, context.getString(R.string.widget_empty_hint))
            return views
        }

        val root = JSONObject(payload)
        val date = root.optString("date")
        val today = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault()).format(Date())
        val isToday = date == today
        val done = root.optInt("done", 0)
        val total = root.optInt("total", 0)

        views.setTextViewText(
            R.id.widget_day,
            if (isToday) root.optString("day") else context.getString(R.string.widget_stale_day),
        )
        views.setTextViewText(
            R.id.widget_progress,
            when {
                !isToday -> context.getString(R.string.widget_stale_hint)
                total == 0 -> context.getString(R.string.widget_no_items)
                else -> context.getString(R.string.widget_progress, done, total)
            },
        )

        val slots = root.optJSONArray("slots") ?: JSONArray()
        for (index in 0 until slots.length()) {
            views.addView(
                R.id.slot_container,
                buildRow(context, date, slots.optJSONObject(index) ?: continue),
            )
        }
        return views
    }

    private fun buildRow(context: Context, date: String, slot: JSONObject): RemoteViews {
        val hour = slot.optInt("hour", 0)
        val text = slot.optString("text")
        val status = slot.optString("status")
        val row = RemoteViews(context.packageName, R.layout.hourly_widget_row)

        row.setTextViewText(R.id.slot_hour, slot.optString("label"))

        when (status) {
            "active" -> {
                row.setTextViewText(R.id.slot_text, text)
                row.setTextColor(R.id.slot_text, context.getColor(R.color.widget_text))
                row.setTextViewTextSize(
                    R.id.slot_text,
                    TypedValue.COMPLEX_UNIT_SP,
                    14f,
                )
                row.setInt(R.id.slot_text, "setPaintFlags", Paint.ANTI_ALIAS_FLAG)
                row.setTextViewText(R.id.slot_status, context.getString(R.string.widget_now))
                row.setTextColor(R.id.slot_status, context.getColor(R.color.widget_active_text))
                row.setInt(
                    R.id.slot_status,
                    "setBackgroundResource",
                    R.drawable.bg_widget_chip_active,
                )
                row.setViewVisibility(R.id.slot_status, View.VISIBLE)
                row.setOnClickPendingIntent(
                    R.id.slot_status,
                    toggleIntent(context, date, hour),
                )
            }

            "completed" -> {
                row.setTextViewText(R.id.slot_text, text)
                row.setTextColor(R.id.slot_text, context.getColor(R.color.widget_done_text))
                row.setTextViewTextSize(
                    R.id.slot_text,
                    TypedValue.COMPLEX_UNIT_SP,
                    12f,
                )
                row.setInt(
                    R.id.slot_text,
                    "setPaintFlags",
                    Paint.STRIKE_THRU_TEXT_FLAG or Paint.ANTI_ALIAS_FLAG,
                )
                row.setTextViewText(R.id.slot_status, context.getString(R.string.widget_done))
                row.setTextColor(R.id.slot_status, context.getColor(R.color.widget_done_text))
                row.setInt(
                    R.id.slot_status,
                    "setBackgroundResource",
                    R.drawable.bg_widget_chip_done,
                )
                row.setViewVisibility(R.id.slot_status, View.VISIBLE)
                row.setOnClickPendingIntent(
                    R.id.slot_status,
                    toggleIntent(context, date, hour),
                )
            }

            else -> {
                row.setTextViewText(R.id.slot_text, context.getString(R.string.widget_add))
                row.setTextColor(R.id.slot_text, context.getColor(R.color.widget_muted))
                row.setTextViewTextSize(
                    R.id.slot_text,
                    TypedValue.COMPLEX_UNIT_SP,
                    13f,
                )
                row.setInt(R.id.slot_text, "setPaintFlags", Paint.ANTI_ALIAS_FLAG)
                row.setViewVisibility(R.id.slot_status, View.GONE)
            }
        }

        row.setOnClickPendingIntent(R.id.slot_row, openAppIntent(context, hour))
        return row
    }

    private fun toggleIntent(context: Context, date: String, hour: Int): PendingIntent {
        val uri = Uri.parse("hourly://toggle?date=$date&hour=$hour")
        return HomeWidgetBackgroundIntent.getBroadcast(context, uri)
    }

    private fun openAppIntent(context: Context, hour: Int): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("hour", hour)
        }
        return PendingIntent.getActivity(
            context,
            100 + hour,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }
}
