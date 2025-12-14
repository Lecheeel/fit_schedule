import 'package:flutter/material.dart';

/// 关于区块
class AboutSection extends StatelessWidget {
  final VoidCallback onAboutPressed;

  const AboutSection({
    super.key,
    required this.onAboutPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, '关于'),
        ListTile(
          leading: const Icon(Icons.info),
          title: const Text('关于FITschedule'),
          subtitle: const Text('版本 1.0.0'),
          onTap: onAboutPressed,
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

