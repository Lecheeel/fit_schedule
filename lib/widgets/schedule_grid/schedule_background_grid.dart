import 'package:flutter/material.dart';
import '../../utils/time_utils.dart';
import '../../utils/app_theme.dart';

/// 课表背景网格组件
class ScheduleBackgroundGrid extends StatelessWidget {
  final double timeColumnWidth;
  final double classHourHeight;
  final double restHeight;

  const ScheduleBackgroundGrid({
    super.key,
    required this.timeColumnWidth,
    required this.classHourHeight,
    required this.restHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 1-4节课网格
        ..._buildGridRows(context, 1, 4),
        
        // 午休
        _buildBreakRow(context, "午休"),
        
        // 5-8节课网格
        ..._buildGridRows(context, 5, 8),
        
        // 晚休
        _buildBreakRow(context, "晚休"),
        
        // 9-11节课网格
        ..._buildGridRows(context, 9, 11),
      ],
    );
  }

  /// 构建网格行
  List<Widget> _buildGridRows(BuildContext context, int startClass, int endClass) {
    List<Widget> rows = [];
    
    for (int classHour = startClass; classHour <= endClass; classHour++) {
      rows.add(_buildGridRow(context, classHour));
    }
    
    return rows;
  }

  /// 构建单个网格行
  Widget _buildGridRow(BuildContext context, int classHour) {    final startTime = TimeUtils.getClassStartTime(classHour);
    final endTime = TimeUtils.getClassEndTime(classHour);
    final fontSize = classHourHeight < 40 ? 9.0 : 11.0;
    final smallFontSize = classHourHeight < 40 ? 8.0 : 9.0;
    
    return Container(
      height: classHourHeight,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppTheme.gridLineColor,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 时间列
          Container(
            width: timeColumnWidth,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: AppTheme.gridLineColor,
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
                  const SizedBox(height: 1),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      TimeUtils.formatTimeOfDay(startTime),
                      style: TextStyle(
                        fontSize: smallFontSize,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),                    ),
                  ),
                  const SizedBox(height: 1),
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
          ),
          
          // 七天空白列（用于定位）
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: List.generate(7, (dayIndex) {
                return Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        right: dayIndex < 6 ? BorderSide(
                          color: AppTheme.gridLineColor,
                          width: 0.5,
                        ) : BorderSide.none,
                      ),
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

  /// 构建休息时间行（跨列显示）
  Widget _buildBreakRow(BuildContext context, String text) {
    return Container(
      height: restHeight,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.gridLineColor,
            width: 0.5,
          ),
        ),
      ),      child: Row(
        children: [
          // 保持时间列的宽度一致性
          Container(
            width: timeColumnWidth,
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: AppTheme.gridLineColor,
                  width: 0.5,
                ),
              ),
            ),
          ),
          // 跨列显示休息时间
          Expanded(
            child: Container(
              alignment: Alignment.center,
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}