import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/schedule_provider.dart';

/// 课表管理区块
class ScheduleSettingsSection extends StatelessWidget {
  final VoidCallback onManageSchedules;
  final VoidCallback onCreateSmartSchedule;

  const ScheduleSettingsSection({
    super.key,
    required this.onManageSchedules,
    required this.onCreateSmartSchedule,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ScheduleProvider>(
      builder: (context, provider, child) {
        final currentSchedule = provider.currentSchedule;
        final scheduleCount = provider.schedules.length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(context, '课表管理'),
            
            // 当前课表信息
            if (currentSchedule != null)
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.calendar_month,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                ),
                title: Text(
                  currentSchedule.name,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  '${currentSchedule.shortDescription} · ${scheduleCount > 1 ? "共$scheduleCount个课表" : "1个课表"}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: onManageSchedules,
              )
            else
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.calendar_month_outlined,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                ),
                title: const Text('暂无课表'),
                subtitle: const Text('点击创建你的第一个课表'),
                trailing: const Icon(Icons.add),
                onTap: onCreateSmartSchedule,
              ),

            // 快捷操作
            if (currentSchedule != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onCreateSmartSchedule,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('新建'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onManageSchedules,
                        icon: const Icon(Icons.settings, size: 18),
                        label: const Text('管理'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const Divider(),
          ],
        );
      },
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
