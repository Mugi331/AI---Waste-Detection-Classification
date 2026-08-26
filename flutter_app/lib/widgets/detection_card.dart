import 'package:flutter/material.dart';
import '../data/bin_asset_mapper.dart';
import '../data/guidance_repository.dart';
import '../models/detection_result.dart';
import '../theme/app_theme.dart';
import 'confidence_indicator.dart';
import 'recycling_guidance_card.dart';

/// Card representing the app's SINGLE primary result for the
/// photographed item: detected material, model confidence, a
/// corresponding recycling-bin illustration, and recycling guidance.
///
/// Deliberately has no ordinal numbering ("Detection 1", "Detection
/// 2", ...) — this app always shows at most one of these per photo,
/// matching the single-item scanning product interaction.
class DetectionCard extends StatelessWidget {
  final DetectionResult detection;

  const DetectionCard({super.key, required this.detection});

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
        return Icons.help_outline_rounded;
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
    final binAsset = BinAssetMapper.assetFor(detection.wasteClass);

    return Card(
      shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: const BorderSide(color: Color.fromARGB(255, 184, 175, 152)),
    ),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: Icon(
                    _iconFor(detection.wasteClass),
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Detected',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: AppColors.brownSecondary,
                            ),
                      ),
                      Text(
                        _labelFor(detection.wasteClass, detection.rawLabel),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppColors.brownPrimary,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // --- AI output (model confidence score, not a probability
            // of correctness) ------------------------------------------
            Text(
              'Confidence',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.brownSecondary,
                  ),
            ),
            const SizedBox(height: 4),
            ConfidenceIndicator(confidence: detection.confidence),

            // --- Recycling-bin illustration ----------------------------

            if (binAsset != null) ...[
              const SizedBox(height: 20),

              Center(
                child: _BinPop(
                  child: SizedBox(
                    width: 130,
                    height: 130,
                    child: Image.asset(
                      binAsset,
                      fit: BoxFit.contain,

                      errorBuilder: (
                        context,
                        error,
                        stackTrace,
                      ) {
                        debugPrint(
                          'BIN ASSET FAILED: $binAsset',
                        );

                        debugPrint(
                          'BIN ASSET ERROR: $error',
                        );

                        return Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius:
                                BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.red,
                              width: 2,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'BIN FAILED',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              Center(
                child: Text(
                  'Recycle using the ${guidance.shortLabel}',
                  textAlign: TextAlign.center,
                  style:
                      Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(
                            color: AppColors.brownPrimary,
                          ),
                ),
              ),

              const SizedBox(height: 16),
            ] else
              const SizedBox(height: 16),

            // --- Application logic (NOT from the AI model) -------------
            RecyclingGuidanceCard(guidance: guidance),
          ],
        ),
      ),
    );
  }
}

/// Simple pop + fade entrance for the bin illustration. Built entirely
/// with core Flutter (TweenAnimationBuilder) — no animation package
/// needed for this.
class _BinPop extends StatelessWidget {
  final Widget child;
  const _BinPop({required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: Transform.scale(scale: 0.7 + (0.3 * value), child: child),
        );
      },
      child: child,
    );
  }
}
