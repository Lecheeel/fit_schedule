import 'package:flutter/material.dart';

/// 学期管理区块
class SemesterSection extends StatelessWidget {
  final VoidCallback onPressed;

  const SemesterSection({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, '学期管理'),
        ListTile(
          leading: const Icon(Icons.calendar_today),
          title: const Text('学期管理'),
          subtitle: const Text('设置学期起始日期和周数'),
          trailing: const Icon(Icons.chevron_right),
          onTap: onPressed,
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

