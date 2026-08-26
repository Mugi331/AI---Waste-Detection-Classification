import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Small horizontal confidence bar + percentage label.
///
/// Uses a single warm sage fill rather than red/amber/green
/// "traffic-light" styling. A lower score isn't a warning the user
/// needs to react to — it's simply the model's own confidence in its
/// one prediction, shown plainly, not editorialised.
class ConfidenceIndicator extends StatelessWidget {
  final double confidence; // 0.0 - 1.0

  const ConfidenceIndicator({super.key, required this.confidence});

  @override
  Widget build(BuildContext context) {
    final clamped = confidence.clamp(0.0, 1.0);

    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: clamped,
              minHeight: 10,
              backgroundColor: AppColors.sage.withValues(alpha: 0.18),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.sage),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '${(clamped * 100).toStringAsFixed(0)}%',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.brownPrimary,
          ),
        ),
      ],
    );
  }
}
