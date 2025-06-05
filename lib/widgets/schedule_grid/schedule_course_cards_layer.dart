import 'package:flutter/material.dart';
import '../../models/course.dart';
import 'schedule_course_card.dart';
import 'schedule_grid_utils.dart';

/// 课程卡片层组件
class ScheduleCourseCardsLayer extends StatelessWidget {
  final List<Course> courses;
  final List<Course> allCourses;
  final bool showNonCurrentWeekCourses;
  final int weekNumber;
  final double timeColumnWidth;
  final double dayColumnWidth;
  final double classHourHeight;
  final double restHeight;
  final Function(BuildContext, List<Course>, int, List<int>) onTimeSlotTap;

  const ScheduleCourseCardsLayer({
    super.key,
    required this.courses,
    required this.allCourses,
    required this.showNonCurrentWeekCourses,
    required this.weekNumber,
    required this.timeColumnWidth,
    required this.dayColumnWidth,
    required this.classHourHeight,
    required this.restHeight,
    required this.onTimeSlotTap,
  });

  @override
  Widget build(BuildContext context) {
    List<Widget> courseCards = [];
    
    // 为每一天构建课程卡片
    for (int dayOfWeek = 1; dayOfWeek <= 7; dayOfWeek++) {
      final dayCourses = courses.where((course) => course.dayOfWeek == dayOfWeek).toList();
      final dayOtherCourses = showNonCurrentWeekCourses 
          ? allCourses.where((course) => 
              course.dayOfWeek == dayOfWeek && 
              !courses.any((c) => c.id == course.id)).toList()
          : <Course>[];
      
      courseCards.addAll(_buildDayCourseCards(
        context,
        dayOfWeek,
        dayCourses,
        dayOtherCourses,
      ));
    }
    
    return Stack(children: courseCards);
  }

  /// 构建单天的课程卡片
  List<Widget> _buildDayCourseCards(
    BuildContext context,
    int dayOfWeek,
    List<Course> dayCourses,
    List<Course> dayOtherCourses,
  ) {
    List<Widget> cards = [];
    Set<String> processedCourses = {};
    
    // 获取所有课程（包括当前周和其他周）
    final allDayCourses = [...dayCourses, ...dayOtherCourses];
    
    // 按课程处理，而不是按时间段分组
    for (final course in dayCourses) {
      if (processedCourses.contains(course.id.toString())) {
        continue; // 已经处理过这门课程
      }
      
      // 查找与当前课程有时间重叠的所有课程（考虑拆分）
      final timeSlotCourses = _findOverlappingCourses(course, allDayCourses);
      
      cards.add(ScheduleCourseCard(
        course: course,
        timeSlotCourses: timeSlotCourses,
        dayOfWeek: dayOfWeek,
        weekNumber: weekNumber,
        timeColumnWidth: timeColumnWidth,
        dayColumnWidth: dayColumnWidth,
        classHourHeight: classHourHeight,
        restHeight: restHeight,
        onTap: () => onTimeSlotTap(context, timeSlotCourses, dayOfWeek, course.classHours),
      ));
      
      processedCourses.add(course.id.toString());
    }
    
    // 处理只有其他周课程的情况
    for (final course in dayOtherCourses) {
      if (processedCourses.contains(course.id.toString())) {
        continue;
      }
      
      // 检查是否与已处理的课程重叠
      bool overlapsWithProcessed = false;
      for (final processedCourse in dayCourses) {
        if (_coursesOverlapConsideringBreaks(course.classHours, processedCourse.classHours)) {
          overlapsWithProcessed = true;
          break;
        }
      }
      
      if (!overlapsWithProcessed) {
        final timeSlotCourses = _findOverlappingCourses(course, dayOtherCourses);
        
        cards.add(ScheduleCourseCard(
          course: course,
          timeSlotCourses: timeSlotCourses,
          dayOfWeek: dayOfWeek,
          weekNumber: weekNumber,
          timeColumnWidth: timeColumnWidth,
          dayColumnWidth: dayColumnWidth,
          classHourHeight: classHourHeight,
          restHeight: restHeight,
          onTap: () => onTimeSlotTap(context, timeSlotCourses, dayOfWeek, course.classHours),
        ));
        
        processedCourses.add(course.id.toString());
      }
    }
    
    return cards;
  }

  /// 查找与指定课程有时间重叠的所有课程（考虑拆分）
  List<Course> _findOverlappingCourses(Course targetCourse, List<Course> allCourses) {
    List<Course> overlappingCourses = [];
    
    for (final course in allCourses) {
      if (_coursesOverlapConsideringBreaks(targetCourse.classHours, course.classHours)) {
        overlappingCourses.add(course);
      }
    }
    
    return overlappingCourses;
  }

  /// 检查两个课程是否重叠（考虑拆分后的情况）
  bool _coursesOverlapConsideringBreaks(List<int> hours1, List<int> hours2) {
    // 如果两个课程都不跨越休息时间，使用原有的重叠检查
    if (!ScheduleGridUtils.crossesBreakTime(hours1) && !ScheduleGridUtils.crossesBreakTime(hours2)) {
      return ScheduleGridUtils.coursesOverlap(hours1, hours2);
    }
    
    // 获取拆分后的时间段
    final segments1 = ScheduleGridUtils.splitCourseAcrossBreaks(hours1);
    final segments2 = ScheduleGridUtils.splitCourseAcrossBreaks(hours2);
    
    // 检查任意段之间是否有重叠
    for (final segment1 in segments1) {
      for (final segment2 in segments2) {
        if (ScheduleGridUtils.coursesOverlap(segment1, segment2)) {
          return true;
        }
      }
    }
    
    return false;
  }
}