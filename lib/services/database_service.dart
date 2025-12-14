import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

import '../models/course.dart';
import '../models/schedule.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  // 数据库版本
  static const int _databaseVersion = 2;

  // 单例模式
  factory DatabaseService() => _instance;

  DatabaseService._internal();

  // 获取数据库实例
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // 初始化数据库
  Future<Database> _initDatabase() async {
    // 使用标准的数据库路径，与 Android 小部件保持一致
    final databasesPath = await getDatabasesPath();
    final newPath = join(databasesPath, 'fit_schedule.db');

    // 检查是否需要迁移旧数据库
    await _migrateOldDatabaseIfNeeded(newPath);

    return await openDatabase(
      newPath,
      version: _databaseVersion,
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,
    );
  }

  // 迁移旧数据库（如果存在）
  Future<void> _migrateOldDatabaseIfNeeded(String newPath) async {
    try {
      final newFile = File(newPath);

      // 如果新位置已有数据库，则不需要迁移
      if (await newFile.exists()) {
        return;
      }

      // 检查旧位置是否有数据库
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final oldPath = join(documentsDirectory.path, 'fit_schedule.db');
      final oldFile = File(oldPath);

      if (await oldFile.exists()) {
        // 复制旧数据库到新位置
        await oldFile.copy(newPath);
        debugPrint('数据库已迁移: $oldPath -> $newPath');

        // 可选：删除旧数据库
        await oldFile.delete();
      }
    } catch (e) {
      debugPrint('数据库迁移失败（这是正常的，如果是首次安装）: $e');
    }
  }

  // 创建数据库表（新版本）
  Future<void> _createDatabase(Database db, int version) async {
    // 创建课表表（新）
    await db.execute('''
      CREATE TABLE schedules(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        startDate TEXT NOT NULL,
        numberOfWeeks INTEGER NOT NULL,
        isActive INTEGER NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');

    // 创建课程表（包含scheduleId）
    await db.execute('''
      CREATE TABLE courses(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        scheduleId INTEGER,
        name TEXT NOT NULL,
        teacher TEXT,
        location TEXT,
        color INTEGER NOT NULL,
        dayOfWeek INTEGER NOT NULL,
        classHours TEXT NOT NULL,
        weeks TEXT NOT NULL,
        note TEXT,
        FOREIGN KEY (scheduleId) REFERENCES schedules (id) ON DELETE CASCADE
      )
    ''');
  }

  // 数据库升级（从旧版本迁移）
  Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    debugPrint('数据库升级: $oldVersion -> $newVersion');

    if (oldVersion < 2) {
      // 从版本1升级到版本2：将semesters改为schedules，并在courses中添加scheduleId
      await _migrateToVersion2(db);
    }
  }

  // 迁移到版本2：课表系统
  Future<void> _migrateToVersion2(Database db) async {
    debugPrint('开始迁移到版本2（课表系统）...');

    try {
      // 1. 检查是否存在旧的semesters表
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='semesters'"
      );
      final hasSemestersTable = tables.isNotEmpty;

      // 2. 创建新的schedules表
      await db.execute('''
        CREATE TABLE IF NOT EXISTS schedules(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          startDate TEXT NOT NULL,
          numberOfWeeks INTEGER NOT NULL,
          isActive INTEGER NOT NULL,
          createdAt TEXT NOT NULL
        )
      ''');

      // 3. 检查courses表是否有scheduleId字段
      final courseColumns = await db.rawQuery('PRAGMA table_info(courses)');
      final hasScheduleId = courseColumns.any((col) => col['name'] == 'scheduleId');

      int? defaultScheduleId;

      // 4. 如果存在旧的semesters表，迁移数据
      if (hasSemestersTable) {
        final oldSemesters = await db.query('semesters');
        
        for (final semester in oldSemesters) {
          // 将旧的学期数据转换为课表
          final scheduleId = await db.insert('schedules', {
            'name': semester['name'],
            'startDate': semester['startDate'],
            'numberOfWeeks': semester['numberOfWeeks'],
            'isActive': semester['isActive'],
            'createdAt': DateTime.now().toIso8601String(),
          });

          // 记录活动学期的课表ID
          if (semester['isActive'] == 1) {
            defaultScheduleId = scheduleId;
          }
        }

        // 删除旧的semesters表
        await db.execute('DROP TABLE IF EXISTS semesters');
        debugPrint('已迁移 ${oldSemesters.length} 个学期到课表');
      }

      // 5. 如果courses表没有scheduleId字段，添加它
      if (!hasScheduleId) {
        // 添加scheduleId列
        await db.execute('ALTER TABLE courses ADD COLUMN scheduleId INTEGER');
        debugPrint('已在courses表中添加scheduleId字段');

        // 如果有默认课表，将现有课程关联到它
        if (defaultScheduleId != null) {
          await db.execute(
            'UPDATE courses SET scheduleId = ? WHERE scheduleId IS NULL',
            [defaultScheduleId]
          );
          debugPrint('已将现有课程关联到默认课表 ID: $defaultScheduleId');
        } else {
          // 如果没有课表但有课程，创建一个默认课表
          final existingCourses = await db.query('courses');
          if (existingCourses.isNotEmpty) {
            final newScheduleId = await db.insert('schedules', {
              'name': Schedule.generateSmartName(),
              'startDate': Schedule.estimateStartDate().toIso8601String(),
              'numberOfWeeks': 20,
              'isActive': 1,
              'createdAt': DateTime.now().toIso8601String(),
            });

            await db.execute(
              'UPDATE courses SET scheduleId = ? WHERE scheduleId IS NULL',
              [newScheduleId]
            );
            debugPrint('创建了默认课表并关联了 ${existingCourses.length} 门课程');
          }
        }
      }

      debugPrint('版本2迁移完成');
    } catch (e) {
      debugPrint('版本2迁移失败: $e');
      rethrow;
    }
  }

  // =============== 课表相关操作 ===============

  // 插入课表
  Future<int> insertSchedule(Schedule schedule) async {
    final db = await database;

    // 如果当前课表被设置为激活状态，则先将其他所有课表设置为非激活状态
    if (schedule.isActive) {
      await db.update(
        'schedules',
        {'isActive': 0},
        where: 'isActive = ?',
        whereArgs: [1],
      );
    }

    return await db.insert(
      'schedules',
      schedule.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // 更新课表
  Future<int> updateSchedule(Schedule schedule) async {
    final db = await database;

    // 如果当前课表被设置为激活状态，则先将其他所有课表设置为非激活状态
    if (schedule.isActive) {
      await db.update(
        'schedules',
        {'isActive': 0},
        where: 'isActive = ?',
        whereArgs: [1],
      );
    }

    return await db.update(
      'schedules',
      schedule.toMap(),
      where: 'id = ?',
      whereArgs: [schedule.id],
    );
  }

  // 删除课表（同时删除关联的课程）
  Future<int> deleteSchedule(int id) async {
    final db = await database;
    
    // 先删除关联的课程
    await db.delete(
      'courses',
      where: 'scheduleId = ?',
      whereArgs: [id],
    );
    
    // 再删除课表
    return await db.delete(
      'schedules',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // 获取所有课表
  Future<List<Schedule>> getAllSchedules() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'schedules',
      orderBy: 'createdAt DESC',
    );
    return List.generate(maps.length, (i) {
      return Schedule.fromMap(maps[i]);
    });
  }

  // 获取当前激活的课表
  Future<Schedule?> getActiveSchedule() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'schedules',
      where: 'isActive = ?',
      whereArgs: [1],
    );

    if (maps.isEmpty) return null;
    return Schedule.fromMap(maps.first);
  }

  // 设置活动课表
  Future<void> setActiveSchedule(int scheduleId) async {
    final db = await database;
    
    // 先将所有课表设为非活动
    await db.update(
      'schedules',
      {'isActive': 0},
    );
    
    // 再设置指定课表为活动
    await db.update(
      'schedules',
      {'isActive': 1},
      where: 'id = ?',
      whereArgs: [scheduleId],
    );
  }

  // 获取课表的课程数量
  Future<int> getScheduleCourseCount(int scheduleId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM courses WHERE scheduleId = ?',
      [scheduleId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // =============== 课程相关操作 ===============

  // 插入课程
  Future<int> insertCourse(Course course) async {
    final db = await database;
    return await db.insert(
      'courses',
      course.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // 更新课程
  Future<int> updateCourse(Course course) async {
    final db = await database;
    return await db.update(
      'courses',
      course.toMap(),
      where: 'id = ?',
      whereArgs: [course.id],
    );
  }

  // 删除课程
  Future<int> deleteCourse(int id) async {
    final db = await database;
    return await db.delete(
      'courses',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // 删除指定课表的所有课程
  Future<int> deleteAllCoursesBySchedule(int scheduleId) async {
    final db = await database;
    return await db.delete(
      'courses',
      where: 'scheduleId = ?',
      whereArgs: [scheduleId],
    );
  }

  // 删除所有课程（已废弃，请使用 deleteAllCoursesBySchedule）
  Future<int> deleteAllCourses() async {
    final db = await database;
    return await db.delete('courses');
  }

  // 获取所有课程（当前活动课表的）
  Future<List<Course>> getAllCourses() async {
    final activeSchedule = await getActiveSchedule();
    if (activeSchedule == null) return [];
    
    return await getCoursesBySchedule(activeSchedule.id!);
  }

  // 获取指定课表的所有课程
  Future<List<Course>> getCoursesBySchedule(int scheduleId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'courses',
      where: 'scheduleId = ?',
      whereArgs: [scheduleId],
    );
    return List.generate(maps.length, (i) {
      return Course.fromMap(maps[i]);
    });
  }

  // 根据ID获取单个课程
  Future<Course?> getCourseById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'courses',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) {
      return null;
    }

    return Course.fromMap(maps.first);
  }

  // 根据星期几获取课程（当前活动课表）
  Future<List<Course>> getCoursesByDay(int dayOfWeek) async {
    final activeSchedule = await getActiveSchedule();
    if (activeSchedule == null) return [];

    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'courses',
      where: 'scheduleId = ? AND dayOfWeek = ?',
      whereArgs: [activeSchedule.id, dayOfWeek],
    );
    return List.generate(maps.length, (i) {
      return Course.fromMap(maps[i]);
    });
  }

  // 获取指定周次的所有课程（当前活动课表）
  Future<List<Course>> getCoursesByWeek(int weekNumber) async {
    final List<Course> allCourses = await getAllCourses();
    return allCourses.where((course) => course.isActiveInWeek(weekNumber)).toList();
  }

  // 获取指定周次和星期几的课程
  Future<List<Course>> getCoursesByWeekAndDay(int weekNumber, int dayOfWeek) async {
    final List<Course> coursesOnDay = await getCoursesByDay(dayOfWeek);
    return coursesOnDay.where((course) => course.isActiveInWeek(weekNumber)).toList();
  }

  // =============== 兼容性方法（保留旧API，内部转发到新实现）===============

  // 以下方法为兼容旧代码保留，内部调用课表相关方法

  // 获取所有"学期"（实际返回课表）
  @Deprecated('请使用 getAllSchedules() 替代')
  Future<List<Schedule>> getAllSemesters() async {
    return getAllSchedules();
  }

  // 获取当前"学期"（实际返回活动课表）
  @Deprecated('请使用 getActiveSchedule() 替代')
  Future<Schedule?> getActiveSemester() async {
    return getActiveSchedule();
  }

  // 插入"学期"（实际插入课表）
  @Deprecated('请使用 insertSchedule() 替代')
  Future<int> insertSemester(dynamic semester) async {
    if (semester is Schedule) {
      return insertSchedule(semester);
    }
    throw ArgumentError('请使用Schedule类型');
  }

  // 更新"学期"（实际更新课表）
  @Deprecated('请使用 updateSchedule() 替代')
  Future<int> updateSemester(dynamic semester) async {
    if (semester is Schedule) {
      return updateSchedule(semester);
    }
    throw ArgumentError('请使用Schedule类型');
  }

  // 删除"学期"（实际删除课表）
  @Deprecated('请使用 deleteSchedule() 替代')
  Future<int> deleteSemester(int id) async {
    return deleteSchedule(id);
  }
}
