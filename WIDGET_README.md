# FITschedule 桌面组件使用说明

## 功能介绍

FITschedule 应用现在支持 Android 桌面组件功能，可以在手机桌面直接查看今日课程安排，无需打开应用。

## 主要特性

- 📅 显示当前日期（月日 星期）
- 📚 显示今日课程列表（最多3门课程）
- ⏰ 显示课程时间
- 📍 显示上课地点
- 🔄 自动同步课程数据
- 👆 点击组件可直接打开应用

## 如何添加桌面组件

1. 长按手机桌面空白处
2. 选择"小组件"或"桌面组件"
3. 找到"FITschedule"应用
4. 选择"今日课程"组件
5. 拖拽到桌面合适位置

## 组件显示规则

- **有课程时**：显示课程名称、时间和地点
- **无课程时**：显示"今日无课程安排"
- **超过3门课程**：显示前3门课程，并提示还有更多课程
- **数据加载失败**：显示"加载课程失败"

## 数据同步

桌面组件会在以下情况自动更新：
- 添加新课程
- 修改课程信息
- 删除课程
- 批量导入课程
- 清空所有课程

## 技术实现

### Android 端
- `TodayScheduleWidgetProvider.kt` - 桌面组件提供者
- `WidgetDatabaseHelper.kt` - 数据库访问助手
- `MainActivity.kt` - 方法通道处理

### Flutter 端
- `WidgetService.dart` - 桌面组件服务
- `ScheduleProvider.dart` - 数据变化通知

## 组件尺寸

- 最小尺寸：250dp × 110dp
- 目标尺寸：4×2 网格
- 支持水平和垂直调整大小

## 更新频率

- 自动更新：每小时更新一次
- 手动更新：课程数据变化时立即更新
- 点击更新：点击组件时刷新数据

## 注意事项

1. 桌面组件需要 Android 系统支持
2. 首次添加组件时可能需要等待数据加载
3. 如果组件显示异常，可以尝试重新添加
4. 组件会自动适应系统主题（浅色/深色）

## 故障排除

### 组件不显示课程
1. 检查应用是否有课程数据
2. 确认当前日期是否有课程安排
3. 尝试删除并重新添加组件

### 组件无法点击
1. 确保组件完全加载完成
2. 检查应用是否被系统限制后台运行

### 数据不同步
1. 打开应用确认课程数据正确
2. 手动刷新组件（删除重新添加）
3. 重启应用

## 开发说明

如需修改组件样式或功能，主要文件位置：
- 布局文件：`android/app/src/main/res/layout/today_schedule_widget.xml`
- 样式文件：`android/app/src/main/res/drawable/widget_background.xml`
- 配置文件：`android/app/src/main/res/xml/today_schedule_widget_info.xml`
- 核心逻辑：`android/app/src/main/kotlin/com/example/fit_schedule/` 