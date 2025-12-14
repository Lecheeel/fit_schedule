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
    
    // 未添加学期
    if (semester == null) {
      return _buildEmptySemesterView(context);
    }

    // 有学期但课表为空
    if (scheduleProvider.courses.isEmpty) {
      return _buildEmptyCourseView(context);
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

  // 构建空课表视图（有学期但无课程时显示）
  Widget _buildEmptyCourseView(BuildContext context) {
    return Center(
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
                Navigator.pushNamed(context, '/course_import');
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

  // 构建空学期视图（未添加学期时显示）
  Widget _buildEmptySemesterView(BuildContext context) {
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
              '欢迎使用课程表',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            // 提示信息
            Text(
              '请先添加学期信息以开始使用',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            
            // 智能添加按钮
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _quickAddCurrentSemester(context),
                icon: const Icon(Icons.auto_awesome),
                label: const Text('智能添加本学期'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 12),
            
            // 手动添加按钮
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/semester_management');
                },
                icon: const Icon(Icons.edit_calendar),
                label: const Text('手动添加学期'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // 分隔线
            const Divider(),
            const SizedBox(height: 16),
            
            // 快速模板标题
            Text(
              '或选择快速模板',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            
            // 快速模板按钮
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _buildQuickTemplateChip(
                  context,
                  label: '秋季学期',
                  onTap: () => _addSemesterTemplate(context, isFallSemester: true),
                ),
                _buildQuickTemplateChip(
                  context,
                  label: '春季学期',
                  onTap: () => _addSemesterTemplate(context, isFallSemester: false),
                ),
                _buildQuickTemplateChip(
                  context,
                  label: '16周学期',
                  onTap: () => _addCustomWeeksSemester(context, weeks: 16),
                ),
                _buildQuickTemplateChip(
                  context,
                  label: '18周学期',
                  onTap: () => _addCustomWeeksSemester(context, weeks: 18),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 构建快速模板芯片
  Widget _buildQuickTemplateChip(
    BuildContext context, {
    required String label,
    required VoidCallback onTap,
  }) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      avatar: const Icon(Icons.add, size: 18),
    );
  }

  // 智能添加当前学期
  void _quickAddCurrentSemester(BuildContext context) async {
    final now = DateTime.now();
    final year = now.year;
    final month = now.month;
    
    // 根据月份判断学期
    // 2-7月为春季学期，8月-次年1月为秋季学期
    final isFallSemester = month >= 8 || month <= 1;
    
    String semesterName;
    DateTime startDate;
    int numberOfWeeks = 20;
    
    if (isFallSemester) {
      // 秋季学期（第一学期）
      final academicYear = month >= 8 ? year : year - 1;
      semesterName = '$academicYear-${academicYear + 1}学年第一学期';
      // 秋季学期通常9月初开学，找到9月的第一个周一
      startDate = _findFirstMondayOfMonth(academicYear, 9);
    } else {
      // 春季学期（第二学期）
      semesterName = '${year - 1}-$year学年第二学期';
      // 春季学期通常2月底或3月初开学，找到3月的第一个周一
      startDate = _findFirstMondayOfMonth(year, 3);
    }
    
    // 如果计算出的开学日期在未来，可能是上一学期
    if (startDate.isAfter(now)) {
      if (isFallSemester) {
        // 当前可能是上一年的秋季学期
        semesterName = '${year - 1}-$year学年第一学期';
        startDate = _findFirstMondayOfMonth(year - 1, 9);
      } else {
        // 当前可能是去年的春季学期
        semesterName = '${year - 2}-${year - 1}学年第二学期';
        startDate = _findFirstMondayOfMonth(year - 1, 3);
      }
    }
    
    final semester = Semester(
      name: semesterName,
      startDate: startDate,
      numberOfWeeks: numberOfWeeks,
      isActive: true,
    );
    
    await _saveSemester(context, semester);
  }

  // 添加学期模板
  void _addSemesterTemplate(BuildContext context, {required bool isFallSemester}) async {
    final now = DateTime.now();
    final year = now.year;
    
    String semesterName;
    DateTime startDate;
    
    if (isFallSemester) {
      // 秋季学期
      final academicYear = now.month >= 8 ? year : year - 1;
      semesterName = '$academicYear-${academicYear + 1}学年第一学期';
      startDate = _findFirstMondayOfMonth(academicYear, 9);
    } else {
      // 春季学期
      semesterName = '${year - 1}-$year学年第二学期';
      startDate = _findFirstMondayOfMonth(year, 3);
    }
    
    final semester = Semester(
      name: semesterName,
      startDate: startDate,
      numberOfWeeks: 20,
      isActive: true,
    );
    
    await _saveSemester(context, semester);
  }

  // 添加自定义周数的学期
  void _addCustomWeeksSemester(BuildContext context, {required int weeks}) async {
    final now = DateTime.now();
    final year = now.year;
    final month = now.month;
    
    // 根据月份判断学期
    final isFallSemester = month >= 8 || month <= 1;
    
    String semesterName;
    DateTime startDate;
    
    if (isFallSemester) {
      final academicYear = month >= 8 ? year : year - 1;
      semesterName = '$academicYear-${academicYear + 1}学年第一学期';
      startDate = _findFirstMondayOfMonth(academicYear, 9);
    } else {
      semesterName = '${year - 1}-$year学年第二学期';
      startDate = _findFirstMondayOfMonth(year, 3);
    }
    
    // 如果计算出的开学日期在未来，调整为上一学年
    if (startDate.isAfter(now)) {
      if (isFallSemester) {
        semesterName = '${year - 1}-$year学年第一学期';
        startDate = _findFirstMondayOfMonth(year - 1, 9);
      } else {
        semesterName = '${year - 2}-${year - 1}学年第二学期';
        startDate = _findFirstMondayOfMonth(year - 1, 3);
      }
    }
    
    final semester = Semester(
      name: semesterName,
      startDate: startDate,
      numberOfWeeks: weeks,
      isActive: true,
    );
    
    await _saveSemester(context, semester);
  }

  // 找到指定年月的第一个周一
  DateTime _findFirstMondayOfMonth(int year, int month) {
    var date = DateTime(year, month, 1);
    // weekday: 1-7 对应周一到周日
    while (date.weekday != DateTime.monday) {
      date = date.add(const Duration(days: 1));
    }
    return date;
  }

  // 保存学期
  Future<void> _saveSemester(BuildContext context, Semester semester) async {
    final provider = Provider.of<ScheduleProvider>(context, listen: false);
    
    try {
      await provider.addSemester(semester);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已添加学期"${semester.name}"'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('添加失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
} 