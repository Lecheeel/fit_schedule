import 'package:flutter/material.dart';

/// 应用主题和样式工具类
class AppTheme {
  // 主色调
  static const Color primaryColor = Color(0xFF1976D2); // 蓝色
  static const Color secondaryColor = Color(0xFF388E3C); // 绿色
  
  // 优化的马卡龙色系课程卡片颜色 - 低饱和度，轻盈温柔小清新
  static const List<Color> defaultCourseColors = [
    Color(0xFFFFE4E1), // 马卡龙粉 - 温柔甜美
    Color(0xFFE1F5FE), // 马卡龙天蓝 - 清新宁静
    Color(0xFFE8F5E8), // 马卡龙薄荷绿 - 清新自然
    Color(0xFFFFF9E6), // 马卡龙香草黄 - 温暖明亮
    Color(0xFFF3E5F5), // 马卡龙薰衣草 - 优雅梦幻
    Color(0xFFFFEBEE), // 马卡龙樱花粉 - 浪漫温柔
    Color(0xFFE0F2F1), // 马卡龙青瓷绿 - 清雅淡然
    Color(0xFFFFF8E1), // 马卡龙柠檬黄 - 活力清新
    Color(0xFFEDE7F6), // 马卡龙紫罗兰 - 神秘柔和
    Color(0xFFE1F5FE), // 马卡龙冰蓝 - 清透纯净
    Color(0xFFF1F8E9), // 马卡龙抹茶 - 清淡雅致
    Color(0xFFFCE4EC), // 马卡龙玫瑰 - 甜美温馨
    Color(0xFFE8EAF6), // 马卡龙丁香蓝 - 沉静优雅
    Color(0xFFF9FBE7), // 马卡龙青柠 - 清新活泼
    Color(0xFFFFF3E0), // 马卡龙蜜桃 - 温暖可爱
    Color(0xFFE0F7FA), // 马卡龙薄荷蓝 - 清凉舒适
    // Color(0xFFF8BBD9), // 马卡龙草莓粉 - 甜腻可爱
    Color(0xFFE6FFFA), // 马卡龙海盐绿 - 清新脱俗
  ];
  
  // 对应的深色文字颜色 - 与马卡龙色系协调的温和深色
  static const List<Color> defaultCourseTextColors = [
    Color(0xFFAD7A78), // 深玫瑰棕
    Color(0xFF7BA7BC), // 深天蓝
    Color(0xFF7BA876), // 深薄荷绿
    Color(0xFFB8A76D), // 深香草黄
    Color(0xFF9C7BAD), // 深薰衣草
    Color(0xFFB87A85), // 深樱花粉
    Color(0xFF7BA89C), // 深青瓷绿
    Color(0xFFB8A76D), // 深柠檬黄
    Color(0xFF8E7BA8), // 深紫罗兰
    Color(0xFF7BA7BC), // 深冰蓝
    Color(0xFF87A876), // 深抹茶
    Color(0xFFB87A9C), // 深玫瑰
    Color(0xFF7B87BC), // 深丁香蓝
    Color(0xFF9CB876), // 深青柠
    Color(0xFFB8976D), // 深蜜桃
    Color(0xFF7BBCB8), // 深薄荷蓝
    // Color(0xFFD89BB8), // 深草莓粉
    Color(0xFF7BBCAD), // 深海盐绿
  ];
  
  // 栅格线条颜色 - 极淡的浅灰色
  static const Color gridLineColor = Color(0xFFEFEFEF);
  
  // 亮色主题
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      secondary: secondaryColor,
      brightness: Brightness.light,
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      filled: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      indicatorColor: primaryColor.withOpacity(0.2),
      labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
    ),
  );
  
  // 暗色主题
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      secondary: secondaryColor,
      brightness: Brightness.dark,
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      filled: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      indicatorColor: primaryColor.withOpacity(0.4),
      labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
    ),
  );
  
  // 获取主题数据
  static ThemeData getThemeData({bool isDarkMode = false}) {
    return isDarkMode ? darkTheme : lightTheme;
  }
  
  // 课程卡片样式
  static BoxDecoration getCourseCardDecoration(Color color, {double opacity = 0.9}) {
    return BoxDecoration(
      color: color.withOpacity(opacity),
      borderRadius: BorderRadius.circular(8),
      boxShadow: [
        BoxShadow(
          color: color.withOpacity(0.2),
          blurRadius: 2,
          offset: const Offset(0, 1),
        ),
      ],
    );
  }
  
  // 根据背景颜色获取适合的文本颜色（黑色或白色）
  static Color getTextColorForBackground(Color backgroundColor) {
    // 计算亮度 (亮度 > 0.5 使用黑色文本，否则使用白色文本)
    final double brightness = (backgroundColor.red * 299 + 
                               backgroundColor.green * 587 + 
                               backgroundColor.blue * 114) / 1000 / 255;
    
    return brightness > 0.5 ? Colors.black : Colors.white;
  }
  
  // 获取随机的课程颜色
  static Color getRandomCourseColor(int index) {
    return defaultCourseColors[index % defaultCourseColors.length];
  }
  
  // 获取课程卡片的同色系深色文字颜色
  static Color getCourseTextColor(Color cardColor) {
    // 找到卡片颜色在默认颜色列表中的位置
    final colorIndex = defaultCourseColors.indexOf(cardColor);
    
    if (colorIndex != -1) {
      // 如果找到了对应的颜色，返回对应的深色文字颜色
      return defaultCourseTextColors[colorIndex];
    } else {
      // 如果没有找到对应的颜色，则生成一个同色系的深色版本
      return _generateDarkerTextColor(cardColor);
    }
  }
  
  // 获取随机的同色系深色文字颜色
  static Color getRandomCourseTextColor(int index) {
    return defaultCourseTextColors[index % defaultCourseTextColors.length];
  }
  
  // 生成比背景颜色更深的同色系颜色用于文字
  static Color _generateDarkerTextColor(Color backgroundColor) {
    final hsl = HSLColor.fromColor(backgroundColor);
    
    // 降低亮度，增加饱和度，保持色相不变
    final darkerHsl = hsl.withLightness(
      (hsl.lightness * 0.4).clamp(0.2, 0.6)
    ).withSaturation(
      (hsl.saturation * 1.2).clamp(0.3, 1.0)
    );
    
    return darkerHsl.toColor();
  }
  
  // 获取课程颜色和文字颜色的配对
  static ({Color cardColor, Color textColor}) getCourseColorPair(int index) {
    final colorIndex = index % defaultCourseColors.length;
    return (
      cardColor: defaultCourseColors[colorIndex],
      textColor: defaultCourseTextColors[colorIndex],
    );
  }
} 