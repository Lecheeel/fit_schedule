import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/course.dart';
import '../models/semester.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../services/widget_service.dart';

class ScheduleProvider extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  final NotificationService _notificationService = NotificationService();
  
  Semester? _currentSemester;
  int _currentWeek = 1;
  int _selectedWeek = 1;
  int _selectedDay = DateTime.now().weekday; // 1-7, 对应周一到周日
  List<Course> _courses = [];
  List<Semester> _semesters = [];
  bool _showNonCurrentWeekCourses = false;
  
  // Getters
  Semester? get currentSemester => _currentSemester;
  int get currentWeek => _currentWeek;
  int get selectedWeek => _selectedWeek;
  int get selectedDay => _selectedDay;
  List<Course> get courses => _courses;
  List<Semester> get semesters => _semesters;
  bool get showNonCurrentWeekCourses => _showNonCurrentWeekCourses;
  
  // 初始化Provider
  Future<void> initialize() async {
    // 初始化通知服务
    await _notificationService.init();
    
    // 加载设置
    await _loadSettings();
    
    // 加载学期数据
    await loadSemesters();
    
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
  
  // 加载所有学期
  Future<void> loadSemesters() async {
    _semesters = await _databaseService.getAllSemesters();
    _currentSemester = await _databaseService.getActiveSemester();
    
    // 如果没有活动学期但有学期数据，则设置第一个学期为活动学期
    if (_currentSemester == null && _semesters.isNotEmpty) {
      final firstSemester = _semesters.first.copyWith(isActive: true);
      await _databaseService.updateSemester(firstSemester);
      _currentSemester = firstSemester;
    }
    
    notifyListeners();
  }
  
  // 加载所有课程
  Future<List<Course>> loadCourses() async {
    _courses = await _databaseService.getAllCourses();
    notifyListeners();
    return _courses;
  }
  
  // 计算当前是学期的第几周
  void _calculateCurrentWeek() {
    if (_currentSemester != null) {
      final now = DateTime.now();
      _currentWeek = _currentSemester!.getWeekNumber(now);
      
      // 如果当前日期不在学期内，默认显示第1周
      if (_currentWeek <= 0 || _currentWeek > _currentSemester!.numberOfWeeks) {
        _currentWeek = 1;
      }
      
      // 默认选中当前周
      _selectedWeek = _currentWeek;
    }
  }
  
  // 设置选中的周次
  void setSelectedWeek(int week) {
    if (_currentSemester != null && week >= 1 && week <= _currentSemester!.numberOfWeeks) {
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
    if (_currentSemester == null) return null;
    try {
      return _currentSemester!.getWeekRange(_selectedWeek);
    } catch (e) {
      return null;
    }
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
    final id = await _databaseService.insertCourse(course);
    final newCourse = course.copyWith(id: id);
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
      final id = await _databaseService.insertCourse(course);
      final newCourse = course.copyWith(id: id);
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
  
  // 清空所有课程
  Future<void> clearAllCourses() async {
    await _databaseService.deleteAllCourses();
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
  
  // 添加学期
  Future<void> addSemester(Semester semester) async {
    final id = await _databaseService.insertSemester(semester);
    final newSemester = semester.copyWith(id: id);
    
    _semesters.add(newSemester);
    
    // 如果新学期是活动学期，更新当前学期引用
    if (newSemester.isActive) {
      _currentSemester = newSemester;
      _calculateCurrentWeek();
      await _scheduleWeekNotifications();
    }
    
    notifyListeners();
  }
  
  // 更新学期
  Future<void> updateSemester(Semester semester) async {
    await _databaseService.updateSemester(semester);
    
    // 更新本地学期列表
    final index = _semesters.indexWhere((s) => s.id == semester.id);
    if (index != -1) {
      _semesters[index] = semester;
    }
    
    // 如果更新的是当前活动学期，刷新当前学期引用
    if (semester.isActive) {
      _currentSemester = semester;
      _calculateCurrentWeek();
      await _scheduleWeekNotifications();
    } else if (_currentSemester?.id == semester.id) {
      // 如果原来是活动学期，现在不是了，需要找到新的活动学期
      await loadSemesters();
    }
    
    notifyListeners();
  }
  
  // 删除学期
  Future<void> deleteSemester(int id) async {
    await _databaseService.deleteSemester(id);
    
    // 检查是否删除了当前学期
    bool needToRefreshCurrentSemester = _currentSemester?.id == id;
    
    // 从本地列表中移除
    _semesters.removeWhere((semester) => semester.id == id);
    
    // 如果删除了当前学期，需要重新加载学期数据
    if (needToRefreshCurrentSemester) {
      await loadSemesters();
    }
    
    notifyListeners();
  }
  
  // 为当前选中的周设置课程通知
  Future<void> _scheduleWeekNotifications() async {
    if (_currentSemester == null) return;
    
    // 获取当前周的日期范围
    final weekRange = _currentSemester!.getWeekRange(_selectedWeek);
    
    // 获取当前周的所有课程
    final weekCourses = await getCoursesForWeek(_selectedWeek);
    
    // 设置通知
    await _notificationService.scheduleWeekCoursesNotifications(
      courses: weekCourses,
      weekStartDate: weekRange.start,
    );
  }
} 