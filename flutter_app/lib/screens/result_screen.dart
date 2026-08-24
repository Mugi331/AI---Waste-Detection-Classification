import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/detection_result.dart';
import '../widgets/bounding_box_overlay.dart';
import '../widgets/detection_card.dart';

/// Shows the outcome of analysing ONE photographed waste item:
/// either a single primary result (image + one box + one confidence
/// score + one recycling recommendation), or a clear "no confident
/// detection" state. Never shows a count of "items detected" and
/// never lists multiple result cards — this app is a single-item
/// scanner, not a general multi-object detector viewer.
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
                      // --- Image + single bounding-box overlay -----------
                      // The AspectRatio here is matched exactly to the
                      // analysed image's own aspect ratio, so BoxFit.cover
                      // produces no cropping/letterboxing — see the
                      // alignment note in bounding_box_overlay.dart.
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: AspectRatio(
                          aspectRatio: response.imageWidth / response.imageHeight,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.memory(imageBytes, fit: BoxFit.cover),
                              BoundingBoxOverlay(
                                detection: response.hasResult
                                    ? response.primaryDetection
                                    : null,
                                imageWidth: response.imageWidth,
                                imageHeight: response.imageHeight,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // --- Single result, or no-detection state ----------
                      if (response.hasResult)
                        DetectionCard(detection: response.primaryDetection!)
                      else
                        _buildNoDetectionState(context, scheme),
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

  Widget _buildNoDetectionState(BuildContext context, ColorScheme scheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.search_off, size: 48, color: scheme.outline),
          const SizedBox(height: 12),
          Text(
            'No confident material was detected',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'The photo didn\'t contain a result the app was confident enough '
            'to show. To improve results, try to:',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.outline,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: const [
                _Tip(text: 'Photograph one item at a time'),
                _Tip(text: 'Centre the item in the frame'),
                _Tip(text: 'Move closer so it fills more of the photo'),
                _Tip(text: 'Improve lighting and avoid strong shadows'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Tip extends StatelessWidget {
  final String text;
  const _Tip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•  '),
          Expanded(child: Text(text, style: Theme.of(context).textTheme.bodySmall)),
        ],
      ),
    );
  }
}
