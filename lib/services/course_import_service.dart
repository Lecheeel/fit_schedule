import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../models/course.dart';
import '../utils/app_theme.dart';

/// 课程导入服务
class CourseImportService {
  static const String _baseUrl = 'http://106.15.72.24:8072';
  
  /// 获取完整学期课表
  static Future<CourseImportResult> getFullSchedule(String username, String password) async {
    try {
      final url = Uri.parse('$_baseUrl/get_courses');
      final headers = {'Content-Type': 'application/json'};
      final data = {
        'username': username,
        'password': password,
        'action': 'full_schedule',
        'relogin': false,
      };

      final response = await http.post(
        url,
        headers: headers,
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        if (responseData.containsKey('error')) {
          return CourseImportResult.error(responseData['error']);
        }

        // 解析课程数据
        final courses = await _parseCoursesToCourseList(responseData);
        final semesterInfo = responseData['semester_info'];
        
        return CourseImportResult.success(
          courses: courses,
          semesterStartDate: semesterInfo['start_date'],
          currentWeek: semesterInfo['current_week'],
          totalCourses: semesterInfo['total_courses'],
        );
      } else {
        return CourseImportResult.error('网络请求失败: ${response.statusCode}');
      }
    } catch (e) {
      return CourseImportResult.error('导入失败: $e');
    }
  }

  /// 将API返回的课程数据转换为Course对象列表
  static Future<List<Course>> _parseCoursesToCourseList(Map<String, dynamic> data) async {
    final List courses = data['courses'] ?? [];
    final List<Course> courseList = [];
    
    for (int i = 0; i < courses.length; i++) {
      final courseData = courses[i];
      
      try {
        // 解析周次
        final List<int> weeks = _parseWeeks(courseData['formatted_info']['weeks_text'] ?? '');
        
        // 解析星期几
        final List<int> weekdays = (courseData['weekdays'] as List).map((w) => w as int).toList();
        
        // 解析节次
        final List<int> periods = (courseData['periods'] as List).map((p) => p as int).toList();
        
        // 为每个上课日期创建Course对象
        for (int weekday in weekdays) {
          final course = Course(
            name: courseData['name'] ?? '未知课程',
            teacher: courseData['teacher'],
            location: courseData['classroom'],
            color: AppTheme.getRandomCourseColor(i),
            dayOfWeek: weekday, // API中1-7对应周一到周日
            classHours: periods,
            weeks: weeks,
            note: '从教务系统导入',
          );
          courseList.add(course);
        }
      } catch (e) {
        debugPrint('解析课程失败: ${courseData['name']}, 错误: $e');
        continue;
      }
    }

    return courseList;
  }

  /// 解析周次文本，例如 "1-11,17周" -> [1,2,3,4,5,6,7,8,9,10,11,17]
  static List<int> _parseWeeks(String weeksText) {
    final List<int> weeks = [];
    
    if (weeksText.isEmpty) return weeks;
    
    // 移除"周"字符
    final cleanText = weeksText.replaceAll('周', '').trim();
    
    // 按逗号分割
    final parts = cleanText.split(',');
    
    for (String part in parts) {
      part = part.trim();
      if (part.contains('-')) {
        // 处理范围，例如 "1-11"
        final rangeParts = part.split('-');
        if (rangeParts.length == 2) {
          final start = int.tryParse(rangeParts[0].trim());
          final end = int.tryParse(rangeParts[1].trim());
          if (start != null && end != null) {
            for (int i = start; i <= end; i++) {
              weeks.add(i);
            }
          }
        }
      } else {
        // 处理单个数字
        final week = int.tryParse(part);
        if (week != null) {
          weeks.add(week);
        }
      }
    }
    
    return weeks..sort();
  }
}

/// 课程导入结果
class CourseImportResult {
  final bool success;
  final String? error;
  final List<Course>? courses;
  final String? semesterStartDate;
  final int? currentWeek;
  final int? totalCourses;

  CourseImportResult._({
    required this.success,
    this.error,
    this.courses,
    this.semesterStartDate,
    this.currentWeek,
    this.totalCourses,
  });

  factory CourseImportResult.success({
    required List<Course> courses,
    required String semesterStartDate,
    required int currentWeek,
    required int totalCourses,
  }) {
    return CourseImportResult._(
      success: true,
      courses: courses,
      semesterStartDate: semesterStartDate,
      currentWeek: currentWeek,
      totalCourses: totalCourses,
    );
  }

  factory CourseImportResult.error(String error) {
    return CourseImportResult._(
      success: false,
      error: error,
    );
  }
} 