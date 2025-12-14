import 'package:flutter/material.dart';

/// 外观设置区块
class AppearanceSection extends StatelessWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onDarkModeChanged;

  const AppearanceSection({
    super.key,
    required this.isDarkMode,
    required this.onDarkModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, '外观'),
        SwitchListTile(
          title: const Text('深色模式'),
          subtitle: const Text('启用深色主题'),
          value: isDarkMode,
          onChanged: onDarkModeChanged,
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

