import 'package:flutter/material.dart';

/// 自定义绘制器，用于绘制右下角三角形标志
class TrianglePainter extends CustomPainter {
  final Color baseColor;
  
  const TrianglePainter({required this.baseColor});

  @override
  void paint(Canvas canvas, Size size) {
    // 创建比背景颜色深一些的颜色
    final triangleColor = _getDarkerColor(baseColor);
    
    final paint = Paint()
      ..color = triangleColor
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(size.width * 0.6, size.height); // 从右下角向左的起点调整
    path.lineTo(size.width, size.height); // 到右下角
    path.lineTo(size.width, size.height * 0.4); // 向上的终点调整
    path.close(); // 闭合路径

    canvas.drawPath(path, paint);
  }

  /// 获取比基础颜色深一些的颜色
  Color _getDarkerColor(Color baseColor) {
    // 计算HSL值来调整颜色
    final hsl = HSLColor.fromColor(baseColor);
    
    // 降低亮度，增加饱和度来获得更深的颜色
    final darkerHsl = hsl.withLightness(
      (hsl.lightness * 0.7).clamp(0.0, 1.0)
    ).withSaturation(
      (hsl.saturation * 1.2).clamp(0.0, 1.0)
    );
    
    return darkerHsl.toColor();
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    if (oldDelegate is TrianglePainter) {
      return oldDelegate.baseColor != baseColor;
    }
    return true;
  }
}