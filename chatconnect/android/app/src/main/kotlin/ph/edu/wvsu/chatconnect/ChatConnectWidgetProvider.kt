package ph.edu.wvsu.chatconnect

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Renders the quote-of-the-day widget. Data comes from [widgetData], which
 * Flutter populates via `HomeWidget.saveWidgetData` in
 * `lib/services/home_widget_service.dart` — this class never talks to the
 * Flutter engine directly, it only reads what was last written there.
 */
class ChatConnectWidgetProvider : HomeWidgetProvider() {

  /// Maps the mood label last written by [MoodService.logMood] (via
  /// `HomeWidgetService.pushLatestMood`) to one of the gradient drawables in
  /// `res/drawable/`. Unset or unrecognized moods fall back to the neutral
  /// default gradient.
  private fun backgroundFor(moodLabel: String?): Int =
      when (moodLabel) {
        "Happy" -> R.drawable.widget_background_happy
        "Sad" -> R.drawable.widget_background_sad
        "Angry" -> R.drawable.widget_background_angry
        "Anxious" -> R.drawable.widget_background_anxious
        else -> R.drawable.widget_background
      }

  override fun onUpdate(
      context: Context,
      appWidgetManager: AppWidgetManager,
      appWidgetIds: IntArray,
      widgetData: SharedPreferences,
  ) {
    appWidgetIds.forEach { widgetId ->
      val views = RemoteViews(context.packageName, R.layout.chatconnect_widget).apply {
        setTextViewText(
            R.id.widget_quote_text,
            widgetData.getString("quote_text", null)
                ?: context.getString(R.string.widget_default_quote),
        )
        setTextViewText(
            R.id.widget_quote_author,
            widgetData.getString("quote_author", null)
                ?: context.getString(R.string.widget_default_author),
        )
        setInt(
            R.id.widget_container,
            "setBackgroundResource",
            backgroundFor(widgetData.getString("mood_label", null)),
        )

        // Tapping anywhere on the widget opens the app normally.
        val openAppIntent = HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)
        setOnClickPendingIntent(R.id.widget_container, openAppIntent)
      }

      appWidgetManager.updateAppWidget(widgetId, views)
    }
  }
}
