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

private const val PURPOSE_FALLBACK = "¿Qué propósito te guía hoy?"
private const val LUZ_FALLBACK = "Abre la app para leer el Evangelio de hoy."
private const val LUZ_STALE = "Descubre lo que Dios te quiere decir hoy en Diálogo Interior."

abstract class BaseDialogoWidgetProvider(
    private val layoutResId: Int
) : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        val today = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault()).format(Date())
        val savedDate = widgetData.getString("widget_date", "")
        val isToday = savedDate == today
        val lockTitle = widgetData.getString("lock_title", "Luz del día").orEmpty()
        val lockBodyRaw = widgetData.getString("lock_body", LUZ_FALLBACK).orEmpty()
        val purposeRaw = widgetData.getString("purpose", "").orEmpty()

        val lockBody = if (isToday) lockBodyRaw else LUZ_STALE
        val purposeText = if (isToday && purposeRaw.isNotBlank()) purposeRaw else PURPOSE_FALLBACK

        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, layoutResId)
            bindContent(views, lockTitle, lockBody, purposeText)
            bindOpenAppIntent(context, views)
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    protected abstract fun bindContent(
        views: RemoteViews,
        lockTitle: String,
        lockBody: String,
        purposeText: String
    )

    private fun bindOpenAppIntent(context: Context, views: RemoteViews) {
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
        views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)
    }
}

class DialogoLuzWidgetProvider : BaseDialogoWidgetProvider(R.layout.widget_luz_small) {
    override fun bindContent(
        views: RemoteViews,
        lockTitle: String,
        lockBody: String,
        purposeText: String
    ) {
        views.setTextViewText(R.id.widget_luz_subtitle, lockTitle)
        views.setTextViewText(R.id.widget_luz_body, lockBody)
    }
}

class DialogoPurposeWidgetProvider : BaseDialogoWidgetProvider(R.layout.widget_purpose_small) {
    override fun bindContent(
        views: RemoteViews,
        lockTitle: String,
        lockBody: String,
        purposeText: String
    ) {
        views.setTextViewText(R.id.widget_purpose_body, purposeText)
    }
}

class DialogoCombinedWidgetProvider : BaseDialogoWidgetProvider(R.layout.widget_combined_medium) {
    override fun bindContent(
        views: RemoteViews,
        lockTitle: String,
        lockBody: String,
        purposeText: String
    ) {
        views.setTextViewText(R.id.widget_luz_subtitle, lockTitle)
        views.setTextViewText(R.id.widget_luz_body, lockBody)
        views.setTextViewText(R.id.widget_purpose_body, purposeText)
    }
}
