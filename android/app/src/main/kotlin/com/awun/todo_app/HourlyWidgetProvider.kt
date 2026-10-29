package com.awun.todo_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Paint
import android.net.Uri
import android.os.Bundle
import android.util.TypedValue
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONArray
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale

/**
 * Home screen widget: the day in hour order, the live hour as the hero card,
 * and a segmented day meter.
 *
 * The app sends a JSON document through `home_widget` under the key
 * `hourly_payload`. The hero chip and each row chip toggle the item through a
 * Dart background callback; a tap on a row opens the app at that hour.
 *
 * The widget resizes from a 2x2 cell to a full screen card, so it renders one
 * of three layouts and rebuilds itself when the launcher reports a new size.
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
            appWidgetManager.updateAppWidget(
                widgetId,
                buildViews(context, payload, appWidgetManager.getAppWidgetOptions(widgetId)),
            )
        }
    }

    /** The user resized the widget: repaint it in the layout its size earns. */
    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle,
    ) {
        super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
        val payload = HomeWidgetPlugin.getData(context).getString(PAYLOAD_KEY, null)
        appWidgetManager.updateAppWidget(appWidgetId, buildViews(context, payload, newOptions))
    }

    // ---------------------------------------------------------------- build

    /**
     * The launcher reports the placement size in dp. Missing values fall back
     * to the 4x3 default so a widget always gets a sensible layout.
     */
    private fun decisionFor(options: Bundle?): WidgetSize.Decision {
        fun option(key: String): Int = options?.getInt(key, 0) ?: 0
        val minWidth = option(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH)
        val minHeight = option(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT)
        return WidgetSize.decide(
            minWidthDp = if (minWidth > 0) minWidth else DEFAULT_MIN_WIDTH_DP,
            minHeightDp = if (minHeight > 0) minHeight else DEFAULT_MIN_HEIGHT_DP,
            maxWidthDp = option(AppWidgetManager.OPTION_APPWIDGET_MAX_WIDTH),
            maxHeightDp = option(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT),
        )
    }

    private fun layoutFor(bucket: WidgetSize.Bucket): Int = when (bucket) {
        WidgetSize.Bucket.compact -> R.layout.hourly_widget_compact
        WidgetSize.Bucket.medium -> R.layout.hourly_widget
        WidgetSize.Bucket.large -> R.layout.hourly_widget_large
    }

    private fun buildViews(context: Context, payload: String?, options: Bundle?): RemoteViews {
        val decision = decisionFor(options)
        val views = RemoteViews(context.packageName, layoutFor(decision.bucket))
        val root = payload?.let { runCatching { JSONObject(it) }.getOrNull() }
        val scale = scaleFor(decision.bucket, decision.heightDp)
        if (root == null) {
            return emptyViews(context, views, decision, scale)
        }

        val dateKey = root.optString("date")
        val isToday = dateKey == todayKey()
        val dayLabel = root.optString("day")
        val done = root.optInt("done", 0)
        val total = root.optInt("total", 0)
        val minutesInto = root.optInt("minutesIntoHour", 0).coerceIn(0, 59)
        val minutesLeft = root.optInt("minutesLeft", 60 - minutesInto).coerceIn(0, 60)
        val liveHour = root.optInt("nowHour", -1).takeIf { it in 0..23 } ?: currentHour()
        val entries = readEntries(root)

        bindChrome(context, views, decision, dayLabel, isToday, done, total, scale)
        bindBody(context, views, decision, entries, liveHour, isToday, minutesInto, minutesLeft, scale)
        bindFooter(context, views, decision, entries, liveHour, isToday)
        return views
    }

    /** No payload yet: a quiet card that opens the app. */
    private fun emptyViews(
        context: Context,
        views: RemoteViews,
        decision: WidgetSize.Decision,
        scale: TypeScale,
    ): RemoteViews {
        val slot = HourSlot(currentHour(), "empty", "")
        views.setTextViewText(R.id.widget_day, "")
        views.setTextViewTextSize(R.id.widget_day, TypedValue.COMPLEX_UNIT_SP, scale.day)
        if (decision.bucket == WidgetSize.Bucket.compact) {
            views.setViewVisibility(R.id.widget_progress, View.GONE)
            bindHero(context, views, slot, HeroMode.empty, 0, 60, scale)
            return views
        }
        views.setTextViewText(R.id.widget_progress, "")
        views.setTextViewTextSize(R.id.widget_brand, TypedValue.COMPLEX_UNIT_SP, scale.brand)
        views.setTextViewTextSize(R.id.widget_progress, TypedValue.COMPLEX_UNIT_SP, scale.footer)
        views.setViewVisibility(R.id.widget_body, View.VISIBLE)
        views.removeAllViews(R.id.widget_body)
        if (decision.bucket == WidgetSize.Bucket.large) {
            views.setViewVisibility(R.id.widget_nothing_line, View.GONE)
        }
        // The strip is still a day at a glance: 24 free hours, no ring.
        bindDayStrip(context, views, emptyList(), -1, false)

        val hero = RemoteViews(context.packageName, R.layout.hourly_widget_hero)
        bindHero(context, hero, slot, HeroMode.empty, 0, 60, scale)
        views.addView(R.id.widget_body, hero)

        val filler = RemoteViews(context.packageName, R.layout.hourly_widget_filler)
        filler.setTextViewText(R.id.widget_filler_line, context.getString(R.string.widget_empty_hint))
        filler.setTextViewTextSize(R.id.widget_filler_line, TypedValue.COMPLEX_UNIT_SP, scale.more)
        views.addView(R.id.widget_body, filler)

        val open = openAppIntent(context, -1)
        views.setOnClickPendingIntent(R.id.hero_card, open)
        views.setOnClickPendingIntent(R.id.hero_chip, open)
        views.setOnClickPendingIntent(R.id.widget_brand, open)
        views.setOnClickPendingIntent(R.id.widget_day, open)
        return views
    }

    /** Brand, day label, and the footer count. The compact layout has no brand. */
    private fun bindChrome(
        context: Context,
        views: RemoteViews,
        decision: WidgetSize.Decision,
        dayLabel: String,
        isToday: Boolean,
        done: Int,
        total: Int,
        scale: TypeScale,
    ) {
        val locale = Locale.getDefault()
        val dayText = if (isToday || dayLabel.isEmpty()) {
            dayLabel.uppercase(locale)
        } else {
            context.getString(R.string.widget_stale_day, dayLabel).uppercase(locale)
        }
        val open = openAppIntent(context, -1)

        views.setTextViewText(R.id.widget_day, dayText)
        views.setTextViewTextSize(R.id.widget_day, TypedValue.COMPLEX_UNIT_SP, scale.day)
        views.setOnClickPendingIntent(R.id.widget_day, open)

        views.setTextViewText(R.id.widget_progress, footerText(context, isToday, done, total))
        views.setTextViewTextSize(R.id.widget_progress, TypedValue.COMPLEX_UNIT_SP, scale.footer)

        if (decision.bucket == WidgetSize.Bucket.compact) {
            // A 2x2 card has no room for the count; it is the first line to go.
            views.setViewVisibility(
                R.id.widget_progress,
                if (decision.heightDp >= WidgetSize.COMPACT_FOOTER_HEIGHT_DP) {
                    View.VISIBLE
                } else {
                    View.GONE
                },
            )
            return
        }

        views.setTextViewText(R.id.widget_brand, context.getString(R.string.widget_brand))
        views.setTextViewTextSize(R.id.widget_brand, TypedValue.COMPLEX_UNIT_SP, scale.brand)
        views.setOnClickPendingIntent(R.id.widget_brand, open)
    }

    /**
     * Paints the body: the day in hour order, the live hour as the hero card.
     *
     * The compact bucket has no body container, so its layout already holds the
     * hero card at the top level.
     */
    private fun bindBody(
        context: Context,
        views: RemoteViews,
        decision: WidgetSize.Decision,
        entries: List<HourSlot>,
        liveHour: Int,
        isToday: Boolean,
        minutesInto: Int,
        minutesLeft: Int,
        scale: TypeScale,
    ) {
        val live = entries.firstOrNull { it.hour == liveHour }
            ?: HourSlot(liveHour, "empty", "")

        if (decision.bucket == WidgetSize.Bucket.compact) {
            bindHero(context, views, live, if (isToday) HeroMode.live else HeroMode.stale, minutesInto, minutesLeft, scale)
            return
        }

        views.removeAllViews(R.id.widget_body)
        val plan = WidgetDayPlan.build(
            entries = entries,
            liveHour = liveHour,
            cells = decision.cells,
            includePast = decision.bucket == WidgetSize.Bucket.large,
        )
        val rowLayout = if (decision.bucket == WidgetSize.Bucket.large) {
            R.layout.hourly_widget_row_tall
        } else {
            R.layout.hourly_widget_row
        }
        plan.forEach { item ->
            val child: RemoteViews? = when (item.kind) {
                BodyItemKind.hero -> {
                    val hero = RemoteViews(context.packageName, R.layout.hourly_widget_hero)
                    bindHero(
                        context = context,
                        views = hero,
                        slot = item.slot ?: live,
                        mode = if (isToday) HeroMode.live else HeroMode.stale,
                        minutesInto = minutesInto,
                        minutesLeft = minutesLeft,
                        scale = scale,
                    )
                    hero
                }

                BodyItemKind.row ->
                    buildRow(context, item.slot!!, isToday, liveHour, scale, rowLayout)

                BodyItemKind.earlier -> moreLine(
                    context,
                    context.getString(R.string.widget_earlier_hours, item.count),
                    scale,
                )

                BodyItemKind.later -> moreLine(
                    context,
                    context.getString(R.string.widget_more_hours, item.count),
                    scale,
                )

                // The large bucket says this once, in the panel under the strip,
                // and a one cell card is the hero itself: the count line under
                // the strip already carries the day. So the body stays a plain
                // list of hours wherever there is a footer to speak for it.
                BodyItemKind.filler -> if (decision.bucket == WidgetSize.Bucket.large ||
                    decision.cells <= 1
                ) {
                    null
                } else {
                    val filler = RemoteViews(context.packageName, R.layout.hourly_widget_filler)
                    filler.setTextViewText(
                        R.id.widget_filler_line,
                        context.getString(R.string.widget_nothing_else),
                    )
                    filler.setTextViewTextSize(
                        R.id.widget_filler_line,
                        TypedValue.COMPLEX_UNIT_SP,
                        scale.more,
                    )
                    filler
                }
            }
            if (child != null) {
                views.addView(R.id.widget_body, child)
            }
        }
    }

    /**
     * The hero card: big time, NOW tag, state chip, the item, and how far the
     * hour has run. The minutes bar is time, not work, so it stays continuous.
     */
    private fun bindHero(
        context: Context,
        views: RemoteViews,
        slot: HourSlot,
        mode: HeroMode,
        minutesInto: Int,
        minutesLeft: Int,
        scale: TypeScale,
    ) {
        views.setTextViewText(R.id.hero_time, hourLabel(slot.hour))
        views.setTextViewTextSize(R.id.hero_time, TypedValue.COMPLEX_UNIT_SP, scale.heroTime)
        views.setTextViewTextSize(R.id.hero_text, TypedValue.COMPLEX_UNIT_SP, scale.heroText)
        views.setTextViewTextSize(R.id.hero_meta, TypedValue.COMPLEX_UNIT_SP, scale.heroMeta)
        views.setTextViewTextSize(R.id.hero_chip, TypedValue.COMPLEX_UNIT_SP, scale.chip)
        views.setTextViewTextSize(R.id.hero_now, TypedValue.COMPLEX_UNIT_SP, scale.chip)
        views.setProgressBar(R.id.hero_progress, 60, minutesInto, false)
        views.setViewVisibility(R.id.hero_chip, View.VISIBLE)
        // The compact card carries NOW inside its one chip, and hides the bar's
        // sibling meta so a 4x2 placement cannot show two tiny floating labels.
        views.setViewVisibility(
            R.id.hero_now,
            if (mode == HeroMode.live && !scale.compactLayout) View.VISIBLE else View.GONE,
        )
        views.setViewVisibility(R.id.hero_progress, View.VISIBLE)
        views.setViewVisibility(
            R.id.hero_meta,
            if (scale.showHeroMeta) View.VISIBLE else View.GONE,
        )
        views.setOnClickPendingIntent(R.id.hero_card, openAppIntent(context, slot.hour))

        val chipClick = if (mode == HeroMode.live) {
            toggleIntent(context, slot.state, slot.hour)
        } else {
            openAppIntent(context, slot.hour)
        }
        views.setOnClickPendingIntent(R.id.hero_chip, chipClick)

        val meta = when (mode) {
            HeroMode.stale -> context.getString(R.string.widget_stale_hint)
            HeroMode.empty -> context.getString(R.string.widget_open_app)
            HeroMode.live -> hourMeta(context, minutesInto, minutesLeft, scale.compactLayout)
        }
        val chipNow = mode == HeroMode.live && scale.compactLayout

        when {
            mode == HeroMode.stale -> {
                views.setInt(R.id.hero_card, "setBackgroundResource", R.drawable.bg_widget_hero_empty)
                setChip(context, views, R.string.widget_chip_stale, R.color.widget_muted, R.drawable.bg_widget_chip_muted, chipNow = false)
                views.setTextViewText(R.id.hero_text, slot.text.ifEmpty { context.getString(R.string.widget_empty_hint) })
                views.setTextViewText(R.id.hero_meta, meta)
            }

            mode == HeroMode.empty || slot.state == "empty" -> {
                views.setInt(R.id.hero_card, "setBackgroundResource", R.drawable.bg_widget_hero_empty)
                setChip(context, views, R.string.widget_chip_free, R.color.widget_muted, R.drawable.bg_widget_chip_muted, chipNow = false)
                views.setTextViewText(R.id.hero_text, context.getString(R.string.widget_hero_empty))
                views.setTextViewText(R.id.hero_meta, meta)
            }

            slot.state == "completed" -> {
                views.setInt(R.id.hero_card, "setBackgroundResource", R.drawable.bg_widget_hero_done)
                setChip(context, views, R.string.widget_done, R.color.widget_done_text, R.drawable.bg_widget_chip_done, chipNow)
                views.setTextViewText(R.id.hero_text, slot.text)
                views.setTextViewText(R.id.hero_meta, meta)
            }

            else -> {
                views.setInt(R.id.hero_card, "setBackgroundResource", R.drawable.bg_widget_hero_active)
                setChip(context, views, R.string.widget_chip_in_place, R.color.widget_active_text, R.drawable.bg_widget_chip_active, chipNow)
                views.setTextViewText(R.id.hero_text, slot.text)
                views.setTextViewText(R.id.hero_meta, meta)
            }
        }
    }

    /**
     * One hour row. Only the hero says NOW; a row says IN PLACE, DONE, MISSED,
     * or FREE. A row whose hour has already gone by and that is still in place
     * reads MISSED, never IN PLACE: the plan did not happen, and the green chip
     * said it did.
     */
    private fun buildRow(
        context: Context,
        slot: HourSlot,
        isToday: Boolean,
        liveHour: Int,
        scale: TypeScale,
        layout: Int,
    ): RemoteViews {
        val row = RemoteViews(context.packageName, layout)
        val state = WidgetDayPlan.rowStateFor(slot, liveHour, isToday)

        row.setTextViewText(R.id.slot_hour, hourLabel(slot.hour))
        row.setTextViewTextSize(R.id.slot_hour, TypedValue.COMPLEX_UNIT_SP, scale.rowHour)
        row.setTextViewTextSize(R.id.slot_text, TypedValue.COMPLEX_UNIT_SP, scale.rowText)
        row.setTextViewTextSize(R.id.slot_status, TypedValue.COMPLEX_UNIT_SP, scale.rowChip)
        row.setOnClickPendingIntent(R.id.slot_row, openAppIntent(context, slot.hour))

        when (state) {
            RowState.inPlace -> {
                row.setTextViewText(R.id.slot_text, slot.text)
                row.setTextColor(R.id.slot_text, context.getColor(R.color.widget_text))
                row.setInt(R.id.slot_text, "setPaintFlags", Paint.ANTI_ALIAS_FLAG)
                row.setInt(R.id.slot_bar, "setBackgroundResource", R.drawable.bg_row_bar_active)
                applyRowChip(
                    context,
                    row,
                    R.string.widget_chip_in_place,
                    R.color.widget_active_text,
                    R.drawable.bg_widget_chip_active,
                )
            }

            RowState.done -> {
                row.setTextViewText(R.id.slot_text, slot.text)
                row.setTextColor(R.id.slot_text, context.getColor(R.color.widget_muted))
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
            }

            RowState.missed -> {
                row.setTextViewText(R.id.slot_text, slot.text)
                row.setTextColor(R.id.slot_text, context.getColor(R.color.widget_muted))
                row.setInt(R.id.slot_text, "setPaintFlags", Paint.ANTI_ALIAS_FLAG)
                row.setInt(R.id.slot_bar, "setBackgroundResource", R.drawable.bg_row_bar_missed)
                applyRowChip(
                    context,
                    row,
                    R.string.widget_chip_missed,
                    R.color.widget_missed_text,
                    R.drawable.bg_widget_chip_missed,
                )
            }

            RowState.free -> {
                row.setTextViewText(R.id.slot_text, context.getString(R.string.widget_free_hour))
                row.setTextColor(R.id.slot_text, context.getColor(R.color.widget_muted))
                row.setInt(R.id.slot_text, "setPaintFlags", Paint.ANTI_ALIAS_FLAG)
                row.setInt(R.id.slot_bar, "setBackgroundResource", R.drawable.bg_row_bar_empty)
                applyRowChip(
                    context,
                    row,
                    R.string.widget_chip_free,
                    R.color.widget_muted,
                    R.drawable.bg_widget_chip_muted,
                )
            }
        }

        if (isToday && slot.state != "empty") {
            // A missed hour still toggles: the user can mark it done late.
            row.setOnClickPendingIntent(
                R.id.slot_status,
                toggleIntent(context, slot.state, slot.hour),
            )
        } else if (isToday) {
            row.setOnClickPendingIntent(R.id.slot_status, openAppIntent(context, slot.hour))
        }
        return row
    }

    /**
     * The footer. The day strip is one tick per hour of the day, 00 to 23, in
     * hour order: red for done, green for in place, muted red for missed, the
     * faint track for a free hour, and a ring on the live hour. A tinted week of
     * planned hours alone (the old meter) had no empty hours to sit against, so
     * it read as a second progress bar; the whole day does not.
     *
     * The large bucket adds the labels, the quiet line, the count, and the
     * legend; the medium bucket keeps the strip and the count.
     */
    private fun bindFooter(
        context: Context,
        views: RemoteViews,
        decision: WidgetSize.Decision,
        entries: List<HourSlot>,
        liveHour: Int,
        isToday: Boolean,
    ) {
        if (decision.bucket == WidgetSize.Bucket.compact) {
            return
        }
        bindDayStrip(context, views, entries, liveHour, isToday)
        if (decision.bucket == WidgetSize.Bucket.large) {
            views.setViewVisibility(
                R.id.widget_nothing_line,
                if (isToday && !WidgetDayPlan.hasUpcoming(entries, liveHour)) {
                    View.VISIBLE
                } else {
                    View.GONE
                },
            )
        }
    }

    /** 24 ticks, one per hour, added in hour order. */
    private fun bindDayStrip(
        context: Context,
        views: RemoteViews,
        entries: List<HourSlot>,
        liveHour: Int,
        isToday: Boolean,
    ) {
        views.removeAllViews(R.id.widget_day_strip)
        val byHour = entries.associateBy { it.hour }
        for (hour in 0 until WidgetDayPlan.HOURS_IN_DAY) {
            val slot = byHour[hour] ?: HourSlot(hour, "empty", "")
            val isLive = isToday && hour == liveHour
            val background = when (WidgetDayPlan.rowStateFor(slot, liveHour, isToday)) {
                RowState.done ->
                    if (isLive) R.drawable.bg_widget_seg_done_live else R.drawable.bg_widget_seg_done
                RowState.inPlace ->
                    if (isLive) R.drawable.bg_widget_seg_active_live else R.drawable.bg_widget_seg_active
                RowState.missed ->
                    if (isLive) R.drawable.bg_widget_seg_missed_live else R.drawable.bg_widget_seg_missed
                RowState.free ->
                    if (isLive) R.drawable.bg_widget_seg_free_live else R.drawable.bg_widget_seg_free
            }
            val tick = RemoteViews(context.packageName, R.layout.widget_day_tick)
            tick.setInt(R.id.segment_body, "setBackgroundResource", background)
            views.addView(R.id.widget_day_strip, tick)
        }
    }

    /** The payload's planned hours, one per hour, with a slots fallback. */
    private fun readEntries(root: JSONObject): List<HourSlot> {
        val fromSegments = readArray(root.optJSONArray("segments"), "state")
        if (fromSegments.isNotEmpty()) {
            return fromSegments
        }
        return readArray(root.optJSONArray("slots"), "status").filter { it.state != "empty" }
    }

    private fun readArray(array: JSONArray?, stateKey: String): List<HourSlot> {
        if (array == null) {
            return emptyList()
        }
        val out = mutableListOf<HourSlot>()
        for (index in 0 until array.length()) {
            val item = array.optJSONObject(index) ?: continue
            val hour = item.optInt("hour", -1)
            if (hour !in 0..23) continue
            out += HourSlot(
                hour = hour,
                state = item.optString(stateKey, "empty"),
                text = item.optString("text"),
            )
        }
        return out.sortedBy { it.hour }
    }

    private fun moreLine(context: Context, text: String, scale: TypeScale): RemoteViews {
        val line = RemoteViews(context.packageName, R.layout.hourly_widget_more)
        line.setTextViewText(R.id.widget_more_line, text)
        line.setTextViewTextSize(R.id.widget_more_line, TypedValue.COMPLEX_UNIT_SP, scale.more)
        return line
    }

    private fun setChip(
        context: Context,
        views: RemoteViews,
        textRes: Int,
        colorRes: Int,
        backgroundRes: Int,
        chipNow: Boolean,
    ) {
        val label = context.getString(textRes)
        // One chip instead of a NOW label plus a state label: the compact card
        // has no room to float two tiny words next to each other.
        views.setTextViewText(
            R.id.hero_chip,
            if (chipNow) "${context.getString(R.string.widget_now)} · $label" else label,
        )
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

    /**
     * Every countdown names what ends: the hour, not the item. The compact card
     * says "This hour · 26 min left" under its bar, so the bar cannot be read as
     * the day's progress.
     */
    private fun hourMeta(
        context: Context,
        minutesInto: Int,
        minutesLeft: Int,
        compact: Boolean,
    ): String = when {
        minutesLeft <= 1 -> context.getString(R.string.widget_hour_ending)
        minutesInto == 0 ->
            context.getString(
                if (compact) R.string.widget_hour_bar_started else R.string.widget_hour_started,
            )
        compact -> context.getString(R.string.widget_hour_bar_label, minutesLeft)
        else -> context.getString(R.string.widget_hour_ends_in, minutesLeft)
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

    private fun hourLabel(hour: Int): String = String.format(Locale.getDefault(), "%02d:00", hour)

    private fun currentHour(): Int = Calendar.getInstance().get(Calendar.HOUR_OF_DAY)

    private fun todayKey(): String =
        SimpleDateFormat("yyyy-MM-dd", Locale.getDefault()).format(Date())

    /** Which state the hero card is in. */
    private enum class HeroMode { live, stale, empty }

    /** Text sizes per bucket, so a full screen card does not keep 10sp labels. */
    private data class TypeScale(
        val heroTime: Float,
        val heroText: Float,
        val heroMeta: Float,
        val chip: Float,
        val rowText: Float,
        val rowHour: Float,
        val rowChip: Float,
        val brand: Float,
        val day: Float,
        val footer: Float,
        val more: Float,
        val compactLayout: Boolean = false,
        val showHeroMeta: Boolean = true,
    )

    private fun scaleFor(bucket: WidgetSize.Bucket, heightDp: Int): TypeScale = when (bucket) {
        // Nothing the user has to read is under 10sp, in any bucket.
        WidgetSize.Bucket.compact -> TypeScale(
            heroTime = 22f, heroText = 12f, heroMeta = 10.5f, chip = 10f,
            rowText = 12f, rowHour = 11f, rowChip = 10f,
            brand = 10f, day = 10.5f, footer = 10.5f, more = 10.5f,
            compactLayout = true,
            // A 2x2 card keeps the item and the bar; the day label under the
            // bar is the line that has to go, or the card clips its own hero.
            showHeroMeta = heightDp >= WidgetSize.COMPACT_FOOTER_HEIGHT_DP,
        )

        WidgetSize.Bucket.medium -> TypeScale(
            heroTime = 26f, heroText = 14f, heroMeta = 11.5f, chip = 10f,
            rowText = 13f, rowHour = 11.5f, rowChip = 10f,
            brand = 11f, day = 11.5f, footer = 11.5f, more = 11f,
        )

        WidgetSize.Bucket.large -> TypeScale(
            heroTime = 32f, heroText = 15.5f, heroMeta = 12f, chip = 10.5f,
            rowText = 14f, rowHour = 12.5f, rowChip = 10.5f,
            brand = 11.5f, day = 12.5f, footer = 12f, more = 12f,
        )
    }

    private companion object {
        const val PAYLOAD_KEY = "hourly_payload"

        /** Fallback placement when the launcher reports no options. */
        const val DEFAULT_MIN_WIDTH_DP = 250
        const val DEFAULT_MIN_HEIGHT_DP = 180
    }
}
