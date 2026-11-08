package com.awun.todo_app

import android.content.Context
import android.content.Intent
import android.graphics.Paint
import android.net.Uri
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
 * across midnight. A header names each day (`TODAY`, `TOMORROW · SUN 1`), and it
 * is computed from the device clock, so it follows the day change by itself.
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
)

private sealed interface Row {
    data class Header(val label: String) : Row
    data class Card(val slot: Slot) : Row
}

private class HourlySlotFactory(private val context: Context) :
    RemoteViewsService.RemoteViewsFactory {

    private var rows: List<Row> = emptyList()

    override fun onCreate() = Unit

    override fun onDataSetChanged() {
        val now = Calendar.getInstance()
        val nowKey = keyOf(now.time)
        val nowHour = now.get(Calendar.HOUR_OF_DAY)
        val root = HomeWidgetPlugin.getData(context)
            .getString("hourly_payload", null)
            ?.let { runCatching { JSONObject(it) }.getOrNull() }
        val payload = root?.optJSONArray("slots")

        val slots = ArrayList<Slot>()
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
                slots.add(
                    Slot(
                        date = date,
                        hour = hour,
                        label = item.optString("label"),
                        text = item.optString("text"),
                        status = item.optString("status"),
                    ),
                )
            }
        }
        val window = slots.ifEmpty { clockOnly(now) }
        rows = withHeaders(window, nowKey)
    }

    /** A full window of empty cards, so the list is never blank. */
    private fun clockOnly(now: Calendar): List<Slot> {
        val result = ArrayList<Slot>()
        val start = now.clone() as Calendar
        start.add(Calendar.HOUR_OF_DAY, 1)
        start.set(Calendar.MINUTE, 0)
        for (index in 0 until WINDOW) {
            val hour = start.get(Calendar.HOUR_OF_DAY)
            result.add(
                Slot(
                    date = dateKey(start.time),
                    hour = hour,
                    label = String.format(Locale.getDefault(), "%02d:00", hour),
                    text = "",
                    status = "empty",
                ),
            )
            start.add(Calendar.HOUR_OF_DAY, 1)
        }
        return result
    }

    private fun withHeaders(slots: List<Slot>, nowKey: String): List<Row> {
        val result = ArrayList<Row>()
        var lastDate: String? = null
        for (slot in slots) {
            if (slot.date != lastDate) {
                result.add(Row.Header(headerLabel(slot.date, nowKey)))
                lastDate = slot.date
            }
            result.add(Row.Card(slot))
        }
        return result
    }

    private fun headerLabel(date: String, nowKey: String): String {
        if (date == nowKey) {
            return context.getString(R.string.widget_today)
        }
        val parsed = runCatching {
            SimpleDateFormat("yyyy-MM-dd", Locale.getDefault()).parse(date)
        }.getOrNull() ?: return context.getString(R.string.widget_tomorrow)
        val short = SimpleDateFormat("EEE d", Locale.getDefault())
            .format(parsed)
            .uppercase(Locale.getDefault())
        return context.getString(R.string.widget_section_tomorrow, short)
    }

    override fun getCount(): Int = rows.size

    override fun getViewTypeCount(): Int = 2

    override fun getViewAt(position: Int): RemoteViews = when (val row = rows[position]) {
        is Row.Header -> RemoteViews(context.packageName, R.layout.hourly_widget_section).apply {
            setTextViewText(R.id.section_label, row.label)
        }

        is Row.Card -> cardViews(row.slot)
    }

    private fun cardViews(slot: Slot): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.hourly_widget_slot)
        views.setTextViewText(R.id.slot_hour, slot.label)
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

    override fun getItemId(position: Int): Long = position.toLong()

    override fun hasStableIds(): Boolean = false

    override fun onDestroy() {
        rows = emptyList()
    }

    private fun isAfter(date: String, hour: Int, nowKey: String, nowHour: Int): Boolean =
        date > nowKey || (date == nowKey && hour > nowHour)

    private fun keyOf(date: Date): String = dateKey(date)

    private fun dateKey(date: Date): String =
        SimpleDateFormat("yyyy-MM-dd", Locale.getDefault()).format(date)

    private companion object {
        const val WINDOW = 24
        const val TYPE_HEADER = 0
        const val TYPE_CARD = 1
    }
}
