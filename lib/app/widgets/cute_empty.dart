import 'package:flutter/material.dart';

import '../theme.dart';

/// 简约可爱的空态插画 + 亲切文案。
///
/// 轻量插画元素（docs/01 §5.1 空状态文案可爱、亲切）：手绘风小云朵
/// 托着一颗心，不依赖外部图片资源。
class CuteEmpty extends StatelessWidget {
  const CuteEmpty({
    super.key,
    this.title = '还没有记录',
    this.subtitle = '一起写下第一笔吧~',
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 180,
            height: 132,
            child: CustomPaint(painter: _EmptyIllustration()),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: CoupleColors.textDark,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: CoupleColors.textLight,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

/// 云朵 + 爱心的手绘风小插画。
class _EmptyIllustration extends CustomPainter {
  const _EmptyIllustration();

  @override
  void paint(Canvas canvas, Size size) {
    final cloud = Paint()..color = CoupleColors.blush;
    final heart = Paint()
      ..color = CoupleColors.primary
      ..style = PaintingStyle.fill;

    // 云朵：三个圆 + 底部圆角矩形。
    canvas.drawCircle(Offset(size.width * 0.30, size.height * 0.52), 16, cloud);
    canvas.drawCircle(Offset(size.width * 0.48, size.height * 0.38), 24, cloud);
    canvas.drawCircle(Offset(size.width * 0.70, size.height * 0.52), 17, cloud);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.24, size.height * 0.48, size.width * 0.52, 22),
        const Radius.circular(11),
      ),
      cloud,
    );

    // 爱心：两条弧线组成的贝塞尔心形，置于云朵中央下方。
    final cx = size.width * 0.50;
    final topY = size.height * 0.62;
    final heartPath = Path()
      ..moveTo(cx, topY + 22)
      ..cubicTo(cx - 24, topY + 8, cx - 20, topY - 8, cx, topY + 4)
      ..cubicTo(cx + 20, topY - 8, cx + 24, topY + 8, cx, topY + 22);
    canvas.drawPath(heartPath, heart);

    // 两团小腮红（增加可爱感）。
    final blush = Paint()..color = const Color(0xFFF5C4CF);
    canvas.drawCircle(Offset(cx - 10, topY + 13), 2.5, blush);
    canvas.drawCircle(Offset(cx + 10, topY + 13), 2.5, blush);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
