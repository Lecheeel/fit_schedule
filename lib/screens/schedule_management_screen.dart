import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/schedule.dart';
import '../providers/schedule_provider.dart';
import 'course_import_screen.dart';

/// 课表管理界面
class ScheduleManagementScreen extends StatelessWidget {
  const ScheduleManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('课表管理'),
      ),
      body: Consumer<ScheduleProvider>(
        builder: (context, provider, child) {
          final schedules = provider.schedules;
          final currentSchedule = provider.currentSchedule;

          if (schedules.isEmpty) {
            return _buildEmptyState(context);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: schedules.length,
            itemBuilder: (context, index) {
              final schedule = schedules[index];
              final isActive = schedule.id == currentSchedule?.id;

              return _buildScheduleCard(context, schedule, isActive, provider);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateScheduleDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('新建课表'),
      ),
    );
  }

  // 构建空状态
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_month_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            '暂无课表',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '点击下方按钮创建你的第一个课表',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _showCreateScheduleDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('新建课表'),
          ),
        ],
      ),
    );
  }

  // 构建课表卡片
  Widget _buildScheduleCard(
    BuildContext context,
    Schedule schedule,
    bool isActive,
    ScheduleProvider provider,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: isActive ? null : () => _switchSchedule(context, schedule),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 激活状态条
            if (isActive)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 6),
                color: colorScheme.primary,
                child: const Center(
                  child: Text(
                    '当前使用中',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 标题行
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          schedule.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit') {
                            _showEditScheduleDialog(context, schedule);
                          } else if (value == 'delete') {
                            _showDeleteConfirmDialog(context, schedule);
                          } else if (value == 'switch') {
                            _switchSchedule(context, schedule);
                          }
                        },
                        itemBuilder: (context) => [
                          if (!isActive)
                            const PopupMenuItem<String>(
                              value: 'switch',
                              child: Row(
                                children: [
                                  Icon(Icons.check_circle, size: 18),
                                  SizedBox(width: 8),
                                  Text('切换到此课表'),
                                ],
                              ),
                            ),
                          const PopupMenuItem<String>(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 18),
                                SizedBox(width: 8),
                                Text('编辑'),
                              ],
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 18, color: Colors.red),
                                const SizedBox(width: 8),
                                const Text('删除', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 信息行
                  _buildInfoRow(
                    context,
                    Icons.date_range,
                    schedule.getDateRangeString(),
                  ),
                  const SizedBox(height: 4),
                  _buildInfoRow(
                    context,
                    Icons.view_week,
                    '共${schedule.numberOfWeeks}周',
                  ),
                  const SizedBox(height: 4),
                  FutureBuilder<int>(
                    future: provider.getScheduleCourseCount(schedule.id!),
                    builder: (context, snapshot) {
                      final count = snapshot.data ?? 0;
                      return _buildInfoRow(
                        context,
                        Icons.book,
                        '$count门课程',
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 构建信息行
  Widget _buildInfoRow(BuildContext context, IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  // 显示创建课表对话框
  void _showCreateScheduleDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '新建课表',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '选择创建方式',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),

            // 智能创建选项
            _CreateOptionCard(
              icon: Icons.auto_awesome,
              title: '智能创建',
              subtitle: '自动命名并从教务系统导入课程',
              recommended: true,
              onTap: () {
                Navigator.pop(context);
                _createSmartSchedule(context);
              },
            ),
            const SizedBox(height: 12),

            // 手动创建选项
            _CreateOptionCard(
              icon: Icons.edit_note,
              title: '手动创建',
              subtitle: '自定义课表名称和学期信息',
              onTap: () {
                Navigator.pop(context);
                _showManualCreateDialog(context);
              },
            ),
            
            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ],
        ),
      ),
    );
  }

  // 智能创建课表
  Future<void> _createSmartSchedule(BuildContext context) async {
    final provider = Provider.of<ScheduleProvider>(context, listen: false);

    try {
      // 创建智能课表
      await provider.createSmartSchedule();

      if (context.mounted) {
        // 显示成功提示
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('课表已创建，正在跳转到导入页面...')),
        );

        // 跳转到导入页面
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CourseImportScreen()),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('创建失败: $e')),
        );
      }
    }
  }

  // 显示手动创建对话框
  void _showManualCreateDialog(BuildContext context, [Schedule? schedule]) {
    final isEditing = schedule != null;
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(
      text: isEditing ? schedule.name : Schedule.generateSmartName(),
    );
    var startDate = isEditing ? schedule.startDate : Schedule.estimateStartDate();
    var numberOfWeeks = isEditing ? schedule.numberOfWeeks : 20;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(isEditing ? '编辑课表' : '手动创建课表'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 课表名称
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: '课表名称',
                        hintText: '例如：2024-2025学年第一学期课表',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请输入课表名称';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // 开始日期
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('开始日期'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(DateFormat('yyyy年MM月dd日').format(startDate)),
                          const SizedBox(height: 4),
                          const Text(
                            '系统会自动计算为该日期所在周的周一',
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: startDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (date != null) {
                          setState(() {
                            startDate = date;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 8),

                    // 学期周数
                    Row(
                      children: [
                        const Text('学期周数：'),
                        const SizedBox(width: 8),
                        DropdownButton<int>(
                          value: numberOfWeeks,
                          items: List.generate(25, (index) {
                            final value = index + 1;
                            return DropdownMenuItem<int>(
                              value: value,
                              child: Text('$value'),
                            );
                          }),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                numberOfWeeks = value;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    _saveSchedule(
                      context,
                      isEditing ? schedule.id : null,
                      nameController.text.trim(),
                      startDate,
                      numberOfWeeks,
                    );
                    Navigator.pop(context);
                  }
                },
                child: const Text('保存'),
              ),
            ],
          );
        },
      ),
    );
  }

  // 显示编辑课表对话框
  void _showEditScheduleDialog(BuildContext context, Schedule schedule) {
    _showManualCreateDialog(context, schedule);
  }

  // 保存课表
  Future<void> _saveSchedule(
    BuildContext context,
    int? id,
    String name,
    DateTime startDate,
    int numberOfWeeks,
  ) async {
    final provider = Provider.of<ScheduleProvider>(context, listen: false);

    final schedule = Schedule.fromAnyDay(
      id: id,
      name: name,
      anyDayInFirstWeek: startDate,
      numberOfWeeks: numberOfWeeks,
      isActive: id == null ? provider.schedules.isEmpty : (provider.currentSchedule?.id == id),
    );

    try {
      if (id == null) {
        await provider.addSchedule(schedule);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('课表已创建')),
          );
        }
      } else {
        await provider.updateSchedule(schedule);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('课表已更新')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    }
  }

  // 显示删除确认对话框
  void _showDeleteConfirmDialog(BuildContext context, Schedule schedule) {
    final provider = Provider.of<ScheduleProvider>(context, listen: false);
    final isCurrentSchedule = provider.currentSchedule?.id == schedule.id;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('确定要删除课表"${schedule.name}"吗？'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.red.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '此操作将同时删除该课表下的所有课程，且不可撤销。',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (isCurrentSchedule) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.orange.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '这是当前使用的课表，删除后将自动切换到其他课表。',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteSchedule(context, schedule);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  // 删除课表
  Future<void> _deleteSchedule(BuildContext context, Schedule schedule) async {
    try {
      final provider = Provider.of<ScheduleProvider>(context, listen: false);
      await provider.deleteSchedule(schedule.id!);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已删除课表"${schedule.name}"')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('删除失败: $e')),
        );
      }
    }
  }

  // 切换课表
  Future<void> _switchSchedule(BuildContext context, Schedule schedule) async {
    try {
      final provider = Provider.of<ScheduleProvider>(context, listen: false);
      await provider.switchSchedule(schedule.id!);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已切换到"${schedule.name}"')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('切换失败: $e')),
        );
      }
    }
  }
}

/// 创建选项卡片组件
class _CreateOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool recommended;
  final VoidCallback onTap;

  const _CreateOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.recommended = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: recommended
                      ? colorScheme.primaryContainer
                      : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: recommended
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        if (recommended) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              '推荐',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
