import 'package:flutter/material.dart';

/// 通知设置区块
class NotificationSection extends StatelessWidget {
  final bool enableNotifications;
  final int reminderMinutes;
  final ValueChanged<bool> onEnableNotificationsChanged;
  final VoidCallback onReminderTimePressed;

  const NotificationSection({
    super.key,
    required this.enableNotifications,
    required this.reminderMinutes,
    required this.onEnableNotificationsChanged,
    required this.onReminderTimePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, '通知'),
        SwitchListTile(
          title: const Text('课程提醒'),
          subtitle: const Text('上课前通知提醒'),
          value: enableNotifications,
          onChanged: onEnableNotificationsChanged,
        ),
        if (enableNotifications) ...[
          ListTile(
            title: const Text('提前提醒时间'),
            subtitle: Text('提前 $reminderMinutes 分钟'),
            trailing: const Icon(Icons.chevron_right),
            onTap: onReminderTimePressed,
          ),
        ],
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

