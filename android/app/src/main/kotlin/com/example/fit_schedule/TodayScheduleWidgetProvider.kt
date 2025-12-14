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
        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            // 创建RemoteViews对象
            val views = RemoteViews(context.packageName, R.layout.today_schedule_widget)

            // 设置当前日期
            val dateFormat = SimpleDateFormat("MM月dd日 EEEE", Locale.CHINA)
            val currentDate = dateFormat.format(Date())
            views.setTextViewText(R.id.widget_date, currentDate)

            // 设置ListView的数据适配器
            val serviceIntent = Intent(context, WidgetRemoteViewsService::class.java)
            serviceIntent.putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
            views.setRemoteAdapter(R.id.courses_list_view, serviceIntent)

            // 设置空视图（当ListView为空时显示）
            views.setEmptyView(R.id.courses_list_view, R.id.no_courses_text)

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

            // 检查是否有课程，控制显示
            checkAndDisplayCourses(context, views)

            // 更新桌面组件
            appWidgetManager.updateAppWidget(appWidgetId, views)
            
            // 通知ListView数据已更改
            appWidgetManager.notifyAppWidgetViewDataChanged(appWidgetId, R.id.courses_list_view)
        }

        private fun checkAndDisplayCourses(context: Context, views: RemoteViews) {
            try {
                // 检查今日是否有课程
                val databaseHelper = WidgetDatabaseHelper(context)
                val todayCourses = databaseHelper.getTodayCourses()
                
                if (todayCourses.isEmpty()) {
                    // 显示无课程提示
                    views.setViewVisibility(R.id.no_courses_text, android.view.View.VISIBLE)
                    views.setViewVisibility(R.id.courses_list_view, android.view.View.GONE)
                } else {
                    // 显示课程列表
                    views.setViewVisibility(R.id.no_courses_text, android.view.View.GONE)
                    views.setViewVisibility(R.id.courses_list_view, android.view.View.VISIBLE)
                }
            } catch (e: Exception) {
                // 错误处理 - 显示错误信息
                views.setTextViewText(R.id.no_courses_text, "加载课程失败")
                views.setViewVisibility(R.id.no_courses_text, android.view.View.VISIBLE)
                views.setViewVisibility(R.id.courses_list_view, android.view.View.GONE)
            }
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