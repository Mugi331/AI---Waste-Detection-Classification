import 'package:flutter/material.dart';
import '../models/detection_result.dart';

/// Draws bounding boxes + labels over a displayed image.
///
/// [detections] boxes are expressed in the *original* image's pixel
/// space ([imageWidth] x [imageHeight]); this widget scales them to
/// whatever size the image is actually rendered at, via
/// [BoundingBox.toRect]. Place this in a [Stack] on top of the image.
class BoundingBoxOverlay extends StatelessWidget {
  final List<DetectionResult> detections;
  final double imageWidth;
  final double imageHeight;

  const BoundingBoxOverlay({
    super.key,
    required this.detections,
    required this.imageWidth,
    required this.imageHeight,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: _BoundingBoxPainter(
            detections: detections,
            srcWidth: imageWidth,
            srcHeight: imageHeight,
          ),
        );
      },
    );
  }
}

class _BoundingBoxPainter extends CustomPainter {
  final List<DetectionResult> detections;
  final double srcWidth;
  final double srcHeight;

  _BoundingBoxPainter({
    required this.detections,
    required this.srcWidth,
    required this.srcHeight,
  });

  static const List<Color> _palette = [
    Color(0xFF2E7D32),
    Color(0xFFEF6C00),
    Color(0xFF1565C0),
    Color(0xFF6D4C41),
    Color(0xFFAD1457),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < detections.length; i++) {
      final d = detections[i];
      final rect = d.boundingBox.toRect(
        srcWidth: srcWidth,
        srcHeight: srcHeight,
        dstWidth: size.width,
        dstHeight: size.height,
      );
      final color = _palette[i % _palette.length];

      final boxPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = color;
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(6)),
        boxPaint,
      );

      final label =
          '${d.rawLabel} ${(d.confidence * 100).toStringAsFixed(0)}%';
      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final labelTop = (rect.top - textPainter.height - 6).clamp(
        0.0,
        size.height,
      );
      final labelRect = Rect.fromLTWH(
        rect.left,
        labelTop,
        textPainter.width + 10,
        textPainter.height + 6,
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(labelRect, const Radius.circular(4)),
        Paint()..color = color,
      );
      textPainter.paint(canvas, Offset(labelRect.left + 5, labelRect.top + 3));
    }
  }

  @override
  bool shouldRepaint(covariant _BoundingBoxPainter oldDelegate) {
    return oldDelegate.detections != detections ||
        oldDelegate.srcWidth != srcWidth ||
        oldDelegate.srcHeight != srcHeight;
  }
}
