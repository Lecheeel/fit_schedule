import 'package:flutter/material.dart';
import '../../utils/time_utils.dart';

class DayOfWeekSelector extends StatelessWidget {
  final int selectedDayOfWeek;
  final Function(int) onDaySelected;

  const DayOfWeekSelector({
    super.key,
    required this.selectedDayOfWeek,
    required this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '星期',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(7, (index) {
                final dayOfWeek = index + 1;
                final isSelected = selectedDayOfWeek == dayOfWeek;
                return ChoiceChip(
                  label: Text(TimeUtils.getDayOfWeekName(dayOfWeek)),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      onDaySelected(dayOfWeek);
                    }
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
} 