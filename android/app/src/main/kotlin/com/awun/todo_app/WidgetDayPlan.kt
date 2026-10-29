package com.awun.todo_app

/** One hour the widget can paint: its hour, its state, and its item. */
data class HourSlot(val hour: Int, val state: String, val text: String)

/**
 * How a row paints one hour once the clock is taken into account.
 *
 * `inPlace` is the plan, not the clock: an item that was in place at 11:00 has
 * not happened by 14:00, so it is [missed] and never reads "in place" after its
 * hour has gone. Nothing here flips the stored state; the widget stays read
 * only, and a tap still toggles in place and done.
 */
enum class RowState {
    /** Planned for an hour that has not started yet. */
    inPlace,

    /** Marked done. */
    done,

    /** Planned for an hour that has already gone by, and not done. */
    missed,

    /** No item in this hour. */
    free,
}

/** What one child of the widget body stands for. */
enum class BodyItemKind {
    /** The live hour, painted as the hero card. */
    hero,

    /** A planned or free hour, painted as a row. */
    row,

    /** A "+N earlier hours" summary line. */
    earlier,

    /** A "+N more hours" summary line. */
    later,

    /** A quiet line for a body that has nothing else to show. */
    filler,
}

data class BodyItem(
    val kind: BodyItemKind,
    val slot: HourSlot? = null,
    val count: Int = 0,
)

/**
 * Builds the chronological body of the widget: the hours before now (in the
 * large bucket), the live hour as the hero, then the hours after it.
 *
 * The body is a day, not just the future, so a tall widget at 22:00 shows the
 * day that led there instead of a blank band. When the day does not fit in
 * [cells], the oldest hours fold into an "earlier" line and the furthest into a
 * "more" line, so the count is never silently dropped. Pure Kotlin, so the
 * rules are unit tested on the JVM.
 */
object WidgetDayPlan {

    const val HOURS_IN_DAY = 24

    /**
     * The state a row paints, which is the stored state except for one rule:
     * an item that is still `active` in an hour that has already gone by is
     * [RowState.missed], not "in place". A done item stays done, and a slot
     * from another day is never missed, because the clock on this widget is
     * not that day's clock.
     */
    fun rowStateFor(slot: HourSlot, liveHour: Int, isToday: Boolean): RowState {
        val live = liveHour.coerceIn(0, HOURS_IN_DAY - 1)
        return when {
            slot.state == "active" && isToday && slot.hour < live -> RowState.missed
            slot.state == "completed" -> RowState.done
            slot.state == "active" -> RowState.inPlace
            else -> RowState.free
        }
    }

    /**
     * True when the day has no planned hour after [liveHour], which is when the
     * widget says "Nothing else planned today" instead of leaving the space
     * under the day strip empty.
     */
    fun hasUpcoming(entries: List<HourSlot>, liveHour: Int): Boolean {
        val live = liveHour.coerceIn(0, HOURS_IN_DAY - 1)
        return entries.any { it.hour > live && it.state != "empty" }
    }

    fun build(
        entries: List<HourSlot>,
        liveHour: Int,
        cells: Int,
        includePast: Boolean,
    ): List<BodyItem> {
        val live = liveHour.coerceIn(0, HOURS_IN_DAY - 1)
        val byHour = entries
            .filter { it.hour in 0..HOURS_IN_DAY - 1 }
            .associateBy { it.hour }
        val hero = byHour[live] ?: HourSlot(live, "empty", "")

        val limit = (cells - 1).coerceAtLeast(0)
        if (limit == 0) {
            return listOf(BodyItem(BodyItemKind.hero, hero))
        }

        val future = byHour.values.filter { it.hour > live }.sortedBy { it.hour }
        val past = if (includePast) {
            byHour.values.filter { it.hour < live }.sortedByDescending { it.hour }
        } else {
            emptyList()
        }

        val kept = ArrayList<HourSlot>()
        future.take(limit).forEach { kept += it }
        val laterDropped = future.size - minOf(future.size, limit)

        var earlierDropped = 0
        for (slot in past) {
            if (kept.size < limit) kept += slot else earlierDropped++
        }

        // Free hours only fill a body where every planned hour already fits.
        if (earlierDropped == 0 && laterDropped == 0 && kept.size < limit) {
            for (hour in live + 1 until HOURS_IN_DAY) {
                if (kept.size >= limit) break
                if (byHour.containsKey(hour)) continue
                kept += HourSlot(hour, "empty", "")
            }
        }

        val items = ArrayList<BodyItem>()
        if (earlierDropped > 0) {
            items += BodyItem(BodyItemKind.earlier, count = earlierDropped)
        }
        (kept + hero).sortedBy { it.hour }.forEach { slot ->
            items += if (slot.hour == live) {
                BodyItem(BodyItemKind.hero, slot)
            } else {
                BodyItem(BodyItemKind.row, slot)
            }
        }
        if (laterDropped > 0) {
            items += BodyItem(BodyItemKind.later, count = laterDropped)
        }
        if (kept.isEmpty()) {
            items += BodyItem(BodyItemKind.filler)
        }
        return items
    }
}
