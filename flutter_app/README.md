# WE Snap — Flutter Web Frontend

Mobile-first prototype for the Waste Detection & Classification for
Recycling Assistance project. The AI model (YOLOv8n today, possibly
SSD / Faster R-CNN / EfficientDet later) is developed separately in
Python; this app contains **no Python, PyTorch, Ultralytics, or
`best.pt`** — it only calls a `DetectionService` interface that can
point at a mock today and a real HTTP API later.

## 1. Folder structure

```
lib/
├── main.dart                          # App entry point, theme + home route
├── theme/
│   └── app_theme.dart                 # Centralised Material 3 theme
├── models/
│   ├── detection_result.dart          # BoundingBox, WasteClass, DetectionResult, DetectionResponse
│   └── recycling_guidance.dart        # RecyclingGuidance data class
├── data/
│   └── guidance_repository.dart       # WasteClass -> RecyclingGuidance lookup (Malaysia bin colours)
├── services/
│   └── detection_service.dart         # DetectionService interface + MockDetectionService (+ future API impl)
├── widgets/
│   ├── confidence_indicator.dart      # Colour-coded confidence bar
│   ├── detection_card.dart            # One detection: class + confidence + guidance
│   ├── recycling_guidance_card.dart   # Bin colour / summary / tips panel
│   └── bounding_box_overlay.dart      # CustomPainter that draws boxes over the image
└── screens/
    ├── home_screen.dart               # Branding + "Scan Waste" CTA
    ├── scan_screen.dart               # Camera/gallery picking, preview, loading, error
    └── result_screen.dart             # Image + boxes, detection list, empty state, "scan another"
```

## 2. What each file is responsible for

- **`models/detection_result.dart`** — The generic, detector-agnostic
  data shape (`class`, `confidence`, `bbox`) that everything else
  depends on. `BoundingBox.toRect()` scales AI-space coordinates onto
  whatever size the image is actually rendered at.
- **`services/detection_service.dart`** — The single abstraction
  boundary between UI and AI. `MockDetectionService` randomly returns
  one of three canned multi-item scenarios, an "occasional failure",
  or an "occasional no-detection" result, so every UI state (loading,
  success, error, empty) can be demoed without a backend. The exact
  spot to add the real API call is marked with `🔌` comments.
- **`data/guidance_repository.dart`** — Recycling guidance is
  **application logic, not an AI output**. This file is the only
  place that maps a material class to Malaysia's bin colours (Blue =
  Paper, Brown = Glass, Orange = Plastics & Metals).
- **`widgets/bounding_box_overlay.dart`** — Draws one rectangle +
  label per detection on top of the preview image, colour-cycled so
  overlapping boxes stay distinguishable.
- **`widgets/detection_card.dart`** / **`recycling_guidance_card.dart`**
  — Deliberately split into two visual blocks per card so the raw AI
  result (confidence bar) is visually separate from the
  application-derived guidance (coloured side panel).
- **`screens/scan_screen.dart`** — Owns image selection + the single
  `detectionService.analyseImage(...)` call site, and its
  loading/error UI.
- **`screens/result_screen.dart`** — Purely presentational: renders
  whatever `DetectionResponse` it's given, including the "no items
  detected" empty state.

## 3. Packages added to `pubspec.yaml`

```yaml
dependencies:
  image_picker: ^1.1.2   # camera + gallery, incl. Flutter Web support
  http: ^1.2.2            # for the real backend call later (not used yet)
```

Run after copying files in:

```bash
flutter pub get
```

## 4. Running locally

```bash
cd flutter_app
flutter pub get
flutter run -d chrome
```

This opens the app in desktop Chrome. Desktop browsers don't have a
"real" camera capture UI, so tapping **Camera** there just opens a
normal file picker — that's expected and fine for development.

## 5. Getting the camera to work on iPhone/iPad Safari

This is Flutter **Web** running inside Safari, not a native iOS
build, so there's no `Info.plist` entry to add. Camera access is
entirely handled by the browser via `image_picker`'s web
implementation, with two practical requirements:

1. **HTTPS is required.** Mobile Safari only allows camera capture
   from a *secure context*. `flutter run -d chrome` on `localhost`
   won't let you test the real camera sheet on an iPhone over your
   LAN. For real-device testing:
   ```bash
   flutter build web
   ```
   then deploy the `build/web` folder to any HTTPS static host —
   Firebase Hosting, GitHub Pages, Netlify, or Vercel all work and
   are free for a prototype. Open that HTTPS URL in Safari on the
   iPhone/iPad.
2. **User gesture required.** The camera/gallery sheet can only be
   triggered directly from a tap (which is exactly what the Camera/
   Gallery buttons in `scan_screen.dart` already do — no extra work
   needed).

When it's set up correctly, tapping **Camera** on an iPhone opens the
native "Take Photo or Video / Choose Existing / Cancel" action sheet;
tapping **Gallery** opens the Photos picker directly. The first time,
Safari will prompt for camera permission — no code changes are needed
to handle that, it's a browser-level permission dialog.

## 6. Where to plug in the real AI backend

`ApiDetectionService` in `lib/services/detection_service.dart` is
already implemented — it's not a stub. To use it instead of the mock,
change the last line of that file from:

```dart
final DetectionService detectionService = MockDetectionService();
```

to:

```dart
final DetectionService detectionService =
    ApiDetectionService(baseUrl: 'https://your-api.example.com');
```

Nothing else in the app needs to change — screens and widgets only
depend on the `DetectionService` interface and `DetectionResponse`
model, not on how the data was obtained.

**This app is a single-item scanner, not a multi-object viewer.** The
backend returns at most one primary detection per photo — see the
project-root `README.md` for the full API contract, the
model-inference-threshold vs. application-acceptance-threshold
distinction, and the primary-selection policy. Expected shape
(matched by `DetectionResponse.fromJson`):

```json
{
  "primary_detection": {
    "class": "Plastic",
    "confidence": 0.87,
    "bbox": [120, 80, 310, 420]
  },
  "image_width": 1200,
  "image_height": 1600,
  "candidate_count": 3,
  "status": "success"
}
```

or, when nothing clears the acceptance threshold:

```json
{
  "primary_detection": null,
  "image_width": 1200,
  "image_height": 1600,
  "candidate_count": 0,
  "status": "no_detection"
}
```

(`image_width` / `image_height` are the pixel dimensions `bbox` is
relative to — required for the Flutter overlay to scale the box
correctly regardless of how the image is displayed.)

## 7. Notes on model-agnosticism

- No Flutter file references YOLO, `.pt` weights, or any
  detector-specific concept. `DetectionResult` only ever sees
  `{ class, confidence, bbox }`, so SSD, Faster R-CNN, or
  EfficientDet can replace YOLOv8n on the Python side with zero
  Flutter changes, as long as the API response is normalised to that
  shape.
- `WasteClass` is a fixed 4-class enum (`plastic`, `metal`,
  `paperCardboard`, `glass`) plus `unknown` as a safe fallback for any
  unrecognised label string, so the UI never crashes on a class name
  it doesn't recognise.
- A high confidence score is the model's own confidence, not a
  guarantee of correctness — the UI does not claim otherwise.
