import 'package:flutter/material.dart';
import '../models/course.dart';
import '../utils/time_utils.dart';

class TimeSlotCoursesSheet extends StatelessWidget {
  final List<Course> courses;
  final int dayOfWeek;
  final List<int> classHours;
  final int currentWeek;
  final Function(Course) onCourseTap;

  const TimeSlotCoursesSheet({
    super.key,
    required this.courses,
    required this.dayOfWeek,
    required this.classHours,
    required this.currentWeek,
    required this.onCourseTap,
  });

  static void show(
    BuildContext context, {
    required List<Course> courses,
    required int dayOfWeek,
    required List<int> classHours,
    required int currentWeek,
    required Function(Course) onCourseTap,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TimeSlotCoursesSheet(
        courses: courses,
        dayOfWeek: dayOfWeek,
        classHours: classHours,
        currentWeek: currentWeek,
        onCourseTap: onCourseTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final weekDayNames = ['', '周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    final timeRange = _getTimeRange();
    
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 拖拽指示器
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // 标题
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  '${weekDayNames[dayOfWeek]} 第${TimeUtils.getClassHoursRangeString(classHours)}节',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  timeRange,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // 课程列表
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: courses.length,
              itemBuilder: (context, index) {
                final course = courses[index];
                return _buildCourseItem(context, course);
              },
            ),
          ),
        ],
      ),
    );
  }

  // 构建单个课程项
  Widget _buildCourseItem(BuildContext context, Course course) {
    final isCurrentWeek = course.weeks.contains(currentWeek);
    final weeksText = _formatWeeks(course.weeks);
    
    return InkWell(
      onTap: () {
        Navigator.of(context).pop();
        onCourseTap(course);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // 课程颜色指示器
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: isCurrentWeek ? course.color : Colors.grey[300]!,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            const SizedBox(width: 12),
            
            // 课程信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          course.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isCurrentWeek ? Colors.black : Colors.grey[500],
                          ),
                        ),
                      ),
                      if (!isCurrentWeek)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '非本周',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[500],
                            ),
                          ),
                        ),
                    ],
                  ),
                  
                  const SizedBox(height: 4),
                  
                  if (course.teacher != null && course.teacher!.isNotEmpty)
                    Text(
                      '教师: ${course.teacher!}',
                      style: TextStyle(
                        fontSize: 14,
                        color: isCurrentWeek ? Colors.grey[600] : Colors.grey[500],
                      ),
                    ),
                  
                  if (course.location != null && course.location!.isNotEmpty)
                    Text(
                      '地点: ${course.location!}',
                      style: TextStyle(
                        fontSize: 14,
                        color: isCurrentWeek ? Colors.grey[600] : Colors.grey[500],
                      ),
                    ),
                  
                  const SizedBox(height: 4),
                  
                  Text(
                    '上课周次: $weeksText',
                    style: TextStyle(
                      fontSize: 12,
                      color: isCurrentWeek ? Colors.grey[500] : Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
            
            // 编辑图标
            Icon(
              Icons.edit,
              color: isCurrentWeek ? Colors.grey[400] : Colors.grey[300],
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // 获取时间范围字符串
  String _getTimeRange() {
    if (classHours.isEmpty) return '';
    
    final startTime = TimeUtils.getClassStartTime(classHours.first);
    final endTime = TimeUtils.getClassEndTime(classHours.last);
    
    return '${TimeUtils.formatTimeOfDay(startTime)} - ${TimeUtils.formatTimeOfDay(endTime)}';
  }

  // 格式化周次显示
  String _formatWeeks(List<int> weeks) {
    if (weeks.isEmpty) return '无';
    
    weeks.sort();
    List<String> ranges = [];
    int start = weeks[0];
    int end = weeks[0];
    
    for (int i = 1; i < weeks.length; i++) {
      if (weeks[i] == end + 1) {
        end = weeks[i];
      } else {
        if (start == end) {
          ranges.add('第$start周');
        } else {
          ranges.add('第$start-$end周');
        }
        start = weeks[i];
        end = weeks[i];
      }
    }
    
    if (start == end) {
      ranges.add('第$start周');
    } else {
      ranges.add('第$start-$end周');
    }
    
    return ranges.join(', ');
  }
} 