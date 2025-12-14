import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:typed_data';
import 'dart:convert';

import '../models/course.dart';
import '../main.dart';
import 'database_service.dart';

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
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // 创建高优先级通知渠道
    await _createNotificationChannels();
  }

  // 处理通知点击事件
  void _onNotificationTapped(NotificationResponse notificationResponse) {
    final payload = notificationResponse.payload;
    if (payload == null) return;

    try {
      // 解析 payload（JSON 格式）
      final data = jsonDecode(payload) as Map<String, dynamic>;
      final courseId = data['courseId'] as int?;
      
      if (courseId == null) return;

      // 使用全局导航 key 导航到课程详情
      final context = navigatorKey.currentContext;
      if (context == null) return;

      // 导航到课程详情
      _navigateToCourseDetail(context, courseId);
    } catch (e) {
      debugPrint('处理通知点击失败: $e');
    }
  }

  // 导航到课程详情
  Future<void> _navigateToCourseDetail(BuildContext context, int courseId) async {
    try {
      // 从数据库加载课程
      final databaseService = DatabaseService();
      final course = await databaseService.getCourseById(courseId);
      
      if (course == null) {
        debugPrint('未找到课程: $courseId');
        return;
      }

      // 导航到课程表单页面（查看模式）
      if (context.mounted) {
        Navigator.of(context).pushNamed(
          '/course-form',
          arguments: course,
        );
      }
    } catch (e) {
      debugPrint('导航到课程详情失败: $e');
    }
  }

  // 创建通知渠道
  Future<void> _createNotificationChannels() async {
    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin == null) return;

    // 删除所有旧版本的渠道
    final oldChannels = [
      'course_reminder',
      'course_reminder_v2',
      'course_reminder_v3',
      'test_notification',
      'test_notification_v2',
      'test_notification_v3',
    ];

    for (var channelId in oldChannels) {
      try {
        await androidPlugin.deleteNotificationChannel(channelId);
      } catch (e) {
        // 忽略删除错误
      }
    }

    // 只创建一个统一的高优先级通知渠道（针对小米手机优化）
    const AndroidNotificationChannel notificationChannel =
        AndroidNotificationChannel(
      'fitschedule_notifications', // 统一的渠道ID
      'FIT课表通知',
      description: '课程提醒和应用通知，会在屏幕顶部弹出',
      importance: Importance.max, // 最高重要性 - 必须弹出
      playSound: true,
      enableVibration: true,
      showBadge: true,
      enableLights: true, // 启用LED灯
      ledColor: Color.fromARGB(255, 33, 150, 243), // 蓝色LED
    );

    // 注册渠道
    await androidPlugin.createNotificationChannel(notificationChannel);
  }

  // 重置所有通知设置（用于调试）
  Future<void> resetNotificationChannels() async {
    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin == null) return;

    // 删除所有可能存在的渠道
    final allChannels = [
      'course_reminder',
      'course_reminder_v2',
      'course_reminder_v3',
      'test_notification',
      'test_notification_v2',
      'test_notification_v3',
      'fitschedule_notifications',
    ];

    for (var channelId in allChannels) {
      try {
        await androidPlugin.deleteNotificationChannel(channelId);
      } catch (e) {
        // 忽略错误
      }
    }

    // 重新创建渠道
    await _createNotificationChannels();
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

  // 立即发送测试通知
  Future<void> sendTestNotification() async {
    // 确保已获得通知权限
    final hasPermission = await checkPermission();
    if (!hasPermission) {
      throw Exception('未获得通知权限');
    }

    // 创建自定义振动模式 - 长振动更容易察觉
    final Int64List vibrationPattern = Int64List.fromList([
      0, // 延迟
      500, // 振动500ms
      200, // 停止200ms
      500, // 再振动500ms
    ]);

    // 创建通知详情 - 配置为弹出通知，专门优化小米手机
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'fitschedule_notifications', // 使用统一渠道ID
      'FIT课表通知',
      channelDescription: '课程提醒和应用通知，会在屏幕顶部弹出',
      importance: Importance.max, // 最高重要性
      priority: Priority.max, // 最高优先级
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
      vibrationPattern: vibrationPattern, // 自定义振动模式
      enableLights: true, // 启用LED灯
      ledColor: const Color.fromARGB(255, 255, 0, 0), // 红色LED
      ledOnMs: 1000,
      ledOffMs: 500,
      ticker: '测试通知',
      styleInformation: const BigTextStyleInformation(
        '如果你看到这条通知弹出，说明通知功能正常工作！\n\n小米手机用户提示：如果看不到，请检查应用设置中的"悬浮通知"和"锁屏通知"选项。',
        htmlFormatBigText: true,
        contentTitle: '🔔 测试通知',
        htmlFormatContentTitle: true,
      ),
      category: AndroidNotificationCategory.message,
      showWhen: true,
      when: DateTime.now().millisecondsSinceEpoch,
      // 全屏通知意图 - 对小米手机很重要
      fullScreenIntent: true,
      // 确保在锁屏时也显示
      visibility: NotificationVisibility.public,
      // 自动取消
      autoCancel: true,
      // 持续显示
      ongoing: false,
      // 显示时间戳
      showProgress: false,
      // 最大优先级
      channelShowBadge: true,
    );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    // 发送即时通知
    await _flutterLocalNotificationsPlugin.show(
      999999, // 固定的测试通知ID
      '🔔 测试通知',
      '如果你看到这条通知，说明通知功能正常工作！',
      notificationDetails,
    );
  }

  // 发送带样式的测试通知（展示各种样式）
  Future<void> sendStyledNotification({required String style}) async {
    // 确保已获得通知权限
    final hasPermission = await checkPermission();
    if (!hasPermission) {
      throw Exception('未获得通知权限');
    }

    // 创建自定义振动模式
    final Int64List vibrationPattern = Int64List.fromList([
      0, 300, 100, 300, 100, 300,
    ]);

    AndroidNotificationDetails? androidDetails;
    String title = '';
    String body = '';
    int notificationId = 0;

    switch (style) {
      case 'inbox':
        // 收件箱样式 - 显示多行信息
        notificationId = 888888;
        title = '📬 今日课程安排';
        body = '您今天有5门课程';
        androidDetails = AndroidNotificationDetails(
          'fitschedule_notifications',
          'FIT课表通知',
          channelDescription: '课程提醒和应用通知',
          importance: Importance.max,
          priority: Priority.max,
          icon: '@mipmap/ic_launcher',
          playSound: true,
          enableVibration: true,
          vibrationPattern: vibrationPattern,
          enableLights: true,
          ledColor: const Color.fromARGB(255, 76, 175, 80), // 绿色LED
          ledOnMs: 1000,
          ledOffMs: 500,
          styleInformation: const InboxStyleInformation(
            [
              '📚 08:00 - 高等数学 @ 教学楼A101',
              '💻 10:00 - 数据结构 @ 实验楼B202',
              '🔬 14:00 - 物理实验 @ 理科楼C303',
              '🎨 16:00 - 艺术欣赏 @ 艺术楼D404',
              '⚽ 19:00 - 体育课 @ 体育馆',
            ],
            htmlFormatLines: true,
            contentTitle: '📬 今日课程安排',
            htmlFormatContentTitle: true,
            summaryText: '共5门课程',
            htmlFormatSummaryText: true,
          ),
          fullScreenIntent: true,
          visibility: NotificationVisibility.public,
          autoCancel: true,
          channelShowBadge: true,
        );
        break;

      case 'messaging':
        // 消息样式 - 模拟对话
        notificationId = 777777;
        title = '💬 课程提醒助手';
        body = '您有新的课程消息';
        androidDetails = AndroidNotificationDetails(
          'fitschedule_notifications',
          'FIT课表通知',
          channelDescription: '课程提醒和应用通知',
          importance: Importance.max,
          priority: Priority.max,
          icon: '@mipmap/ic_launcher',
          playSound: true,
          enableVibration: true,
          vibrationPattern: vibrationPattern,
          enableLights: true,
          ledColor: const Color.fromARGB(255, 33, 150, 243), // 蓝色LED
          ledOnMs: 1000,
          ledOffMs: 500,
          styleInformation: MessagingStyleInformation(
            const Person(
              name: '我',
              key: 'me',
              important: true,
            ),
            groupConversation: false,
            conversationTitle: '课程提醒助手',
            htmlFormatContent: true,
            htmlFormatTitle: true,
            messages: [
              Message(
                '你好！提醒您10分钟后有一节高等数学课',
                DateTime.now().subtract(const Duration(minutes: 2)),
                const Person(name: '课程助手', key: 'assistant'),
              ),
              Message(
                '课程地点在哪里？',
                DateTime.now().subtract(const Duration(minutes: 1)),
                const Person(name: '我', key: 'me'),
              ),
              Message(
                '📍 教学楼A101，由王老师授课',
                DateTime.now(),
                const Person(name: '课程助手', key: 'assistant'),
              ),
            ],
          ),
          fullScreenIntent: true,
          visibility: NotificationVisibility.public,
          autoCancel: true,
          channelShowBadge: true,
        );
        break;

      case 'bigtext':
        // 大文本样式 - 显示长文本
        notificationId = 666666;
        title = '📖 课程详情';
        body = '点击查看完整课程信息';
        androidDetails = AndroidNotificationDetails(
          'fitschedule_notifications',
          'FIT课表通知',
          channelDescription: '课程提醒和应用通知',
          importance: Importance.max,
          priority: Priority.max,
          icon: '@mipmap/ic_launcher',
          playSound: true,
          enableVibration: true,
          vibrationPattern: vibrationPattern,
          enableLights: true,
          ledColor: const Color.fromARGB(255, 255, 152, 0), // 橙色LED
          ledOnMs: 1000,
          ledOffMs: 500,
          styleInformation: const BigTextStyleInformation(
            '📚 课程名称：高等数学\n'
            '👨‍🏫 授课老师：王教授\n'
            '📍 上课地点：教学楼A101\n'
            '⏰ 上课时间：周一 8:00-9:40\n'
            '📅 上课周次：第1-16周\n'
            '📝 课程备注：请携带教材和计算器\n\n'
            '温馨提示：请提前10分钟到达教室，不要迟到哦！',
            htmlFormatBigText: true,
            contentTitle: '📖 高等数学课程详情',
            htmlFormatContentTitle: true,
            summaryText: 'FIT课表',
            htmlFormatSummaryText: true,
          ),
          fullScreenIntent: true,
          visibility: NotificationVisibility.public,
          autoCancel: true,
          channelShowBadge: true,
        );
        break;

      case 'progress':
        // 进度条样式 - 显示进度
        notificationId = 555555;
        title = '⏳ 学期进度';
        body = '当前学期已完成';
        androidDetails = const AndroidNotificationDetails(
          'fitschedule_notifications',
          'FIT课表通知',
          channelDescription: '课程提醒和应用通知',
          importance: Importance.max,
          priority: Priority.max,
          icon: '@mipmap/ic_launcher',
          playSound: true,
          enableVibration: true,
          enableLights: true,
          ledColor: Color.fromARGB(255, 156, 39, 176), // 紫色LED
          ledOnMs: 1000,
          ledOffMs: 500,
          showProgress: true,
          maxProgress: 100,
          progress: 65,
          indeterminate: false,
          fullScreenIntent: true,
          visibility: NotificationVisibility.public,
          autoCancel: true,
          channelShowBadge: true,
        );
        break;

      case 'bigpicture':
        // 大图片样式 - 显示带图片的通知
        notificationId = 444444;
        title = '🖼️ 教室导航';
        body = '点击查看教学楼位置';
        androidDetails = AndroidNotificationDetails(
          'fitschedule_notifications',
          'FIT课表通知',
          channelDescription: '课程提醒和应用通知',
          importance: Importance.max,
          priority: Priority.max,
          icon: '@mipmap/ic_launcher',
          largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          playSound: true,
          enableVibration: true,
          vibrationPattern: vibrationPattern,
          enableLights: true,
          ledColor: const Color.fromARGB(255, 0, 188, 212), // 青色LED
          ledOnMs: 1000,
          ledOffMs: 500,
          styleInformation: const BigPictureStyleInformation(
            DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
            largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
            contentTitle: '🖼️ 高等数学教室位置',
            htmlFormatContentTitle: true,
            summaryText: '教学楼A101 - 点击查看详情',
            htmlFormatSummaryText: true,
          ),
          fullScreenIntent: true,
          visibility: NotificationVisibility.public,
          autoCancel: true,
          channelShowBadge: true,
        );
        break;

      case 'media':
        // 媒体样式 - 带操作按钮（模拟课程快捷操作）
        notificationId = 333333;
        title = '🎵 课程快捷操作';
        body = '快速管理您的课程';
        androidDetails = AndroidNotificationDetails(
          'fitschedule_notifications',
          'FIT课表通知',
          channelDescription: '课程提醒和应用通知',
          importance: Importance.max,
          priority: Priority.max,
          icon: '@mipmap/ic_launcher',
          largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          playSound: true,
          enableVibration: true,
          vibrationPattern: vibrationPattern,
          enableLights: true,
          ledColor: const Color.fromARGB(255, 233, 30, 99), // 粉色LED
          ledOnMs: 1000,
          ledOffMs: 500,
          styleInformation: const MediaStyleInformation(
            htmlFormatContent: true,
            htmlFormatTitle: true,
          ),
          fullScreenIntent: true,
          visibility: NotificationVisibility.public,
          autoCancel: true,
          channelShowBadge: true,
          // 注意：actions需要在实际使用时定义具体的意图
          actions: const <AndroidNotificationAction>[
            AndroidNotificationAction(
              'view_schedule',
              '📅 查看课表',
              icon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
              showsUserInterface: true,
            ),
            AndroidNotificationAction(
              'add_course',
              '➕ 添加课程',
              icon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
              showsUserInterface: true,
            ),
            AndroidNotificationAction(
              'navigate',
              '🧭 导航',
              icon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
              showsUserInterface: true,
            ),
          ],
        );
        break;

      case 'custom_layout':
        // 自定义布局样式 - 使用多行信息和操作按钮组合
        notificationId = 222222;
        title = '🎨 课程智能助手🎨 课程智能助手🎨 课程智能助手🎨 课程智能助手';
        body = '为您整理今日课程为您整理今日课程为您整理今日课程为您整理今日课程';
        androidDetails = AndroidNotificationDetails(
          'fitschedule_notifications',
          'FIT课表通知',
          channelDescription: '课程提醒和应用通知',
          importance: Importance.max,
          priority: Priority.max,
          icon: '@mipmap/ic_launcher',
          largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          playSound: true,
          enableVibration: true,
          vibrationPattern: vibrationPattern,
          enableLights: true,
          ledColor: const Color.fromARGB(255, 255, 87, 34), // 深橙色LED
          ledOnMs: 1000,
          ledOffMs: 500,
          styleInformation: const InboxStyleInformation(
            [
              '📚 即将开始：高等数学',
              '⏰ 时间：10分钟后 (8:00-9:40)',
              '📍 地点：教学楼A101',
              '👨‍🏫 教师：王教授',
              '💡 提示：请携带教材和计算器',
            ],
            htmlFormatLines: true,
            contentTitle: '🎨 下节课提醒',
            htmlFormatContentTitle: true,
            summaryText: '点击查看详情或快速操作',
            htmlFormatSummaryText: true,
          ),
          fullScreenIntent: true,
          visibility: NotificationVisibility.public,
          autoCancel: true,
          channelShowBadge: true,
          actions: const <AndroidNotificationAction>[
            AndroidNotificationAction(
              'view_detail',
              '📖 查看详情',
              icon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
              showsUserInterface: true,
            ),
            AndroidNotificationAction(
              'start_navigation',
              '🗺️ 开始导航',
              icon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
              showsUserInterface: true,
            ),
            AndroidNotificationAction(
              'dismiss',
              '✓ 知道了',
              icon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
              cancelNotification: true,
            ),
          ],
        );
        break;

      default:
        throw Exception('未知的样式类型');
    }

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    // 发送通知
    await _flutterLocalNotificationsPlugin.show(
      notificationId,
      title,
      body,
      notificationDetails,
    );
  }

  // 获取随机emoji（让通知更生动）
  String _getRandomEmoji() {
    final emojis = ['📚', '📖', '✏️', '🎓', '📝', '💡', '⏰', '🔔'];
    return emojis[Random().nextInt(emojis.length)];
  }

  // 发送测试课程提醒（2秒后触发）
  // course 参数为可选，如果为 null 则使用默认测试数据
  Future<void> sendTestCourseReminder({Course? course}) async {
    // 确保已获得通知权限
    final hasPermission = await checkPermission();
    if (!hasPermission) {
      throw Exception('未获得通知权限');
    }

    // 如果没有传入课程，创建一个模拟课程对象用于测试
    final testCourse = course ?? Course(
      id: 999,
      name: '高等数学',
      teacher: '王教授',
      location: '教学楼A101',
      color: Colors.blue,
      dayOfWeek: DateTime.now().weekday,
      classHours: [1, 2],
      weeks: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
      note: '请携带教材和计算器',
    );
    
    // 生成通知标题（带随机emoji）
    final String emoji = _getRandomEmoji();
    final String title = '$emoji ${testCourse.name}';

    // 获取课程时间范围（用于更真实的显示）
    final timeRange = testCourse.getTimeRange();
    final weekDays = ['', '周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    final weekDayStr = weekDays[testCourse.dayOfWeek];

    // 构建信息行（4行）
    final List<String> infoLines = [
      '⏰ 时间：$weekDayStr ${timeRange.toString()}',
      '📍 地点：${testCourse.location ?? "未指定地点"}',
      '👨‍🏫 教师：${testCourse.teacher ?? "未指定教师"}',
      if (testCourse.note != null && testCourse.note!.isNotEmpty)
        '💡 提示：${testCourse.note}'
      else
        '💡 请准时到达教室',
    ];

    // 创建自定义振动模式
    final Int64List vibrationPattern = Int64List.fromList([
      0, 300, 100, 300, 100, 300,
    ]);

    // 副标题：还有2分钟开始上课（测试模式）+ 上课地点
    final String summaryText = '还有2分钟开始上课 • ${testCourse.location ?? "未指定地点"}';

    // 创建通知详情
    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'fitschedule_notifications',
          'FIT课表通知',
          channelDescription: '课程提醒和应用通知',
          importance: Importance.max,
          priority: Priority.max,
          icon: '@mipmap/ic_launcher',
          largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          playSound: true,
          enableVibration: true,
          vibrationPattern: vibrationPattern,
          enableLights: true,
          ledColor: const Color.fromARGB(255, 255, 87, 34), // 深橙色LED
          ledOnMs: 1000,
          ledOffMs: 500,
          styleInformation: InboxStyleInformation(
            infoLines,
            htmlFormatLines: true,
            contentTitle: '$emoji ${testCourse.name}',
            htmlFormatContentTitle: true,
            summaryText: summaryText,
            htmlFormatSummaryText: true,
          ),
          fullScreenIntent: true,
          visibility: NotificationVisibility.public,
          autoCancel: true,
          channelShowBadge: true,
          actions: const <AndroidNotificationAction>[
            AndroidNotificationAction(
              'view_detail',
              '📖 查看详情',
              icon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
              showsUserInterface: true,
            ),
            AndroidNotificationAction(
              'dismiss',
              '✓ 知道了',
              icon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
              cancelNotification: true,
            ),
          ],
        );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    // 创建 payload（包含课程ID，用于点击时导航）
    final payload = jsonEncode({
      'courseId': testCourse.id ?? 999,
      'courseName': testCourse.name,
    });

    // 使用延迟发送，等待2秒后再触发（异步方式，不阻塞）
    Future.delayed(const Duration(seconds: 2), () async {
      // 立即发送通知（与智能助手样式相同的方式）
      await _flutterLocalNotificationsPlugin.show(
        888888, // 固定的测试课程提醒ID
        title,
        summaryText, // 使用副标题作为body
        notificationDetails,
        payload: payload, // 添加 payload
      );
    });
    
    // 立即返回，不等待延迟完成
  }

  // 为课程设置提醒通知
  Future<void> scheduleCourseNotification({
    required Course course,
    required DateTime date,
    int minutesBefore = 5, // 提前多少分钟提醒（默认5分钟）
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

    // 生成唯一的通知ID
    final int notificationId = _generateNotificationId(course.id ?? 0, date);

    // 生成通知标题（带随机emoji）
    final String emoji = _getRandomEmoji();
    final String title = '$emoji ${course.name}';

    // 获取星期几
    final weekDays = ['', '周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    final weekDayStr = weekDays[course.dayOfWeek];

    // 构建信息行（4行）
    final List<String> infoLines = [
      '⏰ 时间：$weekDayStr ${timeRange.toString()}',
      '📍 地点：${course.location ?? "未指定地点"}',
      '👨‍🏫 教师：${course.teacher ?? "未指定教师"}',
      if (course.note != null && course.note!.isNotEmpty)
        '💡 提示：${course.note}'
      else
        '💡 请准时到达教室',
    ];

    // 创建自定义振动模式
    final Int64List vibrationPattern = Int64List.fromList([
      0, 300, 100, 300, 100, 300,
    ]);

    // 副标题：还有x分钟开始上课 + 上课地点
    final String summaryText = '还有$minutesBefore分钟开始上课 • ${course.location ?? "未指定地点"}';

    // 创建通知详情
    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'fitschedule_notifications',
          'FIT课表通知',
          channelDescription: '课程提醒和应用通知',
          importance: Importance.max,
          priority: Priority.max,
          icon: '@mipmap/ic_launcher',
          largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          playSound: true,
          enableVibration: true,
          vibrationPattern: vibrationPattern,
          enableLights: true,
          ledColor: const Color.fromARGB(255, 255, 87, 34), // 深橙色LED
          ledOnMs: 1000,
          ledOffMs: 500,
          styleInformation: InboxStyleInformation(
            infoLines,
            htmlFormatLines: true,
            contentTitle: '$emoji ${course.name}',
            htmlFormatContentTitle: true,
            summaryText: summaryText,
            htmlFormatSummaryText: true,
          ),
          fullScreenIntent: true,
          visibility: NotificationVisibility.public,
          autoCancel: true,
          channelShowBadge: true,
          actions: const <AndroidNotificationAction>[
            AndroidNotificationAction(
              'view_detail',
              '📖 查看详情',
              icon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
              showsUserInterface: true,
            ),
            AndroidNotificationAction(
              'dismiss',
              '✓ 知道了',
              icon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
              cancelNotification: true,
            ),
          ],
        );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    // 创建 payload（包含课程ID，用于点击时导航）
    final payload = jsonEncode({
      'courseId': course.id ?? 0,
      'courseName': course.name,
    });

    // 安排通知
    await _flutterLocalNotificationsPlugin.zonedSchedule(
      notificationId,
      title,
      summaryText, // 使用副标题作为body
      tz.TZDateTime.from(notificationTime, tz.local),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload, // 添加 payload
    );
  }

  // 为一周的课程设置通知
  Future<void> scheduleWeekCoursesNotifications({
    required List<Course> courses,
    required DateTime weekStartDate,
    int minutesBefore = 5, // 默认提前5分钟
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
