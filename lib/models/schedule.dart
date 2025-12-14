import 'package:intl/intl.dart';

/// 课表模型
/// 每个课表包含学期时间信息和关联的课程
class Schedule {
  final int? id; // 数据库ID
  final String name; // 课表名称（如"2024-2025学年第一学期课表"）
  final DateTime startDate; // 学期开始日期（第一周的周一）
  final int numberOfWeeks; // 学期周数，默认20周
  final bool isActive; // 是否为当前活动课表
  final DateTime createdAt; // 创建时间

  Schedule({
    this.id,
    required this.name,
    required this.startDate,
    this.numberOfWeeks = 20,
    this.isActive = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// 智能生成课表名称
  /// 根据当前日期自动计算学年和学期
  static String generateSmartName([DateTime? date]) {
    final now = date ?? DateTime.now();
    final year = now.year;
    final month = now.month;

    if (month >= 9 || month == 1) {
      // 第一学期 (9月-1月)
      final startYear = month >= 9 ? year : year - 1;
      return '$startYear-${startYear + 1}学年第一学期课表';
    } else {
      // 第二学期 (2月-8月)
      return '${year - 1}-$year学年第二学期课表';
    }
  }

  /// 智能计算学期开始日期
  /// 根据当前日期估算学期开始的周一
  static DateTime estimateStartDate([DateTime? date]) {
    final now = date ?? DateTime.now();
    final year = now.year;
    final month = now.month;

    DateTime semesterStart;
    if (month >= 9 || month == 1) {
      // 第一学期通常在9月初开始
      final startYear = month >= 9 ? year : year - 1;
      semesterStart = DateTime(startYear, 9, 1);
    } else {
      // 第二学期通常在2月底/3月初开始
      semesterStart = DateTime(year, 2, 20);
    }

    // 计算该日期所在周的周一
    final int daysUntilMonday = (semesterStart.weekday - 1) % 7;
    return semesterStart.subtract(Duration(days: daysUntilMonday));
  }

  /// 创建一个课表，自动计算给定日期所在周的周一作为学期开始日期
  factory Schedule.fromAnyDay({
    int? id,
    required String name,
    required DateTime anyDayInFirstWeek,
    int numberOfWeeks = 20,
    bool isActive = false,
    DateTime? createdAt,
  }) {
    // 计算anyDayInFirstWeek所在周的周一日期
    final int daysUntilMonday = (anyDayInFirstWeek.weekday - 1) % 7;
    final DateTime mondayOfWeek =
        anyDayInFirstWeek.subtract(Duration(days: daysUntilMonday));

    return Schedule(
      id: id,
      name: name,
      startDate: DateTime(mondayOfWeek.year, mondayOfWeek.month, mondayOfWeek.day),
      numberOfWeeks: numberOfWeeks,
      isActive: isActive,
      createdAt: createdAt,
    );
  }

  /// 创建智能课表（自动命名和估算日期）
  factory Schedule.smart({
    int? id,
    bool isActive = false,
    DateTime? createdAt,
  }) {
    final name = generateSmartName();
    final startDate = estimateStartDate();

    return Schedule(
      id: id,
      name: name,
      startDate: startDate,
      numberOfWeeks: 20,
      isActive: isActive,
      createdAt: createdAt,
    );
  }

  /// 从数据库映射创建Schedule对象
  factory Schedule.fromMap(Map<String, dynamic> map) {
    return Schedule(
      id: map['id'],
      name: map['name'],
      startDate: DateTime.parse(map['startDate']),
      numberOfWeeks: map['numberOfWeeks'],
      isActive: map['isActive'] == 1,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }

  /// 转换为数据库映射
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'startDate': startDate.toIso8601String(),
      'numberOfWeeks': numberOfWeeks,
      'isActive': isActive ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// 创建Schedule对象的副本
  Schedule copyWith({
    int? id,
    String? name,
    DateTime? startDate,
    int? numberOfWeeks,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return Schedule(
      id: id ?? this.id,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      numberOfWeeks: numberOfWeeks ?? this.numberOfWeeks,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// 获取指定周次的日期范围
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

  /// 计算指定日期是学期的第几周
  int getWeekNumber(DateTime date) {
    // 将日期转换为当天的00:00:00，避免时间部分影响计算
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final normalizedStartDate =
        DateTime(startDate.year, startDate.month, startDate.day);

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

  /// 返回学期开始和结束日期的格式化字符串
  String getDateRangeString() {
    final dateFormat = DateFormat('yyyy年MM月dd日');
    final endDate = startDate.add(Duration(days: 7 * numberOfWeeks - 1));
    return '${dateFormat.format(startDate)} - ${dateFormat.format(endDate)}';
  }

  /// 获取课表简短描述
  String get shortDescription {
    return '$numberOfWeeks周 · ${DateFormat('yyyy/MM/dd').format(startDate)}起';
  }
}

/// 表示一周的日期范围
class WeekRange {
  final DateTime start; // 周一
  final DateTime end; // 周日

  WeekRange({required this.start, required this.end});

  @override
  String toString() {
    final dateFormat = DateFormat('yyyy-MM-dd');
    return '${dateFormat.format(start)} 至 ${dateFormat.format(end)}';
  }

  /// 获取该周的所有日期
  List<DateTime> getAllDates() {
    return List.generate(
      7,
      (index) => start.add(Duration(days: index)),
    );
  }
}
