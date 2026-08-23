import 'dart:math';
import 'dart:typed_data';
import '../models/detection_result.dart';

/// Abstraction over "however we get detections for an image".
///
/// The UI (ScanScreen) only ever depends on this interface — never on
/// a concrete model or framework. Swapping YOLOv8n for SSD /
/// Faster R-CNN / EfficientDet, or moving from a mock to a real
/// backend, only requires providing a different implementation of
/// this class. No screen or widget needs to change.
abstract class DetectionService {
  Future<DetectionResponse> analyseImage(Uint8List imageBytes);
}

/// Thrown by a [DetectionService] on network/inference failure so the
/// UI can show a friendly error state.
class DetectionServiceException implements Exception {
  final String message;
  DetectionServiceException(this.message);

  @override
  String toString() => message;
}

/// Temporary implementation returning randomised canned results, so
/// the whole frontend (including loading / error / empty states) is
/// fully demoable before a real backend exists.
class MockDetectionService implements DetectionService {
  final Random _random = Random();

  @override
  Future<DetectionResponse> analyseImage(Uint8List imageBytes) async {
    // Simulate network / inference latency.
    await Future.delayed(const Duration(milliseconds: 1400));

    // Occasionally simulate a backend/network failure, so the
    // ScanScreen error state can be demoed without touching code.
    if (_random.nextDouble() < 0.08) {
      throw DetectionServiceException(
        'Could not reach the detection service. Please try again.',
      );
    }

    // Occasionally simulate a "nothing recognisable" result, so the
    // ResultScreen empty state can be demoed without touching code.
    if (_random.nextDouble() < 0.12) {
      return const DetectionResponse(
        detections: [],
        imageWidth: 1000,
        imageHeight: 1000,
      );
    }

    final scenarios = <List<Map<String, dynamic>>>[
      [
        {
          'class': 'Plastic',
          'confidence': 0.94,
          'bbox': [120.0, 80.0, 480.0, 620.0],
        },
      ],
      [
        {
          'class': 'Plastic',
          'confidence': 0.91,
          'bbox': [80.0, 60.0, 380.0, 520.0],
        },
        {
          'class': 'Metal',
          'confidence': 0.84,
          'bbox': [420.0, 150.0, 680.0, 500.0],
        },
      ],
      [
        {
          'class': 'Glass',
          'confidence': 0.88,
          'bbox': [100.0, 100.0, 420.0, 600.0],
        },
        {
          'class': 'Paper_Cardboard',
          'confidence': 0.76,
          'bbox': [450.0, 220.0, 760.0, 640.0],
        },
        {
          'class': 'Metal',
          'confidence': 0.61,
          'bbox': [200.0, 620.0, 500.0, 900.0],
        },
      ],
    ];

    final chosen = scenarios[_random.nextInt(scenarios.length)];

    return DetectionResponse.fromJson({
      'detections': chosen,
      'image_width': 1000,
      'image_height': 1000,
    });
  }
}

// ============================================================================
// 🔌 FUTURE REAL BACKEND INTEGRATION POINT
// ============================================================================
// When the Python/Colab-trained model is served behind a real API,
// implement DetectionService like this and swap the single line at
// the bottom of this file. No screen, widget, or model file needs to
// change — they only depend on the DetectionService interface above.
//
// Uncomment, then add to pubspec.yaml (already listed) and import:
//   import 'dart:convert';
//   import 'package:http/http.dart' as http;
//
// class ApiDetectionService implements DetectionService {
//   final String baseUrl;
//   ApiDetectionService({required this.baseUrl});
//
//   @override
//   Future<DetectionResponse> analyseImage(Uint8List imageBytes) async {
//     final uri = Uri.parse('$baseUrl/detect');
//     final request = http.MultipartRequest('POST', uri)
//       ..files.add(http.MultipartFile.fromBytes(
//         'image',
//         imageBytes,
//         filename: 'upload.jpg',
//       ));
//
//     final streamed = await request.send();
//     final response = await http.Response.fromStream(streamed);
//
//     if (response.statusCode != 200) {
//       throw DetectionServiceException(
//         'Detection service returned ${response.statusCode}',
//       );
//     }
//
//     final json = jsonDecode(response.body) as Map<String, dynamic>;
//     return DetectionResponse.fromJson(json);
//   }
// }
// ============================================================================

/// Single instantiation point used across the whole app.
///
/// 👉 TO SWITCH TO A REAL BACKEND: change this one line, e.g.:
///    final DetectionService detectionService =
///        ApiDetectionService(baseUrl: 'https://your-api.example.com');
final DetectionService detectionService = MockDetectionService();
