# EcoSort AI — Waste Detection & Classification for Recycling Assistance

A focused, single-item recycling scanner: photograph one waste item,
get one material prediction and one recycling recommendation.

```
ai-waste-detection/
├── notebooks/            # model training/experimentation (Python/Colab)
├── src/                  # training scripts, dataset prep
├── backend/
│   ├── app.py             # FastAPI inference API
│   ├── requirements.txt
│   └── models/
│       └── best.pt        # trained YOLOv8n weights (not committed to git)
└── flutter_app/           # Flutter Web frontend
```

## 1. Product interaction

This is **not** a general multi-object detector viewer. The product
contract is:

```
User photographs ONE waste item
        ↓
Image preview + retake/change option
        ↓
User confirms analysis
        ↓
Flutter sends the image to the backend
        ↓
Detector internally may produce several candidate boxes
        ↓
Backend selects ONE primary candidate (see §3)
        ↓
ONE material class + ONE confidence + ONE bounding box returned
        ↓
Flutter shows ONE result card + ONE recycling recommendation
```

The detector remains a normal object detector — it is not retrained
or converted into a classifier. The single-result behaviour comes
from an explicit **primary-selection layer** in `backend/app.py`, not
from changing what the model does.

## 2. Two different confidence concepts

| | Purpose | Where |
|---|---|---|
| **Model inference threshold** (`MODEL_CONF_THRESHOLD = 0.25`) | Which raw candidate boxes the detector returns at all | `backend/app.py` |
| **Application acceptance threshold** (`APP_ACCEPTANCE_THRESHOLD = 0.50`) | Whether the app is willing to *show* the selected candidate to the user | `backend/app.py` |

If the best eligible candidate doesn't clear the acceptance
threshold, the API returns `status: "no_detection"` rather than
forcing a classification. **This does not mean the model is more
accurate** — it means the app won't present a low-confidence guess as
if it were a confident answer. A confidently-selected result can
still be the wrong class; that's a model-generalisation question,
evaluated separately (e.g. we've observed the baseline model
confidently misclassify a paper bag).

## 3. Primary-selection policy

Kept deliberately simple and explainable — no scoring formula, just
sequential filters:

1. Normalise detector labels and discard any label outside the four
   supported canonical classes (`Plastic`, `Metal`, `Paper_Cardboard`, `Glass`).
2. Discard malformed / out-of-bounds boxes.
3. Discard boxes smaller than `MIN_BOX_AREA_RATIO` (2%) of the image
   area — too small to plausibly be the deliberately-photographed
   focus item.
4. Discard boxes centred outside the central `1 − 2×CENTRAL_REGION_MARGIN`
   (70%) region of the frame — the user was asked to centre the item,
   so this treats a stray background object as ineligible.
5. Among what remains, take the highest-confidence candidate.

All four constants live at the top of `backend/app.py`, not scattered
through the code.

## 4. API contract

```
POST /predict
Content-Type: multipart/form-data
Field: file
```

Success:

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

No confident detection:

```json
{
  "primary_detection": null,
  "image_width": 1200,
  "image_height": 1600,
  "candidate_count": 3,
  "status": "no_detection"
}
```

`bbox` and `image_width`/`image_height` are always in the **same
pixel space** — the image actually fed to the detector, after EXIF
orientation correction and RGB conversion (and, if triggered, a
defensive downscale — see `MAX_IMAGE_DIMENSION`). The Flutter client
never needs to know the original upload's raw dimensions; it only
uses `image_width`/`image_height` to scale the box onto whatever size
it renders the preview at.

`candidate_count` reflects however many raw boxes the detector produced
internally above `MODEL_CONF_THRESHOLD`, **before** application-level label,
size, central-region, or acceptance filtering. Therefore a `no_detection`
response may legitimately have `candidate_count > 0`. It is informational
only; the UI never lists those candidates.

## 5. Image handling

- **EXIF orientation**: corrected via `ImageOps.exif_transpose()`
  before conversion to RGB, so a portrait phone photo doesn't get
  analysed sideways while displaying upright (or vice versa).
- **Consistency**: the exact bytes Flutter previews are the exact
  bytes sent to the backend. The backend reports bounding boxes in its
  post-EXIF / post-safety-resize pixel space, while Flutter scales those
  coordinates using the returned `image_width` / `image_height`.
- **Overlay geometry**: the result image uses `BoxFit.contain`, and
  `BoundingBoxOverlay` applies the same aspect-preserving scale plus
  letterboxing offsets. The box therefore remains aligned even if the
  result container's aspect ratio changes later.
- **Large images**: Flutter's image picker already constrains
  `maxWidth` to 1600px; the backend additionally caps at
  `MAX_IMAGE_DIMENSION = 2000px` as a defensive measure, always
  reporting the actual post-cap dimensions used for inference.
- **Invalid uploads**: non-image or corrupted files return a clear
  `400` with a user-facing message, never a crash or a raw stack
  trace.
- **Phone-orientation verification**: before release, manually test at least
  one portrait photo, one landscape photo, one rotated/EXIF-oriented phone
  photo, and one tall 9:16 photo. In every case, verify that the displayed
  image orientation matches the analysed item and that the box remains on
  the same object. This is a black-box UI verification step, not a claim
  that can be proven from source code alone.

## 6. Detector-agnosticism

`backend/app.py` is the only file that knows a YOLO model is
involved. A future SSD / Faster R-CNN / EfficientDet backend just
needs to populate the same internal candidate shape (raw label,
confidence, x1..y2) — `select_primary_detection()` and the JSON
contract above stay identical, and **no Flutter file needs to
change**.

On the Flutter side, `DetectionResult` / `DetectionResponse`
(`flutter_app/lib/models/detection_result.dart`) only ever see
`{ class, confidence, bbox }` — no YOLO-specific concepts appear
anywhere in the frontend.

## 7. Running the backend

```bash
cd backend
pip install -r requirements.txt
uvicorn app:app --reload --port 8000
```

Health check: `GET /health` → `{"status": "ok", "model_loaded": true}`

## 8. Running the frontend

See `flutter_app/README.md` for Flutter-specific setup, the Windows
Developer Mode / symlink requirement, camera-on-Safari notes, and
GitHub Pages deployment.

`ApiDetectionService` applies the same timeout to both the initial request
and the streamed response body, so a server that stalls after accepting the
request still returns a controlled user-facing timeout rather than hanging.

To point the frontend at a real backend instead of the mock, edit the
last line of `flutter_app/lib/services/detection_service.dart`:

```dart
final DetectionService detectionService =
    ApiDetectionService(baseUrl: 'https://your-api.example.com');
```
