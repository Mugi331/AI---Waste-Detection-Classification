import 'package:flutter/material.dart';
import '../models/detection_result.dart';
import '../theme/app_theme.dart';

/// Draws the single primary detection's bounding box + label over a
/// displayed image.
///
/// [detection] is expressed in the *original* analysed image's pixel
/// space ([imageWidth] x [imageHeight]); this widget scales it to
/// whatever size the image is actually rendered at, via
/// [BoundingBox.toRect]. Pass `null` to draw nothing (e.g. while no
/// result exists yet).
///
/// Coordinate-alignment note (UNCHANGED from the functional refactor —
/// only the paint colours below were touched for this visual pass):
/// place this widget inside a [Stack] on top of an [Image] whose
/// parent is sized with an [AspectRatio] matching
/// `imageWidth / imageHeight` exactly (see ResultScreen). When the
/// container's aspect ratio matches the image's own aspect ratio,
/// `BoxFit.cover` (and `contain`/`fill`) all produce the same result —
/// no cropping, no letterboxing margins — so this widget's
/// [LayoutBuilder] constraints are guaranteed to equal the actual
/// rendered image size, keeping the box perfectly aligned. If you
/// ever change ResultScreen to allow a mismatched aspect ratio, this
/// scaling assumption breaks and needs revisiting.
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
            strokeColor: AppColors.sage,
            labelBackground: const Color.fromARGB(255, 179, 221, 144),
            labelTextColor: const Color.fromARGB(255, 71, 59, 53),
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
  final Color strokeColor;
  final Color labelBackground;
  final Color labelTextColor;

  _BoundingBoxPainter({
    required this.detection,
    required this.srcWidth,
    required this.srcHeight,
    required this.strokeColor,
    required this.labelBackground,
    required this.labelTextColor,
  });

  @override
  void paint(Canvas canvas, Size size) {

    final rect = detection.boundingBox.toRect(
      srcWidth: srcWidth,
      srcHeight: srcHeight,
      dstWidth: size.width,
      dstHeight: size.height,
    );

    final boxPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = strokeColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(10)),
      boxPaint,
    );

    final label =
        '${detection.rawLabel} ${(detection.confidence * 100).toStringAsFixed(0)}%';
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: labelTextColor,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final labelTop = (rect.top - textPainter.height - 8).clamp(0.0, size.height);
    final labelRect = Rect.fromLTWH(
      rect.left,
      labelTop,
      textPainter.width + 14,
      textPainter.height + 6,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(labelRect, const Radius.circular(8)),
      Paint()..color = labelBackground,
    );
    textPainter.paint(canvas, Offset(labelRect.left + 7, labelRect.top + 3));
  }

  @override
  bool shouldRepaint(covariant _BoundingBoxPainter oldDelegate) {
    return oldDelegate.detection != detection ||
        oldDelegate.srcWidth != srcWidth ||
        oldDelegate.srcHeight != srcHeight;
  }
}
