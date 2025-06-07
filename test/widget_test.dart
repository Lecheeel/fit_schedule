// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:fit_schedule/main.dart';
import 'package:fit_schedule/providers/schedule_provider.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // 创建测试用的ScheduleProvider
    final scheduleProvider = ScheduleProvider();
    
    // Build our app and trigger a frame with proper provider setup
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => scheduleProvider),
        ],
        child: const MyApp(isDarkMode: false),
      ),
    );

    // 等待widget完全构建
    await tester.pumpAndSettle();

    // 验证应用成功启动，可以找到周视图标签
    expect(find.text('周视图'), findsOneWidget);
    
    // 验证底部导航栏存在
    expect(find.byType(NavigationBar), findsOneWidget);
    
    // 验证所有四个导航项都存在
    expect(find.text('周视图'), findsOneWidget);
    expect(find.text('日视图'), findsOneWidget);
    expect(find.text('课程'), findsOneWidget);
    expect(find.text('设置'), findsOneWidget);
  });
}
