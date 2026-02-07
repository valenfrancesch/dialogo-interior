package com.example.flutter_application_1

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class DialogoWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_layout).apply {
                
                // 1. Recuperar los datos guardados desde Flutter
                // Usamos las mismas claves que definiste en Flutter: "highlighted_text" y "purpose"
                val highlightText = widgetData.getString("highlighted_text", "Abre la app para leer hoy")
                val purposeText = widgetData.getString("purpose", "")

                // 2. Asignar los textos a la vista (XML)
                setTextViewText(R.id.widget_highlight, highlightText)
                
                // 3. Lógica visual para el propósito
                if (purposeText.isNullOrEmpty()) {
                    setTextViewText(R.id.widget_purpose, "Sin propósito guardado aún")
                } else {
                    setTextViewText(R.id.widget_purpose, purposeText)
                }
            }

            // 4. Actualizar el widget
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
