package com.awun.todo_app

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * The widget has to work from a 2x2 cell to a full screen card, so the chooser
 * is the piece that decides what to paint. Sizes are the dp values a launcher
 * reports through the app widget options (a cell is about 70dp).
 *
 * Rows are a fixed height now, never weighted, so cellsFor is also a fit check:
 * whatever it returns has to fit the box, because no row will shrink to make it.
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
        assertEquals(2, WidgetSize.cellsFor(WidgetSize.Bucket.medium, 260))
        assertEquals(3, WidgetSize.cellsFor(WidgetSize.Bucket.medium, 290))
        assertEquals(3, WidgetSize.cellsFor(WidgetSize.Bucket.medium, 300))
        // A medium layout never paints more than the hero and three rows.
        assertEquals(3, WidgetSize.cellsFor(WidgetSize.Bucket.medium, 319))
    }

    @Test
    fun `a 4x6 cell is large and paints three hour cells`() {
        val decision = WidgetSize.decide(minWidthDp = 250, minHeightDp = 400)

        assertEquals(WidgetSize.Bucket.large, decision.bucket)
        assertEquals(3, decision.cells)
    }

    @Test
    fun `a tall cell keeps growing the day up to the ceiling`() {
        assertEquals(2, WidgetSize.cellsFor(WidgetSize.Bucket.large, 320))
        assertEquals(3, WidgetSize.cellsFor(WidgetSize.Bucket.large, 400))
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

        assertEquals(2, without.cells)
        assertEquals(3, with.cells)
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

    // ------------------------------------------------------------- fit logic

    @Test
    fun `the rows a bucket asks for always fit the box`() {
        // The choose is the real invariant: for every height the launcher can
        // report, the bucket it lands in has to fit in that height.
        for (height in 110..1400) {
            val bucket = WidgetSize.bucketFor(360, height)
            assertTrue(
                "$bucket at ${height}dp needs " +
                    "${WidgetSize.contentHeightDp(bucket, height)}dp",
                WidgetSize.fits(bucket, height),
            )
        }
    }

    @Test
    fun `a fitted body leaves less than one row of slack`() {
        // The leftover is what the day panel takes, so it has to stay small: at
        // most one row plus gap that did not fit. The ceilings are exempt,
        // because a very tall card stops adding rows on purpose.
        val ceiling = mapOf(
            WidgetSize.Bucket.medium to 4,
            WidgetSize.Bucket.large to WidgetSize.MAX_CELLS,
        )
        for (bucket in listOf(WidgetSize.Bucket.medium, WidgetSize.Bucket.large)) {
            val max = ceiling.getValue(bucket)
            for (height in 110..1400) {
                if (WidgetSize.bucketFor(360, height) != bucket) continue
                if (WidgetSize.cellsFor(bucket, height) >= max) continue
                val slack = height - WidgetSize.contentHeightDp(bucket, height)
                assertTrue(
                    "$bucket at ${height}dp leaves ${slack}dp",
                    slack < WidgetSize.rowAdvanceDp(bucket),
                )
            }
        }
    }

    @Test
    fun `fixed row heights match the layouts`() {
        assertEquals(40, WidgetSize.ROW_HEIGHT_MEDIUM_DP)
        assertEquals(44, WidgetSize.ROW_HEIGHT_LARGE_DP)
        assertEquals(6, WidgetSize.ROW_GAP_DP)
        assertEquals(40, WidgetSize.rowHeightDp(WidgetSize.Bucket.medium))
        assertEquals(44, WidgetSize.rowHeightDp(WidgetSize.Bucket.large))
        assertEquals(46, WidgetSize.rowAdvanceDp(WidgetSize.Bucket.medium))
        assertEquals(50, WidgetSize.rowAdvanceDp(WidgetSize.Bucket.large))
    }

    @Test
    fun `a taller box never paints fewer hours`() {
        for (bucket in listOf(WidgetSize.Bucket.medium, WidgetSize.Bucket.large)) {
            var last = 0
            for (height in 110..1400) {
                val cells = WidgetSize.cellsFor(bucket, height)
                assertTrue("$bucket shrank at ${height}dp", cells >= last)
                last = cells
            }
        }
    }
}
