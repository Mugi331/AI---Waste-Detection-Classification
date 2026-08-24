import 'dart:ui';

/// A generic bounding box, independent of any specific detector
/// (YOLO, SSD, Faster R-CNN, EfficientDet, ...).
///
/// Coordinates are expressed in the *original* image's pixel space
/// (see [DetectionResponse.imageWidth]/[imageHeight]), NOT in
/// on-screen widget coordinates. [toRect] handles scaling into
/// whatever size the image is actually rendered at.
class BoundingBox {
  final double left;
  final double top;
  final double right;
  final double bottom;

  const BoundingBox({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  double get width => right - left;
  double get height => bottom - top;

  Rect toRect({
    required double srcWidth,
    required double srcHeight,
    required double dstWidth,
    required double dstHeight,
  }) {
    final sx = dstWidth / srcWidth;
    final sy = dstHeight / srcHeight;
    return Rect.fromLTRB(left * sx, top * sy, right * sx, bottom * sy);
  }
}

/// The four material classes this app currently supports, plus a
/// fallback. Kept as an enum (rather than raw strings) so guidance
/// lookup and UI widgets stay decoupled from whatever exact label
/// string a given backend model happens to emit.
enum WasteClass { plastic, metal, paperCardboard, glass, unknown }

WasteClass wasteClassFromLabel(String label) {
  switch (label.trim().toLowerCase()) {
    case 'plastic':
      return WasteClass.plastic;
    case 'metal':
      return WasteClass.metal;
    case 'paper_cardboard':
    case 'paper':
    case 'cardboard':
      return WasteClass.paperCardboard;
    case 'glass':
      return WasteClass.glass;
    default:
      return WasteClass.unknown;
  }
}

/// One detected object returned by the (mocked or real) AI backend.
///
/// This is the only shape the UI ever depends on. It intentionally
/// carries no detector-specific fields (anchors, grid cells, etc.)
/// so a future SSD / Faster R-CNN / EfficientDet backend can populate
/// it without any Flutter-side changes — as long as it can be mapped
/// to { class, confidence, bbox }.
class DetectionResult {
  final WasteClass wasteClass;
  final String rawLabel;
  final double confidence; // 0.0 - 1.0
  final BoundingBox boundingBox;

  const DetectionResult({
    required this.wasteClass,
    required this.rawLabel,
    required this.confidence,
    required this.boundingBox,
  });

  factory DetectionResult.fromJson(Map<String, dynamic> json) {
    final bbox = (json['bbox'] as List)
        .map((e) => (e as num).toDouble())
        .toList();
    final label = json['class'] as String;

    return DetectionResult(
      wasteClass: wasteClassFromLabel(label),
      rawLabel: label,
      confidence: (json['confidence'] as num).toDouble(),
      boundingBox: BoundingBox(
        left: bbox[0],
        top: bbox[1],
        right: bbox[2],
        bottom: bbox[3],
      ),
    );
  }
}

/// High-level outcome of one analysis request, mirroring the
/// backend's "status" field. Kept as an enum rather than a bool so a
/// future distinct status (e.g. "invalid_image") can be added without
/// having to reinterpret a boolean.
enum DetectionStatus { success, noDetection }

DetectionStatus _statusFromJson(String? raw) {
  switch (raw) {
    case 'success':
      return DetectionStatus.success;
    case 'no_detection':
    default:
      return DetectionStatus.noDetection;
  }
}

/// Result of analysing ONE user-submitted photo of ONE waste item.
///
/// The detector may internally evaluate several candidate boxes (see
/// [candidateCount]), but this app is a single-item scanner: only ONE
/// primary detection is ever surfaced to the UI. This intentionally
/// replaces an earlier `detections: List<DetectionResult>` design —
/// exposing a list left the UI to interpret "how many results do I
/// show", which doesn't match the single-item product interaction.
class DetectionResponse {
  final DetectionResult? primaryDetection;
  final double imageWidth;
  final double imageHeight;
  final int candidateCount;
  final DetectionStatus status;

  const DetectionResponse({
    required this.primaryDetection,
    required this.imageWidth,
    required this.imageHeight,
    required this.candidateCount,
    required this.status,
  });

  /// True only when the backend both found AND accepted a primary
  /// detection. Guards defensively against a non-null
  /// [primaryDetection] ever appearing alongside a non-success status.
  bool get hasResult =>
      status == DetectionStatus.success && primaryDetection != null;

  factory DetectionResponse.fromJson(Map<String, dynamic> json) {
    final rawPrimary = json['primary_detection'];
    return DetectionResponse(
      primaryDetection: rawPrimary == null
          ? null
          : DetectionResult.fromJson(rawPrimary as Map<String, dynamic>),
      imageWidth: (json['image_width'] as num).toDouble(),
      imageHeight: (json['image_height'] as num).toDouble(),
      candidateCount: (json['candidate_count'] as num?)?.toInt() ?? 0,
      status: _statusFromJson(json['status'] as String?),
    );
  }
}
