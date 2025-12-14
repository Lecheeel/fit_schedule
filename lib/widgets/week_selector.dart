import 'package:flutter/material.dart';

class WeekSelector extends StatefulWidget {
  final int currentWeek;
  final int selectedWeek;
  final int totalWeeks;
  final Function(int) onWeekSelected;
  
  // 新增：课表相关参数
  final String? scheduleName;
  final bool hasMultipleSchedules;
  final VoidCallback? onScheduleTap;

  const WeekSelector({
    super.key,
    required this.currentWeek,
    required this.selectedWeek,
    required this.totalWeeks,
    required this.onWeekSelected,
    this.scheduleName,
    this.hasMultipleSchedules = false,
    this.onScheduleTap,
  });

  @override
  State<WeekSelector> createState() => _WeekSelectorState();
}

class _WeekSelectorState extends State<WeekSelector> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    // 初始滚动到选中的周次位置
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedWeek();
    });
  }

  @override
  void didUpdateWidget(WeekSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedWeek != widget.selectedWeek) {
      _scrollToSelectedWeek();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToSelectedWeek() {
    if (!_scrollController.hasClients) return;

    const double itemWidth = 40.0;
    final double screenWidth = MediaQuery.of(context).size.width;
    // 考虑左右两侧按钮占用的空间
    final double availableWidth = screenWidth - 140; // 左右各约70px
    final double offset =
        (widget.selectedWeek - 1) * itemWidth - (availableWidth - itemWidth) / 2;

    // 确保滚动位置在有效范围内
    final double maxScroll = _scrollController.position.maxScrollExtent;
    const double minScroll = 0;
    final double normalizedOffset = offset.clamp(minScroll, maxScroll);

    _scrollController.animateTo(
      normalizedOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  // 判断是否在当前周
  bool get _isAtCurrentWeek => widget.selectedWeek == widget.currentWeek;

  // 判断当前周是否有效（在学期范围内）
  bool get _isCurrentWeekValid =>
      widget.currentWeek > 0 && widget.currentWeek <= widget.totalWeeks;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            spreadRadius: 0.5,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // 左侧：当前周指示器/回到当前周按钮
          if (_isCurrentWeekValid)
            _buildCurrentWeekIndicator(colorScheme),

          // 中间：周次选择滑动栏
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              itemCount: widget.totalWeeks,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              itemBuilder: (context, index) {
                final weekNumber = index + 1;
                final isSelected = weekNumber == widget.selectedWeek;
                final isCurrent = weekNumber == widget.currentWeek;

                return GestureDetector(
                  onTap: () => widget.onWeekSelected(weekNumber),
                  child: Container(
                    width: 40,
                    alignment: Alignment.center,
                    margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colorScheme.primary
                          : isCurrent
                              ? colorScheme.primaryContainer
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: isCurrent && !isSelected
                          ? Border.all(
                              color: colorScheme.primary.withOpacity(0.5),
                              width: 1.5,
                            )
                          : null,
                    ),
                    child: Text(
                      '$weekNumber',
                      style: TextStyle(
                        fontSize: 14,
                        color: isSelected
                            ? colorScheme.onPrimary
                            : isCurrent
                                ? colorScheme.primary
                                : colorScheme.onSurface,
                        fontWeight:
                            isSelected || isCurrent ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // 右侧：课表切换按钮
          if (widget.onScheduleTap != null)
            _buildScheduleSwitchButton(colorScheme),
        ],
      ),
    );
  }

  /// 构建当前周指示器按钮
  Widget _buildCurrentWeekIndicator(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isAtCurrentWeek ? null : () => widget.onWeekSelected(widget.currentWeek),
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _isAtCurrentWeek
                  ? colorScheme.primary
                  : colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(10),
              boxShadow: _isAtCurrentWeek
                  ? null
                  : [
                      BoxShadow(
                        color: colorScheme.primary.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _isAtCurrentWeek ? '当前周' : '回到',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    color: _isAtCurrentWeek
                        ? colorScheme.onPrimary.withOpacity(0.9)
                        : colorScheme.primary.withOpacity(0.8),
                  ),
                ),
                Text(
                  '第${widget.currentWeek}周',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _isAtCurrentWeek
                        ? colorScheme.onPrimary
                        : colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 构建课表切换按钮
  Widget _buildScheduleSwitchButton(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onScheduleTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_month,
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
                if (widget.hasMultipleSchedules) ...[
                  const SizedBox(width: 2),
                  Icon(
                    Icons.swap_horiz,
                    size: 14,
                    color: colorScheme.primary,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
