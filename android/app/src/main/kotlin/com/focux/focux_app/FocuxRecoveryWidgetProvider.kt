package com.focux.focux_app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class FocuxRecoveryWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val score = widgetData.getInt("recovery_score", 0)
        val label = widgetData.getString("recovery_label", null) ?: "Conecte seu wearable"
        val hint = widgetData.getString("recovery_hint", null)
            ?: "Abra o Focux para sincronizar Apple Health ou Google Fit."
        val steps = widgetData.getInt("steps", 0)

        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.recovery_widget_layout).apply {
                setTextViewText(R.id.recovery_widget_score, if (score > 0) "$score%" else "--")
                setTextViewText(R.id.recovery_widget_label, label)
                setTextViewText(R.id.recovery_widget_hint, hint)
                setTextViewText(
                    R.id.recovery_widget_steps,
                    if (steps > 0) "${formatSteps(steps)} passos hoje" else "Toque para abrir o app",
                )

                val pendingIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("focux://saude"),
                )
                setOnClickPendingIntent(R.id.recovery_widget_root, pendingIntent)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    private fun formatSteps(steps: Int): String {
        return if (steps >= 1000) {
            val thousands = steps / 1000.0
            String.format("%.1fk", thousands).replace(".0k", "k")
        } else {
            steps.toString()
        }
    }
}
