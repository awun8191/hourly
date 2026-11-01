package com.awun.todo_app

import android.content.Context
import android.content.Intent
import android.graphics.Paint
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale

/**
 * Backs the widget's list of hour cards.
 *
 * The list is a rolling window: every hour after the live one, for 24 hours,
 * across midnight. The rows come from the payload when it covers the hour and
 * from the clock otherwise, so the widget stays full and scrollable even after
 * a long idle period.
 */
class HourlyWidgetService : RemoteViewsService() {

    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory =
        HourlySlotFactory(applicationContext)
}

private data class Slot(
    val date: String,
    val hour: Int,
    val label: String,
    val text: String,
    val status: String,
    val firstOfTomorrow: Boolean,
)

private class HourlySlotFactory(private val context: Context) :
    RemoteViewsService.RemoteViewsFactory {

    private var slots: List<Slot> = emptyList()

    override fun onCreate() = Unit

    override fun onDataSetChanged() {
        val now = Calendar.getInstance()
        val nowKey = keyOf(now.time)
        val nowHour = now.get(Calendar.HOUR_OF_DAY)
        val root = HomeWidgetPlugin.getData(context)
            .getString("hourly_payload", null)
            ?.let { runCatching { JSONObject(it) }.getOrNull() }
        val payload = root?.optJSONArray("slots")

        val parsed = ArrayList<Slot>()
        var seenTomorrow = false
        if (payload != null) {
            for (index in 0 until payload.length()) {
                val item = payload.optJSONObject(index) ?: continue
                val hour = item.optInt("hour", -1)
                val date = item.optString("date")
                if (hour !in 0..23 || date.isEmpty()) {
                    continue
                }
                if (!isAfter(date, hour, nowKey, nowHour)) {
                    continue
                }
                val tomorrow = date != nowKey
                parsed.add(
                    Slot(
                        date = date,
                        hour = hour,
                        label = item.optString("label"),
                        text = item.optString("text"),
                        status = item.optString("status"),
                        firstOfTomorrow = tomorrow && !seenTomorrow,
                    ),
                )
                if (tomorrow) {
                    seenTomorrow = true
                }
            }
        }
        slots = parsed.ifEmpty { clockOnly(now, nowKey) }
    }

    /** A full window of empty cards, so the list is never blank. */
    private fun clockOnly(now: Calendar, nowKey: String): List<Slot> {
        val result = ArrayList<Slot>()
        var seenTomorrow = false
        val start = now.clone() as Calendar
        start.add(Calendar.HOUR_OF_DAY, 1)
        start.set(Calendar.MINUTE, 0)
        for (index in 0 until WINDOW) {
            val date = dateKey(start.time)
            val hour = start.get(Calendar.HOUR_OF_DAY)
            val tomorrow = date != nowKey
            result.add(
                Slot(
                    date = date,
                    hour = hour,
                    label = String.format(Locale.getDefault(), "%02d:00", hour),
                    text = "",
                    status = "empty",
                    firstOfTomorrow = tomorrow && !seenTomorrow,
                ),
            )
            if (tomorrow) {
                seenTomorrow = true
            }
            start.add(Calendar.HOUR_OF_DAY, 1)
        }
        return result
    }

    override fun getCount(): Int = slots.size

    override fun getViewAt(position: Int): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.hourly_widget_slot)
        if (position !in slots.indices) {
            return views
        }
        val slot = slots[position]
        views.setTextViewText(R.id.slot_hour, slot.label)
        views.setTextViewText(R.id.slot_tag, context.getString(R.string.widget_tomorrow))
        views.setViewVisibility(
            R.id.slot_tag,
            if (slot.firstOfTomorrow) View.VISIBLE else View.GONE,
        )

        when (slot.status) {
            "completed" -> {
                views.setTextViewText(R.id.slot_text, slot.text)
                views.setTextColor(R.id.slot_text, context.getColor(R.color.widget_done_text))
                views.setInt(
                    R.id.slot_text,
                    "setPaintFlags",
                    Paint.STRIKE_THRU_TEXT_FLAG or Paint.ANTI_ALIAS_FLAG,
                )
            }

            "active" -> {
                views.setTextViewText(R.id.slot_text, slot.text)
                views.setTextColor(R.id.slot_text, context.getColor(R.color.widget_text))
                views.setInt(R.id.slot_text, "setPaintFlags", Paint.ANTI_ALIAS_FLAG)
            }

            else -> {
                views.setTextViewText(R.id.slot_text, context.getString(R.string.widget_slot_add))
                views.setTextColor(R.id.slot_text, context.getColor(R.color.widget_muted))
                views.setInt(R.id.slot_text, "setPaintFlags", Paint.ANTI_ALIAS_FLAG)
            }
        }
        views.setOnClickFillInIntent(
            R.id.slot_card,
            Intent().apply {
                data = Uri.parse("hourly://edit?date=${slot.date}&hour=${slot.hour}")
            },
        )
        return views
    }

    override fun getLoadingView(): RemoteViews? = null

    override fun getViewTypeCount(): Int = 1

    override fun getItemId(position: Int): Long = position.toLong()

    override fun hasStableIds(): Boolean = false

    override fun onDestroy() {
        slots = emptyList()
    }

    private fun isAfter(date: String, hour: Int, nowKey: String, nowHour: Int): Boolean =
        date > nowKey || (date == nowKey && hour > nowHour)

    private fun keyOf(date: Date): String = dateKey(date)

    private fun dateKey(date: Date): String =
        SimpleDateFormat("yyyy-MM-dd", Locale.getDefault()).format(date)

    private companion object {
        const val WINDOW = 24
    }
}
