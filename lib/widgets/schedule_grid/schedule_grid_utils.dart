import '../../../models/course.dart';

/// 课表网格工具类
class ScheduleGridUtils {
  /// 检查两个课程时间是否重叠
  static bool coursesOverlap(List<int> hours1, List<int> hours2) {
    final set1 = hours1.toSet();
    final set2 = hours2.toSet();
    return set1.intersection(set2).isNotEmpty;
  }

  /// 计算课程卡片的Y位置（考虑午休和晚休）
  static double calculateTopPosition(int startClassHour, double classHourHeight, double restHeight) {
    double topPosition = 0;
    for (int i = 1; i < startClassHour; i++) {
      topPosition += classHourHeight;
      if (i == 4) topPosition += restHeight; // 午休
      if (i == 8) topPosition += restHeight; // 晚休
    }
    return topPosition;
  }

  /// 检查课程是否跨越休息时间
  static bool crossesBreakTime(List<int> classHours) {
    final hours = classHours.toSet();
    
    // 检查是否跨越午休（4-5节之间）
    final crossesLunchBreak = hours.any((h) => h <= 4) && hours.any((h) => h >= 5);
    
    // 检查是否跨越晚休（8-9节之间）
    final crossesEveningBreak = hours.any((h) => h <= 8) && hours.any((h) => h >= 9);
    
    return crossesLunchBreak || crossesEveningBreak;
  }

  /// 将跨越休息时间的课程拆分为多个时间段
  static List<List<int>> splitCourseAcrossBreaks(List<int> classHours) {
    if (!crossesBreakTime(classHours)) {
      return [classHours]; // 不需要拆分
    }

    final sortedHours = classHours.toList()..sort();
    List<List<int>> segments = [];
    List<int> currentSegment = [];

    for (int hour in sortedHours) {
      // 如果当前段为空，直接添加
      if (currentSegment.isEmpty) {
        currentSegment.add(hour);
        continue;
      }

      final lastHour = currentSegment.last;
      
      // 检查是否跨越午休时间（4->5）
      if (lastHour == 4 && hour == 5) {
        segments.add(List.from(currentSegment));
        currentSegment = [hour];
        continue;
      }
      
      // 检查是否跨越晚休时间（8->9）
      if (lastHour == 8 && hour == 9) {
        segments.add(List.from(currentSegment));
        currentSegment = [hour];
        continue;
      }
      
      // 连续的课时，添加到当前段
      currentSegment.add(hour);
    }

    // 添加最后一段
    if (currentSegment.isNotEmpty) {
      segments.add(currentSegment);
    }

    return segments;
  }

  /// 检查课程段是否为连续的时间
  static bool isConsecutiveHours(List<int> hours) {
    if (hours.length <= 1) return true;
    
    final sortedHours = hours.toList()..sort();
    for (int i = 1; i < sortedHours.length; i++) {
      if (sortedHours[i] != sortedHours[i - 1] + 1) {
        return false;
      }
    }
    return true;
  }

  /// 获取课程段的时间范围描述
  static String getSegmentTimeDescription(List<int> segment) {
    if (segment.isEmpty) return '';
    
    final sortedSegment = segment.toList()..sort();
    if (sortedSegment.length == 1) {
      return '第${sortedSegment.first}节';
    } else {
      return '第${sortedSegment.first}-${sortedSegment.last}节';
    }
  }

  /// 生成课程显示文本
  static String generateCourseDisplayText(Course course) {
    // 限制课程名称最多显示7个字符
    String courseName = course.name.length > 7 
        ? '${course.name.substring(0, 7)}...' 
        : course.name;
    
    String displayText = courseName;
    if (course.location != null && course.location!.isNotEmpty) {
      displayText += ' @${course.location!}';
    }
    return displayText;
  }

  /// 生成分段课程显示文本
  static String generateSegmentCourseDisplayText(Course course, List<int> segment, int segmentIndex) {
    // 限制课程名称最多显示8个字符
    String courseName = course.name.length > 8 
        ? '${course.name.substring(0, 8)}...' 
        : course.name;
    
    String displayText = courseName;
    
    if (segmentIndex == 0) {
      // 第一段显示课程名称和地点
      if (course.location != null && course.location!.isNotEmpty) {
        displayText += ' @${course.location!}';
      }
    } else {
      // 后续段只显示课程名称
      // 可以根据需要显示不同的信息
    }
    
    return displayText;
  }

  /// 按时间段分组课程
  static Map<String, List<Course>> groupCoursesByTimeSlot(List<Course> courses) {
    Map<String, List<Course>> groupedCourses = {};
    
    for (final course in courses) {
      final timeSlotKey = course.classHours.join('-');
      if (!groupedCourses.containsKey(timeSlotKey)) {
        groupedCourses[timeSlotKey] = [];
      }
      groupedCourses[timeSlotKey]!.add(course);
    }
    
    return groupedCourses;
  }

  /// 计算响应式尺寸
  /// 确保课表完全填充可用空间
  static Map<String, double> calculateResponsiveSizes(double availableHeight, double availableWidth) {
    // 课表结构：11节课 + 2个休息时间
    // 设 restHeight = classHourHeight * 0.55 (休息时间占课时高度的55%)
    // 总高度 = 11 * classHourHeight + 2 * 0.55 * classHourHeight = 12.1 * classHourHeight
    const double restRatio = 0.55;
    const double totalUnits = 11 + 2 * restRatio; // 12.1
    
    // 计算基础课时高度
    final double baseClassHourHeight = availableHeight / totalUnits;
    
    // 应用合理的限制范围，但允许更大的范围以适应屏幕
    final double classHourHeight = baseClassHourHeight.clamp(20.0, 80.0);
    final double restHeight = (classHourHeight * restRatio).clamp(12.0, 44.0);
    
    // 计算实际总高度
    final double actualTotalHeight = 11 * classHourHeight + 2 * restHeight;
    
    // 如果有高度差异，按比例调整以完全填充
    double finalClassHourHeight = classHourHeight;
    double finalRestHeight = restHeight;
    
    if (actualTotalHeight < availableHeight) {
      final double scaleFactor = availableHeight / actualTotalHeight;
      finalClassHourHeight = classHourHeight * scaleFactor;
      finalRestHeight = restHeight * scaleFactor;
    }
    
    final double timeColumnWidth = availableWidth < 400 ? 40.0 : 50.0;
    final double dayColumnWidth = (availableWidth - timeColumnWidth) / 7;
    
    return {
      'classHourHeight': finalClassHourHeight,
      'restHeight': finalRestHeight,
      'timeColumnWidth': timeColumnWidth,
      'dayColumnWidth': dayColumnWidth,
    };
  }
}
