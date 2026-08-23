import 'package:flutter/material.dart';
import '../data/guidance_repository.dart';
import '../models/detection_result.dart';
import 'confidence_indicator.dart';
import 'recycling_guidance_card.dart';

/// One card representing a single detected item: material class,
/// confidence score, and its recycling guidance. ResultScreen renders
/// one of these per entry in [DetectionResponse.detections], so
/// multiple detections in one image are shown as a simple list.
class DetectionCard extends StatelessWidget {
  final DetectionResult detection;
  final int index;

  const DetectionCard({
    super.key,
    required this.detection,
    required this.index,
  });

  IconData _iconFor(WasteClass c) {
    switch (c) {
      case WasteClass.plastic:
        return Icons.local_drink_outlined;
      case WasteClass.metal:
        return Icons.build_outlined;
      case WasteClass.paperCardboard:
        return Icons.inventory_2_outlined;
      case WasteClass.glass:
        return Icons.wine_bar_outlined;
      case WasteClass.unknown:
        return Icons.help_outline;
    }
  }

  String _labelFor(WasteClass c, String raw) {
    switch (c) {
      case WasteClass.plastic:
        return 'Plastic';
      case WasteClass.metal:
        return 'Metal';
      case WasteClass.paperCardboard:
        return 'Paper / Cardboard';
      case WasteClass.glass:
        return 'Glass';
      case WasteClass.unknown:
        return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final guidance = GuidanceRepository.forClass(detection.wasteClass);
    final scheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: scheme.primaryContainer,
                  child: Icon(
                    _iconFor(detection.wasteClass),
                    color: scheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Detection ${index + 1}',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: scheme.outline,
                            ),
                      ),
                      Text(
                        _labelFor(detection.wasteClass, detection.rawLabel),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // --- AI output ---------------------------------------------
            ConfidenceIndicator(confidence: detection.confidence),
            const SizedBox(height: 16),
            // --- Application logic (NOT from the AI model) -------------
            RecyclingGuidanceCard(guidance: guidance),
          ],
        ),
      ),
    );
  }
}
