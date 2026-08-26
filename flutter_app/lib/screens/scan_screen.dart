import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/detection_service.dart';
import '../services/audio_service.dart';
import '../theme/app_theme.dart';
import 'result_screen.dart';

import 'dart:async';


enum _ScanStatus { idle, analysing, error }

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final ImagePicker _picker = ImagePicker();

  Uint8List? _imageBytes;
  _ScanStatus _status = _ScanStatus.idle;
  String? _errorMessage;

  Future<void> _pickImage(ImageSource source) async {
    if (_status == _ScanStatus.analysing) return;

    // Fire the click sound without waiting for it.
    // This lets the protected Camera/Gallery action run immediately
    // from the same user tap.
    unawaited(
      AppAudioService.instance.playClick(),
    );

    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        imageQuality: 90,
        maxWidth: 1600,
      );

      if (file == null) return;

      final bytes = await file.readAsBytes();

      if (!mounted) return;

      setState(() {
        _imageBytes = bytes;
        _status = _ScanStatus.idle;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _status = _ScanStatus.error;
        _errorMessage =
            'Could not access camera/gallery: $e';
      });

      await AppAudioService.instance.playError();
    }
  }

  Future<void> _analyse() async {
    // Guards: no image selected, or a request already in flight.
    if (_imageBytes == null || _status == _ScanStatus.analysing) return;

    await AppAudioService.instance.playClick();

    final bytesAtRequestTime = _imageBytes!;

    setState(() {
      _status = _ScanStatus.analysing;
      _errorMessage = null;
    });

    try {
      // ------------------------------------------------------------
      // 🔌 Single call site for AI inference. Exactly one request per
      // tap (guarded above). Goes through the DetectionService
      // abstraction (currently mocked), so swapping in the real
      // backend requires no changes here — only in
      // lib/services/detection_service.dart.
      // ------------------------------------------------------------
      final result = await detectionService.analyseImage(bytesAtRequestTime);

      if (!mounted) return;
      // If the user swapped to a different image while this request
      // was in flight, discard this now-stale result rather than
      // navigating to a screen for the wrong photo.
      if (_imageBytes != bytesAtRequestTime) return;

      setState(() => _status = _ScanStatus.idle);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResultScreen(
            imageBytes: bytesAtRequestTime,
            response: result,
          ),
        ),
      );
    } on DetectionServiceException catch (e) {
      if (!mounted || _imageBytes != bytesAtRequestTime) return;
      setState(() {
        _status = _ScanStatus.error;
        _errorMessage = e.message;
      });

      await AppAudioService.instance.playError();
    } catch (_) {
      if (!mounted || _imageBytes != bytesAtRequestTime) return;
      setState(() {
        _status = _ScanStatus.error;
        _errorMessage = 'Something went wrong while analysing the image.';
      });

      await AppAudioService.instance.playError();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Waste')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildInstructions(context),
              const SizedBox(height: 12),
              Expanded(child: _buildPreviewArea(context)),
              const SizedBox(height: 20),
              if (_status == _ScanStatus.error && _errorMessage != null)
                _buildErrorBanner(context),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _status == _ScanStatus.analysing
                          ? null
                          : () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_rounded),
                      label: const Text('Gallery'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _status == _ScanStatus.analysing
                          ? null
                          : () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt_rounded),
                      label: const Text('Camera'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 255, 237, 157), 
                    foregroundColor: AppColors.brownPrimary,
                  ),
                  onPressed: (_imageBytes == null ||
                          _status == _ScanStatus.analysing)
                      ? null
                      : _analyse,
                  icon: _status == _ScanStatus.analysing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.brownPrimary,
                          ),
                        )
                      : const Icon(Icons.search_rounded),
                  label: Text(
                    _status == _ScanStatus.analysing
                        ? 'Analysing…'
                        : 'Detect Now',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstructions(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 255, 211, 92).withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.brownPrimary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Photograph one item at a time. Keep it centred, fully visible, '
              'and well lit.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.brownPrimary,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewArea(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: AppColors.brownPrimary.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _imageBytes == null
              ? _buildEmptyPreview(context)
              // NOTE: BoxFit.contain preserved deliberately — the
              // bounding-box overlay on ResultScreen assumes a known
              // coordinate relationship; do not change this to
              // cover/fill here.
              : Image.memory(_imageBytes!, fit: BoxFit.contain),
          if (_status == _ScanStatus.analysing)
            Container(
              color: AppColors.brownPrimary.withValues(alpha: 0.45),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppColors.pastelYellow),
                    SizedBox(height: 12),
                    Text(
                      'Analysing image…',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
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

  Widget _buildEmptyPreview(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.image_rounded, size: 64, color: AppColors.brownSecondary),
          const SizedBox(height: 12),
          Text(
            'No image selected',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.brownSecondary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Use Camera or Gallery below',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.brownSecondary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      width: double.infinity,
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: scheme.onErrorContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage ?? 'Something went wrong.',
              style: TextStyle(color: scheme.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}
