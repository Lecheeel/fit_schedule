import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// 时间工具类
class TimeUtils {
  /// 将TimeOfDay转换为格式化的字符串（如 08:30）
  static String formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
  
  /// 获取星期几的中文名称
  static String getDayOfWeekName(int dayOfWeek) {
    const dayNames = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    if (dayOfWeek < 1 || dayOfWeek > 7) return '';
    return dayNames[dayOfWeek - 1];
  }
  
  /// 获取课时的时间范围字符串
  static String getClassTimeString(int classHour) {
    final Map<int, String> classTimes = {
      1: '08:30-09:15',
      2: '09:20-10:05',
      3: '10:20-11:05',
      4: '11:10-11:55',
      5: '14:00-14:45',
      6: '14:50-15:35',
      7: '15:45-16:30',
      8: '16:35-17:20',
      9: '18:30-19:15',
      10: '19:25-20:10',
      11: '20:20-21:05',
    };
    
    return classTimes[classHour] ?? '';
  }
  
  /// 获取课时的开始时间
  static TimeOfDay getClassStartTime(int classHour) {
    final Map<int, TimeOfDay> startTimes = {
      1: const TimeOfDay(hour: 8, minute: 30),
      2: const TimeOfDay(hour: 9, minute: 20),
      3: const TimeOfDay(hour: 10, minute: 20),
      4: const TimeOfDay(hour: 11, minute: 10),
      5: const TimeOfDay(hour: 14, minute: 0),
      6: const TimeOfDay(hour: 14, minute: 50),
      7: const TimeOfDay(hour: 15, minute: 45),
      8: const TimeOfDay(hour: 16, minute: 35),
      9: const TimeOfDay(hour: 18, minute: 30),
      10: const TimeOfDay(hour: 19, minute: 25),
      11: const TimeOfDay(hour: 20, minute: 20),
    };
    
    return startTimes[classHour] ?? const TimeOfDay(hour: 0, minute: 0);
  }
  
  /// 获取课时的结束时间
  static TimeOfDay getClassEndTime(int classHour) {
    final Map<int, TimeOfDay> endTimes = {
      1: const TimeOfDay(hour: 9, minute: 15),
      2: const TimeOfDay(hour: 10, minute: 5),
      3: const TimeOfDay(hour: 11, minute: 5),
      4: const TimeOfDay(hour: 11, minute: 55),
      5: const TimeOfDay(hour: 14, minute: 45),
      6: const TimeOfDay(hour: 15, minute: 35),
      7: const TimeOfDay(hour: 16, minute: 30),
      8: const TimeOfDay(hour: 17, minute: 20),
      9: const TimeOfDay(hour: 19, minute: 15),
      10: const TimeOfDay(hour: 20, minute: 10),
      11: const TimeOfDay(hour: 21, minute: 5),
    };
    
    return endTimes[classHour] ?? const TimeOfDay(hour: 0, minute: 0);
  }
  
  /// 获取连续课时的时间范围（例如第1-2节课：08:30-10:05）
  static String getClassesTimeString(List<int> classHours) {
    if (classHours.isEmpty) return '';
    
    classHours.sort(); // 确保课时按顺序排列
    
    final startTime = getClassStartTime(classHours.first);
    final endTime = getClassEndTime(classHours.last);
    
    return '${formatTimeOfDay(startTime)}-${formatTimeOfDay(endTime)}';
  }
  
  /// 格式化日期（如 2025年9月1日）
  static String formatDate(DateTime date) {
    final formatter = DateFormat('yyyy年MM月dd日');
    return formatter.format(date);
  }
  
  /// 格式化短日期（如 9月1日）
  static String formatShortDate(DateTime date) {
    final formatter = DateFormat('MM月dd日');
    return formatter.format(date);
  }
  
  /// 格式化周视图日期（如 9/1 周一）
  static String formatWeekViewDate(DateTime date) {
    final formatter = DateFormat('MM/dd');
    final dayName = getDayOfWeekName(date.weekday);
    return '${formatter.format(date)} $dayName';
  }
  
  /// 获取当前的课时
  static int? getCurrentClassHour() {
    final now = TimeOfDay.now();
    final currentTimeInMinutes = now.hour * 60 + now.minute;
    
    // 定义每节课的时间范围（开始和结束时间，以分钟为单位）
    final Map<int, List<int>> classHourRanges = {
      1: [8 * 60 + 30, 9 * 60 + 15], // 08:30-09:15
      2: [9 * 60 + 20, 10 * 60 + 5], // 09:20-10:05
      3: [10 * 60 + 20, 11 * 60 + 5], // 10:20-11:05
      4: [11 * 60 + 10, 11 * 60 + 55], // 11:10-11:55
      5: [14 * 60, 14 * 60 + 45], // 14:00-14:45
      6: [14 * 60 + 50, 15 * 60 + 35], // 14:50-15:35
      7: [15 * 60 + 45, 16 * 60 + 30], // 15:45-16:30
      8: [16 * 60 + 35, 17 * 60 + 20], // 16:35-17:20
      9: [18 * 60 + 30, 19 * 60 + 15], // 18:30-19:15
      10: [19 * 60 + 25, 20 * 60 + 10], // 19:25-20:10
      11: [20 * 60 + 20, 21 * 60 + 5], // 20:20-21:05
    };
    
    // 检查当前时间是否在某节课的时间范围内
    for (final entry in classHourRanges.entries) {
      final classHour = entry.key;
      final range = entry.value;
      
      if (currentTimeInMinutes >= range[0] && currentTimeInMinutes <= range[1]) {
        return classHour;
      }
    }
    
    return null; // 当前不在任何课时内
  }
  
  /// 检查当前是否在上课时间
  static bool isInClassTime() {
    return getCurrentClassHour() != null;
  }
  
  /// 获取课时区间的字符串表示（如 1-2节）
  static String getClassHoursString(List<int> classHours) {
    if (classHours.isEmpty) return '';
    
    classHours.sort(); // 确保课时按顺序排列
    
    if (classHours.length == 1) {
      return '第${classHours.first}节';
    } else {
      return '第${classHours.first}-${classHours.last}节';
    }
  }
  
  /// 获取课时区间的简短字符串表示（如 1-2 或 1），用于日视图
  static String getClassHoursRangeString(List<int> classHours) {
    if (classHours.isEmpty) return '';
    
    classHours.sort(); // 确保课时按顺序排列
    
    if (classHours.length == 1) {
      return '${classHours.first}';
    } else {
      return '${classHours.first}-${classHours.last}';
    }
  }
  
  /// 获取周次区间的字符串表示（如 1-4周）
  static String getWeeksString(List<int> weeks) {
    if (weeks.isEmpty) return '';
    
    weeks.sort(); // 确保周次按顺序排列
    
    // 处理连续的周次
    List<String> ranges = [];
    int start = weeks.first;
    int end = start;
    
    for (int i = 1; i < weeks.length; i++) {
      if (weeks[i] == end + 1) {
        // 连续周次
        end = weeks[i];
      } else {
        // 遇到不连续的周次，添加之前的范围
        if (start == end) {
          ranges.add('$start');
        } else {
          ranges.add('$start-$end');
        }
        start = weeks[i];
        end = start;
      }
    }
    
    // 添加最后一个范围
    if (start == end) {
      ranges.add('$start');
    } else {
      ranges.add('$start-$end');
    }
    
    return '${ranges.join(',')}周';
  }
} 