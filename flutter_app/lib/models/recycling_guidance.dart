import 'package:flutter/material.dart';

/// Application-level recycling advice for a material class.
///
/// This is NOT produced by the AI model — the model only outputs
/// bounding box + class + confidence (see [DetectionResult]).
/// Guidance is looked up separately, in [GuidanceRepository].
class RecyclingGuidance {
  final String binName;
  final Color binColor;
  final String summary;
  final List<String> tips;

  const RecyclingGuidance({
    required this.binName,
    required this.binColor,
    required this.summary,
    required this.tips,
  });
}
