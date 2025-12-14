import 'package:flutter/material.dart';

/// 显示关于对话框
void showAboutAppDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('关于FITschedule'),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('FITschedule是一款简洁、易用的课表应用，为师生提供课程管理和提醒功能。'),
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

