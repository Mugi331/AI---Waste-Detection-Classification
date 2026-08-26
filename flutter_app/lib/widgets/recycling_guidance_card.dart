import 'package:flutter/material.dart';
import '../models/recycling_guidance.dart';
import '../theme/app_theme.dart';

/// Displays recycling/disposal guidance, visually separated from the
/// raw AI detection result above it (see [DetectionCard]) so it's
/// clear the guidance is application logic, not a model output.
///
/// The small coloured dot next to the bin name uses
/// [RecyclingGuidance.binColor] — the FACTUAL bin colour (blue/brown/
/// orange), not a decorative pastel. That distinction is intentional:
/// see the note in `theme/app_theme.dart`.
class RecyclingGuidanceCard extends StatelessWidget {
  final RecyclingGuidance guidance;

  const RecyclingGuidanceCard({super.key, required this.guidance});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: guidance.binColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  guidance.binName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.brownPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            guidance.summary,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.brownPrimary),
          ),
          const SizedBox(height: 10),
          ...guidance.tips.map(
            (tip) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🌱  ', style: TextStyle(fontSize: 12)),
                  Expanded(
                    child: Text(
                      tip,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.brownSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
