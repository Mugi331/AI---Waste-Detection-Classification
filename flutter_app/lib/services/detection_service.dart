import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../models/detection_result.dart';

/// Abstraction over "however we get a primary detection for an image".
///
/// The UI (ScanScreen) only ever depends on this interface — never on
/// a concrete model or framework. Swapping YOLOv8n for SSD /
/// Faster R-CNN / EfficientDet, or moving from a mock to a real
/// backend, only requires providing a different implementation of
/// this class. No screen or widget needs to change.
///
/// Contract: exactly one analysis attempt per call. Implementations
/// must return a [DetectionResponse] with at most ONE
/// [DetectionResponse.primaryDetection] — never a list — matching the
/// backend's single-primary-detection response shape.
abstract class DetectionService {
  Future<DetectionResponse> analyseImage(Uint8List imageBytes);
}

/// Thrown by a [DetectionService] on network/backend/parsing failure
/// so the UI can show a friendly, specific error state. This is
/// distinct from a successful response with status "no_detection" —
/// that is NOT an error, it's a valid outcome the UI shows directly.
class DetectionServiceException implements Exception {
  final String message;
  DetectionServiceException(this.message);

  @override
  String toString() => message;
}

/// Calls the real Python/FastAPI backend.
///
/// POSTs to `$baseUrl/predict` with a single multipart field named
/// "file", and parses the backend's { primary_detection, image_width,
/// image_height, candidate_count, status } response shape.
class ApiDetectionService implements DetectionService {
  final String baseUrl;
  final Duration timeout;

  ApiDetectionService({
    required this.baseUrl,
    this.timeout = const Duration(seconds: 30),
  });

  @override
  Future<DetectionResponse> analyseImage(Uint8List imageBytes) async {
    final uri = Uri.parse('$baseUrl/predict');

    http.StreamedResponse streamed;
    try {
      final request = http.MultipartRequest('POST', uri)
        ..files.add(
          http.MultipartFile.fromBytes(
            'file',
            imageBytes,
            filename: 'upload.jpg',
          ),
        );
      streamed = await request.send().timeout(timeout);
    } on TimeoutException {
      throw DetectionServiceException(
        'The detection service took too long to respond. Please try again.',
      );
    } catch (_) {
      throw DetectionServiceException(
        'Could not reach the detection service. Check your connection and try again.',
      );
    }

    final http.Response response;
    try {
      response = await http.Response
          .fromStream(streamed)
          .timeout(timeout);
    } on TimeoutException {
      throw DetectionServiceException(
        'The detection service took too long to finish sending the result. Please try again.',
      );
    } catch (_) {
      throw DetectionServiceException(
        'The connection was interrupted while receiving the result.',
      );
    }

    if (response.statusCode != 200) {
      throw DetectionServiceException(_extractServerError(response));
    }

    Map<String, dynamic> json;
    try {
      json = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw DetectionServiceException(
        'Received an unexpected response from the server.',
      );
    }

    try {
      return DetectionResponse.fromJson(json);
    } catch (_) {
      throw DetectionServiceException(
        'Received a malformed response from the server.',
      );
    }
  }

  /// FastAPI's default HTTPException body looks like {"detail": "..."}
  /// — surface that message when present, otherwise fall back to a
  /// generic status-code message. Never leaks raw stack traces.
  String _extractServerError(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      if (body is Map && body['detail'] is String) {
        return body['detail'] as String;
      }
    } catch (_) {
      // fall through to generic message
    }
    return 'Detection service returned an error (${response.statusCode}).';
  }
}

/// Temporary implementation returning a single randomised primary
/// detection (or an occasional no-detection / failure), so the whole
/// frontend is demoable before/without the real backend.
///
/// Follows the SAME single-primary-detection contract as
/// [ApiDetectionService] — it must never return more than one
/// detection, so the UI is never tested against a shape the real
/// backend won't actually produce.
class MockDetectionService implements DetectionService {
  final Random _random = Random();

  @override
  Future<DetectionResponse> analyseImage(Uint8List imageBytes) async {
    await Future.delayed(const Duration(milliseconds: 1400));

    // Simulate an occasional backend/network failure.
    if (_random.nextDouble() < 0.08) {
      throw DetectionServiceException(
        'Could not reach the detection service. Please try again.',
      );
    }

    const imageWidth = 1000.0;
    const imageHeight = 1000.0;

    // Simulate an occasional "no candidate passed the acceptance
    // threshold" outcome — a valid, non-error result.
    if (_random.nextDouble() < 0.15) {
      return const DetectionResponse(
        primaryDetection: null,
        imageWidth: imageWidth,
        imageHeight: imageHeight,
        candidateCount: 0,
        status: DetectionStatus.noDetection,
      );
    }

    final scenarios = <Map<String, dynamic>>[
      {
        'class': 'Plastic',
        'confidence': 0.94,
        'bbox': [220.0, 150.0, 780.0, 820.0],
      },
      {
        'class': 'Metal',
        'confidence': 0.81,
        'bbox': [200.0, 180.0, 760.0, 800.0],
      },
      {
        'class': 'Paper_Cardboard',
        'confidence': 0.76,
        'bbox': [180.0, 160.0, 800.0, 840.0],
      },
      {
        'class': 'Glass',
        'confidence': 0.88,
        'bbox': [230.0, 140.0, 770.0, 830.0],
      },
    ];

    final chosen = scenarios[_random.nextInt(scenarios.length)];

    return DetectionResponse.fromJson({
      'primary_detection': chosen,
      'image_width': imageWidth,
      'image_height': imageHeight,
      // Simulates the detector having internally seen more than one
      // raw candidate even though only one is ever surfaced.
      'candidate_count': 1 + _random.nextInt(3),
      'status': 'success',
    });
  }
}

/// Single instantiation point used across the whole app.
///
/// 👉 TO SWITCH TO THE REAL BACKEND: change this one line, e.g.:
///    final DetectionService detectionService =
///        ApiDetectionService(baseUrl: 'https://your-api.example.com');
final DetectionService detectionService =
    ApiDetectionService(
      baseUrl: 'http://127.0.0.1:8000',
    );

