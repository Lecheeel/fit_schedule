import 'package:flutter/services.dart';

class WidgetService {
  static const MethodChannel _channel = MethodChannel('com.example.fit_schedule/widget');

  /// 更新桌面组件
  static Future<bool> updateWidget() async {
    try {
      final result = await _channel.invokeMethod('updateWidget');
      print('Widget update result: $result');
      return true;
    } on PlatformException catch (e) {
      print('Failed to update widget: ${e.message}');
      return false;
    } catch (e) {
      print('Unexpected error updating widget: $e');
      return false;
    }
  }

  /// 在课程数据变化时自动更新桌面组件
  static Future<void> notifyDataChanged() async {
    await updateWidget();
  }
} 