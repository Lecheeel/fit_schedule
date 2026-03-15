import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/account.dart';
import '../providers/schedule_provider.dart';

class AccountManagementScreen extends StatefulWidget {
  const AccountManagementScreen({super.key});

  @override
  State<AccountManagementScreen> createState() =>
      _AccountManagementScreenState();
}

class _AccountManagementScreenState extends State<AccountManagementScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('账号管理'),
      ),
      body: Consumer<ScheduleProvider>(
        builder: (context, provider, _) {
          final accounts = provider.accounts;

          if (accounts.isEmpty) {
            return _buildEmptyState(context);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: accounts.length,
            itemBuilder: (context, index) {
              final account = accounts[index];
              return _buildAccountCard(context, account, provider);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddAccountDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_circle_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            '暂无保存的账号',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '添加教务系统账号后可快速更新课表',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _showAddAccountDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('添加账号'),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountCard(
    BuildContext context,
    Account account,
    ScheduleProvider provider,
  ) {
    final isCurrentSchedule =
        provider.currentSchedule?.id == account.scheduleId &&
            account.scheduleId != null;

    // 查找关联的课表名称
    String? scheduleName;
    if (account.scheduleId != null) {
      try {
        final schedule = provider.schedules.firstWhere(
          (s) => s.id == account.scheduleId,
        );
        scheduleName = schedule.name;
      } catch (_) {
        scheduleName = null;
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          if (isCurrentSchedule)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 4),
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Center(
                child: Text(
                  '当前使用',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: isCurrentSchedule
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Icon(
                Icons.person,
                color: isCurrentSchedule
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            title: Text(
              account.displayName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('学号: ${account.username}'),
                if (scheduleName != null)
                  Text(
                    '课表: $scheduleName',
                    style: const TextStyle(fontSize: 12),
                  ),
                if (account.lastSyncAt != null)
                  Text(
                    '上次同步: ${DateFormat('yyyy-MM-dd HH:mm').format(account.lastSyncAt!)}',
                    style: const TextStyle(fontSize: 12),
                  ),
              ],
            ),
            isThreeLine: true,
            trailing: PopupMenuButton<String>(
              onSelected: (value) =>
                  _onMenuSelected(context, value, account, provider),
              itemBuilder: (context) => [
                if (!isCurrentSchedule && account.scheduleId != null)
                  const PopupMenuItem(
                    value: 'switch',
                    child: ListTile(
                      leading: Icon(Icons.swap_horiz),
                      title: Text('切换到此课表'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                const PopupMenuItem(
                  value: 'sync',
                  child: ListTile(
                    leading: Icon(Icons.sync),
                    title: Text('更新课表'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                    leading: Icon(Icons.edit),
                    title: Text('编辑账号'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete, color: Colors.red),
                    title: Text('删除账号', style: TextStyle(color: Colors.red)),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _syncAccount(context, account, provider),
                    icon: const Icon(Icons.sync, size: 18),
                    label: const Text('更新课表'),
                  ),
                ),
                if (!isCurrentSchedule && account.scheduleId != null) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () =>
                          _switchToAccount(context, account, provider),
                      icon: const Icon(Icons.swap_horiz, size: 18),
                      label: const Text('切换'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onMenuSelected(
    BuildContext context,
    String value,
    Account account,
    ScheduleProvider provider,
  ) {
    switch (value) {
      case 'switch':
        _switchToAccount(context, account, provider);
        break;
      case 'sync':
        _syncAccount(context, account, provider);
        break;
      case 'edit':
        _showEditAccountDialog(context, account);
        break;
      case 'delete':
        _showDeleteConfirmDialog(context, account, provider);
        break;
    }
  }

  Future<void> _switchToAccount(
    BuildContext context,
    Account account,
    ScheduleProvider provider,
  ) async {
    if (account.scheduleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('此账号尚未关联课表，请先更新课表')),
      );
      return;
    }

    try {
      await provider.switchToAccountSchedule(account);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已切换到 ${account.displayName} 的课表')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('切换失败: $e')),
        );
      }
    }
  }

  Future<void> _syncAccount(
    BuildContext context,
    Account account,
    ScheduleProvider provider,
  ) async {
    // 显示确认对话框
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('更新课表'),
        content: Text(
          '将使用账号 ${account.displayName} 从教务系统获取最新课表。\n\n'
          '${account.scheduleId != null ? '这将覆盖该账号关联课表的所有课程。' : '将创建新课表并关联到此账号。'}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确认更新'),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    _showSyncProgressDialog(context);

    try {
      final message = await provider.syncScheduleWithAccount(account);
      if (context.mounted) {
        Navigator.pop(context); // 关闭进度对话框
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // 关闭进度对话框
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('同步失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showSyncProgressDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('正在从教务系统获取课表...'),
          ],
        ),
      ),
    );
  }

  void _showAddAccountDialog(BuildContext context) {
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    final nicknameController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool obscurePassword = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('添加账号'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: usernameController,
                  decoration: const InputDecoration(
                    labelText: '学号',
                    hintText: '请输入学号',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? '请输入学号' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  decoration: InputDecoration(
                    labelText: '密码',
                    hintText: '请输入密码',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off),
                      onPressed: () => setDialogState(
                          () => obscurePassword = !obscurePassword),
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? '请输入密码' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: nicknameController,
                  decoration: const InputDecoration(
                    labelText: '备注名（可选）',
                    hintText: '如：张三',
                    prefixIcon: Icon(Icons.badge),
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final provider =
                    Provider.of<ScheduleProvider>(context, listen: false);
                final account = Account(
                  username: usernameController.text.trim(),
                  password: passwordController.text,
                  nickname: nicknameController.text.trim().isNotEmpty
                      ? nicknameController.text.trim()
                      : null,
                );
                await provider.addAccount(account);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditAccountDialog(BuildContext context, Account account) {
    final usernameController = TextEditingController(text: account.username);
    final passwordController = TextEditingController(text: account.password);
    final nicknameController =
        TextEditingController(text: account.nickname ?? '');
    final formKey = GlobalKey<FormState>();
    bool obscurePassword = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('编辑账号'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: usernameController,
                  decoration: const InputDecoration(
                    labelText: '学号',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? '请输入学号' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  decoration: InputDecoration(
                    labelText: '密码',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off),
                      onPressed: () => setDialogState(
                          () => obscurePassword = !obscurePassword),
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? '请输入密码' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: nicknameController,
                  decoration: const InputDecoration(
                    labelText: '备注名（可选）',
                    prefixIcon: Icon(Icons.badge),
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final provider =
                    Provider.of<ScheduleProvider>(context, listen: false);
                final updatedAccount = account.copyWith(
                  username: usernameController.text.trim(),
                  password: passwordController.text,
                  nickname: nicknameController.text.trim().isNotEmpty
                      ? nicknameController.text.trim()
                      : null,
                );
                await provider.updateAccount(updatedAccount);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmDialog(
    BuildContext context,
    Account account,
    ScheduleProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除账号'),
        content: Text(
          '确定要删除账号 ${account.displayName} 吗？\n\n'
          '删除账号不会删除已导入的课表和课程。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await provider.deleteAccount(account.id!);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('已删除账号 ${account.displayName}')),
                );
              }
            },
            child: const Text('确认删除'),
          ),
        ],
      ),
    );
  }
}
