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
 * The list is the whole of today, midnight to 23:00, under one header. The
 * live hour carries an accent border and a NOW tag, a past hour still in place
 * reads MISSED, and everything else matches the hero card states. It resets at
 * midnight by itself: the payload only carries today, and the clock picks the
 * live row.
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
                if (hour !in 0..23 || date != nowKey) {
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
        val day = slots.ifEmpty { clockOnly(nowKey) }.sortedBy { it.hour }
        val result = ArrayList<Row>()
        result.add(Row.Header(todayHeader()))
        for (slot in day) {
            result.add(Row.Card(slot))
        }
        rows = result
    }

    /** A full day of empty cards, so the list is never blank. */
    private fun clockOnly(nowKey: String): List<Slot> {
        val result = ArrayList<Slot>()
        for (hour in 0..23) {
            result.add(
                Slot(
                    date = nowKey,
                    hour = hour,
                    label = String.format(Locale.getDefault(), "%02d:00", hour),
                    text = "",
                    status = "empty",
                ),
            )
        }
        return result
    }

    private fun todayHeader(): String {
        val label = SimpleDateFormat("EEEE d", Locale.getDefault())
            .format(Date())
            .uppercase(Locale.getDefault())
        return context.getString(R.string.widget_section_today, label)
    }

    override fun getCount(): Int = rows.size

    override fun getViewTypeCount(): Int = 2

    override fun getViewAt(position: Int): RemoteViews {
        if (position !in rows.indices) {
            return RemoteViews(context.packageName, R.layout.hourly_widget_slot)
        }
        return when (val row = rows[position]) {
            is Row.Header -> RemoteViews(context.packageName, R.layout.hourly_widget_section).apply {
                setTextViewText(R.id.section_label, row.label)
            }

            is Row.Card -> cardViews(row.slot, Calendar.getInstance().get(Calendar.HOUR_OF_DAY))
        }
    }

    private fun cardViews(slot: Slot, nowHour: Int): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.hourly_widget_slot)
        views.setTextViewText(R.id.slot_hour, slot.label)

        val isLive = slot.hour == nowHour
        val isPast = slot.hour < nowHour
        views.setViewVisibility(R.id.slot_now, if (isLive) View.VISIBLE else View.GONE)
        if (isLive) {
            views.setTextViewText(R.id.slot_now, context.getString(R.string.widget_now))
        }
        views.setInt(
            R.id.slot_card,
            "setBackgroundResource",
            if (isLive) R.drawable.bg_widget_slot_live else R.drawable.bg_widget_slot,
        )

        when {
            slot.status == "completed" -> {
                views.setTextViewText(R.id.slot_text, slot.text)
                views.setTextColor(R.id.slot_text, context.getColor(R.color.widget_done_text))
                views.setInt(
                    R.id.slot_text,
                    "setPaintFlags",
                    Paint.STRIKE_THRU_TEXT_FLAG or Paint.ANTI_ALIAS_FLAG,
                )
            }

            slot.status == "active" && isPast -> {
                views.setTextViewText(R.id.slot_text, slot.text)
                views.setTextColor(R.id.slot_text, context.getColor(R.color.widget_missed_text))
                views.setInt(R.id.slot_text, "setPaintFlags", Paint.ANTI_ALIAS_FLAG)
            }

            slot.status == "active" -> {
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

    private fun keyOf(date: Date): String =
        SimpleDateFormat("yyyy-MM-dd", Locale.getDefault()).format(date)

    private companion object {
        const val HOURS = 24
    }
}
