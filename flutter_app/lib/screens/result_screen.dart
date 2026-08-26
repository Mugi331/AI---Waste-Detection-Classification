import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/detection_result.dart';
import '../services/audio_service.dart';
import '../theme/app_theme.dart';
import '../widgets/bounding_box_overlay.dart';
import '../widgets/detection_card.dart';

class ResultScreen extends StatefulWidget {
  final Uint8List imageBytes;
  final DetectionResponse response;

  const ResultScreen({
    super.key,
    required this.imageBytes,
    required this.response,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  @override
  void initState() {
    super.initState();

    // ResultScreen is the single authority for result feedback:
    // success result -> success.mp3
    // no-detection result -> error.mp3
    if (widget.response.hasResult) {
      AppAudioService.instance.playSuccess();
    } else {
      AppAudioService.instance.playError();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detection Result'),
      ),
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
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: AspectRatio(
                          aspectRatio:
                              widget.response.imageWidth /
                              widget.response.imageHeight,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.memory(
                                widget.imageBytes,
                                fit: BoxFit.cover,
                              ),
                              BoundingBoxOverlay(
                                detection:
                                    widget.response.hasResult
                                        ? widget.response.primaryDetection
                                        : null,
                                imageWidth:
                                    widget.response.imageWidth,
                                imageHeight:
                                    widget.response.imageHeight,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (widget.response.hasResult)
                        DetectionCard(
                          detection:
                              widget.response.primaryDetection!,
                        )
                      else
                        _buildNoDetectionState(context),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () async {
                    await AppAudioService.instance.playClick();

                    if (!context.mounted) return;

                    Navigator.pop(context);
                  },
                  icon: const Icon(
                    Icons.refresh_rounded,
                  ),
                  label: const Text(
                    'Scan Another Item',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoDetectionState(
    BuildContext context,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: 32,
        horizontal: 20,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.borderLight,
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.search_off_rounded,
            size: 44,
            color: AppColors.brownSecondary,
          ),
          const SizedBox(height: 12),
          Text(
            "Couldn't identify this one",
            style:
                Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(
                      color: AppColors.brownPrimary,
                    ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Try centring one item, moving closer, or improving the lighting.',
            style:
                Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(
                      color: AppColors.brownSecondary,
                    ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
