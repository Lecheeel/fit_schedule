import 'package:flutter/material.dart';

/// 显示提醒时间选择对话框
Future<int?> showReminderDialog(BuildContext context, int currentMinutes) {
  return showDialog<int>(
    context: context,
    builder: (context) {
      int tempMinutes = currentMinutes;
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
            onPressed: () => Navigator.pop(context, tempMinutes),
            child: const Text('确定'),
          ),
        ],
      );
    },
  );
}

