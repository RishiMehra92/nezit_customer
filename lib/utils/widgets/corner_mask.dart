import 'package:flutter/material.dart';

class CornerMask extends StatelessWidget {
  final double radius;
  final Color color;

  const CornerMask({super.key, required this.radius, required this.color});

  @override
  Widget build(BuildContext context) {
    if (radius <= 0) return const SizedBox.shrink();
    return IgnorePointer(
      child: CustomPaint(
        painter: _CornerMaskPainter(radius: radius, color: color),
      ),
    );
  }
}

class _CornerMaskPainter extends CustomPainter {
  final double radius;
  final Color color;

  _CornerMaskPainter({required this.radius, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Top Left
    var path = Path()
      ..moveTo(0, 0)
      ..lineTo(radius, 0)
      ..arcToPoint(
        Offset(0, radius),
        radius: Radius.circular(radius),
        clockwise: false,
      )
      ..close();
    canvas.drawPath(path, paint);

    // Top Right
    path = Path()
      ..moveTo(size.width, 0)
      ..lineTo(size.width - radius, 0)
      ..arcToPoint(
        Offset(size.width, radius),
        radius: Radius.circular(radius),
        clockwise: true,
      )
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CornerMaskPainter oldDelegate) {
    return oldDelegate.radius != radius || oldDelegate.color != color;
  }
}
