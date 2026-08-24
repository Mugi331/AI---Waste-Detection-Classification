"""
FastAPI backend for the EcoSort AI waste detection app.

Endpoint contract
------------------
POST /predict
    multipart/form-data, field name: "file"

Success response:
{
  "primary_detection": {
    "class": "Plastic",
    "confidence": 0.87,
    "bbox": [x1, y1, x2, y2]
  },
  "image_width": 1200,
  "image_height": 1600,
  "candidate_count": 3,
  "status": "success"
}

No confident detection (raw candidates may still have been produced):
{
  "primary_detection": null,
  "image_width": 1200,
  "image_height": 1600,
  "candidate_count": 3,
  "status": "no_detection"
}

bbox and image_width/image_height are ALWAYS expressed in the same pixel
space: the image actually fed to the detector, after EXIF-orientation
correction, RGB conversion, and (if triggered) the safety-cap downscale
below. The Flutter client only needs image_width/image_height to scale the
box onto whatever size it renders the preview at - it never needs to know
the original upload's raw dimensions.

Detector-agnosticism: this file is the ONLY place that knows a YOLO model
is being used. A future SSD / Faster R-CNN / EfficientDet backend just
needs to populate the same `candidates` list (raw_label, confidence,
x1..y2) below - select_primary_detection() and the response contract stay
identical.
"""

from __future__ import annotations

import io
import logging
from contextlib import asynccontextmanager
from dataclasses import dataclass
from typing import Optional

from fastapi import FastAPI, File, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from PIL import Image, ImageOps, UnidentifiedImageError

logger = logging.getLogger("ecosort.backend")
logging.basicConfig(level=logging.INFO)

# ============================================================================
# Configuration constants
# Kept centralised and named instead of scattered magic numbers, so the
# primary-selection policy stays easy to explain and to tune.
# ============================================================================

MODEL_PATH = "models/best.pt"

# (A) MODEL INFERENCE THRESHOLD
# Governs which raw candidate boxes the detector returns at all. Kept
# permissive so the primary-selection layer below has real candidates to
# reason about.
MODEL_CONF_THRESHOLD = 0.25

# (B) APPLICATION ACCEPTANCE THRESHOLD
# Governs whether the app is willing to SHOW the selected candidate to the
# user - independent of, and stricter than, MODEL_CONF_THRESHOLD.
APP_ACCEPTANCE_THRESHOLD = 0.50

# A candidate box smaller than this fraction of the image area is treated
# as unlikely to be the deliberately-photographed focus item (e.g. a stray
# background object) and is excluded from primary-selection eligibility.
MIN_BOX_AREA_RATIO = 0.02  # 2% of the image area

# Fractional margin (per side) defining the "expected focus region" of the
# frame. A candidate whose box centre falls outside this central region is
# treated as unlikely to be the item the user intentionally centred, and is
# excluded from eligibility.
CENTRAL_REGION_MARGIN = 0.15  # central 70% of width and height

# Defensive safety cap for very large mobile photos. If the longer side
# exceeds this, the image is downscaled (aspect ratio preserved) BEFORE
# inference, and the POST-resize dimensions are what get returned as
# image_width/image_height, keeping bbox coordinates consistent.
MAX_IMAGE_DIMENSION = 2000  # pixels, longer side

# Reject absurdly large uploads before ever attempting to decode them.
MAX_UPLOAD_BYTES = 15 * 1024 * 1024  # 15 MB

# Restrict this to your actual deployed frontend origin(s) in production
# (e.g. your GitHub Pages URL). "*" is convenient for local/demo dev only.
ALLOWED_ORIGINS = ["*"]

# Normalises whatever label strings the trained model emits (model.names)
# into the four canonical class strings the Flutter app expects. Unsupported
# labels return None and are excluded before primary selection, so the app can
# never surface an unknown detector label as a successful recycling result.
LABEL_NORMALISATION = {
    "plastic": "Plastic",
    "metal": "Metal",
    "paper_cardboard": "Paper_Cardboard",
    "paper": "Paper_Cardboard",
    "cardboard": "Paper_Cardboard",
    "glass": "Glass",
}


def normalise_label(raw_label: str) -> Optional[str]:
    return LABEL_NORMALISATION.get(raw_label.strip().lower())


# ============================================================================
# Model lifecycle - loaded once at startup, never reloaded per-request.
# ============================================================================

_model = None


@asynccontextmanager
async def lifespan(app: FastAPI):
    global _model
    from ultralytics import YOLO  # imported here so module import stays cheap

    logger.info("Loading detector from %s ...", MODEL_PATH)
    _model = YOLO(MODEL_PATH)
    logger.info("Detector loaded.")
    yield
    _model = None


app = FastAPI(title="EcoSort AI Detection API", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=ALLOWED_ORIGINS,
    allow_methods=["POST"],
    allow_headers=["*"],
)


# ============================================================================
# Candidate / primary-selection logic
# ============================================================================

@dataclass
class Candidate:
    raw_label: str
    confidence: float
    x1: float
    y1: float
    x2: float
    y2: float

    @property
    def width(self) -> float:
        return self.x2 - self.x1

    @property
    def height(self) -> float:
        return self.y2 - self.y1

    @property
    def area(self) -> float:
        return max(0.0, self.width) * max(0.0, self.height)

    @property
    def center(self) -> tuple[float, float]:
        return (self.x1 + self.x2) / 2, (self.y1 + self.y2) / 2


def _is_well_formed(c: Candidate, image_width: int, image_height: int) -> bool:
    if c.width <= 0 or c.height <= 0:
        return False
    if c.x1 < 0 or c.y1 < 0 or c.x2 > image_width or c.y2 > image_height:
        return False
    return True


