import 'package:flutter/material.dart';
import '../models/course.dart';
import '../utils/app_theme.dart';
import '../utils/time_utils.dart';

class CourseCard extends StatelessWidget {
  final Course course;
  final double height;
  final bool isDetailMode;
  final VoidCallback? onTap;
  final int? currentWeek;
  final bool showNonCurrentWeekCourses;
  final bool hasConflictingCourses;
  final VoidCallback? onConflictTap;

  const CourseCard({
    super.key,
    required this.course,
    this.height = 60,
    this.isDetailMode = false,
    this.onTap,
    this.currentWeek,
    this.showNonCurrentWeekCourses = false,
    this.hasConflictingCourses = false,
    this.onConflictTap,
  });

  bool get isCurrentWeekCourse => 
      currentWeek == null ? true : course.weeks.contains(currentWeek);

  @override
  Widget build(BuildContext context) {
    // 获取卡片和文字颜色
    final Color cardColor = isCurrentWeekCourse 
        ? course.color 
        : Colors.grey[300]!;
    
    // 使用新的同色系深色文字颜色
    final textColor = isCurrentWeekCourse 
        ? AppTheme.getCourseTextColor(course.color)
        : Colors.grey[500]!;
    
    // 如果不显示非本周课程且不是本周课程，则返回空容器
    if (!showNonCurrentWeekCourses && !isCurrentWeekCourse && !hasConflictingCourses) {
      return const SizedBox.shrink();
    }
    
    // 根据卡片高度动态计算字体大小
    final double titleFontSize = _calculateFontSize(height, 12, 0.85);
    final double subtitleFontSize = _calculateFontSize(height, 12, 0.7);
    
    // 计算内容显示的最大行数（基于高度），限制为6行
    final int maxLines = _calculateMaxLines(height).clamp(1, 6);
    
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            height: height,
            width: double.infinity,
            padding: EdgeInsets.all(_calculatePadding(height)),
            decoration: isCurrentWeekCourse 
                ? AppTheme.getCourseCardDecoration(course.color)
                : AppTheme.getCourseCardDecoration(cardColor, opacity: 0.8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              children: [
                // 课程名称 - 最多3行
                Flexible(
                  child: Text(
                    course.name,
                    style: TextStyle(
                      color: textColor,
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.bold,
                      height: 1.0, // 进一步减小行高，从1.1改为1.0
                    ),
                    maxLines: 3, // 固定为最多3行
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                
                // 如果高度足够且剩余行数充足，显示更多信息
                if (maxLines > 3) ...[
                  // 教师名称 - 优先显示
                  if (course.teacher != null && course.teacher!.isNotEmpty && maxLines > 3)
                    Padding(
                      padding: EdgeInsets.only(top: height * 0.003), // 进一步减小间距，从0.005改为0.003
                      child: Text(
                        course.teacher!,
                        style: TextStyle(
                          color: textColor.withOpacity(0.8),
                          fontSize: subtitleFontSize,
                          height: 0.95, // 减小行高，从1.0改为0.95
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  
                  // 教室位置
                  if (course.location != null && course.location!.isNotEmpty && maxLines > 4)
                    Padding(
                      padding: EdgeInsets.only(top: height * 0.003), // 进一步减小间距
                      child: Text(
                        course.location!,
                        style: TextStyle(
                          color: textColor.withOpacity(0.8),
                          fontSize: subtitleFontSize,
                          height: 0.95, // 减小行高
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  
                  // 课程时间 - 仅在详情模式显示
                  if (isDetailMode && maxLines > 5)
                    Padding(
                      padding: EdgeInsets.only(top: height * 0.003), // 进一步减小间距
                      child: Text(
                        TimeUtils.getClassesTimeString(course.classHours),
                        style: TextStyle(
                          color: textColor.withOpacity(0.6),
                          fontSize: subtitleFontSize * 0.9,
                          height: 0.95, // 减小行高
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ],
            ),
          ),
          
          // 添加冲突课程标识
          if (hasConflictingCourses)
            Positioned(
              top: 0,
              right: 0,
              child: GestureDetector(
                onTap: onConflictTap,
                child: Container(
                  padding: EdgeInsets.all(_calculatePadding(height) / 2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(_calculatePadding(height) * 3),
                  ),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.white,
                    size: _calculateIconSize(height),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  // 根据卡片高度计算字体大小
  double _calculateFontSize(double height, double baseSize, double factor) {
    final double calculatedSize = baseSize * (height / 100) * factor;
    return calculatedSize.clamp(8.5, baseSize * 1.2);
  }
  
  // 根据卡片高度计算内边距 - 减小内边距
  double _calculatePadding(double height) {
    return (height * 0.035).clamp(1.0, 5.0); // 进一步减小内边距，从0.04改为0.035，范围从1.5-6.0改为1.0-5.0
  }
  
  // 根据卡片高度计算图标大小
  double _calculateIconSize(double height) {
    return (height * 0.12).clamp(12.0, 24.0);
  }
  
  // 根据卡片高度计算最大行数
  int _calculateMaxLines(double height) {
    // 每16个高度单位提供1行，进一步提高密度，从18改为16
    return (height / 10).floor().clamp(1, 6);
  }
} 