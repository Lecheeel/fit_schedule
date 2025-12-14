import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/schedule.dart';
import '../providers/schedule_provider.dart';
import '../widgets/week_selector.dart';
import '../widgets/date_header.dart';
import '../widgets/week_schedule_grid.dart';
import 'schedule_management_screen.dart';
import 'course_import_screen.dart';

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
    final currentSchedule = scheduleProvider.currentSchedule;

    // 未添加课表
    if (currentSchedule == null) {
      return _buildEmptyScheduleView(context);
    }

    // 有课表但课程为空
    if (scheduleProvider.courses.isEmpty) {
      return _buildEmptyCourseView(context, currentSchedule);
    }

    return Column(
      children: [
        // 周次选择器（包含课表切换按钮）
        WeekSelector(
          currentWeek: currentWeek,
          selectedWeek: selectedWeek,
          totalWeeks: currentSchedule.numberOfWeeks,
          scheduleName: currentSchedule.name,
          hasMultipleSchedules: scheduleProvider.schedules.length > 1,
          onWeekSelected: (week) {
            scheduleProvider.setSelectedWeek(week);
            _pageController.animateToPage(
              week - 1,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          },
          onScheduleTap: () => _showScheduleSwitcher(context),
        ),

        // 周视图表格
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              scheduleProvider.setSelectedWeek(index + 1);
            },
            itemCount: currentSchedule.numberOfWeeks,
            itemBuilder: (context, index) {
              final weekNumber = index + 1;
              return _buildWeekSchedule(context, weekNumber, currentSchedule);
            },
          ),
        ),
      ],
    );
  }

  // 构建周课表
  Widget _buildWeekSchedule(BuildContext context, int weekNumber, Schedule schedule) {
    // 获取该周的日期范围
    final weekRange = schedule.getWeekRange(weekNumber);
    final weekDates = weekRange.getAllDates();

    return Column(
      children: [
        // 显示日期栏
        DateHeader(weekDates: weekDates),

        // 课表主体
        Expanded(
          child: WeekScheduleGrid(
            weekNumber: weekNumber,
            weekDates: weekDates,
          ),
        ),
      ],
    );
  }

  // 显示课表切换器
  void _showScheduleSwitcher(BuildContext context) {
    final provider = Provider.of<ScheduleProvider>(context, listen: false);
    final schedules = provider.schedules;
    final currentSchedule = provider.currentSchedule;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 拖动条
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // 标题
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    '切换课表',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ScheduleManagementScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.settings, size: 18),
                    label: const Text('管理'),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // 课表列表
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: schedules.length,
                itemBuilder: (context, index) {
                  final schedule = schedules[index];
                  final isActive = schedule.id == currentSchedule?.id;

                  return ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isActive
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.surfaceContainerHighest,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isActive ? Icons.check : Icons.calendar_month,
                        color: isActive
                            ? Colors.white
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      schedule.name,
                      style: TextStyle(
                        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text(schedule.shortDescription),
                    trailing: isActive
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '当前',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          )
                        : null,
                    onTap: isActive
                        ? null
                        : () async {
                            Navigator.pop(context);
                            await provider.switchSchedule(schedule.id!);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('已切换到"${schedule.name}"'),
                                ),
                              );
                            }
                          },
                  );
                },
              ),
            ),

            // 底部安全区域
            SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
          ],
        ),
      ),
    );
  }

  // 构建空课表视图（有课表但无课程时显示）
  Widget _buildEmptyCourseView(BuildContext context, Schedule schedule) {
    return Column(
      children: [
        // 周次选择器（保持显示）
        Consumer<ScheduleProvider>(
          builder: (context, provider, child) {
            return WeekSelector(
              currentWeek: provider.currentWeek,
              selectedWeek: provider.selectedWeek,
              totalWeeks: schedule.numberOfWeeks,
              scheduleName: schedule.name,
              hasMultipleSchedules: provider.schedules.length > 1,
              onWeekSelected: (week) => provider.setSelectedWeek(week),
              onScheduleTap: () => _showScheduleSwitcher(context),
            );
          },
        ),
        
        // 空状态内容
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 图标
                  Icon(
                    Icons.calendar_month_outlined,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 24),

                  // 标题
                  Text(
                    '课表为空',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),

                  // 提示信息
                  Text(
                    '快速添加课程，开始你的学习之旅',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 32),

                  // 教务系统导入卡片
                  _buildAddCourseCard(
                    context,
                    icon: Icons.cloud_download,
                    title: '从教务系统导入',
                    description: '登录教务系统，一键获取完整课表',
                    color: Colors.blue,
                    isPrimary: true,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CourseImportScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // 手动添加课程卡片
                  _buildAddCourseCard(
                    context,
                    icon: Icons.add_circle_outline,
                    title: '手动添加课程',
                    description: '自己动手，逐个添加课程信息',
                    color: Colors.green,
                    isPrimary: false,
                    onTap: () {
                      Navigator.pushNamed(context, '/course_management');
                    },
                  ),
                  const SizedBox(height: 24),

                  // 提示文本
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '推荐使用教务系统导入，更快更准确',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontStyle: FontStyle.italic,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 构建添加课程卡片
  Widget _buildAddCourseCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(isPrimary ? 0.15 : 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(isPrimary ? 0.5 : 0.3),
            width: isPrimary ? 2 : 1.5,
          ),
        ),
        child: Row(
          children: [
            // 图标
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),

            // 文字内容
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: color,
                          fontSize: 16,
                        ),
                      ),
                      if (isPrimary) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '推荐',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: color.withOpacity(0.8),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            // 箭头
            Icon(
              Icons.arrow_forward_ios,
              color: color.withOpacity(0.6),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // 构建空课表视图（未添加课表时显示）
  Widget _buildEmptyScheduleView(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 图标
            Icon(
              Icons.calendar_today_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 24),

            // 标题
            Text(
              '欢迎使用 FITschedule',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),

            // 提示信息
            Text(
              '创建你的第一个课表开始使用',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 32),

            // 智能创建按钮
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _createSmartScheduleAndImport(context),
                icon: const Icon(Icons.auto_awesome),
                label: const Text('智能创建课表'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '自动命名并从教务系统导入课程',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),

            // 手动创建按钮
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ScheduleManagementScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.edit_calendar),
                label: const Text('手动创建课表'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 智能创建课表并跳转导入
  Future<void> _createSmartScheduleAndImport(BuildContext context) async {
    final provider = Provider.of<ScheduleProvider>(context, listen: false);

    try {
      await provider.createSmartSchedule();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('课表已创建，正在跳转到导入页面...')),
        );

        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CourseImportScreen()),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('创建失败: $e')),
        );
      }
    }
  }
}
