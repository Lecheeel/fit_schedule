package com.example.fit_schedule

import android.content.Context
import android.database.sqlite.SQLiteDatabase
import android.database.sqlite.SQLiteException
import java.io.File
import java.text.SimpleDateFormat
import java.util.*

class WidgetDatabaseHelper(private val context: Context) {

    companion object {
        private const val DATABASE_NAME = "fit_schedule.db"
    }

    /**
     * 获取今日课程列表
     */
    fun getTodayCourses(): List<CourseInfo> {
        return try {
            // 获取当前日期和周次
            val dayOfWeek = getCurrentDayOfWeek()
            val scheduleInfo = getActiveScheduleInfo()
            
            if (scheduleInfo == null) {
                android.util.Log.w("WidgetDebug", "No active schedule found")
                return emptyList()
            }
            
            val currentWeek = scheduleInfo.currentWeek
            val scheduleId = scheduleInfo.scheduleId
            
            android.util.Log.d("WidgetDebug", "Today: dayOfWeek=$dayOfWeek, week=$currentWeek, scheduleId=$scheduleId")
            
            val database = openFlutterDatabase()
            if (database != null) {
                val courses = getCoursesByDay(database, dayOfWeek, currentWeek, scheduleId)
                database.close()
                android.util.Log.d("WidgetDebug", "Found ${courses.size} courses")
                courses
            } else {
                android.util.Log.e("WidgetDebug", "Database is null")
                emptyList()
            }
        } catch (e: Exception) {
            // 如果读取数据库失败，返回空列表
            android.util.Log.e("WidgetDebug", "Error loading courses: ${e.message}")
            emptyList()
        }
    }

    /**
     * 打开Flutter应用的SQLite数据库
     */
    private fun openFlutterDatabase(): SQLiteDatabase? {
        return try {
            // Flutter应用的数据库通常存储在应用的数据目录下
            val databasePath = File(context.getDatabasePath(DATABASE_NAME).absolutePath)
            
            android.util.Log.d("WidgetDebug", "Database path: ${databasePath.absolutePath}")
            android.util.Log.d("WidgetDebug", "Database exists: ${databasePath.exists()}")
            
            if (databasePath.exists()) {
                val db = SQLiteDatabase.openDatabase(
                    databasePath.absolutePath,
                    null,
                    SQLiteDatabase.OPEN_READONLY
                )
                android.util.Log.d("WidgetDebug", "Database opened successfully")
                db
            } else {
                android.util.Log.e("WidgetDebug", "Database file not found")
                null
            }
        } catch (e: SQLiteException) {
            android.util.Log.e("WidgetDebug", "Failed to open database: ${e.message}")
            null
        }
    }

    /**
     * 活动课表信息数据类
     */
    private data class ScheduleInfo(
        val scheduleId: Int,
        val currentWeek: Int
    )
    
    /**
     * 获取当前活动课表信息（ID和当前周次）
     */
    private fun getActiveScheduleInfo(): ScheduleInfo? {
        return try {
            val database = openFlutterDatabase()
            if (database != null) {
                // 查询当前活动课表（数据库已从semesters迁移到schedules表）
                val cursor = database.rawQuery(
                    "SELECT id, startDate, numberOfWeeks FROM schedules WHERE isActive = 1",
                    null
                )
                
                cursor.use {
                    if (it.moveToFirst()) {
                        val scheduleId = it.getInt(0)
                        val startDateStr = it.getString(1)
                        val numberOfWeeks = it.getInt(2)
                        
                        android.util.Log.d("WidgetDebug", "Schedule found: id=$scheduleId, startDate=$startDateStr, numberOfWeeks=$numberOfWeeks")
                        
                        // 解析开始日期并计算当前周次
                        val startDate = parseDate(startDateStr)
                        
                        val currentWeek = if (startDate != null) {
                            val now = Date()
                            val diff = now.time - startDate.time
                            val weeks = (diff / (1000 * 60 * 60 * 24 * 7)).toInt() + 1
                            
                            android.util.Log.d("WidgetDebug", "Calculated current week: $weeks")
                            
                            // 如果周次超出范围，返回边界值
                            when {
                                weeks < 1 -> 1
                                weeks > numberOfWeeks -> numberOfWeeks
                                else -> weeks
                            }
                        } else {
                            1
                        }
                        
                        database.close()
                        return ScheduleInfo(scheduleId, currentWeek)
                    } else {
                        android.util.Log.w("WidgetDebug", "No active schedule found in database")
                    }
                }
                database.close()
            }
            null
        } catch (e: Exception) {
            android.util.Log.e("WidgetDebug", "Error getting active schedule info: ${e.message}")
            null
        }
    }

