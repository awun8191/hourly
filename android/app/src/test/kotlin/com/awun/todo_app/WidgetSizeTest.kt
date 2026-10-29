package com.awun.todo_app

import org.junit.Assert.assertEquals
import org.junit.Test

/**
 * The widget has to work from a 2x2 cell to a full screen card, so the chooser
 * is the piece that decides what to paint. Sizes are the dp values a launcher
 * reports through the app widget options (a cell is about 70dp).
 */
class WidgetSizeTest {

    @Test
    fun `a 2x2 cell is compact and shows one hour`() {
        val decision = WidgetSize.decide(minWidthDp = 110, minHeightDp = 110)

        assertEquals(WidgetSize.Bucket.compact, decision.bucket)
        assertEquals(1, decision.cells)
    }

    @Test
    fun `a short or narrow placement stays compact`() {
        assertEquals(WidgetSize.Bucket.compact, WidgetSize.bucketFor(250, 110))
        assertEquals(WidgetSize.Bucket.compact, WidgetSize.bucketFor(110, 400))
        assertEquals(WidgetSize.Bucket.compact, WidgetSize.bucketFor(250, 180))
    }

    @Test
    fun `a 4x4 cell is medium with the hero and one row`() {
        val decision = WidgetSize.decide(minWidthDp = 250, minHeightDp = 250)

        assertEquals(WidgetSize.Bucket.medium, decision.bucket)
        assertEquals(2, decision.cells)
    }

    @Test
    fun `a medium cell grows one row per cell of height`() {
        assertEquals(1, WidgetSize.cellsFor(WidgetSize.Bucket.medium, 200))
        assertEquals(2, WidgetSize.cellsFor(WidgetSize.Bucket.medium, 250))
        assertEquals(3, WidgetSize.cellsFor(WidgetSize.Bucket.medium, 260))
        assertEquals(4, WidgetSize.cellsFor(WidgetSize.Bucket.medium, 290))
        assertEquals(4, WidgetSize.cellsFor(WidgetSize.Bucket.medium, 300))
        // A medium layout never paints more than the hero and three rows.
        assertEquals(4, WidgetSize.cellsFor(WidgetSize.Bucket.medium, 319))
    }

    @Test
    fun `a 4x6 cell is large with six hour cells`() {
        val decision = WidgetSize.decide(minWidthDp = 250, minHeightDp = 400)

        assertEquals(WidgetSize.Bucket.large, decision.bucket)
        assertEquals(6, decision.cells)
    }

    @Test
    fun `a tall cell keeps growing the day up to the ceiling`() {
        assertEquals(3, WidgetSize.cellsFor(WidgetSize.Bucket.large, 320))
        assertEquals(6, WidgetSize.cellsFor(WidgetSize.Bucket.large, 400))
        assertEquals(WidgetSize.MAX_CELLS, WidgetSize.cellsFor(WidgetSize.Bucket.large, 600))
    }

    @Test
    fun `a wide but short cell stays medium`() {
        val decision = WidgetSize.decide(minWidthDp = 400, minHeightDp = 250)

        assertEquals(WidgetSize.Bucket.medium, decision.bucket)
        assertEquals(2, decision.cells)
    }

    @Test
    fun `launcher headroom adds one more hour in the large bucket`() {
        val without = WidgetSize.decide(minWidthDp = 250, minHeightDp = 340)
        val with = WidgetSize.decide(
            minWidthDp = 250,
            minHeightDp = 340,
            maxWidthDp = 400,
            maxHeightDp = 500,
        )

        assertEquals(4, without.cells)
        assertEquals(5, with.cells)
    }

    @Test
    fun `a full screen placement stops at the cell ceiling`() {
        val decision = WidgetSize.decide(
            minWidthDp = 600,
            minHeightDp = 900,
            maxWidthDp = 900,
            maxHeightDp = 1200,
        )

        assertEquals(WidgetSize.Bucket.large, decision.bucket)
        assertEquals(WidgetSize.MAX_CELLS, decision.cells)
    }

    @Test
    fun `a nonsense size falls back to one compact hour`() {
        val decision = WidgetSize.decide(minWidthDp = 0, minHeightDp = 0)

        assertEquals(WidgetSize.Bucket.compact, decision.bucket)
        assertEquals(1, decision.cells)
    }
}
