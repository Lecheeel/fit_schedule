import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/schedule_provider.dart';
import '../utils/developer_tools_handler.dart';
import '../widgets/settings_sections/appearance_section.dart';
import '../widgets/settings_sections/schedule_section.dart';
import '../widgets/settings_sections/notification_section.dart';
import '../widgets/settings_sections/about_section.dart';
import '../widgets/settings_sections/developer_section.dart';
import '../widgets/settings_sections/developer_card.dart';
import '../widgets/settings_dialogs/reminder_dialog.dart';
import '../widgets/settings_dialogs/about_dialog.dart';
import '../widgets/settings_dialogs/developer_easter_egg_dialog.dart';
import '../widgets/settings_dialogs/system_info_dialog.dart';
import 'account_management_screen.dart';
import 'schedule_management_screen.dart';
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

          // 课表管理
          ScheduleSettingsSection(
            onManageSchedules: () => _navigateToScheduleManagement(context),
            onCreateSmartSchedule: () => _createSmartScheduleAndImport(context),
          ),

          // 账号管理
          _buildAccountSection(scheduleProvider),

          // 课表显示设置
          _buildScheduleDisplaySection(scheduleProvider),

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

  Widget _buildAccountSection(ScheduleProvider scheduleProvider) {
    final accountCount = scheduleProvider.accounts.length;
    final currentAccount = scheduleProvider.getAccountForCurrentSchedule();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            '账号管理',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.manage_accounts),
          title: const Text('教务系统账号'),
          subtitle: Text(
            accountCount > 0 ? '已保存 $accountCount 个账号' : '未保存账号',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _navigateToAccountManagement(context),
        ),
        if (currentAccount != null)
          ListTile(
            leading: const Icon(Icons.sync),
            title: const Text('快速更新课表'),
            subtitle: Text('使用 ${currentAccount.displayName} 的账号更新'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _quickSync(context, currentAccount, scheduleProvider),
          ),
        const Divider(),
      ],
    );
  }

  void _navigateToAccountManagement(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AccountManagementScreen(),
      ),
    );
  }

  Future<void> _quickSync(
    BuildContext context,
    dynamic account,
    ScheduleProvider provider,
  ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('正在从教务系统获取最新课表...'),
          ],
        ),
      ),
    );

    try {
      final message = await provider.syncScheduleWithAccount(account);
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('同步失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildScheduleDisplaySection(ScheduleProvider scheduleProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            '课表显示',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        SwitchListTile(
          title: const Text('显示非本周课程'),
          subtitle: const Text('以灰色显示不在当前周上课的课程'),
          value: _showNonCurrentWeekCourses,
          onChanged: (value) {
            setState(() => _showNonCurrentWeekCourses = value);
            _saveSettings();
            scheduleProvider.setShowNonCurrentWeekCourses(value);
          },
        ),
        ListTile(
          leading: const Icon(Icons.cloud_download),
          title: const Text('导入课程'),
          subtitle: const Text('从教务系统导入课程'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _navigateToImportCourse(context),
        ),
        const Divider(),
      ],
    );
  }

  // 导航到课表管理页面
  void _navigateToScheduleManagement(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ScheduleManagementScreen(),
      ),
    );
  }

  // 智能创建课表并导入
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
