import 'package:flutter/material.dart';

/// 课表设置区块
class ScheduleSection extends StatelessWidget {
  final bool showNonCurrentWeekCourses;
  final ValueChanged<bool> onShowNonCurrentWeekCoursesChanged;
  final VoidCallback onImportCourse;

  const ScheduleSection({
    super.key,
    required this.showNonCurrentWeekCourses,
    required this.onShowNonCurrentWeekCoursesChanged,
    required this.onImportCourse,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, '课表设置'),
        ListTile(
          leading: const Icon(Icons.download),
          title: const Text('导入课表'),
          subtitle: const Text('从教务系统导入课程安排'),
          trailing: const Icon(Icons.chevron_right),
          onTap: onImportCourse,
        ),
        SwitchListTile(
          title: const Text('显示非本周课程'),
          subtitle: const Text('非本周课程将以灰色显示'),
          value: showNonCurrentWeekCourses,
          onChanged: onShowNonCurrentWeekCoursesChanged,
        ),
        const Divider(),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

