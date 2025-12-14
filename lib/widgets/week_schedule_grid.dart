import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/course.dart';
import '../providers/schedule_provider.dart';
import 'time_slot_courses_sheet.dart';
import 'schedule_grid/schedule_background_grid.dart';
import 'schedule_grid/schedule_course_cards_layer.dart';
import 'schedule_grid/schedule_grid_utils.dart';

/// 周课表网格组件
class WeekScheduleGrid extends StatelessWidget {
  final int weekNumber;

  const WeekScheduleGrid({
    super.key,
    required this.weekNumber,
  });

  @override
  Widget build(BuildContext context) {
    final scheduleProvider = Provider.of<ScheduleProvider>(context);
    
    return OrientationBuilder(
      builder: (context, orientation) {
        return FutureBuilder<List<Course>>(
          future: scheduleProvider.getCoursesForWeek(weekNumber),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (snapshot.hasError) {
              return Center(child: Text('加载课程失败: ${snapshot.error}'));
            }
            
            final courses = snapshot.data ?? [];
            
            // 如果显示非本周课程，获取该星期所有课程（不考虑周次）
            List<Course> allCourses = [];
            if (scheduleProvider.showNonCurrentWeekCourses) {
              allCourses = scheduleProvider.courses;
            }
            
            return LayoutBuilder(
              builder: (context, constraints) {
                return _buildScheduleWithMergedCourses(
                  context, 
                  courses, 
                  allCourses, 
                  scheduleProvider, 
                  constraints.maxHeight,
                  constraints.maxWidth
                );
              }
            );
          },
        );
      }
    );
  }

  /// 构建包含合并课程的课表
  Widget _buildScheduleWithMergedCourses(
    BuildContext context, 
    List<Course> courses, 
    List<Course> allCourses, 
    ScheduleProvider scheduleProvider, 
    double availableHeight,
    double availableWidth
  ) {
    // 计算响应式尺寸
    final sizes = ScheduleGridUtils.calculateResponsiveSizes(availableHeight, availableWidth);
    
    return Stack(
      children: [
        // 背景网格
        ScheduleBackgroundGrid(
          timeColumnWidth: sizes['timeColumnWidth']!,
          classHourHeight: sizes['classHourHeight']!,
          restHeight: sizes['restHeight']!,
        ),
        
        // 课程卡片层
        ScheduleCourseCardsLayer(
          courses: courses,
          allCourses: allCourses,
          showNonCurrentWeekCourses: scheduleProvider.showNonCurrentWeekCourses,
          weekNumber: weekNumber,
          timeColumnWidth: sizes['timeColumnWidth']!,
          dayColumnWidth: sizes['dayColumnWidth']!,
          classHourHeight: sizes['classHourHeight']!,
          restHeight: sizes['restHeight']!,
          onTimeSlotTap: _showTimeSlotCourses,
        ),
      ],
    );
  }

  /// 显示课程详情
  void _showCourseDetail(BuildContext context, Course course) {
    Navigator.pushNamed(
      context, 
      '/course-form',
      arguments: course,
    );
  }

  /// 显示时间槽课程
  void _showTimeSlotCourses(BuildContext context, List<Course> timeSlotCourses, int dayOfWeek, List<int> classHours) {
    TimeSlotCoursesSheet.show(
      context,
      courses: timeSlotCourses,
      dayOfWeek: dayOfWeek,
      classHours: classHours,
      currentWeek: weekNumber,
      onCourseTap: (course) => _showCourseDetail(context, course),
    );
  }
}
