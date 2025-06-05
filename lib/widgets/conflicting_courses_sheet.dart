import 'package:flutter/material.dart';
import '../models/course.dart';
import '../utils/app_theme.dart';
import '../utils/time_utils.dart';

class ConflictingCoursesSheet extends StatelessWidget {
  final List<Course> courses;
  final int currentWeek;
  final Function(Course) onCourseTap;

  const ConflictingCoursesSheet({
    super.key,
    required this.courses,
    required this.currentWeek,
    required this.onCourseTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '同时段课程',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: courses.length,
              itemBuilder: (context, index) {
                final course = courses[index];
                final isCurrentWeekCourse = course.isActiveInWeek(currentWeek);
                
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isCurrentWeekCourse 
                        ? course.color 
                        : Colors.grey[300]!,
                    child: Text(
                      course.name.substring(0, 1),
                      style: TextStyle(
                        color: isCurrentWeekCourse 
                            ? AppTheme.getCourseTextColor(course.color)
                            : Colors.grey[500]!,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    course.name,
                    style: TextStyle(
                      color: isCurrentWeekCourse 
                          ? null 
                          : Colors.grey[500],
                    ),
                  ),
                  subtitle: Text(
                    '${course.teacher ?? ""} ${course.location ?? ""}\n周次: ${TimeUtils.getWeeksString(course.weeks)}',
                    style: TextStyle(
                      color: isCurrentWeekCourse 
                          ? null 
                          : Colors.grey[500],
                    ),
                  ),
                  onTap: () => onCourseTap(course),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // 静态方法，用于显示底部表单
  static void show(
    BuildContext context, {
    required List<Course> courses,
    required int currentWeek,
    required Function(Course) onCourseTap,
  }) {
    showModalBottomSheet(
      context: context,
      builder: (context) => ConflictingCoursesSheet(
        courses: courses,
        currentWeek: currentWeek,
        onCourseTap: onCourseTap,
      ),
    );
  }
} 