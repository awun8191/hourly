package com.awun.todo_app

import android.app.Activity
import android.net.Uri
import android.os.Bundle
import android.view.WindowManager
import android.text.Editable
import android.text.TextWatcher
import android.view.Gravity
import android.view.ViewGroup
import android.widget.EditText
import android.widget.TextView
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * A small text field over the home screen, opened from the widget.
 *
 * Android widgets cannot host an EditText, so this dialog is the closest the
 * platform allows. It writes straight into the same store the Flutter app
 * reads (`FlutterSharedPreferences`, key `flutter.hours.v1.<date>`), then asks
 * the Dart background callback to repaint the widget.
 */
class QuickAddActivity : Activity() {

    companion object {
        const val EXTRA_DATE = "date"
        const val EXTRA_HOUR = "hour"

        private const val PREFS = "FlutterSharedPreferences"
        private const val PREFIX = "flutter.hours.v1."
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.quick_add)
        window.setSoftInputMode(WindowManager.LayoutParams.SOFT_INPUT_STATE_VISIBLE)

        val data = intent.data
        val date = intent.getStringExtra(EXTRA_DATE)
            ?: data?.getQueryParameter("date")
            ?: todayKey()
        val hour = if (intent.hasExtra(EXTRA_HOUR)) {
            intent.getIntExtra(EXTRA_HOUR, -1)
        } else {
            data?.getQueryParameter("hour")?.toIntOrNull() ?: -1
        }
        if (hour !in 0..23) {
            finish()
            return
        }

        window.setLayout(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.WRAP_CONTENT,
        )
        window.setGravity(Gravity.CENTER)
        setFinishOnTouchOutside(true)

        val day = runCatching {
            SimpleDateFormat("yyyy-MM-dd", Locale.getDefault()).parse(date)
        }.getOrNull() ?: Date()
        findViewById<TextView>(R.id.quick_day).text =
            SimpleDateFormat("EEEE d", Locale.getDefault())
                .format(day)
                .uppercase(Locale.getDefault())
        findViewById<TextView>(R.id.quick_title).text =
            String.format(Locale.getDefault(), "%02d:00", hour)

        val field = findViewById<EditText>(R.id.quick_text)
        val clear = findViewById<TextView>(R.id.quick_clear)
        field.setText(readText(date, hour))
        field.setSelection(field.text.length)
        field.requestFocus()

        fun syncClear() {
            clear.isEnabled = field.text.isNotEmpty()
            clear.alpha = if (clear.isEnabled) 1f else 0.35f
        }

        field.addTextChangedListener(
            object : TextWatcher {
                override fun beforeTextChanged(s: CharSequence?, start: Int, count: Int, after: Int) = Unit
                override fun onTextChanged(s: CharSequence?, start: Int, before: Int, count: Int) = Unit
                override fun afterTextChanged(s: Editable?) = syncClear()
            },
        )
        syncClear()

        clear.setOnClickListener {
            write(date, hour, "")
            finish()
        }
        findViewById<TextView>(R.id.quick_cancel).setOnClickListener { finish() }
        findViewById<TextView>(R.id.quick_close).setOnClickListener { finish() }
        findViewById<TextView>(R.id.quick_save).setOnClickListener {
            write(date, hour, field.text.toString().trim())
            finish()
        }
    }

    private fun readText(date: String, hour: Int): String {
        val raw = preferences().getString(PREFIX + date, null) ?: return ""
        return runCatching {
            JSONObject(raw).optJSONObject(hour.toString())?.optString("text").orEmpty()
        }.getOrDefault("")
    }

    private fun write(date: String, hour: Int, text: String) {
        val day = runCatching {
            JSONObject(preferences().getString(PREFIX + date, null) ?: "{}")
        }.getOrDefault(JSONObject())

        if (text.isEmpty()) {
            day.remove(hour.toString())
        } else {
            val existing = day.optJSONObject(hour.toString())
            day.put(
                hour.toString(),
                JSONObject().apply {
                    put("text", text)
                    put("status", existing?.optString("status").orEmpty().ifEmpty { "active" })
                    put("updatedAt", stamp())
                },
            )
        }

        val editor = preferences().edit()
        if (day.length() == 0) {
            editor.remove(PREFIX + date)
        } else {
            editor.putString(PREFIX + date, day.toString())
        }
        editor.commit()

        HomeWidgetBackgroundIntent
            .getBroadcast(this, Uri.parse("hourly://refresh"))
            .send()
    }

    private fun preferences() = getSharedPreferences(PREFS, MODE_PRIVATE)

    private fun stamp(): String =
        SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS", Locale.US).format(Date())

    private fun todayKey(): String =
        SimpleDateFormat("yyyy-MM-dd", Locale.getDefault()).format(Date())
}
