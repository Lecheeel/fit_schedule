import 'package:flutter/material.dart';
import '../utils/time_utils.dart';

class DateHeader extends StatelessWidget {
  final List<DateTime> weekDates;

  const DateHeader({
    super.key,
    required this.weekDates,
  });

  @override
  Widget build(BuildContext context) {
    // 使用LayoutBuilder响应尺寸变化
    return LayoutBuilder(
      builder: (context, constraints) {
        // 根据可用宽度动态调整时间列宽度
        final timeColumnWidth = constraints.maxWidth < 400 ? 40.0 : 50.0;
        // 根据宽度动态调整字体大小
        final double dayNameFontSize = constraints.maxWidth < 360 ? 9.0 : 11.0;
        final double dateFontSize = constraints.maxWidth < 360 ? 8.0 : 9.0;
        
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 4), 
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
          child: Row(
            children: [
              // 时间列
              SizedBox(
                width: timeColumnWidth,
                child: Center(
                  child: Text(
                    '时间',
                    style: TextStyle(
                      fontSize: dayNameFontSize,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
              
              // 日期列
              Expanded(
                child: Row(
                  children: List.generate(7, (index) {
                    final date = weekDates[index];
                    final isToday = _isToday(date);
                    
                    return Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        decoration: isToday
                            ? BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              )
                            : null,
                        child: Column(
                          children: [
                            // 使用FittedBox确保文本在小尺寸时不溢出
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                TimeUtils.getDayOfWeekName(index + 1),
                                style: TextStyle(
                                  fontSize: dayNameFontSize,
                                  fontWeight: FontWeight.bold,
                                  color: isToday 
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '${date.month}/${date.day}',
                                style: TextStyle(
                                  fontSize: dateFontSize,
                                  color: isToday 
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        );
      }
    );
  }

  // 检查日期是否为今天
  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }
} 