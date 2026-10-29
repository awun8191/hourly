package com.awun.todo_app

/**
 * Size buckets for the home screen widget.
 *
 * The widget is placed anywhere from a small 2x2 cell to a full screen tall
 * card, so the provider picks one of three layouts from the actual size the
 * launcher reports. Nothing here touches Android, which keeps the chooser
 * unit testable on the JVM.
 *
 * The numbers are the chrome each layout spends before the first row: the
 * brand line, the hero card, the day strip, and (in the large bucket) the
 * labels, the quiet line, the count, and the legend. Rows are a fixed height
 * plus a gap, never weighted, so a body either fits its box or paints one fewer
 * hour; [fits] and [contentHeightDp] are what the tests hold that to.
 *
 * A cell is about 70dp, so a 4x4 placement lands in medium and a 4x6 or taller
 * placement in large.
 */
object WidgetSize {

    /** The three widget layouts. */
    enum class Bucket { compact, medium, large }

    /** Which layout to inflate and how many hour cells fit in it. */
    data class Decision(val bucket: Bucket, val cells: Int, val heightDp: Int = 0)

    /** Most hour cells a tall placement is allowed to paint. */
    const val MAX_CELLS = 7

    /** Below this width or height only the live hour fits. */
    private const val COMPACT_WIDTH_DP = 170
    private const val COMPACT_HEIGHT_DP = 200

    /** At or above this height the whole day is worth painting. */
    private const val LARGE_HEIGHT_DP = 320

    /** Body room the medium layout has before its first row. */
    private const val MEDIUM_CHROME_DP = 188

    /** Body room the large layout has before its first row. */
    private const val LARGE_CHROME_DP = 260

    /** Fixed row heights: the layouts carry the same numbers, and never stretch. */
    const val ROW_HEIGHT_MEDIUM_DP = 40
    const val ROW_HEIGHT_LARGE_DP = 44

    /** Space between two hour cells. */
    const val ROW_GAP_DP = 6

    /** A compact card can show its footer once it has this much room. */
    const val COMPACT_FOOTER_HEIGHT_DP = 140

    fun bucketFor(widthDp: Int, heightDp: Int): Bucket = when {
        widthDp < COMPACT_WIDTH_DP || heightDp < COMPACT_HEIGHT_DP -> Bucket.compact
        heightDp >= LARGE_HEIGHT_DP -> Bucket.large
        else -> Bucket.medium
    }

    /** The height one hour row takes in [bucket], gap not included. */
    fun rowHeightDp(bucket: Bucket): Int = when (bucket) {
        Bucket.compact -> 0
        Bucket.medium -> ROW_HEIGHT_MEDIUM_DP
        Bucket.large -> ROW_HEIGHT_LARGE_DP
    }

    /** The height one row plus the gap under the previous cell takes. */
    fun rowAdvanceDp(bucket: Bucket): Int = rowHeightDp(bucket) + ROW_GAP_DP

    private fun chromeFor(bucket: Bucket): Int = when (bucket) {
        Bucket.compact -> 0
        Bucket.medium -> MEDIUM_CHROME_DP
        Bucket.large -> LARGE_CHROME_DP
    }

    /**
     * Hour cells that fit in [heightDp], the hero included. One cell is the
     * hero, the rest are rows.
     */
    fun cellsFor(bucket: Bucket, heightDp: Int): Int = when (bucket) {
        Bucket.compact -> 1
        Bucket.medium ->
            1 + ((heightDp - MEDIUM_CHROME_DP) / rowAdvanceDp(bucket)).coerceIn(0, 3)
        Bucket.large ->
            1 + ((heightDp - LARGE_CHROME_DP) / rowAdvanceDp(bucket)).coerceIn(0, 6)
    }

    /**
     * The height the painted cells need in [bucket]: the chrome, the hero, and
     * one fixed row plus gap for each hour after it.
     */
    fun contentHeightDp(bucket: Bucket, heightDp: Int): Int =
        chromeFor(bucket) + (cellsFor(bucket, heightDp) - 1) * rowAdvanceDp(bucket)

    /** True when the painted cells do not overrun the box the launcher gave us. */
    fun fits(bucket: Bucket, heightDp: Int): Boolean =
        bucket == Bucket.compact || contentHeightDp(bucket, heightDp) <= heightDp

    /**
     * The bucket comes from the size the widget has now (the min options on
     * Android 12 and up). When the launcher also reports headroom above that
     * minimum, a tall placement gets one extra cell, so a full screen widget
     * fills its box instead of leaving a blank band.
     */
    fun decide(
        minWidthDp: Int,
        minHeightDp: Int,
        maxWidthDp: Int = 0,
        maxHeightDp: Int = 0,
    ): Decision {
        val width = minWidthDp.coerceAtLeast(1)
        val height = minHeightDp.coerceAtLeast(1)
        val bucket = bucketFor(width, height)
        var cells = cellsFor(bucket, height)
        if (bucket == Bucket.large && maxHeightDp - height >= 60) {
            cells = (cells + 1).coerceAtMost(MAX_CELLS)
        }
        return Decision(bucket, cells, height)
    }
}
