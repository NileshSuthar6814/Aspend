package org.x.aspend.ns

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

class HomeWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        appWidgetIds.forEach { appWidgetId ->
            updateWidget(context, appWidgetManager, appWidgetId)
        }
    }

    private fun updateWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ) {
        val views = RemoteViews(context.packageName, R.layout.home_widget)

        // Get widget data
        val widgetData = HomeWidgetPlugin.getData(context)
        val balance = widgetData.getString("balance", "₹0.00")
        val transactionCount = widgetData.getString("transaction_count", "0")

        // Update balance display
        views.setTextViewText(R.id.widget_balance, balance)

        // Create intent for income button
        val incomeIntent = Intent(context, MainActivity::class.java).apply {
            action = "ADD_INCOME"
            data = Uri.parse("aspend://add_income")
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val incomePendingIntent = PendingIntent.getActivity(
            context,
            0,
            incomeIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.income_button, incomePendingIntent)

        // Create intent for expense button
        val expenseIntent = Intent(context, MainActivity::class.java).apply {
            action = "ADD_EXPENSE"
            data = Uri.parse("aspend://add_expense")
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val expensePendingIntent = PendingIntent.getActivity(
            context,
            1,
            expenseIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.expense_button, expensePendingIntent)

        // Update the widget
        appWidgetManager.updateAppWidget(appWidgetId, views)
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)

        // Handle widget updates
        if (intent.action == AppWidgetManager.ACTION_APPWIDGET_UPDATE) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(
                ComponentName(context, HomeWidgetProvider::class.java)
            )
            onUpdate(context, appWidgetManager, appWidgetIds)
        }
    }
} 