package com.awun.todo_app

import android.content.Context
import android.content.Intent
import android.graphics.Paint
import android.net.Uri
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONObject

/**
 * Backs the widget's list of hour fields.
 *
 * Android cannot scroll a widget without a collection view, so the fields live
 * in a ListView driven by this service. Each item is a card that fills the
 * quick add dialog for its own hour.
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

private class HourlySlotFactory(private val context: Context) :
    RemoteViewsService.RemoteViewsFactory {

    private var slots: List<Slot> = emptyList()

    override fun onCreate() = Unit

    override fun onDataSetChanged() {
        val raw = HomeWidgetPlugin.getData(context).getString("hourly_payload", null)
        val root = raw?.let { runCatching { JSONObject(it) }.getOrNull() }
        val date = root?.optString("date").orEmpty()
        val upcoming = root?.optJSONArray("upcoming")
        val parsed = ArrayList<Slot>()
        if (upcoming != null) {
            for (index in 0 until upcoming.length()) {
                val item = upcoming.optJSONObject(index) ?: continue
                val hour = item.optInt("hour", -1)
                if (hour !in 0..23) {
                    continue
                }
                parsed.add(
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
        slots = parsed
    }

    override fun getCount(): Int = slots.size

    override fun getViewAt(position: Int): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.hourly_widget_slot)
        if (position !in slots.indices) {
            return views
        }
        val slot = slots[position]
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

    override fun getViewTypeCount(): Int = 1

    override fun getItemId(position: Int): Long = position.toLong()

    override fun hasStableIds(): Boolean = false

    override fun onDestroy() {
        slots = emptyList()
    }
}
