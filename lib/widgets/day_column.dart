import 'package:flutter/material.dart';
import '../models/course.dart';
import '../utils/time_utils.dart';
import '../utils/app_theme.dart';
import 'course_card.dart';

class DayColumn extends StatelessWidget {
  final List<Course> courses;
  final List<Course> allCourses;
  final int currentWeek;
  final bool showNonCurrentWeekCourses;
  final Function(Course) onCourseTap;
  final Function(List<Course>) onConflictTap;

  const DayColumn({
    super.key,
    required this.courses,
    required this.allCourses,
    required this.currentWeek,
    required this.showNonCurrentWeekCourses,
    required this.onCourseTap,
    required this.onConflictTap,
  });

  @override
  Widget build(BuildContext context) {
    // 使用LayoutBuilder来响应容器大小变化
    return LayoutBuilder(
      builder: (context, constraints) {
        // 计算单个课时格子的高度（基于当前可用高度而非屏幕高度）
        // 这样在小窗口模式下也能正确适应
        final double availableHeight = constraints.maxHeight;
        
        // 总共有11节课+2个休息时间，因此总共13行
        final double classHourHeight = (availableHeight / 13).clamp(25.0, 60.0);
        // 休息时间的高度可以比课时格子矮一些
        final double restHeight = (classHourHeight * 0.6).clamp(15.0, 30.0);
        
        // 创建一个表示每个课时是否被占用的映射
        Map<int, List<Course>> courseMap = {};
        
        // 初始化每个课时的课程列表
        for (int i = 1; i <= 11; i++) {
          courseMap[i] = [];
        }
        
        // 先添加本周课程
        for (final course in courses) {
          for (final hour in course.classHours) {
            courseMap[hour]!.add(course);
          }
        }
        
        // 如果需要显示非本周课程，再添加其他周次的课程
        if (showNonCurrentWeekCourses && allCourses.isNotEmpty) {
          for (final course in allCourses) {
            // 只添加不在本周上课的课程
            if (!course.isActiveInWeek(currentWeek)) {
              for (final hour in course.classHours) {
                // 避免重复添加
                if (!courseMap[hour]!.any((c) => c.id == course.id)) {
                  courseMap[hour]!.add(course);
                }
              }
            }
          }
        }
        
        // 处理课程显示，防止重复显示同一课程
        Set<String> displayedCourseIds = {};
        
        // 构建课程卡片列表
        final List<Widget> courseWidgets = [];
        
        // 遍历每个时间段，计算课程的位置
        for (int classHour = 1; classHour <= 11; classHour++) {
          final coursesForHour = courseMap[classHour] ?? [];
          
          for (final course in coursesForHour) {
            // 确保每个课程只显示一次
            if (course.classHours.first == classHour && !displayedCourseIds.contains(course.id.toString())) {
              displayedCourseIds.add(course.id.toString());
              
              // 计算课程的位置和高度
              final int lastClassHour = course.classHours.last;
              final int firstClassHour = course.classHours.first;
              final int spanHours = lastClassHour - firstClassHour + 1;
              
              // 计算课程卡片的顶部位置，需要考虑午休和晚休
              double top = 0;
              if (firstClassHour <= 4) {
                // 第1-4节课
                top = (firstClassHour - 1) * classHourHeight;
              } else if (firstClassHour <= 8) {
                // 第5-8节课，需要加上午休的高度
                top = 4 * classHourHeight + restHeight + (firstClassHour - 5) * classHourHeight;
              } else {
                // 第9-11节课，需要加上午休和晚休的高度
                top = 4 * classHourHeight + restHeight + 4 * classHourHeight + restHeight + (firstClassHour - 9) * classHourHeight;
              }
              
              // 计算课程卡片的高度，只计算课时的高度，不包括休息时间
              double height = spanHours * classHourHeight;
              
              // 检查是否有冲突
              final hasConflict = coursesForHour.length > 1;
              
              // 添加课程卡片
              courseWidgets.add(
                Positioned(
                  top: top,
                  left: 0,
                  right: 0,
                  height: height,
                  child: RepaintBoundary(
                    child: Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4.0),
                        child: CourseCard(
                          course: course,
                          height: height - 4.0,
                          currentWeek: currentWeek,
                          showNonCurrentWeekCourses: showNonCurrentWeekCourses,
                          hasConflictingCourses: hasConflict,
                          onTap: () => onCourseTap(course),
                          onConflictTap: hasConflict 
                              ? () => onConflictTap(coursesForHour)
                              : null,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }
          }
        }
        
        // 创建网格背景单元格
        List<Widget> gridCells = [];
        
        // 添加1-4节课的背景单元格
        for (int i = 1; i <= 4; i++) {
          gridCells.add(
            Container(
              height: classHourHeight,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: AppTheme.gridLineColor,
                    width: 0.5,
                  ),
                  right: BorderSide(
                    color: AppTheme.gridLineColor,
                    width: 0.5,
                  ),
                ),
              ),
            )
          );
        }
        
        // 添加午休的背景单元格
        gridCells.add(
          Container(
            height: restHeight,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
              border: Border(
                bottom: BorderSide(
                  color: AppTheme.gridLineColor,
                  width: 0.5,
                ),
                right: BorderSide(
                  color: AppTheme.gridLineColor,
                  width: 0.5,
                ),
              ),
            ),
          )
        );
        
        // 添加5-8节课的背景单元格
        for (int i = 5; i <= 8; i++) {
          gridCells.add(
            Container(
              height: classHourHeight,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: AppTheme.gridLineColor,
                    width: 0.5,
                  ),
                  right: BorderSide(
                    color: AppTheme.gridLineColor,
                    width: 0.5,
                  ),
                ),
              ),
            )
          );
        }
        
        // 添加晚休的背景单元格
        gridCells.add(
          Container(
            height: restHeight,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
              border: Border(
                bottom: BorderSide(
                  color: AppTheme.gridLineColor,
                  width: 0.5,
                ),
                right: BorderSide(
                  color: AppTheme.gridLineColor,
                  width: 0.5,
                ),
              ),
            ),
          )
        );
        
        // 添加9-11节课的背景单元格
        for (int i = 9; i <= 11; i++) {
          gridCells.add(
            Container(
              height: classHourHeight,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: AppTheme.gridLineColor,
                    width: 0.5,
                  ),
                  right: BorderSide(
                    color: AppTheme.gridLineColor,
                    width: 0.5,
                  ),
                ),
              ),
            )
          );
        }
        
        // 创建每个课时格子的背景
        return Stack(
          fit: StackFit.expand, // 确保Stack填满整个可用空间
          children: [
            // 首先创建背景网格
            Column(
              children: gridCells,
            ),
            
            // 然后添加课程卡片
            ...courseWidgets,
          ],
        );
      }
    );
  }
} 