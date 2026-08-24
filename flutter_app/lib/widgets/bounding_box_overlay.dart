import 'package:flutter/material.dart';
import '../models/detection_result.dart';

/// Draws the single primary detection's bounding box + label over a
/// displayed image.
///
/// [detection] is expressed in the analysed image's pixel space
/// ([imageWidth] x [imageHeight]). The painter uses the same geometry as
/// `BoxFit.contain`: it preserves aspect ratio and accounts for any
/// letterboxing offsets before mapping the box to screen coordinates.
///
/// This keeps the overlay aligned even if the surrounding result layout is
/// later changed to an aspect ratio that does not exactly match the image.
/// Pass `null` to draw nothing (for example, for a no-detection result).
class BoundingBoxOverlay extends StatelessWidget {
  final DetectionResult? detection;
  final double imageWidth;
  final double imageHeight;

  const BoundingBoxOverlay({
    super.key,
    required this.detection,
    required this.imageWidth,
    required this.imageHeight,
  });

  @override
  Widget build(BuildContext context) {
    final d = detection;
    if (d == null) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: _BoundingBoxPainter(
            detection: d,
            srcWidth: imageWidth,
            srcHeight: imageHeight,
            color: Theme.of(context).colorScheme.primary,
          ),
        );
      },
    );
  }
}

class _BoundingBoxPainter extends CustomPainter {
  final DetectionResult detection;
  final double srcWidth;
  final double srcHeight;
  final Color color;

  _BoundingBoxPainter({
    required this.detection,
    required this.srcWidth,
    required this.srcHeight,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (srcWidth <= 0 || srcHeight <= 0 || size.isEmpty) return;

    // Match Image(..., fit: BoxFit.contain): scale uniformly, then centre
    // the rendered image inside the available widget area.
    final scaleX = size.width / srcWidth;
    final scaleY = size.height / srcHeight;
    final scale = scaleX < scaleY ? scaleX : scaleY;

    final renderedWidth = srcWidth * scale;
    final renderedHeight = srcHeight * scale;
    final offsetX = (size.width - renderedWidth) / 2;
    final offsetY = (size.height - renderedHeight) / 2;

    final box = detection.boundingBox;
    final rect = Rect.fromLTRB(
      offsetX + box.left * scale,
      offsetY + box.top * scale,
      offsetX + box.right * scale,
      offsetY + box.bottom * scale,
    );

    final boxPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = color;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      boxPaint,
    );

    final label =
        '${detection.rawLabel} ${(detection.confidence * 100).toStringAsFixed(0)}%';
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final labelTop = (rect.top - textPainter.height - 8).clamp(0.0, size.height);
    final labelRect = Rect.fromLTWH(
      rect.left,
      labelTop,
      textPainter.width + 12,
      textPainter.height + 6,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(labelRect, const Radius.circular(4)),
      Paint()..color = color,
    );
    textPainter.paint(canvas, Offset(labelRect.left + 6, labelRect.top + 3));
  }

  @override
  bool shouldRepaint(covariant _BoundingBoxPainter oldDelegate) {
    return oldDelegate.detection != detection ||
        oldDelegate.srcWidth != srcWidth ||
        oldDelegate.srcHeight != srcHeight ||
        oldDelegate.color != color;
  }
}
