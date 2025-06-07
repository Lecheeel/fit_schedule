# GitHub Actions 自动构建 Flutter Android APK 设置说明

## 🎯 概述

这个 GitHub Actions 工作流将自动构建您的 Flutter Android APK，支持以下功能：
- 自动在推送到 main/master 分支时构建
- 支持 Pull Request 构建验证
- 支持手动触发构建
- 自动上传构建产物
- 支持签名发布版本（可选）

## 📋 前置条件

1. 您的项目已推送到 GitHub 仓库
2. 项目是有效的 Flutter 项目

## 🔧 基础设置步骤

### 1. 确认工作流文件已创建
工作流文件位于：`.github/workflows/build-android.yml`

### 2. 推送代码到 GitHub
```bash
git add .
git commit -m "Add GitHub Actions workflow for Android APK build"
git push origin main
```

### 3. 验证工作流
- 访问您的 GitHub 仓库
- 点击 "Actions" 标签页
- 您应该能看到 "Build Flutter Android APK" 工作流正在运行

## 🔐 生产环境签名设置（可选但推荐）

如果您想构建签名的发布版本，需要以下额外步骤：

### 1. 生成签名密钥（如果还没有）
```bash
keytool -genkey -v -keystore android_keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias key
```

### 2. 配置 GitHub Secrets
在您的 GitHub 仓库中：
1. 进入 Settings → Secrets and variables → Actions
2. 点击 "New repository secret" 添加以下密钥：

| 密钥名称 | 描述 | 示例值 |
|---------|------|--------|
| `KEYSTORE_BASE64` | keystore 文件的 base64 编码 | (见下方获取方法) |
| `KEYSTORE_PASSWORD` | keystore 密码 | your_keystore_password |
| `KEY_ALIAS` | 密钥别名 | key |
| `KEY_PASSWORD` | 密钥密码 | your_key_password |

### 3. 获取 KEYSTORE_BASE64
在终端运行：
```bash
# Windows (PowerShell)
[Convert]::ToBase64String([IO.File]::ReadAllBytes("android_keystore.jks"))

# macOS/Linux
base64 android_keystore.jks
```

复制输出的 base64 字符串到 `KEYSTORE_BASE64` secret。

### 4. 配置签名 (android/app/build.gradle.kts)
您需要更新 `android/app/build.gradle.kts` 文件来支持签名：

```kotlin
android {
    // ... 其他配置

    signingConfigs {
        create("release") {
            keyAlias = System.getenv("KEY_ALIAS")
            keyPassword = System.getenv("KEY_PASSWORD")
            storeFile = file("android_keystore.jks")
            storePassword = System.getenv("KEYSTORE_PASSWORD")
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}
```

## 🚀 使用方法

### 自动触发
- 推送代码到 main 或 master 分支时自动构建
- 创建 Pull Request 时自动构建验证

### 手动触发
1. 访问 GitHub 仓库的 Actions 页面
2. 选择 "Build Flutter Android APK" 工作流
3. 点击 "Run workflow" 按钮

### 下载构建产物
1. 进入 Actions 页面
2. 选择对应的工作流运行
3. 在 "Artifacts" 部分下载 APK 文件

## 📱 构建产物

- **无签名设置时**：生成 `debug-apk` 产物（debug 版本）
- **有签名设置时**：生成 `release-apk` 产物（release 版本）
- **自动发布**：当推送到 main 分支且有签名配置时，会自动创建 GitHub Release

## 🔧 自定义配置

### 修改 Flutter 版本
在 `.github/workflows/build-android.yml` 中修改：
```yaml
- name: Setup Flutter
  uses: subosito/flutter-action@v2
  with:
    flutter-version: '3.24.3'  # 修改为您需要的版本
    channel: 'stable'
```

### 修改触发条件
```yaml
on:
  push:
    branches: [ main, master, develop ]  # 添加更多分支
  pull_request:
    branches: [ main, master ]
```

## 📝 注意事项

1. 首次运行可能需要较长时间，因为需要下载 Flutter SDK
2. 确保您的项目通过 `flutter test` 测试
3. 如果构建失败，检查 Actions 日志获取详细错误信息
4. 建议在本地先测试 `flutter build apk` 命令确保构建成功

## 🆘 常见问题

### Q: 构建失败，提示 Java 版本问题
A: 工作流已配置 Java 17，如果仍有问题，请检查您的项目是否需要特定 Java 版本。

### Q: 测试阶段失败
A: 确保您的项目通过本地 `flutter test` 命令，或在工作流中注释掉测试步骤。

### Q: 签名构建失败
A: 检查所有 secrets 是否正确设置，特别是 `KEYSTORE_BASE64` 格式是否正确。

## 🎉 完成！

现在您的 Flutter 项目已经配置了自动构建 Android APK 的 GitHub Actions 工作流！每次推送到主分支时都会自动构建，您可以在 Actions 页面下载构建好的 APK 文件。 