import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/detection_service.dart';
import 'result_screen.dart';

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
    // Prevent picking a new image mid-analysis, which could otherwise
    // race with an in-flight request and show a stale result.
    if (_status == _ScanStatus.analysing) return;

    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        imageQuality: 90,
        maxWidth: 1600,
      );
      if (file == null) return; // user cancelled — leave state as-is

      final bytes = await file.readAsBytes();

      // A new image invalidates any previous analysis/error — always
      // start the next screen state from a clean slate.
      setState(() {
        _imageBytes = bytes;
        _status = _ScanStatus.idle;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _status = _ScanStatus.error;
        _errorMessage = 'Could not access camera/gallery: $e';
      });
    }
  }

  Future<void> _analyse() async {
    // Guards: no image selected, or a request already in flight.
    if (_imageBytes == null || _status == _ScanStatus.analysing) return;

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
    } catch (_) {
      if (!mounted || _imageBytes != bytesAtRequestTime) return;
      setState(() {
        _status = _ScanStatus.error;
        _errorMessage = 'Something went wrong while analysing the image.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Scan Waste')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildInstructions(scheme),
              const SizedBox(height: 12),
              Expanded(child: _buildPreviewArea(scheme)),
              const SizedBox(height: 20),
              if (_status == _ScanStatus.error && _errorMessage != null)
                _buildErrorBanner(scheme),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _status == _ScanStatus.analysing
                          ? null
                          : () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Gallery'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _status == _ScanStatus.analysing
                          ? null
                          : () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: const Text('Camera'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
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
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.search),
                  label: Text(
                    _status == _ScanStatus.analysing
                        ? 'Analysing…'
                        : 'Analyse Waste',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstructions(ColorScheme scheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.center_focus_strong, size: 18, color: scheme.onSecondaryContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Photograph one item at a time. Keep it centred, fully visible, '
              'and well lit.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSecondaryContainer,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewArea(ColorScheme scheme) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _imageBytes == null
              ? _buildEmptyPreview(scheme)
              : Image.memory(_imageBytes!, fit: BoxFit.contain),
          if (_status == _ScanStatus.analysing)
            Container(
              color: Colors.black.withValues(alpha: 0.35),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 12),
                    Text(
                      'Analysing image…',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
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

  Widget _buildEmptyPreview(ColorScheme scheme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.image_outlined, size: 64, color: scheme.outline),
          const SizedBox(height: 12),
          Text(
            'No image selected',
            style: TextStyle(color: scheme.outline, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Use Camera or Gallery below',
            style: TextStyle(color: scheme.outline, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(ColorScheme scheme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      width: double.infinity,
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: scheme.onErrorContainer),
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
