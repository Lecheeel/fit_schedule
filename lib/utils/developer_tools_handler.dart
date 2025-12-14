import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/notification_service.dart';
import '../widgets/settings_dialogs/permission_dialog.dart';
import '../providers/schedule_provider.dart';

/// 开发者工具处理类
class DeveloperToolsHandler {
  final BuildContext context;
  final NotificationService _notificationService = NotificationService();

  DeveloperToolsHandler(this.context);

  /// 重置通知设置
  Future<void> resetNotificationSettings() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.refresh, size: 48, color: Colors.green),
        title: const Text('重置通知设置'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('这将删除所有旧的通知渠道并重新创建新渠道。'),
            SizedBox(height: 16),
            Text(
              '操作步骤：',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('1. 点击"确定重置"'),
            Text('2. 等待重置完成'),
            Text('3. 点击"发送测试通知"'),
            Text('4. 通知应该从屏幕顶部弹出'),
            SizedBox(height: 16),
            Text(
              '⚠️ 如果还是不弹出，请完全卸载应用后重新安装',
              style: TextStyle(fontSize: 12, color: Colors.orange),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('确定重置'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _notificationService.resetNotificationChannels();
      
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text('通知设置已重置！请发送测试通知验证'),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('重置失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 发送测试通知
  Future<void> sendTestNotification() async {
    try {
      await _notificationService.sendTestNotification();

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text('测试通知已发送！请查看通知栏'),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      // 如果是权限问题，显示权限对话框
      if (e.toString().contains('权限')) {
        showPermissionDialog(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('发送失败: $e'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// 检查通知权限
  Future<void> checkNotificationPermission() async {
    try {
      final hasPermission = await _notificationService.checkPermission();
      
      if (!context.mounted) return;
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          icon: Icon(
            hasPermission ? Icons.check_circle : Icons.error,
            size: 48,
            color: hasPermission ? Colors.green : Colors.orange,
          ),
          title: Text(hasPermission ? '权限已授予' : '权限未授予'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                hasPermission 
                  ? '通知权限已授予，应用可以正常发送通知。'
                  : '通知权限未授予，应用无法发送通知提醒。',
                textAlign: TextAlign.center,
              ),
              if (!hasPermission) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.lightbulb, 
                            size: 16, 
                            color: Colors.orange.shade700,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '如何授予权限：',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '1. 打开手机设置\n'
                        '2. 找到应用管理\n'
                        '3. 找到FITschedule\n'
                        '4. 开启通知权限',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('关闭'),
            ),
            if (!hasPermission)
              ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  // 尝试再次请求权限
                  await _notificationService.checkPermission();
                },
                icon: const Icon(Icons.settings),
                label: const Text('请求权限'),
              ),
          ],
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('检查失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 清除所有通知
  Future<void> clearAllNotifications() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.warning, size: 48, color: Colors.orange),
        title: const Text('确认清除'),
        content: const Text('确定要清除所有已设置的通知吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('确定清除'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _notificationService.cancelAllNotifications();
      
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('已清除所有通知'),
            ],
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('清除失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 发送样式化测试通知
  Future<void> sendStyledNotification(String style) async {
    try {
      await _notificationService.sendStyledNotification(style: style);

      if (!context.mounted) return;
      
      String styleName = '';
      switch (style) {
        case 'inbox':
          styleName = '收件箱样式';
          break;
        case 'messaging':
          styleName = '消息对话样式';
          break;
        case 'bigtext':
          styleName = '大文本样式';
          break;
        case 'progress':
          styleName = '进度条样式';
          break;
        case 'bigpicture':
          styleName = '大图片样式';
          break;
        case 'media':
          styleName = '媒体样式';
          break;
        case 'custom_layout':
          styleName = '智能助手样式';
          break;
        default:
          styleName = '样式化';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text('$styleName通知已发送！请查看通知栏'),
              ),
            ],
          ),
          backgroundColor: Colors.deepPurple,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      // 如果是权限问题，显示权限对话框
      if (e.toString().contains('权限')) {
        showPermissionDialog(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('发送失败: $e'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// 发送测试课程提醒（2秒后触发，从课表中随机选择一节课）
  Future<void> sendTestCourseReminder() async {
    try {
      // 从 Provider 获取所有课程
      final scheduleProvider = Provider.of<ScheduleProvider>(context, listen: false);
      final allCourses = scheduleProvider.courses;

      // 如果课表为空，使用默认测试数据
      if (allCourses.isEmpty) {
        await _notificationService.sendTestCourseReminder();
        
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.access_time, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text('课表为空，使用默认测试数据！将在2秒后弹出通知'),
                ),
              ],
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      // 随机选择一节课
      final randomCourse = allCourses[DateTime.now().millisecondsSinceEpoch % allCourses.length];
      
      // 发送该课程的测试提醒
      await _notificationService.sendTestCourseReminder(course: randomCourse);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.access_time, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text('测试提醒已安排：${randomCourse.name} - 将在2秒后弹出通知'),
              ),
            ],
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      // 如果是权限问题，显示权限对话框
      if (e.toString().contains('权限')) {
        showPermissionDialog(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('发送失败: $e'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}

