import 'package:intl/intl.dart';

class Semester {
  final int? id; // 数据库ID
  final String name; // 学期名称
  final DateTime startDate; // 开学日期（第一周的周一）
  final int numberOfWeeks; // 学期周数，默认20周
  final bool isActive; // 是否为当前学期

  Semester({
    this.id,
    required this.name,
    required this.startDate,
    this.numberOfWeeks = 20,
    this.isActive = false,
  });

  // 创建一个学期，自动计算给定日期所在周的周一作为学期开始日期
  factory Semester.fromAnyDay({
    int? id,
    required String name,
    required DateTime anyDayInFirstWeek,
    int numberOfWeeks = 20,
    bool isActive = false,
  }) {
    // 计算anyDayInFirstWeek所在周的周一日期
    // weekday: 1-7，对应周一到周日
    final int daysUntilMonday = (anyDayInFirstWeek.weekday - 1) % 7;
    final DateTime mondayOfWeek = anyDayInFirstWeek.subtract(Duration(days: daysUntilMonday));
    
    // 创建新的学期，以这个周一为开始日期
    return Semester(
      id: id,
      name: name,
      startDate: DateTime(mondayOfWeek.year, mondayOfWeek.month, mondayOfWeek.day),
      numberOfWeeks: numberOfWeeks,
      isActive: isActive,
    );
  }

  // 从数据库映射创建Semester对象
  factory Semester.fromMap(Map<String, dynamic> map) {
    return Semester(
      id: map['id'],
      name: map['name'],
      startDate: DateTime.parse(map['startDate']),
      numberOfWeeks: map['numberOfWeeks'],
      isActive: map['isActive'] == 1,
    );
  }

  // 转换为数据库映射
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'startDate': startDate.toIso8601String(),
      'numberOfWeeks': numberOfWeeks,
      'isActive': isActive ? 1 : 0,
    };
  }

  // 创建Semester对象的副本
  Semester copyWith({
    int? id,
    String? name,
    DateTime? startDate,
    int? numberOfWeeks,
    bool? isActive,
  }) {
    return Semester(
      id: id ?? this.id,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      numberOfWeeks: numberOfWeeks ?? this.numberOfWeeks,
      isActive: isActive ?? this.isActive,
    );
  }

  // 获取指定周次的日期范围
  WeekRange getWeekRange(int weekNumber) {
    if (weekNumber < 1 || weekNumber > numberOfWeeks) {
      throw ArgumentError('周次必须在1和$numberOfWeeks之间');
    }

    // 计算指定周的开始日期（周一）
    final weekStartDate = startDate.add(Duration(days: (weekNumber - 1) * 7));
    
    // 计算指定周的结束日期（周日）
    final weekEndDate = weekStartDate.add(const Duration(days: 6));

    return WeekRange(start: weekStartDate, end: weekEndDate);
  }

  // 计算指定日期是学期的第几周
  int getWeekNumber(DateTime date) {
    // 将日期转换为当天的00:00:00，避免时间部分影响计算
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final normalizedStartDate = DateTime(startDate.year, startDate.month, startDate.day);
    
    // 计算两个日期之间的天数差
    final difference = normalizedDate.difference(normalizedStartDate).inDays;
    
    // 计算周数（向下取整并加1）
    final weekNumber = (difference / 7).floor() + 1;
    
    // 检查计算的周数是否在学期范围内
    if (weekNumber < 1 || weekNumber > numberOfWeeks) {
      return 0; // 返回0表示不在学期内
    }
    
    return weekNumber;
  }

  // 返回学期开始和结束日期的格式化字符串
  String getDateRangeString() {
    final dateFormat = DateFormat('yyyy年MM月dd日');
    final endDate = startDate.add(Duration(days: 7 * numberOfWeeks - 1));
    return '${dateFormat.format(startDate)} - ${dateFormat.format(endDate)}';
  }
}

// 表示一周的日期范围
class WeekRange {
  final DateTime start; // 周一
  final DateTime end; // 周日

  WeekRange({required this.start, required this.end});

  @override
  String toString() {
    final dateFormat = DateFormat('yyyy-MM-dd');
    return '${dateFormat.format(start)} 至 ${dateFormat.format(end)}';
  }

  // 获取该周的所有日期
  List<DateTime> getAllDates() {
    return List.generate(
      7,
      (index) => start.add(Duration(days: index)),
    );
  }
} 