package net.splixa.app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class SplixaQuickAddWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            val isPro = widgetData.getBoolean("is_pro", false)
            val views = RemoteViews(context.packageName, R.layout.splixa_quick_add_widget)
            views.setTextViewText(
                R.id.widget_action,
                if (isPro) context.getString(R.string.widget_quick_add)
                else context.getString(R.string.widget_unlock_pro),
            )
            val intent = HomeWidgetLaunchIntent.getActivity(
                context,
                MainActivity::class.java,
                Uri.parse("splixa://quick-add"),
            )
            views.setOnClickPendingIntent(R.id.widget_container, intent)
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
