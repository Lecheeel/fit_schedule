import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/schedule_provider.dart';

/// 显示系统信息对话框
Future<void> showSystemInfoDialog(
  BuildContext context,
  bool isDarkMode,
  bool enableNotifications,
  int reminderMinutes,
) async {
  final scheduleProvider = Provider.of<ScheduleProvider>(context, listen: false);
  final prefs = await SharedPreferences.getInstance();
  
  if (!context.mounted) return;
  
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      icon: const Icon(Icons.info, size: 48, color: Colors.blue),
      title: const Text('系统信息'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoItem('应用版本', '1.0.0'),
            _buildInfoItem('Flutter版本', '3.x'),
            const Divider(),
            _buildInfoItem('学期数量', '${scheduleProvider.semesters.length}'),
            _buildInfoItem('课程数量', '${scheduleProvider.courses.length}'),
            _buildInfoItem('当前学期', scheduleProvider.currentSemester?.name ?? '未设置'),
            const Divider(),
            _buildInfoItem('深色模式', isDarkMode ? '已启用' : '未启用'),
            _buildInfoItem('通知提醒', enableNotifications ? '已启用' : '未启用'),
            _buildInfoItem('提醒时间', '$reminderMinutes 分钟'),
            const Divider(),
            _buildInfoItem('数据库路径', 'data/schedule.db'),
            _buildInfoItem('SharedPreferences', '${prefs.getKeys().length} 项'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('关闭'),
        ),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.pop(context);
            // 复制信息到剪贴板
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('系统信息已准备就绪'),
                duration: Duration(seconds: 1),
              ),
            );
          },
          icon: const Icon(Icons.copy),
          label: const Text('复制'),
        ),
      ],
    ),
  );
}

/// 构建信息项
Widget _buildInfoItem(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
            ),
          ),
        ),
      ],
    ),
  );
}

