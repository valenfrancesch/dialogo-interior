package com.dialogointerior.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Build
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import java.text.SimpleDateFormat
import java.util.*

class DialogoWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_layout).apply {
                
                // Get today's date in the same format as Flutter saves it
                val today = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault()).format(Date())
                val savedDate = widgetData.getString("widget_date", "")
                
                // Check if the saved data is from today
                val isToday = savedDate == today
                
                // 1. Retrieve data from Flutter (only if from today)
                val highlightText = if (isToday) {
                    widgetData.getString("highlighted_text", "Abre la app para leer hoy")
                } else {
                    "Abre la app para leer hoy"
                }
                
                val purposeText = if (isToday) {
                    widgetData.getString("purpose", "")
                } else {
                    ""
                }

                // 2. Set text to views
                setTextViewText(R.id.widget_highlight, highlightText)
                
                // 3. Purpose display logic
                if (purposeText.isNullOrEmpty()) {
                    setTextViewText(R.id.widget_purpose, "Sin propósito guardado aún")
                } else {
                    setTextViewText(R.id.widget_purpose, purposeText)
                }

                // 4. Configure click to open app
                val intent = context.packageManager.getLaunchIntentForPackage(context.packageName)
                intent?.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                
                val pendingIntent = PendingIntent.getActivity(
                    context,
                    0,
                    intent,
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                    } else {
                        PendingIntent.FLAG_UPDATE_CURRENT
                    }
                )
                
                setOnClickPendingIntent(R.id.widget_root, pendingIntent)
            }

            // 5. Update widget
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
