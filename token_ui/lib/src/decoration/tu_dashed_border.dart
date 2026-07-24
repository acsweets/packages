import 'package:flutter/material.dart';

/// Rounded-rect dashed border around [child].
class TuDashedBorder extends StatelessWidget {
  const TuDashedBorder({
    super.key,
    required this.child,
    this.dashWidth = 5.0,
    this.dashSpace = 3.0,
    this.borderWidth = 2.0,
    this.borderGradient,
    this.borderColor = Colors.black,
    this.borderRadius,
  });

  final Widget child;
  final double dashWidth;
  final double dashSpace;
  final double borderWidth;
  final Gradient? borderGradient;
  final Color borderColor;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: TuDashedBorderPainter(
        dashWidth: dashWidth,
        dashSpace: dashSpace,
        borderWidth: borderWidth,
        borderGradient: borderGradient,
        borderColor: borderColor,
        borderRadius: borderRadius,
      ),
      child: child,
    );
  }
}

class TuDashedBorderPainter extends CustomPainter {
  TuDashedBorderPainter({
    required this.dashWidth,
    required this.dashSpace,
    required this.borderWidth,
    this.borderGradient,
    required this.borderColor,
    this.borderRadius,
  });

  final double dashWidth;
  final double dashSpace;
  final double borderWidth;
  final Gradient? borderGradient;
  final Color borderColor;
  final BorderRadius? borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final radius = borderRadius;
    final path = radius != null
        ? (Path()..addRRect(
            RRect.fromRectAndCorners(
              rect,
              topLeft: radius.topLeft,
              topRight: radius.topRight,
              bottomLeft: radius.bottomLeft,
              bottomRight: radius.bottomRight,
            ),
          ))
        : (Path()..addRect(rect));

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final gradient = borderGradient;
    if (gradient != null) {
      paint.shader = gradient.createShader(rect);
    } else {
      paint.color = borderColor;
    }

    canvas.drawPath(_createDashedPath(path, dashWidth, dashSpace), paint);
  }

  Path _createDashedPath(Path source, double dashWidth, double dashSpace) {
    final dest = Path();
    for (final metric in source.computeMetrics()) {
      double distance = 0.0;
      var draw = true;
      while (distance < metric.length) {
        final length = draw ? dashWidth : dashSpace;
        if (distance + length > metric.length) {
          if (draw) {
            dest.addPath(
              metric.extractPath(distance, metric.length),
              Offset.zero,
            );
          }
          break;
        }
        if (draw) {
          dest.addPath(
            metric.extractPath(distance, distance + length),
            Offset.zero,
          );
        }
        distance += length;
        draw = !draw;
      }
    }
    return dest;
  }

  @override
  bool shouldRepaint(covariant TuDashedBorderPainter oldDelegate) =>
      oldDelegate.dashWidth != dashWidth ||
      oldDelegate.dashSpace != dashSpace ||
      oldDelegate.borderWidth != borderWidth ||
      oldDelegate.borderGradient != borderGradient ||
      oldDelegate.borderColor != borderColor ||
      oldDelegate.borderRadius != borderRadius;
}
