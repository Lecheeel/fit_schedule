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

            // 设置点击事件 - 点击桌面组件打开应用
            val intent = Intent(context, MainActivity::class.java)
            intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            val pendingIntent = PendingIntent.getActivity(
                context, 
                0, 
                intent, 
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.courses_container, pendingIntent)

            // 加载今日课程数据
            loadTodayCourses(context, views)

            // 更新桌面组件
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        private fun loadTodayCourses(context: Context, views: RemoteViews) {
            try {
                // 使用数据库助手获取今日课程
                val databaseHelper = WidgetDatabaseHelper(context)
                val todayCourses = databaseHelper.getTodayCourses()
                
                if (todayCourses.isEmpty()) {
                    // 显示无课程信息
                    views.setTextViewText(R.id.no_courses_text, "今日无课程安排")
                    views.setViewVisibility(R.id.no_courses_text, android.view.View.VISIBLE)
                } else {
                    // 隐藏无课程文本
                    views.setViewVisibility(R.id.no_courses_text, android.view.View.GONE)
                    
                    // 显示课程列表
                    displayCourses(views, todayCourses)
                }
            } catch (e: Exception) {
                // 错误处理 - 显示错误信息
                views.setTextViewText(R.id.no_courses_text, "加载课程失败")
                views.setViewVisibility(R.id.no_courses_text, android.view.View.VISIBLE)
            }
        }

        private fun displayCourses(views: RemoteViews, courses: List<WidgetDatabaseHelper.CourseInfo>) {
            // 由于RemoteViews的限制，我们只能显示有限的课程信息
            // 这里将前几门课程的信息组合成一个字符串显示
            
            val displayText = StringBuilder()
            val maxCourses = minOf(courses.size, 3) // 最多显示3门课程
            
            for (i in 0 until maxCourses) {
                val course = courses[i]
                if (i > 0) displayText.append("\n\n")
                
                displayText.append("📚 ${course.name}")
                if (course.time.isNotEmpty()) {
                    displayText.append("\n⏰ ${course.time}")
                }
                if (course.location.isNotEmpty()) {
                    displayText.append("\n📍 ${course.location}")
                }
            }
            
            // 如果还有更多课程，显示提示
            if (courses.size > maxCourses) {
                displayText.append("\n\n还有 ${courses.size - maxCourses} 门课程...")
            }
            
            views.setTextViewText(R.id.no_courses_text, displayText.toString())
            views.setViewVisibility(R.id.no_courses_text, android.view.View.VISIBLE)
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