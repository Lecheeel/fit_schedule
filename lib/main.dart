import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'providers/schedule_provider.dart';
import 'services/notification_service.dart';
import 'screens/week_view_screen.dart';
import 'screens/day_view_screen.dart';
import 'screens/course_management_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/course_form_screen.dart';
import 'screens/course_import_screen.dart';
import 'screens/semester_management_screen.dart';
import 'utils/app_theme.dart';
import 'models/course.dart';

// 全局导航key，用于通知点击时导航
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 设置系统UI样式
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent, // 透明状态栏
    statusBarIconBrightness: Brightness.dark, // 状态栏图标颜色
    systemNavigationBarColor: Colors.white, // 导航栏颜色
    systemNavigationBarDividerColor: Colors.transparent, // 导航栏分隔线
    systemNavigationBarIconBrightness: Brightness.dark, // 导航栏图标颜色
  ));
  
  // 初始化通知服务
  final notificationService = NotificationService();
  await notificationService.init();
  
  // 初始化ScheduleProvider
  final scheduleProvider = ScheduleProvider();
  await scheduleProvider.initialize();
  
  // 获取主题设置
  final prefs = await SharedPreferences.getInstance();
  final isDarkMode = prefs.getBool('isDarkMode') ?? false;
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => scheduleProvider),
      ],
      child: MyApp(isDarkMode: isDarkMode),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool isDarkMode;
  
  const MyApp({super.key, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FITschedule',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const HomePage(),
      navigatorKey: navigatorKey, // 添加全局导航key
      debugShowCheckedModeBanner: false, // 移除debug标签
      // 添加命名路由
      routes: {
        '/course-form': (context) => CourseFormScreen(),
        '/course_import': (context) => const CourseImportScreen(),
        '/course_management': (context) => const CourseManagementScreen(),
        '/semester_management': (context) => const SemesterManagementScreen(),
      },
      // 添加路由生成器，处理需要传参的路由
      onGenerateRoute: (settings) {
        if (settings.name == '/course-form') {
          final course = settings.arguments as Course?;
          return MaterialPageRoute(
            builder: (context) => CourseFormScreen(course: course),
            settings: settings,
          );
        }
        return null;
      },
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  
  static const List<Widget> _widgetOptions = <Widget>[
    WeekViewScreen(),
    DayViewScreen(),
    CourseManagementScreen(),
    SettingsScreen(),
  ];
  
  
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 确保应用安全区域
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent, // 设置导航栏为透明
      ),
      child: Scaffold(
        // 使用SafeArea确保内容不被状态栏遮挡
        body: SafeArea(
          // bottom设为false让内容延伸到底部，以适配全面屏
          bottom: false,
          child: _widgetOptions.elementAt(_selectedIndex),
        ),
        // 设置背景色与应用背景相同
        backgroundColor: Theme.of(context).colorScheme.surface,
        // 设置导航栏背景色，适配全面屏
        bottomNavigationBar: Container(
          // 添加底部安全区域边距
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom,
          ),
          // 设置导航栏背景色
          color: Theme.of(context).colorScheme.surface,
          child: NavigationBar(
            height: 60, // 设置固定高度
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onItemTapped,
            destinations: const <NavigationDestination>[
              NavigationDestination(
                icon: Icon(Icons.view_week),
                label: '周视图',
              ),
              NavigationDestination(
                icon: Icon(Icons.view_day),
                label: '日视图',
              ),
              NavigationDestination(
                icon: Icon(Icons.book),
                label: '课程',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings),
                label: '设置',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
