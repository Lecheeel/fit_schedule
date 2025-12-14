import 'package:flutter/material.dart';

/// 显示开发者彩蛋对话框
void showDeveloperEasterEggDialog(BuildContext context) {
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

