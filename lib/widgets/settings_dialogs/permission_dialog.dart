import 'package:flutter/material.dart';
import '../../services/notification_service.dart';

/// 显示权限对话框
void showPermissionDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      icon: const Icon(Icons.warning, size: 48, color: Colors.orange),
      title: const Text('需要通知权限'),
      content: const Text('请授予通知权限，以便应用可以发送课程提醒。'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(context);
            final notificationService = NotificationService();
            await notificationService.checkPermission();
          },
          child: const Text('去设置'),
        ),
      ],
    ),
  );
}

