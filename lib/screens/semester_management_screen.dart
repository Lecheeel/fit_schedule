import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/semester.dart';
import '../providers/schedule_provider.dart';

class SemesterManagementScreen extends StatelessWidget {
  const SemesterManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('学期管理'),
      ),
      body: Consumer<ScheduleProvider>(
        builder: (context, provider, child) {
          final semesters = provider.semesters;
          final currentSemester = provider.currentSemester;
          
          if (semesters.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('暂无学期信息'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showSemesterDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('添加学期'),
                  ),
                ],
              ),
            );
          }
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: semesters.length,
            itemBuilder: (context, index) {
              final semester = semesters[index];
              final isActive = semester.id == currentSemester?.id;
              
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Row(
                    children: [
                      Text(
                        semester.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isActive)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            '当前学期',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        context,
                        Icons.date_range,
                        semester.getDateRangeString(),
                      ),
                      _buildInfoRow(
                        context,
                        Icons.view_week,
                        '共${semester.numberOfWeeks}周',
                      ),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showSemesterDialog(context, semester);
                      } else if (value == 'delete') {
                        _showDeleteConfirmDialog(context, semester);
                      } else if (value == 'active') {
                        _setActiveSemester(context, semester);
                      }
                    },
                    itemBuilder: (context) => [
                      if (!isActive)
                        const PopupMenuItem<String>(
                          value: 'active',
                          child: Row(
                            children: [
                              Icon(Icons.check_circle, size: 18),
                              SizedBox(width: 8),
                              Text('设为当前学期'),
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
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('删除', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showSemesterDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  // 构建信息行
  Widget _buildInfoRow(BuildContext context, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 显示学期表单对话框
  void _showSemesterDialog(BuildContext context, [Semester? semester]) {
    final isEditing = semester != null;
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(
      text: isEditing ? semester.name : '',
    );
    var startDate = isEditing ? semester.startDate : DateTime.now();
    var numberOfWeeks = isEditing ? semester.numberOfWeeks : 20;
    var isActive = isEditing ? semester.isActive : false;
    
    // 格式化日期的函数
    String formatDate(DateTime date) {
      return DateFormat('yyyy年MM月dd日').format(date);
    }
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(isEditing ? '编辑学期' : '添加学期'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 学期名称
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: '学期名称',
                        hintText: '例如：大二学年第一学期',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请输入学期名称';
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
                          Text(formatDate(startDate)),
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
                    const SizedBox(height: 16),
                    
                    // 当前学期
                    if (Provider.of<ScheduleProvider>(context, listen: false).semesters.isEmpty || !isEditing || !semester.isActive)
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('设为当前学期'),
                        value: isActive,
                        onChanged: (value) {
                          setState(() {
                            isActive = value ?? false;
                          });
                        },
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
                    _saveSemester(
                      context,
                      isEditing ? semester.id : null,
                      nameController.text.trim(),
                      startDate,
                      numberOfWeeks,
                      isActive,
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

  // 保存学期
  void _saveSemester(
    BuildContext context,
    int? id,
    String name,
    DateTime startDate,
    int numberOfWeeks,
    bool isActive,
  ) async {
    final provider = Provider.of<ScheduleProvider>(context, listen: false);
    
    // 如果设置为当前学期，需要将其他学期的活动状态设为false
    if (isActive) {
      for (var semester in provider.semesters) {
        if (semester.id != id && semester.isActive) {
          await provider.updateSemester(semester.copyWith(isActive: false));
        }
      }
    }
    
    // 使用fromAnyDay工厂方法创建学期，确保学期开始日期一定是周一
    final semester = Semester.fromAnyDay(
      id: id,
      name: name,
      anyDayInFirstWeek: startDate,
      numberOfWeeks: numberOfWeeks,
      isActive: isActive,
    );
    
    try {
      if (id == null) {
        await provider.addSemester(semester);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('学期已添加')),
          );
        }
      } else {
        await provider.updateSemester(semester);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('学期已更新')),
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
  void _showDeleteConfirmDialog(BuildContext context, Semester semester) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除学期"${semester.name}"吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteSemester(context, semester);
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

  // 删除学期
  void _deleteSemester(BuildContext context, Semester semester) async {
    try {
      final provider = Provider.of<ScheduleProvider>(context, listen: false);
      await provider.deleteSemester(semester.id!);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已删除学期"${semester.name}"')),
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

  // 设置活动学期
  void _setActiveSemester(BuildContext context, Semester semester) async {
    try {
      final provider = Provider.of<ScheduleProvider>(context, listen: false);
      
      // 先将所有学期设为非活动
      for (var s in provider.semesters) {
        if (s.isActive) {
          await provider.updateSemester(s.copyWith(isActive: false));
        }
      }
      
      // 设置当前学期为活动学期
      await provider.updateSemester(semester.copyWith(isActive: true));
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已将"${semester.name}"设为当前学期')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('设置失败: $e')),
        );
      }
    }
  }
} 