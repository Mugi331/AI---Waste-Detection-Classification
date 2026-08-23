import 'package:flutter/material.dart';
import '../models/recycling_guidance.dart';

/// Displays recycling/disposal guidance, visually separated from the
/// raw AI detection result above it (see [DetectionCard]) so it's
/// clear the guidance is application logic, not a model output.
class RecyclingGuidanceCard extends StatelessWidget {
  final RecyclingGuidance guidance;

  const RecyclingGuidanceCard({super.key, required this.guidance});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: guidance.binColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: guidance.binColor, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.delete_outline, size: 18, color: guidance.binColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  guidance.binName,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: guidance.binColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(guidance.summary, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 8),
          ...guidance.tips.map(
            (tip) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('•  '),
                  Expanded(
                    child: Text(tip, style: Theme.of(context).textTheme.bodySmall),
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
