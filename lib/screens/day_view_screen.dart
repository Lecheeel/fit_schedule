import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/course.dart';
import '../providers/schedule_provider.dart';
import '../utils/time_utils.dart';
import '../utils/app_theme.dart';

class DayViewScreen extends StatefulWidget {
  const DayViewScreen({super.key});

  @override
  State<DayViewScreen> createState() => _DayViewScreenState();
}

class _DayViewScreenState extends State<DayViewScreen> {
  late PageController _pageController;
  // 日视图独立管理选中的日期，不使用provider中的selectedDay
  late int _selectedDayOfWeek;

  @override
  void initState() {
    super.initState();
    // 默认显示今天
    _selectedDayOfWeek = DateTime.now().weekday;
    // 初始化PageController，默认显示今天
    _pageController = PageController(
      initialPage: _selectedDayOfWeek - 1,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheduleProvider = Provider.of<ScheduleProvider>(context);
    // 使用当前实际周（currentWeek）而不是选中周（selectedWeek）
    final currentWeek = scheduleProvider.currentWeek;
    final weekRange = scheduleProvider.getCurrentWeekRange();
    
    if (weekRange == null) {
      return const Center(
        child: Text('请先添加课表'),
      );
    }

    final weekDates = weekRange.getAllDates();

    return Column(
      children: [
        // 日期选择器
        _buildDateSelector(weekDates, currentWeek),
        
        // 日视图
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _selectedDayOfWeek = index + 1;
              });
            },
            itemCount: 7,
            itemBuilder: (context, index) {
              final dayOfWeek = index + 1; // 1-7, 对应周一到周日
              return _buildDaySchedule(context, currentWeek, dayOfWeek);
            },
          ),
        ),
      ],
    );
  }

  // 构建日期选择器
  Widget _buildDateSelector(List<DateTime> weekDates, int currentWeek) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 7,
        itemBuilder: (context, index) {
          final dayOfWeek = index + 1; // 1-7, 对应周一到周日
          final date = weekDates[index];
          final isSelected = _selectedDayOfWeek == dayOfWeek;
          final isToday = _isToday(date);
          
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDayOfWeek = dayOfWeek;
              });
              _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            child: Container(
              width: 60,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isSelected 
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                    : isToday 
                        ? Theme.of(context).colorScheme.secondary.withOpacity(0.1)
                        : null,
                borderRadius: BorderRadius.circular(8),
                border: isSelected
                    ? Border.all(color: Theme.of(context).colorScheme.primary)
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    TimeUtils.getDayOfWeekName(dayOfWeek),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isSelected 
                          ? Theme.of(context).colorScheme.primary
                          : isToday 
                              ? Theme.of(context).colorScheme.secondary
                              : null,
                    ),
                  ),
                  Text(
                    '${date.month}/${date.day}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected 
                          ? Theme.of(context).colorScheme.primary
                          : isToday 
                              ? Theme.of(context).colorScheme.secondary
                              : null,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // 构建日程表
  Widget _buildDaySchedule(BuildContext context, int weekNumber, int dayOfWeek) {
    final scheduleProvider = Provider.of<ScheduleProvider>(context);
    
    return FutureBuilder<List<Course>>(
      future: scheduleProvider.getCoursesForWeekAndDay(weekNumber, dayOfWeek),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(child: Text('加载课程失败: ${snapshot.error}'));
        }
        
        final courses = snapshot.data ?? [];
        
        // 如果显示非本周课程，获取所有该天的课程
        List<Course> allDayCourses = [];
        if (scheduleProvider.showNonCurrentWeekCourses) {
          // 直接使用provider中已加载的课程列表，不触发新的加载
          allDayCourses = scheduleProvider.courses
              .where((course) => course.dayOfWeek == dayOfWeek)
              .toList();
        }
        
        // 合并本周课程和非本周课程（如果需要显示的话）
        List<Course> displayCourses = List.from(courses);
        
        if (scheduleProvider.showNonCurrentWeekCourses) {
          // 添加非本周课程（去重）
          for (final course in allDayCourses) {
            if (!course.isActiveInWeek(weekNumber) && 
                !displayCourses.any((c) => c.id == course.id)) {
              displayCourses.add(course);
            }
          }
        }
        
        if (displayCourses.isEmpty) {
          return const Center(child: Text('今天没有课程安排'));
        }
        
        // 按照课时排序
        displayCourses.sort((a, b) => a.classHours.first.compareTo(b.classHours.first));
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: displayCourses.length,
          itemBuilder: (context, index) {
            final course = displayCourses[index];
            return _buildCourseTile(course, weekNumber);
          },
        );
      },
    );
  }

  // 构建课程卡片
  Widget _buildCourseTile(Course course, int currentWeek) {
    final startTime = TimeUtils.getClassStartTime(course.classHours.first);
    final endTime = TimeUtils.getClassEndTime(course.classHours.last);
    final timeRange = '${TimeUtils.formatTimeOfDay(startTime)}-${TimeUtils.formatTimeOfDay(endTime)}';
    final isCurrentWeekCourse = course.isActiveInWeek(currentWeek);
    
    // 使用更深的课程颜色以确保文字清晰
    final courseColor = isCurrentWeekCourse 
        ? AppTheme.getCourseTextColor(course.color) // 使用深色文字颜色作为主色
        : Colors.grey[600]!; // 非本周课程使用更深的灰色
    
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context, 
          '/course-form',
          arguments: course,
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 左侧时间列
              SizedBox(
                width: 60,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      TimeUtils.getClassHoursRangeString(course.classHours),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: courseColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      TimeUtils.formatTimeOfDay(startTime),
                      style: TextStyle(
                        fontSize: 10,
                        color: isCurrentWeekCourse 
                            ? Theme.of(context).colorScheme.onSurfaceVariant
                            : Colors.grey[500],
                      ),
                    ),
                    Text(
                      TimeUtils.formatTimeOfDay(endTime),
                      style: TextStyle(
                        fontSize: 10,
                        color: isCurrentWeekCourse 
                            ? Theme.of(context).colorScheme.onSurfaceVariant
                            : Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              
              // 主内容区域
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 标题行
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            course.name,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isCurrentWeekCourse ? Colors.black : Colors.grey[500],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!isCurrentWeekCourse)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(10),
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
                    const SizedBox(height: 8),
                    
                    // 详细信息
                    _buildInfoRow(
                      Icons.access_time, 
                      timeRange, 
                      isCurrentWeekCourse ? null : Colors.grey[500],
                    ),
                    if (course.location != null && course.location!.isNotEmpty)
                      _buildInfoRow(
                        Icons.location_on, 
                        course.location!, 
                        isCurrentWeekCourse ? null : Colors.grey[500],
                      ),
                    if (course.teacher != null && course.teacher!.isNotEmpty)
                      _buildInfoRow(
                        Icons.person, 
                        course.teacher!, 
                        isCurrentWeekCourse ? null : Colors.grey[500],
                      ),
                    _buildInfoRow(
                      Icons.calendar_today, 
                      '周次: ${TimeUtils.getWeeksString(course.weeks)}', 
                      isCurrentWeekCourse ? null : Colors.grey[500],
                    ),
                    if (course.note != null && course.note!.isNotEmpty)
                      _buildInfoRow(
                        Icons.note, 
                        course.note!, 
                        isCurrentWeekCourse ? null : Colors.grey[500],
                      ),
                  ],
                ),
              ),
              
              // 右侧节次标签
              Container(
                constraints: const BoxConstraints(maxWidth: 80),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isCurrentWeekCourse 
                      ? course.color.withOpacity(0.2) // 保持背景色使用原始颜色
                      : Colors.grey[300]!.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  TimeUtils.getClassHoursString(course.classHours),
                  style: TextStyle(
                    fontSize: 12,
                    color: courseColor,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 构建信息行
  Widget _buildInfoRow(IconData icon, String text, [Color? color]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon, 
            size: 16, 
            color: color ?? Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: color ?? Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // 判断日期是否为今天
  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }
}
