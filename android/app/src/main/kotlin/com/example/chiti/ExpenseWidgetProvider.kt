package com.example.chiti

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Color
import android.net.Uri
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Home Screen widget showing the most recently active group's name, total
 * spend, and the Host's (Thủ quỹ) net balance. Data is pushed from Dart via
 * `HomeWidget.saveWidgetData` and rendered as a Material card.
 *
 * Tapping the widget opens the app directly on that group's detail screen
 * (deep link `chiti://group/<tripId>`).
 */
class ExpenseWidgetProvider : HomeWidgetProvider() {

  override fun onUpdate(
      context: Context,
      appWidgetManager: AppWidgetManager,
      appWidgetIds: IntArray,
      widgetData: SharedPreferences,
  ) {
    val hasData = widgetData.getBoolean("hasData", false)

    appWidgetIds.forEach { widgetId ->
      val views =
          android.widget.RemoteViews(context.packageName, R.layout.expense_widget_layout)
              .apply {
                // Deep link: open the group detail screen on tap.
                val tripId = widgetData.getString("tripId", null)
                val uri =
                    if (hasData && !tripId.isNullOrEmpty())
                      Uri.parse("chiti://group/$tripId")
                    else null
                val pendingIntent =
                    HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java, uri)
                setOnClickPendingIntent(R.id.widget_container, pendingIntent)

                // Group / activity name.
                setTextViewText(
                    R.id.widget_group_name,
                    if (hasData) widgetData.getString("groupName", null) ?: "—"
                    else context.getString(R.string.widget_no_group))
              }

      // The remaining fields only make sense with real data.
      if (hasData) {
        views.setTextViewText(
            R.id.widget_total_spent,
            widgetData.getString("totalSpent", null) ?: "—")
        views.setTextViewText(R.id.widget_net, widgetData.getString("netLabel", null) ?: "—")
        val netColor = parseColor(widgetData.getString("netColor", null))
        views.setTextColor(R.id.widget_net, netColor)
      } else {
        views.setTextViewText(R.id.widget_total_spent, "")
        views.setTextViewText(R.id.widget_net, "")
      }

      appWidgetManager.updateAppWidget(widgetId, views)
    }
  }

  private fun parseColor(value: String?): Int {
    return when (value) {
      "red" -> Color.parseColor("#C62828")
      "green" -> Color.parseColor("#2E7D32")
      else -> Color.parseColor("#616161")
    }
  }
}