    /**
     * 从数据库中查询指定日期、周次和课表的课程
     */
    private fun getCoursesByDay(database: SQLiteDatabase, dayOfWeek: Int, currentWeek: Int, scheduleId: Int): List<CourseInfo> {
        val courses = mutableListOf<CourseInfo>()
        
        try {
            // 查询指定课表和星期几的课程
            val cursor = database.rawQuery(
                """
                SELECT name, teacher, location, color, classHours, weeks 
                FROM courses 
                WHERE dayOfWeek = ? AND scheduleId = ?
                """.trimIndent(),
                arrayOf(dayOfWeek.toString(), scheduleId.toString())
            )

            android.util.Log.d("WidgetDebug", "Query: dayOfWeek=$dayOfWeek, scheduleId=$scheduleId, currentWeek=$currentWeek")

            cursor.use {
                while (it.moveToNext()) {
                    val name = it.getString(0) ?: ""
                    val teacher = it.getString(1) ?: ""
                    val location = it.getString(2) ?: ""
                    val colorValue = it.getInt(3)
                    val classHoursJson = it.getString(4) ?: "[]"
                    val weeksJson = it.getString(5) ?: "[]"

                    // 解析课时和周次JSON
                    val classHours = parseJsonIntArray(classHoursJson)
                    val weeks = parseJsonIntArray(weeksJson)

                    android.util.Log.d("WidgetDebug", "Course: $name, weeks=$weeks, classHours=$classHours, color=$colorValue")

                    // 检查当前周是否在上课周次内
                    if (weeks.contains(currentWeek) && classHours.isNotEmpty()) {
                        val timeRange = getTimeRangeFromClassHours(classHours)
                        // 确保颜色值有效，如果无效则使用默认颜色
                        val finalColor = if (colorValue != 0) colorValue else 0xFF667eea.toInt()
                        courses.add(
                            CourseInfo(
                                name = name,
                                time = timeRange,
                                location = location,
                                teacher = teacher,
                                color = finalColor
                            )
                        )
                        android.util.Log.d("WidgetDebug", "Added course: $name (week $currentWeek is in $weeks)")
                    } else {
                        android.util.Log.d("WidgetDebug", "Skipped course: $name (week $currentWeek not in $weeks)")
                    }
                }
            }
        } catch (e: Exception) {
            android.util.Log.e("WidgetDebug", "Error querying courses: ${e.message}")
        }

        // 按时间排序
        return courses.sortedBy { it.time }
    }

    /**
     * 解析JSON格式的整数数组
     */
    private fun parseJsonIntArray(json: String): List<Int> {
        return try {
            // 简单的JSON数组解析，去掉方括号和空格，然后分割
            json.trim()
                .removePrefix("[")
                .removeSuffix("]")
                .split(",")
                .mapNotNull { it.trim().toIntOrNull() }
        } catch (e: Exception) {
            emptyList()
        }
    }

    /**
     * 根据课时获取时间范围
     */
    private fun getTimeRangeFromClassHours(classHours: List<Int>): String {
        if (classHours.isEmpty()) return ""

        val startTimes = mapOf(
            1 to "08:30", 2 to "09:20", 3 to "10:20", 4 to "11:10",
            5 to "14:00", 6 to "14:50", 7 to "15:45", 8 to "16:35",
            9 to "18:30", 10 to "19:25", 11 to "20:20"
        )

        val endTimes = mapOf(
            1 to "09:15", 2 to "10:05", 3 to "11:05", 4 to "11:55",
            5 to "14:45", 6 to "15:35", 7 to "16:30", 8 to "17:20",
            9 to "19:15", 10 to "20:10", 11 to "21:05"
        )

        val startTime = startTimes[classHours.first()] ?: ""
        val endTime = endTimes[classHours.last()] ?: ""

        return if (startTime.isNotEmpty() && endTime.isNotEmpty()) {
            "$startTime-$endTime"
        } else {
            ""
        }
    }

    /**
     * 获取当前是星期几（1-7，对应周一到周日）
     */
    private fun getCurrentDayOfWeek(): Int {
        val calendar = Calendar.getInstance()
        val dayOfWeek = calendar.get(Calendar.DAY_OF_WEEK)
        
        // Calendar.DAY_OF_WEEK: 周日=1, 周一=2, ..., 周六=7
        // 转换为: 周一=1, 周二=2, ..., 周日=7
        return when (dayOfWeek) {
            Calendar.SUNDAY -> 7
            else -> dayOfWeek - 1
        }
    }

    /**
     * 解析日期字符串，支持多种格式
     */
    private fun parseDate(dateStr: String): Date? {
        // 尝试ISO格式 (yyyy-MM-ddTHH:mm:ss.SSSZ 或类似)
        val isoFormats = listOf(
            SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS", Locale.getDefault()),
            SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss", Locale.getDefault()),
            SimpleDateFormat("yyyy-MM-dd", Locale.getDefault())
        )
        
        for (format in isoFormats) {
            try {
                return format.parse(dateStr.split("Z")[0].split("+")[0])
            } catch (e: Exception) {
                // 继续尝试下一个格式
            }
        }
        
        return null
    }

    /**
     * 课表摘要信息
     */
    data class ScheduleSummary(
        val currentWeek: Int,
        val courseCount: Int
    )

    /**
     * 获取课表摘要信息
     */
    fun getScheduleSummary(): ScheduleSummary {
        val scheduleInfo = getActiveScheduleInfo()
        val currentWeek = scheduleInfo?.currentWeek ?: 1
        val courses = getTodayCourses()
        return ScheduleSummary(currentWeek, courses.size)
    }

    /**
     * 课程信息数据类
     */
    data class CourseInfo(
        val name: String,
        val time: String,
        val location: String,
        val teacher: String = "",
        val color: Int = 0xFF667eea.toInt()
    )
}
