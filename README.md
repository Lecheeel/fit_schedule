# FITschedule - 课表管理应用

一个基于 Flutter 开发的安卓课表管理应用，专注于提供便捷的课程管理和查看功能。

## 项目简介

FITschedule 是一个现代化的课表管理应用，支持周视图、日视图、课程管理等核心功能，帮助用户高效管理日常课程安排。

### 核心功能
- 📅 周视图课表：一周课程安排一览
- 📍 日视图：单日课程详细信息
- ➕ 课程管理：添加、编辑、删除课程
- 📚 学期管理：支持多学期课程安排
- 🎨 主题切换：明暗主题支持
- ⚙️ 个性化设置：自定义课程颜色、时间等

## 运行环境

- **平台**: 仅安卓平台
- **设备ID**: M2102K1C
- **开发语言**: Dart/Flutter

## 快速开始

### 前置要求
- Flutter SDK (^3.8.0)
- Android 开发环境
- 连接的安卓设备或模拟器

### 运行应用

#### 方法一：使用批处理脚本（推荐）
```bash
run.bat
```
此脚本会自动设置 UTF-8 编码，避免中文乱码问题。

#### 方法二：直接运行 Flutter 命令
如果遇到中文乱码问题，请先设置 UTF-8 编码：
```bash
chcp 65001
flutter run -d M2102K1C
```

### 解决中文乱码问题

在 Windows 系统上运行 Flutter 应用时，终端可能会显示中文乱码。解决方法：

#### 方案 1：临时解决（仅当前终端有效）
```bash
chcp 65001
```

#### 方案 2：项目级永久解决（推荐）
使用项目提供的 `run.bat` 脚本启动应用，自动设置 UTF-8 编码：
```bash
run.bat
```

#### 方案 3：系统级全局设置（一劳永逸）
如果需要在整个系统范围内使用 UTF-8 编码，运行 `setup_utf8.bat` 脚本：
```bash
setup_utf8.bat
```

**注意**：系统级设置需要管理员权限，设置完成后需要重启计算机才能生效。

## 项目结构

```
lib/
├── models/          # 数据模型
│   ├── course.dart      # 课程模型
│   └── semester.dart    # 学期模型
├── providers/       # 状态管理
│   └── schedule_provider.dart
├── screens/         # 页面
│   ├── week_view_screen.dart     # 周视图
│   ├── day_view_screen.dart      # 日视图
│   └── ...
├── services/        # 业务服务
│   ├── database_service.dart
│   └── ...
├── widgets/         # 自定义组件
├── utils/           # 工具类
└── main.dart        # 入口文件
```

## 开发约定

- 所有 UI 文本使用中文
- Git 提交信息使用英文
- 优先考虑安卓平台的用户体验
- 遵循 Material Design 设计规范

## 依赖包

主要依赖：
- `provider`: 状态管理
- `sqflite`: 本地数据库
- `shared_preferences`: 数据持久化
- `flutter_local_notifications`: 本地通知
- `intl`: 国际化支持
- 更多依赖见 `pubspec.yaml`

## 许可证

MIT License
