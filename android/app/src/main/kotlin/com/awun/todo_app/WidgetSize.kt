package com.awun.todo_app

/**
 * Size buckets for the home screen widget.
 *
 * The widget is placed anywhere from a small 2x2 cell to a full screen tall
 * card, so the provider picks one of three layouts from the actual size the
 * launcher reports. Nothing here touches Android, which keeps the chooser
 * unit testable on the JVM.
 *
 * The numbers are the chrome each layout spends before the first hour: the
 * medium layout pays for the brand line, the meter, and the footer (about
 * 185dp with the hero card), the large layout a little more (about 221dp) and
 * a taller hero. A cell is about 70dp, so a 4x4 placement lands in medium and
 * a 4x6 or taller placement in large.
 */
object WidgetSize {

    /** The three widget layouts. */
    enum class Bucket { compact, medium, large }

    /** Which layout to inflate and how many hour cells fit in it. */
    data class Decision(val bucket: Bucket, val cells: Int)

    /** Most hour cells a tall placement is allowed to paint. */
    const val MAX_CELLS = 7

    /** Below this width or height only the live hour fits. */
    private const val COMPACT_WIDTH_DP = 170
    private const val COMPACT_HEIGHT_DP = 200

    /** At or above this height the whole day is worth painting. */
    private const val LARGE_HEIGHT_DP = 320

    /** Body room the medium layout has before its first row. */
    private const val MEDIUM_CHROME_DP = 185

    /** Body room the large layout has before its first row. */
    private const val LARGE_CHROME_DP = 221

    /** Smallest comfortable row. */
    private const val ROW_DP = 34

    fun bucketFor(widthDp: Int, heightDp: Int): Bucket = when {
        widthDp < COMPACT_WIDTH_DP || heightDp < COMPACT_HEIGHT_DP -> Bucket.compact
        heightDp >= LARGE_HEIGHT_DP -> Bucket.large
        else -> Bucket.medium
    }

    /**
     * Hour cells that fit in [heightDp], the hero included. One cell is the
     * hero, the rest are rows.
     */
    fun cellsFor(bucket: Bucket, heightDp: Int): Int = when (bucket) {
        Bucket.compact -> 1
        Bucket.medium -> 1 + ((heightDp - MEDIUM_CHROME_DP) / ROW_DP).coerceIn(0, 3)
        Bucket.large -> 1 + ((heightDp - LARGE_CHROME_DP) / ROW_DP).coerceIn(2, 6)
    }

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
        return Decision(bucket, cells)
    }
}
