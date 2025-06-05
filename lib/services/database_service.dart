import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

import '../models/course.dart';
import '../models/semester.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

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
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'fit_schedule.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDatabase,
    );
  }

  // 创建数据库表
  Future<void> _createDatabase(Database db, int version) async {
    // 创建学期表
    await db.execute('''
      CREATE TABLE semesters(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        startDate TEXT NOT NULL,
        numberOfWeeks INTEGER NOT NULL,
        isActive INTEGER NOT NULL
      )
    ''');

    // 创建课程表
    await db.execute('''
      CREATE TABLE courses(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        teacher TEXT,
        location TEXT,
        color INTEGER NOT NULL,
        dayOfWeek INTEGER NOT NULL,
        classHours TEXT NOT NULL,
        weeks TEXT NOT NULL,
        note TEXT
      )
    ''');
  }

  // =============== 学期相关操作 ===============

  // 插入学期
  Future<int> insertSemester(Semester semester) async {
    final db = await database;
    
    // 如果当前学期被设置为激活状态，则先将其他所有学期设置为非激活状态
    if (semester.isActive) {
      await db.update(
        'semesters',
        {'isActive': 0},
        where: 'isActive = ?',
        whereArgs: [1],
      );
    }
    
    return await db.insert(
      'semesters',
      semester.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // 更新学期
  Future<int> updateSemester(Semester semester) async {
    final db = await database;
    
    // 如果当前学期被设置为激活状态，则先将其他所有学期设置为非激活状态
    if (semester.isActive) {
      await db.update(
        'semesters',
        {'isActive': 0},
        where: 'isActive = ?',
        whereArgs: [1],
      );
    }
    
    return await db.update(
      'semesters',
      semester.toMap(),
      where: 'id = ?',
      whereArgs: [semester.id],
    );
  }

  // 删除学期
  Future<int> deleteSemester(int id) async {
    final db = await database;
    return await db.delete(
      'semesters',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // 获取所有学期
  Future<List<Semester>> getAllSemesters() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('semesters');
    return List.generate(maps.length, (i) {
      return Semester.fromMap(maps[i]);
    });
  }

  // 获取当前激活的学期
  Future<Semester?> getActiveSemester() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'semesters',
      where: 'isActive = ?',
      whereArgs: [1],
    );

    if (maps.isEmpty) return null;
    return Semester.fromMap(maps.first);
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

  // 删除所有课程
  Future<int> deleteAllCourses() async {
    final db = await database;
    return await db.delete('courses');
  }

  // 获取所有课程
  Future<List<Course>> getAllCourses() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('courses');
    return List.generate(maps.length, (i) {
      return Course.fromMap(maps[i]);
    });
  }

  // 根据星期几获取课程
  Future<List<Course>> getCoursesByDay(int dayOfWeek) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'courses',
      where: 'dayOfWeek = ?',
      whereArgs: [dayOfWeek],
    );
    return List.generate(maps.length, (i) {
      return Course.fromMap(maps[i]);
    });
  }

  // 获取指定周次的所有课程
  Future<List<Course>> getCoursesByWeek(int weekNumber) async {
    final List<Course> allCourses = await getAllCourses();
    return allCourses.where((course) => course.isActiveInWeek(weekNumber)).toList();
  }

  // 获取指定周次和星期几的课程
  Future<List<Course>> getCoursesByWeekAndDay(int weekNumber, int dayOfWeek) async {
    final List<Course> coursesOnDay = await getCoursesByDay(dayOfWeek);
    return coursesOnDay.where((course) => course.isActiveInWeek(weekNumber)).toList();
  }
} 