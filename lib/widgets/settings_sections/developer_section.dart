import 'package:flutter/material.dart';

/// 开发者工具区块
class DeveloperSection extends StatefulWidget {
  final VoidCallback onResetNotifications;
  final VoidCallback onSendTestNotification;
  final VoidCallback onCheckPermission;
  final VoidCallback onClearAllNotifications;
  final VoidCallback onShowSystemInfo;
  final Function(String) onSendStyledNotification;
  final VoidCallback onSendTestCourseReminder;

  const DeveloperSection({
    super.key,
    required this.onResetNotifications,
    required this.onSendTestNotification,
    required this.onCheckPermission,
    required this.onClearAllNotifications,
    required this.onShowSystemInfo,
    required this.onSendStyledNotification,
    required this.onSendTestCourseReminder,
  });

  @override
  State<DeveloperSection> createState() => _DeveloperSectionState();
}

class _DeveloperSectionState extends State<DeveloperSection> {
  bool _isStyledNotificationExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, '开发者工具'),
        ListTile(
          leading: const Icon(Icons.refresh, color: Colors.green),
          title: const Text('重置通知设置'),
          subtitle: const Text('删除旧渠道并重新创建（修复弹出问题）'),
          trailing: const Icon(Icons.autorenew),
          onTap: widget.onResetNotifications,
        ),
        ListTile(
          leading: const Icon(Icons.notifications_active, color: Colors.orange),
          title: const Text('发送测试通知'),
          subtitle: const Text('测试通知功能是否正常'),
          trailing: const Icon(Icons.send),
          onTap: widget.onSendTestNotification,
        ),
        ListTile(
          leading: const Icon(Icons.school, color: Colors.deepOrange),
          title: const Text('测试课程提醒'),
          subtitle: const Text('2秒后弹出智能助手样式的课程通知'),
          trailing: const Icon(Icons.schedule),
          onTap: widget.onSendTestCourseReminder,
        ),
        // 样式化通知测试（可展开）
        ExpansionTile(
          leading: const Icon(Icons.style, color: Colors.deepPurple),
          title: const Text('样式化通知测试'),
          subtitle: const Text('测试各种通知样式效果'),
          initiallyExpanded: _isStyledNotificationExpanded,
          onExpansionChanged: (expanded) {
            setState(() => _isStyledNotificationExpanded = expanded);
          },
          children: [
            // 基础样式
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                '基础样式',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.inbox, color: Colors.green),
              title: const Text('收件箱样式'),
              subtitle: const Text('显示多行课程列表'),
              onTap: () => widget.onSendStyledNotification('inbox'),
            ),
            ListTile(
              leading: const Icon(Icons.message, color: Colors.blue),
              title: const Text('消息对话样式'),
              subtitle: const Text('模拟课程助手对话'),
              onTap: () => widget.onSendStyledNotification('messaging'),
            ),
            ListTile(
              leading: const Icon(Icons.article, color: Colors.orange),
              title: const Text('大文本样式'),
              subtitle: const Text('显示完整课程详情'),
              onTap: () => widget.onSendStyledNotification('bigtext'),
            ),
            ListTile(
              leading: const Icon(Icons.trending_up, color: Colors.purple),
              title: const Text('进度条样式'),
              subtitle: const Text('显示学期进度'),
              onTap: () => widget.onSendStyledNotification('progress'),
            ),
            const Divider(indent: 16, endIndent: 16),
            // 高级自定义样式
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                '高级自定义样式',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.image, color: Colors.cyan),
              title: const Text('大图片样式'),
              subtitle: const Text('显示教室位置图片'),
              onTap: () => widget.onSendStyledNotification('bigpicture'),
            ),
            ListTile(
              leading: const Icon(Icons.music_note, color: Colors.pink),
              title: const Text('媒体样式 + 操作按钮'),
              subtitle: const Text('带快捷操作按钮的通知'),
              onTap: () => widget.onSendStyledNotification('media'),
            ),
            ListTile(
              leading: const Icon(Icons.auto_awesome, color: Colors.deepOrange),
              title: const Text('智能助手样式'),
              subtitle: const Text('综合布局 + 多个操作按钮'),
              onTap: () => widget.onSendStyledNotification('custom_layout'),
            ),
          ],
        ),
        ListTile(
          leading: const Icon(Icons.verified_user, color: Colors.blue),
          title: const Text('检查通知权限'),
          subtitle: const Text('查看是否已授予通知权限'),
          trailing: const Icon(Icons.check_circle_outline),
          onTap: widget.onCheckPermission,
        ),
        ListTile(
          leading: const Icon(Icons.clear_all, color: Colors.red),
          title: const Text('清除所有通知'),
          subtitle: const Text('取消所有已设置的通知'),
          trailing: const Icon(Icons.delete_sweep),
          onTap: widget.onClearAllNotifications,
        ),
        ListTile(
          leading: const Icon(Icons.bug_report, color: Colors.purple),
          title: const Text('系统信息'),
          subtitle: const Text('查看应用调试信息'),
          trailing: const Icon(Icons.info_outline),
          onTap: widget.onShowSystemInfo,
        ),
        const Divider(),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
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
}

