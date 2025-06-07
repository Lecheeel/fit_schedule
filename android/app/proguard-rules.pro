# Flutter 相关规则
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Dart 相关规则
-dontwarn io.flutter.embedding.**

# 保持所有注解
-keepattributes *Annotation*

# 保持行号信息，便于调试
-keepattributes SourceFile,LineNumberTable

# 如果您使用了 Gson 序列化
-keepattributes Signature
-keep class com.google.gson.** { *; }

# 通用的 Android 规则
-keep public class * extends android.app.Activity
-keep public class * extends android.app.Service
-keep public class * extends android.content.BroadcastReceiver
-keep public class * extends android.content.ContentProvider

# 保持 WebView 相关类（如果使用）
-keep class android.webkit.** { *; }

# 保持所有的 native 方法
-keepclasseswithmembernames class * {
    native <methods>;
} 