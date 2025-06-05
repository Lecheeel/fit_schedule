import 'package:flutter/material.dart';

class WeeksSelector extends StatelessWidget {
  final List<int> selectedWeeks;
  final Function(List<int>) onWeeksChanged;

  const WeeksSelector({
    super.key,
    required this.selectedWeeks,
    required this.onWeeksChanged,
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
                  '周次',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _showWeeksDialog(context),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('选择'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (selectedWeeks.isEmpty)
              const Text('请选择上课周次')
            else
              Text(
                '已选择 ${_formatWeeks(selectedWeeks)} 周',
                style: const TextStyle(fontSize: 14),
              ),
          ],
        ),
      ),
    );
  }

  // 显示周次选择对话框
  void _showWeeksDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        // 创建临时选择状态
        List<int> tempSelected = List.from(selectedWeeks);
        
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('选择上课周次'),
              content: SizedBox(
                width: double.maxFinite,
                height: 300,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton(
                          onPressed: () {
                            setState(() {
                              tempSelected = List.generate(20, (i) => i + 1);
                            });
                          },
                          child: const Text('全选'),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              tempSelected = List.generate(10, (i) => i + 1);
                            });
                          },
                          child: const Text('前10周'),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              tempSelected = List.generate(10, (i) => i + 11);
                            });
                          },
                          child: const Text('后10周'),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              tempSelected.clear();
                            });
                          },
                          child: const Text('清空'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 5,
                          childAspectRatio: 1.5,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: 20,
                        itemBuilder: (context, index) {
                          final week = index + 1;
                          final isSelected = tempSelected.contains(week);
                          return InkWell(
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  tempSelected.remove(week);
                                } else {
                                  tempSelected.add(week);
                                  tempSelected.sort();
                                }
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : null,
                                border: Border.all(
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).dividerColor,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Center(
                                child: Text(
                                  '$week',
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : null,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '已选择 ${_formatWeeks(tempSelected)} 周',
                      style: const TextStyle(fontSize: 14),
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
                    onWeeksChanged(tempSelected);
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

  // 格式化周次
  String _formatWeeks(List<int> weeks) {
    if (weeks.isEmpty) return '';
    
    // 先排序
    weeks.sort();
    
    // 处理连续的周次
    final formattedWeeks = <String>[];
    int start = weeks[0];
    int end = start;
    
    for (int i = 1; i < weeks.length; i++) {
      if (weeks[i] == end + 1) {
        end = weeks[i];
      } else {
        formattedWeeks.add(start == end ? '$start' : '$start-$end');
        start = end = weeks[i];
      }
    }
    
    formattedWeeks.add(start == end ? '$start' : '$start-$end');
    
    return formattedWeeks.join('、');
  }
} 