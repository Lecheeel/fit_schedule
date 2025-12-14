package com.example.fit_schedule

import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import android.widget.RemoteViewsService

/**
 * RemoteViewsService 用于为小部件的ListView提供数据
 */
class WidgetRemoteViewsService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory {
        return WidgetRemoteViewsFactory(this.applicationContext)
    }
}

/**
 * RemoteViewsFactory 负责创建和管理ListView的每一项
 */
class WidgetRemoteViewsFactory(private val context: Context) : RemoteViewsService.RemoteViewsFactory {
    
    private var courses: List<WidgetDatabaseHelper.CourseInfo> = emptyList()
    private val databaseHelper = WidgetDatabaseHelper(context)

    override fun onCreate() {
        // 初始化
    }

    override fun onDataSetChanged() {
        // 当数据需要更新时调用
        // 这里从数据库加载今日课程
        try {
            courses = databaseHelper.getTodayCourses()
        } catch (e: Exception) {
            courses = emptyList()
        }
    }

    override fun onDestroy() {
        // 清理资源
        courses = emptyList()
    }

    override fun getCount(): Int {
        return courses.size
    }

    override fun getViewAt(position: Int): RemoteViews {
        // 创建并返回指定位置的视图
        val views = RemoteViews(context.packageName, R.layout.widget_course_item)
        
        if (position < courses.size) {
            val course = courses[position]
            
            // 设置课程名称
            views.setTextViewText(R.id.course_name, "📚 ${course.name}")
            
            // 设置时间
            if (course.time.isNotEmpty()) {
                views.setTextViewText(R.id.course_time, "⏰ ${course.time}")
                views.setViewVisibility(R.id.course_time, android.view.View.VISIBLE)
            } else {
                views.setViewVisibility(R.id.course_time, android.view.View.GONE)
            }
            
            // 设置地点
            if (course.location.isNotEmpty()) {
                views.setTextViewText(R.id.course_location, "📍 ${course.location}")
                views.setViewVisibility(R.id.course_location, android.view.View.VISIBLE)
            } else {
                views.setViewVisibility(R.id.course_location, android.view.View.GONE)
            }
            
            // 设置点击事件 - 点击单个课程项也打开应用
            val fillInIntent = Intent()
            fillInIntent.putExtra("course_name", course.name)
            views.setOnClickFillInIntent(R.id.course_name, fillInIntent)
        }
        
        return views
    }

    override fun getLoadingView(): RemoteViews? {
        // 返回加载视图，返回null使用默认加载视图
        return null
    }

    override fun getViewTypeCount(): Int {
        // 返回视图类型的数量
        return 1
    }

    override fun getItemId(position: Int): Long {
        return position.toLong()
    }

    override fun hasStableIds(): Boolean {
        return true
    }
}

