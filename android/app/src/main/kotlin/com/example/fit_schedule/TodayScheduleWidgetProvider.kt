package com.example.fit_schedule

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import java.text.SimpleDateFormat
import java.util.*

class TodayScheduleWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        // 更新所有的桌面组件实例
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onEnabled(context: Context) {
        // 第一个桌面组件被添加时调用
        super.onEnabled(context)
    }

    override fun onDisabled(context: Context) {
        // 最后一个桌面组件被移除时调用
        super.onDisabled(context)
    }

    companion object {
        private val dayOfWeekNames = arrayOf("周日", "周一", "周二", "周三", "周四", "周五", "周六")

        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            // 创建RemoteViews对象
            val views = RemoteViews(context.packageName, R.layout.today_schedule_widget)

            // 设置当前周几（简化为只显示周几）
            val calendar = Calendar.getInstance()
            val dayOfWeek = dayOfWeekNames[calendar.get(Calendar.DAY_OF_WEEK) - 1]
            views.setTextViewText(R.id.widget_date, dayOfWeek)

            // 获取课表摘要信息
            val databaseHelper = WidgetDatabaseHelper(context)
            val summary = databaseHelper.getScheduleSummary()
            
            // 设置周次
            views.setTextViewText(R.id.widget_week, "第${summary.currentWeek}周")
            
            // 设置课程数量统计
            val summaryText = if (summary.courseCount > 0) {
                "今日 ${summary.courseCount} 节课"
            } else {
                "今日无课程安排"
            }
            views.setTextViewText(R.id.widget_summary, summaryText)

            // 设置ListView的数据适配器
            val serviceIntent = Intent(context, WidgetRemoteViewsService::class.java)
            serviceIntent.putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
            // 添加唯一的data URI以确保Intent是唯一的
            serviceIntent.data = android.net.Uri.parse(serviceIntent.toUri(Intent.URI_INTENT_SCHEME))
            views.setRemoteAdapter(R.id.courses_list_view, serviceIntent)

            // 设置空视图（当ListView为空时显示）
            views.setEmptyView(R.id.courses_list_view, R.id.no_courses_container)

            // 检查是否有课程，控制显示
            val todayCourses = databaseHelper.getTodayCourses()
            if (todayCourses.isEmpty()) {
                // 显示无课程提示
                views.setViewVisibility(R.id.no_courses_container, android.view.View.VISIBLE)
                views.setViewVisibility(R.id.courses_list_view, android.view.View.GONE)
            } else {
                // 显示课程列表
                views.setViewVisibility(R.id.no_courses_container, android.view.View.GONE)
                views.setViewVisibility(R.id.courses_list_view, android.view.View.VISIBLE)
            }

            // 设置整个小组件的点击事件 - 点击打开应用
            val launchIntent = Intent(context, MainActivity::class.java)
            launchIntent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            val launchPendingIntent = PendingIntent.getActivity(
                context,
                appWidgetId,
                launchIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_date, launchPendingIntent)
            views.setOnClickPendingIntent(R.id.widget_week, launchPendingIntent)
            views.setOnClickPendingIntent(R.id.widget_summary, launchPendingIntent)

            // 设置ListView的点击事件模板
            val clickIntent = Intent(context, MainActivity::class.java)
            clickIntent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            val clickPendingIntent = PendingIntent.getActivity(
                context,
                0,
                clickIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setPendingIntentTemplate(R.id.courses_list_view, clickPendingIntent)

            // 更新桌面组件
            appWidgetManager.updateAppWidget(appWidgetId, views)
            
            // 通知ListView数据已更改
            appWidgetManager.notifyAppWidgetViewDataChanged(appWidgetId, R.id.courses_list_view)
        }

        /**
         * 手动更新桌面组件（可以从Flutter端调用）
         */
        fun updateAllWidgets(context: Context) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val thisWidget = android.content.ComponentName(context, TodayScheduleWidgetProvider::class.java)
            val allWidgetIds = appWidgetManager.getAppWidgetIds(thisWidget)
            
            for (widgetId in allWidgetIds) {
                updateAppWidget(context, appWidgetManager, widgetId)
            }
        }
    }
}
