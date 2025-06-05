import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/course.dart';
import '../providers/schedule_provider.dart';
import '../utils/time_utils.dart';
import '../utils/app_theme.dart';
import 'course_form_screen.dart';
import 'course_import_screen.dart';

class CourseManagementScreen extends StatelessWidget {
  const CourseManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('课程管理'),
        actions: [
          IconButton(
            onPressed: () => _navigateToImportCourse(context),
            icon: const Icon(Icons.download),
            tooltip: '导入课表',
          ),
        ],
      ),
      body: FutureBuilder<List<Course>>(
        future: Provider.of<ScheduleProvider>(context, listen: false).loadCourses(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(child: Text('加载课程失败: ${snapshot.error}'));
          }
          
          return Consumer<ScheduleProvider>(
            builder: (context, provider, child) {
              final courses = provider.courses;
              
              if (courses.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '暂无课程信息',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '您可以手动添加课程或从教务系统导入',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => _navigateToImportCourse(context),
                            icon: const Icon(Icons.download),
                            label: const Text('导入课表'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                          ),
                          const SizedBox(width: 16),
                          OutlinedButton.icon(
                            onPressed: () => _navigateToAddCourse(context),
                            icon: const Icon(Icons.add),
                            label: const Text('手动添加'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }
              
              // 按课程名称排序
              final sortedCourses = List<Course>.from(courses)
                ..sort((a, b) => a.name.compareTo(b.name));
              
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: sortedCourses.length,
                itemBuilder: (context, index) {
                  final course = sortedCourses[index];
                  return _buildCourseItem(context, course);
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddCourse(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  // 构建课程项
  Widget _buildCourseItem(BuildContext context, Course course) {
    // 获取周几的文本表示
    final dayOfWeekText = _getDayOfWeekText(course.dayOfWeek);
    
    // 获取课时的文本表示
    final classHoursText = '第${course.classHours.join('、')}节';
    
    // 获取周次的文本表示
    final weeksText = _formatWeeks(course.weeks);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: course.color,
          child: Text(
            course.name.isNotEmpty ? course.name.substring(0, 1) : '?',
            style: TextStyle(
              color: AppTheme.getCourseTextColor(course.color),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          course.name,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            _buildInfoText(context, '$dayOfWeekText $classHoursText'),
            if (course.teacher != null && course.teacher!.isNotEmpty)
              _buildInfoText(context, '教师: ${course.teacher}'),
            if (course.location != null && course.location!.isNotEmpty)
              _buildInfoText(context, '地点: ${course.location}'),
            _buildInfoText(context, '周次: $weeksText'),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              _navigateToEditCourse(context, course);
            } else if (value == 'delete') {
              _showDeleteConfirmDialog(context, course);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem<String>(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 18),
                  SizedBox(width: 8),
                  Text('编辑'),
                ],
              ),
            ),
            const PopupMenuItem<String>(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 18, color: Colors.red),
                  SizedBox(width: 8),
                  Text('删除', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        onTap: () => _navigateToEditCourse(context, course),
      ),
    );
  }

  // 构建信息文本
  Widget _buildInfoText(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  // 获取星期几的文本表示
  String _getDayOfWeekText(int dayOfWeek) {
    final days = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return days[dayOfWeek - 1];
  }

  // 格式化周次
  String _formatWeeks(List<int> weeks) {
    if (weeks.isEmpty) return '';
    
    // 处理连续的周次
    final formattedWeeks = <String>[];
    int start = weeks[0];
    int end = start;
    
    for (int i = 1; i < weeks.length; i++) {
      if (weeks[i] == end + 1) {
        end = weeks[i];
      } else {
        formattedWeeks.add(start == end ? '$start' : '$start-$end');
        start = end = weeks[i];
      }
    }
    
    formattedWeeks.add(start == end ? '$start' : '$start-$end');
    
    return formattedWeeks.join('、');
  }

  // 导航到添加课程页面
  void _navigateToAddCourse(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CourseFormScreen(),
      ),
    );
  }

  // 导航到编辑课程页面
  void _navigateToEditCourse(BuildContext context, Course course) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CourseFormScreen(course: course),
      ),
    );
  }

  // 导航到导入课表页面
  void _navigateToImportCourse(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CourseImportScreen(),
      ),
    );
  }

  // 显示删除确认对话框
  void _showDeleteConfirmDialog(BuildContext context, Course course) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除课程"${course.name}"吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteCourse(context, course);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  // 删除课程
  void _deleteCourse(BuildContext context, Course course) async {
    try {
      final provider = Provider.of<ScheduleProvider>(context, listen: false);
      await provider.deleteCourse(course.id!);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已删除课程"${course.name}"')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('删除失败: $e')),
        );
      }
    }
  }
} 