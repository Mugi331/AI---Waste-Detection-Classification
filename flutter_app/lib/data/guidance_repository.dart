import 'package:flutter/material.dart';
import '../models/detection_result.dart';
import '../models/recycling_guidance.dart';

/// Maps a detected [WasteClass] to recycling guidance, following the
/// Malaysia standard recycling bin colour scheme:
///   Blue Bin   -> Paper
///   Brown Bin  -> Glass
///   Orange Bin -> Plastics & Metals
///
/// Kept as a plain static lookup, separate from the AI/service layer,
/// so it's trivial to edit, extend to new classes, or localise later
/// without touching detection logic anywhere else in the app.
class GuidanceRepository {
  static const Map<WasteClass, RecyclingGuidance> _guidance = {
    WasteClass.plastic: RecyclingGuidance(
      binName: 'Orange Bin — Plastics & Metals',
      shortLabel: 'Orange Bin',
      binColor: Color(0xFFEF6C00),
      summary: 'Plastic items go in the Orange recycling bin.',
      tips: [
        'Rinse containers to remove food or liquid residue.',
        'Flatten bottles to save space where possible.',
        'Remove caps if your local facility requests separation.',
        'Avoid bagging recyclables in plastic bags.',
      ],
    ),
    WasteClass.metal: RecyclingGuidance(
      binName: 'Orange Bin — Plastics & Metals',
      shortLabel: 'Orange Bin',
      binColor: Color(0xFFEF6C00),
      summary: 'Metal items (cans, tins, foil) go in the Orange bin.',
      tips: [
        'Rinse cans to remove food residue.',
        'Crush cans if possible to save space.',
        'Wrap sharp metal edges before disposal.',
      ],
    ),
    WasteClass.paperCardboard: RecyclingGuidance(
      binName: 'Blue Bin — Paper',
      shortLabel: 'Blue Bin',
      binColor: Color(0xFF1565C0),
      summary: 'Paper and cardboard go in the Blue recycling bin.',
      tips: [
        'Flatten boxes to save space.',
        'Keep paper dry and free of food contamination.',
        'Remove plastic tape or windows from packaging where possible.',
      ],
    ),
    WasteClass.glass: RecyclingGuidance(
      binName: 'Brown Bin — Glass',
      shortLabel: 'Brown Bin',
      binColor: Color(0xFF6D4C41),
      summary: 'Glass items go in the Brown recycling bin.',
      tips: [
        'Rinse bottles and jars before disposal.',
        'Remove lids and place them in the appropriate bin.',
        'Handle broken glass carefully and wrap it before disposal.',
      ],
    ),
    WasteClass.unknown: RecyclingGuidance(
      binName: 'General Waste',
      shortLabel: 'General Waste',
      binColor: Color(0xFF616161),
      summary:
          'This item could not be confidently matched to a recycling category.',
      tips: [
        'Check local recycling guidelines for this item.',
        'When unsure, general waste disposal may be the safest option.',
      ],
    ),
  };

  static RecyclingGuidance forClass(WasteClass wasteClass) {
    return _guidance[wasteClass] ?? _guidance[WasteClass.unknown]!;
  }
}