def _is_in_central_region(c: Candidate, image_width: int, image_height: int) -> bool:
    margin_x = image_width * CENTRAL_REGION_MARGIN
    margin_y = image_height * CENTRAL_REGION_MARGIN
    cx, cy = c.center
    return (
        margin_x <= cx <= image_width - margin_x
        and margin_y <= cy <= image_height - margin_y
    )


def select_primary_detection(
    candidates: list[Candidate], image_width: int, image_height: int
) -> Optional[Candidate]:
    """
    Simple, explainable primary-selection policy:

      1. Discard malformed / out-of-bounds boxes.
      2. Discard boxes too small to plausibly be the deliberately
         photographed focus item.
      3. Discard boxes centred well outside the expected central capture
         region.
      4. Among what's left, take the highest-confidence candidate.

    This policy improves INTERACTION CONSISTENCY - a single-item photo
    always yields a single, sensible result. It does NOT improve model
    correctness: a confidently-selected primary detection can still be
    the wrong class. That is a model-generalisation concern, evaluated
    separately, not something this function can fix.
    """
    image_area = image_width * image_height
    if image_area <= 0:
        return None

    eligible = [
        c
        for c in candidates
        if _is_well_formed(c, image_width, image_height)
        and (c.area / image_area) >= MIN_BOX_AREA_RATIO
        and _is_in_central_region(c, image_width, image_height)
    ]
    if not eligible:
        return None
    return max(eligible, key=lambda c: c.confidence)


# ============================================================================
# Image decoding
# ============================================================================

def decode_image(raw_bytes: bytes) -> Image.Image:
    """
    Safely decode uploaded bytes into an orientation-corrected, RGB PIL
    image. Never lets a decode failure propagate as an unhandled 500 -
    always a clear 400 instead.
    """
    try:
        image = Image.open(io.BytesIO(raw_bytes))
        image.load()  # force full decode now, not lazily later
    except UnidentifiedImageError:
        raise HTTPException(
            status_code=400,
            detail="Unsupported or corrupted image file. Please upload a JPEG or PNG photo.",
        )
    except Exception:
        logger.exception("Unexpected error decoding upload")
        raise HTTPException(status_code=400, detail="Could not read the uploaded image.")

    # Correct EXIF orientation (common on phone photos) BEFORE anything
    # else, so the analysed pixel grid matches what the user (and the
    # Flutter preview) actually sees.
    image = ImageOps.exif_transpose(image)
    image = image.convert("RGB")

    if image.width <= 0 or image.height <= 0:
        raise HTTPException(status_code=400, detail="Uploaded image has invalid dimensions.")

    # Defensive downscale for very large mobile photos. Whatever size we
    # end up with here is what gets returned as image_width/image_height,
    # so bbox coordinates stay consistent with it.
    longer_side = max(image.width, image.height)
    if longer_side > MAX_IMAGE_DIMENSION:
        scale = MAX_IMAGE_DIMENSION / longer_side
        new_size = (round(image.width * scale), round(image.height * scale))
        image = image.resize(new_size, Image.LANCZOS)

    return image


# ============================================================================
# Endpoint
# ============================================================================

@app.post("/predict")
async def predict(file: UploadFile = File(...)):
    if _model is None:
        raise HTTPException(
            status_code=503, detail="Detector is not ready yet. Please try again shortly."
        )

    raw_bytes = await file.read()

    if not raw_bytes:
        raise HTTPException(status_code=400, detail="Uploaded file is empty.")
    if len(raw_bytes) > MAX_UPLOAD_BYTES:
        raise HTTPException(status_code=413, detail="Image is too large. Please use a smaller photo.")

    image = decode_image(raw_bytes)

    try:
        results = _model.predict(image, conf=MODEL_CONF_THRESHOLD, verbose=False)
    except Exception:
        logger.exception("Detector inference failed")
        raise HTTPException(status_code=500, detail="Detection failed. Please try again.")

    candidates: list[Candidate] = []
    raw_candidate_count = 0

    if results:
        result = results[0]
        names = result.names
        for box in result.boxes:
            raw_candidate_count += 1

            x1, y1, x2, y2 = [float(v) for v in box.xyxy[0].tolist()]
            confidence = float(box.conf[0].item())
            class_id = int(box.cls[0].item())
            raw_label = names.get(class_id, str(class_id))
            canonical_label = normalise_label(raw_label)

            # Defensive contract guard: only the four supported recycling
            # classes are eligible to become a user-facing primary result.
            if canonical_label is None:
                logger.warning("Ignoring unsupported detector label: %s", raw_label)
                continue

            candidates.append(
                Candidate(
                    raw_label=canonical_label,
                    confidence=confidence,
                    x1=x1,
                    y1=y1,
                    x2=x2,
                    y2=y2,
                )
            )

    primary = select_primary_detection(candidates, image.width, image.height)

    if primary is None or primary.confidence < APP_ACCEPTANCE_THRESHOLD:
        return {
            "primary_detection": None,
            "image_width": image.width,
            "image_height": image.height,
            "candidate_count": raw_candidate_count,
            "status": "no_detection",
        }

    return {
        "primary_detection": {
            "class": primary.raw_label,
            "confidence": round(primary.confidence, 4),
            "bbox": [primary.x1, primary.y1, primary.x2, primary.y2],
        },
        "image_width": image.width,
        "image_height": image.height,
        "candidate_count": raw_candidate_count,
        "status": "success",
    }


@app.get("/health")
async def health():
    return {"status": "ok", "model_loaded": _model is not None}
