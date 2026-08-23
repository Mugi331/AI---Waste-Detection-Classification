import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/detection_result.dart';
import '../widgets/bounding_box_overlay.dart';
import '../widgets/detection_card.dart';

class ResultScreen extends StatelessWidget {
  final Uint8List imageBytes;
  final DetectionResponse response;

  const ResultScreen({
    super.key,
    required this.imageBytes,
    required this.response,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Detection Result')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- Image + bounding-box overlay -----------------
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: AspectRatio(
                          aspectRatio: response.imageWidth / response.imageHeight,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.memory(imageBytes, fit: BoxFit.cover),
                              if (response.hasDetections)
                                BoundingBoxOverlay(
                                  detections: response.detections,
                                  imageWidth: response.imageWidth,
                                  imageHeight: response.imageHeight,
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // --- Detections list, or empty state --------------
                      if (response.hasDetections) ...[
                        Text(
                          '${response.detections.length} item'
                          '${response.detections.length > 1 ? 's' : ''} detected',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 12),
                        for (var i = 0; i < response.detections.length; i++)
                          DetectionCard(
                            detection: response.detections[i],
                            index: i,
                          ),
                      ] else
                        _buildEmptyState(context, scheme),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () =>
                      Navigator.popUntil(context, (route) => route.isFirst),
                  icon: const Icon(Icons.replay),
                  label: const Text('Scan Another Item'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ColorScheme scheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.search_off, size: 48, color: scheme.outline),
          const SizedBox(height: 12),
          Text(
            'No recyclable material detected',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Try a clearer photo, better lighting, or move closer to the item.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.outline,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
