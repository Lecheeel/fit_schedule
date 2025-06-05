import 'package:flutter/material.dart';
import '../../models/course.dart';
import 'triangle_painter.dart';
import 'schedule_grid_utils.dart';
import '../../utils/app_theme.dart';

/// 课程卡片组件
class ScheduleCourseCard extends StatelessWidget {
  final Course course;
  final List<Course> timeSlotCourses;
  final int dayOfWeek;
  final int weekNumber;
  final double timeColumnWidth;
  final double dayColumnWidth;
  final double classHourHeight;
  final double restHeight;
  final VoidCallback onTap;

  const ScheduleCourseCard({
    super.key,
    required this.course,
    required this.timeSlotCourses,
    required this.dayOfWeek,
    required this.weekNumber,
    required this.timeColumnWidth,
    required this.dayColumnWidth,
    required this.classHourHeight,
    required this.restHeight,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // 检查课程是否跨越休息时间
    if (ScheduleGridUtils.crossesBreakTime(course.classHours)) {
      // 如果跨越休息时间，使用分段卡片
      return _buildSegmentedCourseCards(context);
    } else {
      // 否则使用原有的单一卡片
      return _buildSingleCourseCard(context);
    }
  }

  /// 构建分段课程卡片
  Widget _buildSegmentedCourseCards(BuildContext context) {
    final segments = ScheduleGridUtils.splitCourseAcrossBreaks(course.classHours);
    
    return Stack(
      children: segments.asMap().entries.map((entry) {
        final index = entry.key;
        final segment = entry.value;
        final isLastSegment = index == segments.length - 1;
        
        return ScheduleCourseSegmentCard(
          course: course,
          segment: segment,
          segmentIndex: index,
          isLastSegment: isLastSegment,
          timeSlotCourses: timeSlotCourses,
          dayOfWeek: dayOfWeek,
          weekNumber: weekNumber,
          timeColumnWidth: timeColumnWidth,
          dayColumnWidth: dayColumnWidth,
          classHourHeight: classHourHeight,
          restHeight: restHeight,
          onTap: onTap,
        );
      }).toList(),
    );
  }

  /// 构建单一课程卡片（原有逻辑）
  Widget _buildSingleCourseCard(BuildContext context) {
    // 计算卡片位置和大小
    final startClassHour = course.classHours.first;
    final cardHeight = course.classHours.length * classHourHeight;
    
    // 计算Y位置（考虑午休和晚休）
    final topPosition = ScheduleGridUtils.calculateTopPosition(
      startClassHour,
      classHourHeight,
      restHeight
    );
    
    // 计算X位置
    final leftPosition = timeColumnWidth + (dayOfWeek - 1) * dayColumnWidth;
    
    // 判断是否为当前周课程
    final isCurrentWeekCourse = course.weeks.contains(weekNumber);
    
    // 根据是否为当前周课程设置颜色 
    final backgroundColor = isCurrentWeekCourse 
        ? course.color 
        : Colors.grey[300]!;
    final textColor = isCurrentWeekCourse 
        ? AppTheme.getCourseTextColor(course.color)
        : Colors.grey[500]!; 
    
    // 构建课程内容
    final displayText = ScheduleGridUtils.generateCourseDisplayText(course);
    
    return Positioned(
      left: leftPosition + 1,
      top: topPosition + 1,
      width: dayColumnWidth - 2,
      height: cardHeight - 2,
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          children: [
            // 主卡片
            Container(
              width: double.infinity,
              height: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1), // 进一步减少上下间距
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Center(
                child: _buildCourseText(displayText, textColor),
              ),
            ),
            
            // 多课程三角形标志 - 改为右下角
            if (timeSlotCourses.length > 1)
              Positioned(
                bottom: 0,
                right: 0,
                child: CustomPaint(
                  size: const Size(24, 24),
                  painter: TrianglePainter(baseColor: backgroundColor),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseText(String text, Color color) {
    // 解析课程名称和地点
    final atIndex = text.indexOf(' @');
    if (atIndex != -1) {
      // 包含地点信息
      final courseName = text.substring(0, atIndex);
      final location = text.substring(atIndex + 2); // 跳过 " @"
      
      return RichText(
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
        maxLines: course.classHours.length * 2,
        text: TextSpan(
          children: [
            TextSpan(
              text: courseName,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextSpan(
              text: '\n@$location',
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.normal, // 地点不加粗
              ),
            ),
          ],
        ),
      );
    } else {
      // 只有课程名称
      return Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
        maxLines: course.classHours.length * 2,
      );
    }
  }
}

/// 分段课程卡片组件
class ScheduleCourseSegmentCard extends StatelessWidget {
  final Course course;
  final List<int> segment;
  final int segmentIndex;
  final bool isLastSegment;
  final List<Course> timeSlotCourses;
  final int dayOfWeek;
  final int weekNumber;
  final double timeColumnWidth;
  final double dayColumnWidth;
  final double classHourHeight;
  final double restHeight;
  final VoidCallback onTap;

  const ScheduleCourseSegmentCard({
    super.key,
    required this.course,
    required this.segment,
    required this.segmentIndex,
    required this.isLastSegment,
    required this.timeSlotCourses,
    required this.dayOfWeek,
    required this.weekNumber,
    required this.timeColumnWidth,
    required this.dayColumnWidth,
    required this.classHourHeight,
    required this.restHeight,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // 计算段的位置和大小
    final startClassHour = segment.first;
    final cardHeight = segment.length * classHourHeight;
    
    // 计算Y位置
    final topPosition = ScheduleGridUtils.calculateTopPosition(
      startClassHour,
      classHourHeight,
      restHeight
    );
    
    // 计算X位置
    final leftPosition = timeColumnWidth + (dayOfWeek - 1) * dayColumnWidth;
    
    // 判断是否为当前周课程
    final isCurrentWeekCourse = course.weeks.contains(weekNumber);
    
    // 根据是否为当前周课程设置颜色 
    final backgroundColor = isCurrentWeekCourse 
        ? course.color 
        : Colors.grey[300]!;
    final textColor = isCurrentWeekCourse 
        ? AppTheme.getCourseTextColor(course.color)
        : Colors.grey[500]!; 
    
    // 生成显示文本（为分段显示优化）
    final displayText = ScheduleGridUtils.generateSegmentCourseDisplayText(course, segment, segmentIndex);
    
    return Positioned(
      left: leftPosition + 1,
      top: topPosition + 1,
      width: dayColumnWidth - 2,
      height: cardHeight - 2,
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          children: [
            // 主卡片
            Container(
              width: double.infinity,
              height: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1), // 进一步减少上下间距
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Center(
                child: _buildSegmentCourseText(displayText, textColor, segment),
              ),
            ),
            
            // 多课程三角形标志 - 只在最后一段显示
            if (timeSlotCourses.length > 1 && isLastSegment)
              Positioned(
                bottom: 0,
                right: 0,
                child: CustomPaint(
                  size: const Size(24, 24),
                  painter: TrianglePainter(baseColor: backgroundColor),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentCourseText(String text, Color color, List<int> segment) {
    // 解析课程名称和地点
    final atIndex = text.indexOf(' @');
    if (atIndex != -1) {
      // 包含地点信息
      final courseName = text.substring(0, atIndex);
      final location = text.substring(atIndex + 2); // 跳过 " @"
      
      return RichText(
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
        maxLines: segment.length * 2,
        text: TextSpan(
          children: [
            TextSpan(
              text: courseName,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextSpan(
              text: ' @$location',
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.normal, // 地点不加粗
              ),
            ),
          ],
        ),
      );
    } else {
      // 只有课程名称
      return Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
        maxLines: segment.length * 2,
      );
    }
  }
}