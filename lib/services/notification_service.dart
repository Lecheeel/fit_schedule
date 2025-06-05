import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'dart:math';

import '../models/course.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  static final FlutterLocalNotificationsPlugin
  _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  // 单例模式
  factory NotificationService() => _instance;

  NotificationService._internal();

  // 初始化通知服务
  Future<void> init() async {
    // 初始化时区数据
    tz_data.initializeTimeZones();

    // 设置Android通知渠道
    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // 初始化通知插件
    const InitializationSettings initializationSettings =
        InitializationSettings(android: androidInitializationSettings);

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse:
          (NotificationResponse notificationResponse) {
            // 处理通知点击事件
          },
    );
  }

  // 检查通知权限
  Future<bool> checkPermission() async {
    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    if (androidPlugin == null) return false;

    final bool? granted = await androidPlugin.requestNotificationsPermission();
    return granted ?? false;
  }

  // 取消所有通知
  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  // 为课程设置提醒通知
  Future<void> scheduleCourseNotification({
    required Course course,
    required DateTime date,
    int minutesBefore = 10, // 提前多少分钟提醒
  }) async {
    // 确保已获得通知权限
    final hasPermission = await checkPermission();
    if (!hasPermission) return;

    // 获取课程时间范围
    final timeRange = course.getTimeRange();

    // 创建上课时间的DateTime对象
    final startTime = DateTime(
      date.year,
      date.month,
      date.day,
      timeRange.start.hour,
      timeRange.start.minute,
    );

    // 计算提醒时间（提前minutesBefore分钟）
    final notificationTime = startTime.subtract(
      Duration(minutes: minutesBefore),
    );

    // 如果提醒时间已经过去，则不设置通知
    if (notificationTime.isBefore(DateTime.now())) return;

    // 创建通知详情
    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'course_reminder',
          '课程提醒',
          channelDescription: '提醒即将开始的课程',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    // 生成唯一的通知ID
    final int notificationId = _generateNotificationId(course.id ?? 0, date);

    // 生成通知内容
    final String title = '课程提醒: ${course.name}';
    final String body =
        '${timeRange.toString()} @ ${course.location ?? '未知地点'} ${course.teacher != null ? ' - ${course.teacher}' : ''}';

    // 安排通知
    await _flutterLocalNotificationsPlugin.zonedSchedule(
      notificationId,
      title,
      body,
      tz.TZDateTime.from(notificationTime, tz.local),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  // 为一周的课程设置通知
  Future<void> scheduleWeekCoursesNotifications({
    required List<Course> courses,
    required DateTime weekStartDate,
    int minutesBefore = 10,
  }) async {
    for (final course in courses) {
      // 计算课程日期（周一=1，周日=7）
      final courseDate = weekStartDate.add(
        Duration(days: course.dayOfWeek - 1),
      );
      await scheduleCourseNotification(
        course: course,
        date: courseDate,
        minutesBefore: minutesBefore,
      );
    }
  }

  // 生成唯一的通知ID
  int _generateNotificationId(int courseId, DateTime date) {
    // 使用课程ID和日期创建唯一ID
    // 格式: CCCYYMMDDHHMM (课程ID + 年(2位) + 月 + 日 + 小时 + 分钟)
    String yearStr = (date.year % 100).toString().padLeft(2, '0');
    String monthStr = date.month.toString().padLeft(2, '0');
    String dayStr = date.day.toString().padLeft(2, '0');
    String hourStr = date.hour.toString().padLeft(2, '0');
    String minuteStr = date.minute.toString().padLeft(2, '0');

    String idStr =
        courseId.toString().padLeft(3, '0') +
        yearStr +
        monthStr +
        dayStr +
        hourStr +
        minuteStr;

    // 确保ID不超过int的范围
    return min(int.parse(idStr), 2147483647);
  }
}
