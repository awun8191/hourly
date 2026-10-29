package com.awun.todo_app

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * The widget body is a day, not only the future: a tall widget at 22:00 has to
 * show the evening that led there instead of a blank band.
 */
class WidgetDayPlanTest {

    private fun slot(hour: Int, state: String = "active", text: String = "Hour $hour") =
        HourSlot(hour, state, text)

    private fun hours(items: List<BodyItem>) = items.mapNotNull { it.slot?.hour }

    @Test
    fun `the hero sits at the live hour inside a chronological day`() {
        val items = WidgetDayPlan.build(
            entries = listOf(slot(9), slot(14, "completed"), slot(23)),
            liveHour = 22,
            cells = 6,
            includePast = true,
        )

        assertEquals(
            listOf(BodyItemKind.row, BodyItemKind.row, BodyItemKind.hero, BodyItemKind.row),
            items.map { it.kind },
        )
        assertEquals(listOf(9, 14, 22, 23), hours(items))
        assertEquals("empty", items.first { it.kind == BodyItemKind.hero }.slot?.state)
    }

    @Test
    fun `hours that do not fit fold into an earlier count`() {
        val items = WidgetDayPlan.build(
            entries = (0..9).map { slot(it) },
            liveHour = 12,
            cells = 4,
            includePast = true,
        )

        assertEquals(BodyItemKind.earlier, items.first().kind)
        assertEquals(7, items.first().count)
        assertEquals(listOf(7, 8, 9, 12), hours(items))
        assertTrue(items.any { it.kind == BodyItemKind.hero })
    }

    @Test
    fun `hours that do not fit fold into a more count after the live hour`() {
        val items = WidgetDayPlan.build(
            entries = (10..23).map { slot(it) },
            liveHour = 9,
            cells = 4,
            includePast = true,
        )

        assertEquals(listOf(9, 10, 11, 12), hours(items))
        assertEquals(BodyItemKind.later, items.last().kind)
        assertEquals(11, items.last().count)
    }

    @Test
    fun `the medium bucket never shows hours before now`() {
        val items = WidgetDayPlan.build(
            entries = listOf(slot(8), slot(21)),
            liveHour = 20,
            cells = 4,
            includePast = false,
        )

        assertEquals(listOf(20, 21, 22, 23), hours(items))
        assertTrue(items.none { it.kind == BodyItemKind.earlier })
    }

    @Test
    fun `free hours fill a quiet body`() {
        val items = WidgetDayPlan.build(
            entries = listOf(slot(10, "completed")),
            liveHour = 9,
            cells = 4,
            includePast = false,
        )

        assertEquals(listOf(9, 10, 11, 12), hours(items))
        assertEquals("empty", items.last().slot?.state)
    }

    @Test
    fun `a day with nothing after the live hour gets a quiet line`() {
        val items = WidgetDayPlan.build(
            entries = emptyList(),
            liveHour = 23,
            cells = 6,
            includePast = true,
        )

        assertEquals(listOf(BodyItemKind.hero, BodyItemKind.filler), items.map { it.kind })
    }

    @Test
    fun `the compact bucket paints the hero only`() {
        val items = WidgetDayPlan.build(
            entries = listOf(slot(9)),
            liveHour = 8,
            cells = 1,
            includePast = true,
        )

        assertEquals(listOf(BodyItemKind.hero), items.map { it.kind })
        assertEquals(8, items.single().slot?.hour)
    }

    @Test
    fun `the live hour appears once, whatever the budget`() {
        val entries = (0..23).map { slot(it) }
        for (cells in 1..WidgetSize.MAX_CELLS) {
            val items = WidgetDayPlan.build(entries, liveHour = 11, cells = cells, includePast = true)
            assertEquals(1, items.count { it.kind == BodyItemKind.hero })
            assertEquals(11, items.first { it.kind == BodyItemKind.hero }.slot?.hour)
        }
    }
}
