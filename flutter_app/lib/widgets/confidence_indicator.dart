import 'package:flutter/material.dart';

/// Small horizontal confidence bar + percentage label.
///
/// Colour-coded so a reviewer can read confidence at a glance:
///   >= 80%  green   (high confidence)
///   50-79%  amber   (medium confidence)
///   < 50%   red     (low confidence)
class ConfidenceIndicator extends StatelessWidget {
  final double confidence; // 0.0 - 1.0

  const ConfidenceIndicator({super.key, required this.confidence});

  Color _colorFor(double c) {
    if (c >= 0.8) return const Color(0xFF2E7D32);
    if (c >= 0.5) return const Color(0xFFF9A825);
    return const Color(0xFFC62828);
  }

  @override
  Widget build(BuildContext context) {
    final clamped = confidence.clamp(0.0, 1.0);
    final color = _colorFor(clamped);

    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: clamped,
              minHeight: 8,
              backgroundColor: color.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '${(clamped * 100).toStringAsFixed(0)}%',
          style: TextStyle(fontWeight: FontWeight.w700, color: color),
        ),
      ],
    );
  }
}
