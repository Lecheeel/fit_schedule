import 'package:flutter/material.dart';
import '../utils/time_utils.dart';

class TimeColumn extends StatelessWidget {
  const TimeColumn({super.key});

  @override
  Widget build(BuildContext context) {
    // 使用LayoutBuilder来响应容器大小变化
    return LayoutBuilder(
      builder: (context, constraints) {
        // 动态计算宽度，保持与容器宽度一致
        final double columnWidth = constraints.maxWidth;
        
        // 计算单个课时格子的高度（基于当前可用高度而非屏幕高度）
        final double availableHeight = constraints.maxHeight;
        
        // 总共有11节课+2个休息时间，因此总共13行
        final double classHourHeight = (availableHeight / 13).clamp(25.0, 60.0);
        // 休息时间的高度可以比课时格子矮一些
        final double restHeight = (classHourHeight * 0.6).clamp(15.0, 30.0);
        
        // 根据可用高度动态调整字体大小
        final double fontSize = classHourHeight < 40 ? 9.0 : 11.0;
        final double smallFontSize = classHourHeight < 40 ? 8.0 : 9.0;
        
        // 创建所有行的集合（包括课时和休息时间）
        List<Widget> columnChildren = [];
        
        // 添加1-4节课
        for (int i = 1; i <= 4; i++) {
          columnChildren.add(_buildClassHourCell(
            context, i, classHourHeight, fontSize, smallFontSize
          ));
        }
        
        // 添加午休
        columnChildren.add(_buildRestCell(context, "午休", restHeight));
        
        // 添加5-8节课
        for (int i = 5; i <= 8; i++) {
          columnChildren.add(_buildClassHourCell(
            context, i, classHourHeight, fontSize, smallFontSize
          ));
        }
        
        // 添加晚休
        columnChildren.add(_buildRestCell(context, "晚休", restHeight));
        
        // 添加9-11节课
        for (int i = 9; i <= 11; i++) {
          columnChildren.add(_buildClassHourCell(
            context, i, classHourHeight, fontSize, smallFontSize
          ));
        }
        
        return SizedBox(
          width: columnWidth,
          child: Column(
            children: columnChildren,
          ),
        );
      }
    );
  }
  
  // 构建课时单元格
  Widget _buildClassHourCell(BuildContext context, int classHour, double height, double fontSize, double smallFontSize) {
    final startTime = TimeUtils.getClassStartTime(classHour);
    final endTime = TimeUtils.getClassEndTime(classHour);
    
    return Container(
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 0.5,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 1.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 使用FittedBox自动调整文本大小以适应可用空间
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '$classHour',
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 1), // 减小间距
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                TimeUtils.formatTimeOfDay(startTime),
                style: TextStyle(
                  fontSize: smallFontSize,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ),
            const SizedBox(height: 1), // 减小间距
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                TimeUtils.formatTimeOfDay(endTime),
                style: TextStyle(
                  fontSize: smallFontSize,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // 构建休息时间单元格
  Widget _buildRestCell(BuildContext context, String text, double height) {
    return Container(
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 0.5,
          ),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
} 