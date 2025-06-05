import 'dart:convert';
import 'package:flutter/material.dart';

class Course {
  final int? id; // 数据库ID
  final String name; // 课程名称
  final String? teacher; // 教师
  final String? location; // 上课地点
  final Color color; // 课程颜色
  final int dayOfWeek; // 星期几（1-7 对应周一到周日）
  final List<int> classHours; // 上课节次（例如 [1, 2] 表示第1-2节课）
  final List<int> weeks; // 上课周次（例如 [1, 2, 3, 4] 表示第1-4周上课）
  final String? note; // 备注

  Course({
    this.id,
    required this.name,
    this.teacher,
    this.location,
    required this.color,
    required this.dayOfWeek,
    required this.classHours,
    required this.weeks,
    this.note,
  });

  // 从数据库映射创建Course对象
  factory Course.fromMap(Map<String, dynamic> map) {
    return Course(
      id: map['id'],
      name: map['name'],
      teacher: map['teacher'],
      location: map['location'],
      color: Color(map['color']),
      dayOfWeek: map['dayOfWeek'],
      classHours: List<int>.from(jsonDecode(map['classHours'])),
      weeks: List<int>.from(jsonDecode(map['weeks'])),
      note: map['note'],
    );
  }

  // 转换为数据库映射
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'teacher': teacher,
      'location': location,
      'color': color.value,
      'dayOfWeek': dayOfWeek,
      'classHours': jsonEncode(classHours),
      'weeks': jsonEncode(weeks),
      'note': note,
    };
  }

  // 创建Course对象的副本
  Course copyWith({
    int? id,
    String? name,
    String? teacher,
    String? location,
    Color? color,
    int? dayOfWeek,
    List<int>? classHours,
    List<int>? weeks,
    String? note,
  }) {
    return Course(
      id: id ?? this.id,
      name: name ?? this.name,
      teacher: teacher ?? this.teacher,
      location: location ?? this.location,
      color: color ?? this.color,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      classHours: classHours ?? this.classHours,
      weeks: weeks ?? this.weeks,
      note: note ?? this.note,
    );
  }

  // 获取课程时间范围
  TimeRange getTimeRange() {
    // 根据课时获取对应的时间
    Map<int, TimeOfDay> startTimes = {
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

    Map<int, TimeOfDay> endTimes = {
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

    // 获取课程的开始和结束时间
    final startClassHour = classHours.first;
    final endClassHour = classHours.last;

    return TimeRange(
      start: startTimes[startClassHour]!,
      end: endTimes[endClassHour]!,
    );
  }

  // 判断课程是否在指定周次上课
  bool isActiveInWeek(int week) {
    return weeks.contains(week);
  }
}

// 表示时间范围的类
class TimeRange {
  final TimeOfDay start;
  final TimeOfDay end;

  TimeRange({required this.start, required this.end});

  @override
  String toString() {
    return '${_formatTimeOfDay(start)}-${_formatTimeOfDay(end)}';
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
} 