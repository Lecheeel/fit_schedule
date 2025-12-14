import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/schedule_provider.dart';
import '../utils/developer_tools_handler.dart';
import '../widgets/settings_sections/appearance_section.dart';
import '../widgets/settings_sections/schedule_section.dart';
import '../widgets/settings_sections/notification_section.dart';
import '../widgets/settings_sections/semester_section.dart';
import '../widgets/settings_sections/about_section.dart';
import '../widgets/settings_sections/developer_section.dart';
import '../widgets/settings_sections/developer_card.dart';
import '../widgets/settings_dialogs/reminder_dialog.dart';
import '../widgets/settings_dialogs/about_dialog.dart';
import '../widgets/settings_dialogs/developer_easter_egg_dialog.dart';
import '../widgets/settings_dialogs/system_info_dialog.dart';
import 'semester_management_screen.dart';
import 'course_import_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDarkMode = false;
  bool _enableNotifications = true;
  bool _showNonCurrentWeekCourses = false;
  int _reminderMinutes = 15;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // 加载设置
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('isDarkMode') ?? false;
      _enableNotifications = prefs.getBool('enableNotifications') ?? true;
      _reminderMinutes = prefs.getInt('reminderMinutes') ?? 15;
      _showNonCurrentWeekCourses = prefs.getBool('showNonCurrentWeekCourses') ?? false;
    });
  }

  // 保存设置
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
    await prefs.setBool('enableNotifications', _enableNotifications);
    await prefs.setInt('reminderMinutes', _reminderMinutes);
    await prefs.setBool('showNonCurrentWeekCourses', _showNonCurrentWeekCourses);
  }

  @override
  Widget build(BuildContext context) {
    final scheduleProvider = Provider.of<ScheduleProvider>(context, listen: false);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: ListView(
        children: [
          // 外观设置
          AppearanceSection(
            isDarkMode: _isDarkMode,
            onDarkModeChanged: (value) {
              setState(() => _isDarkMode = value);
              _saveSettings();
            },
          ),

          // 课表设置
          ScheduleSection(
            showNonCurrentWeekCourses: _showNonCurrentWeekCourses,
            onShowNonCurrentWeekCoursesChanged: (value) {
              setState(() => _showNonCurrentWeekCourses = value);
              _saveSettings();
              scheduleProvider.setShowNonCurrentWeekCourses(value);
            },
            onImportCourse: () => _navigateToImportCourse(context),
          ),

          // 通知设置
          NotificationSection(
            enableNotifications: _enableNotifications,
            reminderMinutes: _reminderMinutes,
            onEnableNotificationsChanged: (value) {
              setState(() => _enableNotifications = value);
              _saveSettings();
            },
            onReminderTimePressed: () async {
              final newMinutes = await showReminderDialog(context, _reminderMinutes);
              if (newMinutes != null) {
                setState(() => _reminderMinutes = newMinutes);
                _saveSettings();
              }
            },
          ),

          // 学期管理
          SemesterSection(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SemesterManagementScreen(),
                ),
              );
            },
          ),

          // 关于
          AboutSection(
            onAboutPressed: () => showAboutAppDialog(context),
          ),
          
          // 开发者工具
          DeveloperSection(
            onResetNotifications: () => DeveloperToolsHandler(context).resetNotificationSettings(),
            onSendTestNotification: () => DeveloperToolsHandler(context).sendTestNotification(),
            onCheckPermission: () => DeveloperToolsHandler(context).checkNotificationPermission(),
            onClearAllNotifications: () => DeveloperToolsHandler(context).clearAllNotifications(),
            onShowSystemInfo: () => showSystemInfoDialog(
              context,
              _isDarkMode,
              _enableNotifications,
              _reminderMinutes,
            ),
            onSendStyledNotification: (style) => DeveloperToolsHandler(context).sendStyledNotification(style),
            onSendTestCourseReminder: () => DeveloperToolsHandler(context).sendTestCourseReminder(),
          ),
          
          // 开发者彩蛋卡片
          DeveloperCard(
            onTap: () => showDeveloperEasterEggDialog(context),
          ),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // 导航到导入课表页面
  void _navigateToImportCourse(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CourseImportScreen(),
      ),
    );
  }
}
