import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/course_import_service.dart';
import '../providers/schedule_provider.dart';

/// 课程导入界面
class CourseImportScreen extends StatefulWidget {
  const CourseImportScreen({super.key});

  @override
  State<CourseImportScreen> createState() => _CourseImportScreenState();
}

class _CourseImportScreenState extends State<CourseImportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _importCourses() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await CourseImportService.getFullSchedule(
        _usernameController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;

      if (result.success) {
        // 显示导入预览对话框
        _showImportPreviewDialog(result);
      } else {
        _showErrorDialog(result.error ?? '导入失败');
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('导入失败: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showImportPreviewDialog(CourseImportResult result) {
    final scheduleProvider = Provider.of<ScheduleProvider>(context, listen: false);
    final existingCourses = scheduleProvider.courses;
    final hasExistingCourses = existingCourses.isNotEmpty;

    // 检测重复课程
    final duplicateCourses = scheduleProvider.findDuplicateCourses(result.courses!);
    final hasDuplicates = duplicateCourses.isNotEmpty;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('导入预览'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('学期开始日期: ${result.semesterStartDate}'),
              Text('当前第 ${result.currentWeek} 周'),
              Text('课程总数: ${result.totalCourses} 门'),
              
              // 显示重复课程警告（优先显示）
              if (hasDuplicates) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    border: Border.all(color: Colors.red.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber,
                        color: Colors.red.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '检测到重复课程',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade700,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '发现 ${duplicateCourses.length} 门课程与现有课程重复（相同名称、时间、周次）。追加导入时将自动跳过重复课程。',
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              // 显示覆盖警告
              if (hasExistingCourses && !hasDuplicates) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    border: Border.all(color: Colors.orange.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning,
                        color: Colors.orange.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '注意事项',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade700,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '当前课表中已有 ${existingCourses.length} 门课程。导入将添加新课程，不会删除现有课程。',
                              style: TextStyle(
                                color: Colors.orange.shade700,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // 学期日期同步提示
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  border: Border.all(color: Colors.blue.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.sync,
                      color: Colors.blue.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '导入时将自动同步学期开始日期，确保周次显示正确。',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              const Text('即将导入以下课程:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Flexible(
                child: SizedBox(
                  height: 200,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: result.courses!.length,
                    itemBuilder: (context, index) {
                      final course = result.courses![index];
                      final isDuplicate = duplicateCourses.contains(course);
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        color: isDuplicate ? Colors.red.shade50 : null,
                        child: ListTile(
                          dense: true,
                          leading: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: isDuplicate ? Colors.grey : course.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  course.name,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDuplicate ? Colors.grey : null,
                                    decoration: isDuplicate ? TextDecoration.lineThrough : null,
                                  ),
                                ),
                              ),
                              if (isDuplicate)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade100,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '重复',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.red.shade700,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Text(
                            '${course.teacher ?? ''} | ${course.location ?? ''}\n'
                            '周${course.dayOfWeek} 第${course.classHours.join('-')}节',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDuplicate ? Colors.grey : null,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          if (hasExistingCourses)
            TextButton(
              onPressed: () => _showImportOptionsDialog(result, duplicateCourses),
              child: const Text('选择导入方式'),
            )
          else
            ElevatedButton(
              onPressed: () => _confirmImport(result, false),
              child: const Text('确认导入'),
            ),
        ],
      ),
    );
  }

  void _showImportOptionsDialog(CourseImportResult result, List<dynamic> duplicateCourses) {
    Navigator.of(context).pop(); // 关闭预览对话框
    
    final hasDuplicates = duplicateCourses.isNotEmpty;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择导入方式'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('请选择如何处理现有课程：'),
            const SizedBox(height: 16),
            Text(
              hasDuplicates 
                ? '• 追加导入：保留现有课程，添加新课程（自动跳过 ${duplicateCourses.length} 门重复课程）\n'
                  '• 覆盖导入：删除所有现有课程，只保留导入的课程'
                : '• 追加导入：保留现有课程，添加新课程\n'
                  '• 覆盖导入：删除所有现有课程，只保留导入的课程',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _confirmImport(result, false); // 追加导入
            },
            child: Text(hasDuplicates 
              ? '追加导入 (跳过重复)' 
              : '追加导入'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showOverwriteConfirmDialog(result);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('覆盖导入'),
          ),
        ],
      ),
    );
  }

  void _showOverwriteConfirmDialog(CourseImportResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认覆盖'),
        content: const Text(
          '此操作将删除所有现有课程，只保留本次导入的课程。\n\n'
          '此操作不可撤销，请确认是否继续？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _confirmImport(result, true); // 覆盖导入
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('确认覆盖'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmImport(CourseImportResult result, bool overwrite) async {
    Navigator.of(context).pop(); // 关闭预览对话框

    try {
      final scheduleProvider = Provider.of<ScheduleProvider>(context, listen: false);
      
      // 【修复 #4】同步学期开始日期
      if (result.semesterStartDate != null) {
        try {
          final startDate = DateTime.parse(result.semesterStartDate!);
          await scheduleProvider.updateCurrentScheduleStartDate(startDate);
        } catch (e) {
          debugPrint('同步学期日期失败: $e');
          // 日期同步失败不影响课程导入
        }
      }
      
      int importedCount;
      String message;
      
      if (overwrite) {
        // 覆盖导入：先清空再导入所有课程
        await scheduleProvider.overwriteCoursesBatch(result.courses!);
        importedCount = result.courses!.length;
        message = '成功覆盖导入 $importedCount 门课程';
      } else {
        // 【修复 #5】追加导入：过滤重复课程后再添加
        final nonDuplicateCourses = scheduleProvider.filterNonDuplicateCourses(result.courses!);
        final skippedCount = result.courses!.length - nonDuplicateCourses.length;
        
        if (nonDuplicateCourses.isNotEmpty) {
          await scheduleProvider.addCoursesBatch(nonDuplicateCourses);
        }
        
        importedCount = nonDuplicateCourses.length;
        
        if (skippedCount > 0) {
          message = '成功导入 $importedCount 门课程，跳过 $skippedCount 门重复课程';
        } else {
          message = '成功导入 $importedCount 门课程';
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(); // 返回上一级界面
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('保存课程失败: $e');
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('导入失败'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('导入课表'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Theme.of(context).primaryColor,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            '教务系统登录',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '请输入您的教务系统账号和密码，我们将从教务系统获取您的课表信息。',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: '学号',
                  hintText: '请输入您的学号',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入学号';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: '密码',
                  hintText: '请输入您的密码',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入密码';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _importCourses,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 12),
                          Text('正在导入课表...'),
                        ],
                      )
                    : const Text(
                        '导入课表',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
              const SizedBox(height: 16),
              Card(
                color: Colors.orange.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.security,
                        color: Colors.orange.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '您的账号信息仅用于获取课表，不会被保存或用于其他用途。',
                          style: TextStyle(
                            color: Colors.orange.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
