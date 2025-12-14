import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/course.dart';
import '../models/schedule.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../services/widget_service.dart';

class ScheduleProvider extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  final NotificationService _notificationService = NotificationService();

  Schedule? _currentSchedule;
  int _currentWeek = 1;
  int _selectedWeek = 1;
  int _selectedDay = DateTime.now().weekday; // 1-7, 对应周一到周日
  List<Course> _courses = [];
  List<Schedule> _schedules = [];
  bool _showNonCurrentWeekCourses = false;

  // Getters
  Schedule? get currentSchedule => _currentSchedule;
  int get currentWeek => _currentWeek;
  int get selectedWeek => _selectedWeek;
  int get selectedDay => _selectedDay;
  List<Course> get courses => _courses;
  List<Schedule> get schedules => _schedules;
  bool get showNonCurrentWeekCourses => _showNonCurrentWeekCourses;

  // 兼容旧代码的别名
  @Deprecated('请使用 currentSchedule 替代')
  Schedule? get currentSemester => _currentSchedule;

  @Deprecated('请使用 schedules 替代')
  List<Schedule> get semesters => _schedules;

  // 初始化Provider
  Future<void> initialize() async {
    // 初始化通知服务
    await _notificationService.init();

    // 加载设置
    await _loadSettings();

    // 加载课表数据
    await loadSchedules();

    // 加载课程数据
    await loadCourses();

    // 计算当前周次
    _calculateCurrentWeek();

    // 设置当周的通知
    await _scheduleWeekNotifications();
  }

  // 加载设置
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _showNonCurrentWeekCourses = prefs.getBool('showNonCurrentWeekCourses') ?? false;
  }

  // 设置是否显示非本周课程
  Future<void> setShowNonCurrentWeekCourses(bool value) async {
    if (_showNonCurrentWeekCourses == value) return; // 避免不必要的更新

    _showNonCurrentWeekCourses = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showNonCurrentWeekCourses', value);
    notifyListeners();
  }

  // 加载所有课表
  Future<void> loadSchedules() async {
    _schedules = await _databaseService.getAllSchedules();
    _currentSchedule = await _databaseService.getActiveSchedule();

    // 如果没有活动课表但有课表数据，则设置第一个课表为活动课表
    if (_currentSchedule == null && _schedules.isNotEmpty) {
      final firstSchedule = _schedules.first.copyWith(isActive: true);
      await _databaseService.updateSchedule(firstSchedule);
      _currentSchedule = firstSchedule;
    }

    notifyListeners();
  }

  // 兼容旧代码
  @Deprecated('请使用 loadSchedules() 替代')
  Future<void> loadSemesters() async {
    await loadSchedules();
  }

  // 加载所有课程
  Future<List<Course>> loadCourses() async {
    _courses = await _databaseService.getAllCourses();
    notifyListeners();
    return _courses;
  }

  // 计算当前是学期的第几周
  void _calculateCurrentWeek() {
    if (_currentSchedule != null) {
      final now = DateTime.now();
      _currentWeek = _currentSchedule!.getWeekNumber(now);

      // 如果当前日期不在学期内，默认显示第1周
      if (_currentWeek <= 0 || _currentWeek > _currentSchedule!.numberOfWeeks) {
        _currentWeek = 1;
      }

      // 默认选中当前周
      _selectedWeek = _currentWeek;
    }
  }

  // 设置选中的周次
  void setSelectedWeek(int week) {
    if (_currentSchedule != null && week >= 1 && week <= _currentSchedule!.numberOfWeeks) {
      _selectedWeek = week;
      notifyListeners();
    }
  }

  // 设置选中的星期
  void setSelectedDay(int day) {
    if (day >= 1 && day <= 7) {
      _selectedDay = day;
      notifyListeners();
    }
  }

  // 获取当前选中周次的日期范围
  WeekRange? getSelectedWeekRange() {
    if (_currentSchedule == null) return null;
    try {
      return _currentSchedule!.getWeekRange(_selectedWeek);
    } catch (e) {
      return null;
    }
  }

  // 获取当前实际周次的日期范围（用于日视图）
  WeekRange? getCurrentWeekRange() {
    if (_currentSchedule == null) return null;
    try {
      return _currentSchedule!.getWeekRange(_currentWeek);
    } catch (e) {
      return null;
    }
  }

  // 重置周视图到当前周
  void resetToCurrentWeek() {
    if (_currentSchedule != null) {
      _selectedWeek = _currentWeek;
      notifyListeners();
    }
  }

  // 重置日期选择到今天
  void resetToToday() {
    _selectedDay = DateTime.now().weekday;
    notifyListeners();
  }

  // 获取特定周次和星期的课程
  Future<List<Course>> getCoursesForWeekAndDay(int week, int day) async {
    return await _databaseService.getCoursesByWeekAndDay(week, day);
  }

  // 获取当前选中周次和星期的课程
  Future<List<Course>> getSelectedDayCourses() async {
    return await getCoursesForWeekAndDay(_selectedWeek, _selectedDay);
  }

  // 获取某一周的所有课程
  Future<List<Course>> getCoursesForWeek(int week) async {
    return await _databaseService.getCoursesByWeek(week);
  }

  // 添加课程
  Future<void> addCourse(Course course) async {
    // 确保课程关联到当前课表
    final courseWithSchedule = course.scheduleId == null && _currentSchedule != null
        ? course.copyWith(scheduleId: _currentSchedule!.id)
        : course;

    final id = await _databaseService.insertCourse(courseWithSchedule);
    final newCourse = courseWithSchedule.copyWith(id: id);
    _courses.add(newCourse);

    // 如果添加的课程在当前周次上课，则设置通知
    if (course.isActiveInWeek(_selectedWeek)) {
      try {
        await _scheduleWeekNotifications();
      } catch (e) {
        debugPrint('设置通知失败: $e');
        // 通知设置失败不影响课程添加
      }
    }

    // 更新桌面组件
    try {
      await WidgetService.notifyDataChanged();
    } catch (e) {
      debugPrint('更新桌面组件失败: $e');
    }

    notifyListeners();
  }

  // 批量添加课程（用于导入，不设置通知）
  Future<void> addCoursesBatch(List<Course> courses) async {
    for (final course in courses) {
      // 确保课程关联到当前课表
      final courseWithSchedule = course.scheduleId == null && _currentSchedule != null
          ? course.copyWith(scheduleId: _currentSchedule!.id)
          : course;

      final id = await _databaseService.insertCourse(courseWithSchedule);
      final newCourse = courseWithSchedule.copyWith(id: id);
      _courses.add(newCourse);
    }

    // 批量添加完成后，一次性设置通知（如果失败也不影响导入）
    try {
      await _scheduleWeekNotifications();
    } catch (e) {
      debugPrint('批量导入后设置通知失败: $e');
      // 通知设置失败不影响课程导入
    }

    // 更新桌面组件
    try {
      await WidgetService.notifyDataChanged();
    } catch (e) {
      debugPrint('更新桌面组件失败: $e');
    }

    notifyListeners();
  }

  // 清空当前课表的所有课程
  Future<void> clearAllCourses() async {
    if (_currentSchedule != null) {
      await _databaseService.deleteAllCoursesBySchedule(_currentSchedule!.id!);
    } else {
      await _databaseService.deleteAllCourses();
    }
    _courses.clear();

    // 取消所有通知
    try {
      await _notificationService.cancelAllNotifications();
    } catch (e) {
      debugPrint('取消通知失败: $e');
    }

    // 更新桌面组件
    try {
      await WidgetService.notifyDataChanged();
    } catch (e) {
      debugPrint('更新桌面组件失败: $e');
    }

    notifyListeners();
  }

  // 覆盖导入课程（先清空再导入）
  Future<void> overwriteCoursesBatch(List<Course> courses) async {
    // 先清空所有课程
    await clearAllCourses();

    // 再批量添加新课程
    await addCoursesBatch(courses);
  }

  // 更新当前课表的开始日期（用于导入时同步学期信息）
  Future<void> updateCurrentScheduleStartDate(DateTime startDate) async {
    if (_currentSchedule == null) return;

    // 计算开始日期所在周的周一
    final int daysUntilMonday = (startDate.weekday - 1) % 7;
    final DateTime mondayOfWeek = startDate.subtract(Duration(days: daysUntilMonday));
    final normalizedStartDate = DateTime(mondayOfWeek.year, mondayOfWeek.month, mondayOfWeek.day);

    // 创建更新后的课表
    final updatedSchedule = _currentSchedule!.copyWith(
      startDate: normalizedStartDate,
    );

    // 更新数据库
    await _databaseService.updateSchedule(updatedSchedule);

    // 更新本地状态
    _currentSchedule = updatedSchedule;
    final index = _schedules.indexWhere((s) => s.id == updatedSchedule.id);
    if (index != -1) {
      _schedules[index] = updatedSchedule;
    }

    // 重新计算当前周次
    _calculateCurrentWeek();

    debugPrint('已更新课表开始日期为: $normalizedStartDate，当前周次: $_currentWeek');
    notifyListeners();
  }

  // 检测重复课程
  // 返回与现有课程重复的导入课程列表
  List<Course> findDuplicateCourses(List<Course> importCourses) {
    final List<Course> duplicates = [];

    for (final importCourse in importCourses) {
      for (final existingCourse in _courses) {
        if (_isCourseDuplicate(importCourse, existingCourse)) {
          duplicates.add(importCourse);
          break; // 找到一个重复就够了
        }
      }
    }

    return duplicates;
  }

  // 判断两个课程是否重复
  // 重复条件：课程名称相同 且 星期几相同 且 节次有重叠 且 周次有重叠
  bool _isCourseDuplicate(Course course1, Course course2) {
    // 课程名称相同（忽略前后空格）
    if (course1.name.trim() != course2.name.trim()) return false;

    // 星期几相同
    if (course1.dayOfWeek != course2.dayOfWeek) return false;

    // 节次有重叠
    final hasClassHourOverlap = course1.classHours.any(
      (hour) => course2.classHours.contains(hour),
    );
    if (!hasClassHourOverlap) return false;

    // 周次有重叠
    final hasWeekOverlap = course1.weeks.any(
      (week) => course2.weeks.contains(week),
    );
    if (!hasWeekOverlap) return false;

    return true;
  }

  // 过滤掉重复的课程，只返回不重复的课程
  List<Course> filterNonDuplicateCourses(List<Course> importCourses) {
    return importCourses.where((importCourse) {
      return !_courses.any((existingCourse) => 
        _isCourseDuplicate(importCourse, existingCourse)
      );
    }).toList();
  }

  // 更新课程
  Future<void> updateCourse(Course course) async {
    await _databaseService.updateCourse(course);

    // 更新本地课程列表
    final index = _courses.indexWhere((c) => c.id == course.id);
    if (index != -1) {
      _courses[index] = course;
    }

    // 重新设置通知
    await _notificationService.cancelAllNotifications();
    await _scheduleWeekNotifications();

    // 更新桌面组件
    try {
      await WidgetService.notifyDataChanged();
    } catch (e) {
      debugPrint('更新桌面组件失败: $e');
    }

    notifyListeners();
  }

  // 删除课程
  Future<void> deleteCourse(int id) async {
    await _databaseService.deleteCourse(id);

    // 从本地列表中移除
    _courses.removeWhere((course) => course.id == id);

    // 重新设置通知
    await _notificationService.cancelAllNotifications();
    await _scheduleWeekNotifications();

    // 更新桌面组件
    try {
      await WidgetService.notifyDataChanged();
    } catch (e) {
      debugPrint('更新桌面组件失败: $e');
    }

    notifyListeners();
  }

  // =============== 课表管理方法 ===============

  // 添加课表
  Future<Schedule> addSchedule(Schedule schedule) async {
    final id = await _databaseService.insertSchedule(schedule);
    final newSchedule = schedule.copyWith(id: id);

    _schedules.insert(0, newSchedule); // 新课表添加到列表开头

    // 如果新课表是活动课表，更新当前课表引用
    if (newSchedule.isActive) {
      _currentSchedule = newSchedule;
      _courses.clear(); // 清空当前课程列表（新课表没有课程）
      _calculateCurrentWeek();
      await _scheduleWeekNotifications();
    }

    notifyListeners();
    return newSchedule;
  }

  // 智能创建课表并返回（用于导入流程）
  Future<Schedule> createSmartSchedule() async {
    final smartSchedule = Schedule.smart(isActive: true);
    return await addSchedule(smartSchedule);
  }

  // 更新课表
  Future<void> updateSchedule(Schedule schedule) async {
    await _databaseService.updateSchedule(schedule);

    // 更新本地课表列表
    final index = _schedules.indexWhere((s) => s.id == schedule.id);
    if (index != -1) {
      _schedules[index] = schedule;
    }

    // 如果更新的是当前活动课表，刷新当前课表引用
    if (schedule.isActive) {
      _currentSchedule = schedule;
      _calculateCurrentWeek();
      await _scheduleWeekNotifications();
    } else if (_currentSchedule?.id == schedule.id) {
      // 如果原来是活动课表，现在不是了，需要找到新的活动课表
      await loadSchedules();
      await loadCourses();
    }

    notifyListeners();
  }

  // 删除课表
  Future<void> deleteSchedule(int id) async {
    await _databaseService.deleteSchedule(id);

    // 检查是否删除了当前课表
    bool needToRefreshCurrentSchedule = _currentSchedule?.id == id;

    // 从本地列表中移除
    _schedules.removeWhere((schedule) => schedule.id == id);

    // 如果删除了当前课表，需要重新加载课表数据
    if (needToRefreshCurrentSchedule) {
      await loadSchedules();
      await loadCourses();
      _calculateCurrentWeek();
    }

    notifyListeners();
  }

  // 切换当前课表
  Future<void> switchSchedule(int scheduleId) async {
    if (_currentSchedule?.id == scheduleId) return; // 已经是当前课表

    await _databaseService.setActiveSchedule(scheduleId);

    // 更新本地状态
    for (int i = 0; i < _schedules.length; i++) {
      _schedules[i] = _schedules[i].copyWith(
        isActive: _schedules[i].id == scheduleId,
      );
      if (_schedules[i].id == scheduleId) {
        _currentSchedule = _schedules[i];
      }
    }

    // 重新加载课程
    await loadCourses();
    _calculateCurrentWeek();
    await _scheduleWeekNotifications();

    // 更新桌面组件
    try {
      await WidgetService.notifyDataChanged();
    } catch (e) {
      debugPrint('更新桌面组件失败: $e');
    }

    notifyListeners();
  }

  // 获取课表的课程数量
  Future<int> getScheduleCourseCount(int scheduleId) async {
    return await _databaseService.getScheduleCourseCount(scheduleId);
  }

  // =============== 兼容旧代码的方法 ===============

  @Deprecated('请使用 addSchedule() 替代')
  Future<void> addSemester(dynamic semester) async {
    if (semester is Schedule) {
      await addSchedule(semester);
    }
  }

  @Deprecated('请使用 updateSchedule() 替代')
  Future<void> updateSemester(dynamic semester) async {
    if (semester is Schedule) {
      await updateSchedule(semester);
    }
  }

  @Deprecated('请使用 deleteSchedule() 替代')
  Future<void> deleteSemester(int id) async {
    await deleteSchedule(id);
  }

  // 为当前实际周次设置课程通知（使用 _currentWeek 而非 _selectedWeek）
  Future<void> _scheduleWeekNotifications() async {
    if (_currentSchedule == null) return;

    // 使用当前实际周次（_currentWeek）而非选中周次（_selectedWeek）
    // 这确保通知总是针对当前周的课程，而不是用户浏览的周次
    final targetWeek = _currentWeek;
    
    // 验证周次有效性
    if (targetWeek < 1 || targetWeek > _currentSchedule!.numberOfWeeks) {
      debugPrint('当前周次 $targetWeek 不在有效范围内，跳过通知设置');
      return;
    }

    try {
      // 获取当前周的日期范围
      final weekRange = _currentSchedule!.getWeekRange(targetWeek);

      // 获取当前周的所有课程
      final weekCourses = await getCoursesForWeek(targetWeek);

      // 设置通知
      await _notificationService.scheduleWeekCoursesNotifications(
        courses: weekCourses,
        weekStartDate: weekRange.start,
      );
      
      debugPrint('已为第 $targetWeek 周设置 ${weekCourses.length} 门课程的通知');
    } catch (e) {
      debugPrint('设置周通知失败: $e');
    }
  }
}
