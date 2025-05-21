import 'package:flutter/material.dart';

class WaistLogoWidget extends StatelessWidget {
  final double size;
  const WaistLogoWidget({super.key, this.size = 180});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(
          size: Size(size, size),
          painter: _WaistPainter(),
        ),
        const SizedBox(height: 16),
        Text(
          '다이어트',
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.22,
            fontWeight: FontWeight.bold,
            letterSpacing: 4,
          ),
        ),
      ],
    );
  }
}

class _WaistPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // 왼쪽 곡선 (허리라인)
    final leftPath = Path();
    leftPath.moveTo(size.width * 0.35, size.height * 0.15);
    leftPath.cubicTo(
      size.width * 0.22, size.height * 0.35,
      size.width * 0.28, size.height * 0.65,
      size.width * 0.35, size.height * 0.85,
    );
    canvas.drawPath(leftPath, paint);

    // 오른쪽 곡선 (허리라인)
    final rightPath = Path();
    rightPath.moveTo(size.width * 0.65, size.height * 0.15);
    rightPath.cubicTo(
      size.width * 0.78, size.height * 0.35,
      size.width * 0.72, size.height * 0.65,
      size.width * 0.65, size.height * 0.85,
    );
    canvas.drawPath(rightPath, paint);

    // 허리 부분 강조 (중앙 가로선)
    final waistLine = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(size.width * 0.42, size.height * 0.5),
      Offset(size.width * 0.58, size.height * 0.5),
      waistLine,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
} 