package com.example.fit_schedule

import android.content.Context
import android.database.sqlite.SQLiteDatabase
import android.database.sqlite.SQLiteException
import java.io.File
import java.text.SimpleDateFormat
import java.util.*

class WidgetDatabaseHelper(private val context: Context) {

    companion object {
        private const val DATABASE_NAME = "schedule_database.db"
    }

    /**
     * 获取今日课程列表
     */
    fun getTodayCourses(): List<CourseInfo> {
        return try {
            val database = openFlutterDatabase()
            if (database != null) {
                getCoursesByDay(database, getCurrentDayOfWeek(), getCurrentWeek())
            } else {
                emptyList()
            }
        } catch (e: Exception) {
            // 如果读取数据库失败，返回空列表
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
            
            if (databasePath.exists()) {
                SQLiteDatabase.openDatabase(
                    databasePath.absolutePath,
                    null,
                    SQLiteDatabase.OPEN_READONLY
                )
            } else {
                null
            }
        } catch (e: SQLiteException) {
            null
        }
    }

    /**
     * 从数据库中查询指定日期和周次的课程
     */
    private fun getCoursesByDay(database: SQLiteDatabase, dayOfWeek: Int, currentWeek: Int): List<CourseInfo> {
        val courses = mutableListOf<CourseInfo>()
        
        try {
            // 查询课程表，假设表名为 courses
            val cursor = database.rawQuery(
                """
                SELECT name, teacher, location, color, classHours, weeks 
                FROM courses 
                WHERE dayOfWeek = ?
                """.trimIndent(),
                arrayOf(dayOfWeek.toString())
            )

            cursor.use {
                while (it.moveToNext()) {
                    val name = it.getString(0) ?: ""
                    val teacher = it.getString(1) ?: ""
                    val location = it.getString(2) ?: ""
                    val classHoursJson = it.getString(4) ?: "[]"
                    val weeksJson = it.getString(5) ?: "[]"

                    // 解析课时和周次JSON
                    val classHours = parseJsonIntArray(classHoursJson)
                    val weeks = parseJsonIntArray(weeksJson)

                    // 检查当前周是否在上课周次内
                    if (weeks.contains(currentWeek) && classHours.isNotEmpty()) {
                        val timeRange = getTimeRangeFromClassHours(classHours)
                        courses.add(
                            CourseInfo(
                                name = name,
                                time = timeRange,
                                location = location,
                                teacher = teacher
                            )
                        )
                    }
                }
            }
        } catch (e: Exception) {
            // 查询失败时返回空列表
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
     * 获取当前周次（简化实现，实际应该从学期设置中计算）
     */
    private fun getCurrentWeek(): Int {
        // 这里简化处理，返回一个固定的周次
        // 实际应该从数据库中读取当前学期信息并计算当前周次
        return 1
    }

    /**
     * 课程信息数据类
     */
    data class CourseInfo(
        val name: String,
        val time: String,
        val location: String,
        val teacher: String = ""
    )
} 