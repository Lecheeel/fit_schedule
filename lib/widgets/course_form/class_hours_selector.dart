import 'package:flutter/material.dart';

class ClassHoursSelector extends StatelessWidget {
  final List<int> selectedClassHours;
  final Function(List<int>) onClassHoursChanged;

  const ClassHoursSelector({
    super.key,
    required this.selectedClassHours,
    required this.onClassHoursChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '课时',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _showClassHoursDialog(context),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('选择'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (selectedClassHours.isEmpty)
              const Text('请选择上课时间')
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: selectedClassHours.map((hour) {
                  return Chip(
                    label: Text('第$hour节'),
                    onDeleted: () {
                      final updatedHours = List<int>.from(selectedClassHours)
                        ..remove(hour);
                      onClassHoursChanged(updatedHours);
                    },
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  // 显示课时选择对话框
  void _showClassHoursDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        // 创建临时选择状态
        List<int> tempSelected = List.from(selectedClassHours);
        
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('选择上课时间'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(11, (index) {
                        final hour = index + 1;
                        final isSelected = tempSelected.contains(hour);
                        return FilterChip(
                          label: Text('第$hour节'),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                tempSelected.add(hour);
                                tempSelected.sort();
                              } else {
                                tempSelected.remove(hour);
                              }
                            });
                          },
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '提示：请选择连续的课时，如第1-2节或第3-4节',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: () {
                    onClassHoursChanged(tempSelected);
                    Navigator.pop(context);
                  },
                  child: const Text('确定'),
                ),
              ],
            );
          },
        );
      },
    );
  }
} 