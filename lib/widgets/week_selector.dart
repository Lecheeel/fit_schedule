import 'package:flutter/material.dart';

class WeekSelector extends StatefulWidget {
  final int currentWeek;
  final int selectedWeek;
  final int totalWeeks;
  final Function(int) onWeekSelected;

  const WeekSelector({
    super.key,
    required this.currentWeek,
    required this.selectedWeek,
    required this.totalWeeks,
    required this.onWeekSelected,
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
    
    final double itemWidth = 40.0;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double offset = (widget.selectedWeek - 1) * itemWidth - (screenWidth - itemWidth) / 2;
    
    // 确保滚动位置在有效范围内
    final double maxScroll = _scrollController.position.maxScrollExtent;
    final double minScroll = 0;
    final double normalizedOffset = offset.clamp(minScroll, maxScroll);
    
    _scrollController.animateTo(
      normalizedOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
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
          // 当前选中周显示
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            margin: const EdgeInsets.only(left: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '第${widget.selectedWeek}周',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ),
          
          // 周次选择滑动栏
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              itemCount: widget.totalWeeks,
              padding: const EdgeInsets.only(left: 8),
              itemBuilder: (context, index) {
                final weekNumber = index + 1;
                final isSelected = weekNumber == widget.selectedWeek;
                final isCurrent = weekNumber == widget.currentWeek;
                
                return GestureDetector(
                  onTap: () => widget.onWeekSelected(weekNumber),
                  child: Container(
                    width: 40,
                    alignment: Alignment.center,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : isCurrent
                              ? Theme.of(context).colorScheme.primaryContainer
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '$weekNumber',
                      style: TextStyle(
                        fontSize: 13,
                        color: isSelected
                            ? Colors.white
                            : isCurrent
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.onSurface,
                        fontWeight: isSelected || isCurrent ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // 显示当前周按钮
          if (widget.currentWeek > 0 && widget.currentWeek <= widget.totalWeeks)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => widget.onWeekSelected(widget.currentWeek),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '当前周',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
} 