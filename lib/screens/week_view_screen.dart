import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/semester.dart';
import '../providers/schedule_provider.dart';
import '../widgets/week_selector.dart';
import '../widgets/date_header.dart';
import '../widgets/week_schedule_grid.dart';

class WeekViewScreen extends StatefulWidget {
  const WeekViewScreen({super.key});

  @override
  State<WeekViewScreen> createState() => _WeekViewScreenState();
}

class _WeekViewScreenState extends State<WeekViewScreen> {
  // 跟踪水平滑动
  late PageController _pageController;
  
  @override
  void initState() {
    super.initState();
    final scheduleProvider = Provider.of<ScheduleProvider>(context, listen: false);
    // 初始化PageController，默认显示当前周
    _pageController = PageController(
      initialPage: scheduleProvider.selectedWeek - 1,
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
    final currentWeek = scheduleProvider.currentWeek;
    final selectedWeek = scheduleProvider.selectedWeek;
    final semester = scheduleProvider.currentSemester;
    
    if (semester == null) {
      return const Center(
        child: Text('请先添加学期信息'),
      );
    }

    return Column(
      children: [
        // 周次选择器
        WeekSelector(
          currentWeek: currentWeek,
          selectedWeek: selectedWeek,
          totalWeeks: semester.numberOfWeeks,
          onWeekSelected: (week) {
            scheduleProvider.setSelectedWeek(week);
            _pageController.animateToPage(
              week - 1,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          },
        ),
        
        // 周视图表格
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              scheduleProvider.setSelectedWeek(index + 1);
            },
            itemCount: semester.numberOfWeeks,
            itemBuilder: (context, index) {
              final weekNumber = index + 1;
              return _buildWeekSchedule(context, weekNumber, semester);
            },
          ),
        ),
      ],
    );
  }

  // 构建周课表
  Widget _buildWeekSchedule(BuildContext context, int weekNumber, Semester semester) {
    // 获取该周的日期范围
    final weekRange = semester.getWeekRange(weekNumber);
    final weekDates = weekRange.getAllDates();
    
    return Column(
      children: [
        // 显示日期栏
        DateHeader(weekDates: weekDates),
        
        // 课表主体
        Expanded(
          child: WeekScheduleGrid(weekNumber: weekNumber),
        ),
      ],
    );
  }
} 