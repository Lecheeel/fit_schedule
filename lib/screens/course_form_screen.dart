import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/course.dart';
import '../providers/schedule_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/course_form/color_picker_widget.dart';
import '../widgets/course_form/day_of_week_selector.dart';
import '../widgets/course_form/class_hours_selector.dart';
import '../widgets/course_form/weeks_selector.dart';

class CourseFormScreen extends StatefulWidget {
  final Course? course;

  const CourseFormScreen({super.key, this.course});

  @override
  State<CourseFormScreen> createState() => _CourseFormScreenState();
}

class _CourseFormScreenState extends State<CourseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _teacherController = TextEditingController();
  final _locationController = TextEditingController();
  final _noteController = TextEditingController();
  
  Color _selectedColor = AppTheme.defaultCourseColors[0];
  int _selectedDayOfWeek = 1;
  List<int> _selectedClassHours = [];
  List<int> _selectedWeeks = [];
  
  bool get _isEditing => widget.course != null;

  @override
  void initState() {
    super.initState();
    
    if (_isEditing) {
      // 如果是编辑模式，填充表单
      final course = widget.course!;
      _nameController.text = course.name;
      _teacherController.text = course.teacher ?? '';
      _locationController.text = course.location ?? '';
      _noteController.text = course.note ?? '';
      _selectedColor = course.color;
      _selectedDayOfWeek = course.dayOfWeek;
      _selectedClassHours = List.from(course.classHours);
      _selectedWeeks = List.from(course.weeks);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _teacherController.dispose();
    _locationController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '编辑课程' : '添加课程'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 课程名称
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '课程名称',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.book),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入课程名称';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // 教师
            TextFormField(
              controller: _teacherController,
              decoration: const InputDecoration(
                labelText: '教师（可选）',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            
            // 上课地点
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: '上课地点（可选）',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
            ),
            const SizedBox(height: 16),
            
            // 课程颜色选择
            ColorPickerWidget(
              selectedColor: _selectedColor,
              onColorChanged: (color) {
                setState(() {
                  _selectedColor = color;
                });
              },
            ),
            const SizedBox(height: 16),
            
            // 星期选择
            DayOfWeekSelector(
              selectedDayOfWeek: _selectedDayOfWeek,
              onDaySelected: (day) {
                setState(() {
                  _selectedDayOfWeek = day;
                });
              },
            ),
            const SizedBox(height: 16),
            
            // 课时选择
            ClassHoursSelector(
              selectedClassHours: _selectedClassHours,
              onClassHoursChanged: (hours) {
                setState(() {
                  _selectedClassHours = hours;
                });
              },
            ),
            const SizedBox(height: 16),
            
            // 周次选择
            WeeksSelector(
              selectedWeeks: _selectedWeeks,
              onWeeksChanged: (weeks) {
                setState(() {
                  _selectedWeeks = weeks;
                });
              },
            ),
            const SizedBox(height: 16),
            
            // 备注
            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: '备注（可选）',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            
            // 保存按钮
            ElevatedButton.icon(
              onPressed: _saveCourse,
              icon: const Icon(Icons.save),
              label: const Text('保存'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 保存课程
  void _saveCourse() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    // 验证必填项
    if (_selectedClassHours.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择上课时间')),
      );
      return;
    }
    
    if (_selectedWeeks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择上课周次')),
      );
      return;
    }
    
    // 创建课程对象
    final course = Course(
      id: _isEditing ? widget.course!.id : null,
      scheduleId: _isEditing ? widget.course!.scheduleId : null,
      name: _nameController.text.trim(),
      teacher: _teacherController.text.trim().isEmpty
          ? null
          : _teacherController.text.trim(),
      location: _locationController.text.trim().isEmpty
          ? null
          : _locationController.text.trim(),
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      color: _selectedColor,
      dayOfWeek: _selectedDayOfWeek,
      classHours: _selectedClassHours,
      weeks: _selectedWeeks,
    );
    
    try {
      final provider = Provider.of<ScheduleProvider>(context, listen: false);
      
      if (_isEditing) {
        await provider.updateCourse(course);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('课程已更新')),
          );
          Navigator.pop(context);
        }
      } else {
        await provider.addCourse(course);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('课程已添加')),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    }
  }
}
