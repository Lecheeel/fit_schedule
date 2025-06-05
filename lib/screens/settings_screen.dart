import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/schedule_provider.dart';
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
          _buildSectionHeader('外观'),
          SwitchListTile(
            title: const Text('深色模式'),
            subtitle: const Text('启用深色主题'),
            value: _isDarkMode,
            onChanged: (value) {
              setState(() {
                _isDarkMode = value;
              });
              _saveSettings();
            },
          ),
          const Divider(),

          // 课表设置
          _buildSectionHeader('课表设置'),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('导入课表'),
            subtitle: const Text('从教务系统导入课程安排'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _navigateToImportCourse(context),
          ),
          SwitchListTile(
            title: const Text('显示非本周课程'),
            subtitle: const Text('非本周课程将以灰色显示'),
            value: _showNonCurrentWeekCourses,
            onChanged: (value) {
              setState(() {
                _showNonCurrentWeekCourses = value;
              });
              _saveSettings();
              scheduleProvider.setShowNonCurrentWeekCourses(value);
            },
          ),
          const Divider(),

          // 通知设置
          _buildSectionHeader('通知'),
          SwitchListTile(
            title: const Text('课程提醒'),
            subtitle: const Text('上课前通知提醒'),
            value: _enableNotifications,
            onChanged: (value) {
              setState(() {
                _enableNotifications = value;
              });
              _saveSettings();
            },
          ),
          if (_enableNotifications) ...[
            ListTile(
              title: const Text('提前提醒时间'),
              subtitle: Text('提前 $_reminderMinutes 分钟'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showReminderDialog(),
            ),
          ],
          const Divider(),

          // 学期管理
          _buildSectionHeader('学期管理'),
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: const Text('学期管理'),
            subtitle: const Text('设置学期起始日期和周数'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SemesterManagementScreen(),
                ),
              );
            },
          ),
          const Divider(),

          // 关于
          _buildSectionHeader('关于'),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('关于FITschedule'),
            subtitle: const Text('版本 1.0.0'),
            onTap: () => _showAboutDialog(),
          ),
          
          // 开发者彩蛋卡片
          _buildDeveloperCard(),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // 构建分区标题
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  // 显示提醒时间选择对话框
  void _showReminderDialog() {
    showDialog(
      context: context,
      builder: (context) {
        int tempMinutes = _reminderMinutes;
        return AlertDialog(
          title: const Text('提前提醒时间'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('上课前多久发送通知提醒？'),
                  const SizedBox(height: 16),
                  DropdownButton<int>(
                    value: tempMinutes,
                    isExpanded: true,
                    items: [5, 10, 15, 20, 30, 60].map((value) {
                      return DropdownMenuItem<int>(
                        value: value,
                        child: Text('$value 分钟'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          tempMinutes = value;
                        });
                      }
                    },
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _reminderMinutes = tempMinutes;
                });
                _saveSettings();
                Navigator.pop(context);
              },
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }

  // 显示关于对话框
  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('关于FITschedule'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('FITschedule是一款简洁、易用的课表应用，为学生提供课程管理和提醒功能。'),
            SizedBox(height: 16),
            Text('版本: 1.0.0'),
            Text('开发者: Liqiu'),
            SizedBox(height: 16),
            Text('© 2025 Liqiu. All rights reserved.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
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

  // 构建开发者彩蛋卡片
  Widget _buildDeveloperCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 0,
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showDeveloperEasterEgg(),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.purple.shade50,
                  Colors.blue.shade50,
                  Colors.cyan.shade50,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.purple.shade200.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.purple.shade300, Colors.blue.shade300],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.shade200.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.code,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            '开发者',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Liqiu',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 显示开发者
  void _showDeveloperEasterEgg() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            // 技术栈
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Text(
                    '技术栈',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: ['Flutter', 'Dart', 'SQLite', 'Material Design']
                        .map((tech) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                tech,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue.shade800,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 特殊信息
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.pink.shade50, Colors.purple.shade50],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
            label: const Text('关闭'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('感谢你的支持！⭐'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(Icons.star),
            label: const Text('点赞支持'),
          ),
        ],
      ),
    );
  }
} 