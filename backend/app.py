from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.middleware.cors import CORSMiddleware

from PIL import Image, ImageOps, UnidentifiedImageError
from io import BytesIO

import cv2
import numpy as np
import onnxruntime as ort


# ============================================================
# Configuration
# ============================================================

MODEL_PATH = "models/best.onnx"

INPUT_SIZE = 640

DETECTOR_CONFIDENCE = 0.25
NMS_IOU_THRESHOLD = 0.45

ACCEPTANCE_CONFIDENCE = 0.50
MIN_BOX_AREA_RATIO = 0.02
CENTER_REGION_RATIO = 0.60

MAX_UPLOAD_BYTES = 10 * 1024 * 1024

CANONICAL_CLASSES = {
    0: "Plastic",
    1: "Metal",
    2: "Paper_Cardboard",
    3: "Glass",
}


# ============================================================
# FastAPI
# ============================================================

app = FastAPI(
    title="Waste Detection API"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ============================================================
# Load ONNX model once
# ============================================================

print(
    f"Loading ONNX detector from {MODEL_PATH}..."
)

session = ort.InferenceSession(
    MODEL_PATH,
    providers=["CPUExecutionProvider"],
)

input_name = session.get_inputs()[0].name

print("ONNX detector loaded.")
print("Input:", input_name)


# ============================================================
# Image preprocessing
# ============================================================

def preprocess_image(image):
    """
    Letterbox image to 640x640 while preserving aspect ratio.

    Returns:
        input_tensor
        scale
        pad_x
        pad_y
    """

    original_width, original_height = image.size

    scale = min(
        INPUT_SIZE / original_width,
        INPUT_SIZE / original_height,
    )

    resized_width = round(
        original_width * scale
    )

    resized_height = round(
        original_height * scale
    )

    image_np = np.array(image)

    resized = cv2.resize(
        image_np,
        (resized_width, resized_height),
        interpolation=cv2.INTER_LINEAR,
    )

    canvas = np.full(
        (
            INPUT_SIZE,
            INPUT_SIZE,
            3,
        ),
        114,
        dtype=np.uint8,
    )

    pad_x = (
        INPUT_SIZE - resized_width
    ) // 2

    pad_y = (
        INPUT_SIZE - resized_height
    ) // 2

    canvas[
        pad_y:pad_y + resized_height,
        pad_x:pad_x + resized_width,
    ] = resized

    # HWC → CHW
    tensor = canvas.transpose(
        2,
        0,
        1,
    )

    tensor = (
        tensor.astype(np.float32)
        / 255.0
    )

    # CHW → BCHW
    tensor = np.expand_dims(
        tensor,
        axis=0,
    )

    return (
        tensor,
        scale,
        pad_x,
        pad_y,
    )


# ============================================================
# Bounding-box helpers
# ============================================================

def xywh_to_xyxy(box):
    x, y, width, height = box

    return [
        x - width / 2,
        y - height / 2,
        x + width / 2,
        y + height / 2,
    ]


def restore_box(
    box,
    scale,
    pad_x,
    pad_y,
    image_width,
    image_height,
):
    x1, y1, x2, y2 = box

    x1 = (x1 - pad_x) / scale
    y1 = (y1 - pad_y) / scale

    x2 = (x2 - pad_x) / scale
    y2 = (y2 - pad_y) / scale

    x1 = max(
        0.0,
        min(float(x1), image_width),
    )

    y1 = max(
        0.0,
        min(float(y1), image_height),
    )

    x2 = max(
        0.0,
        min(float(x2), image_width),
    )

    y2 = max(
        0.0,
        min(float(y2), image_height),
    )

    return [
        x1,
        y1,
        x2,
        y2,
    ]


# ============================================================
# ONNX inference + NMS
# ============================================================

def run_detector(image):

    image_width, image_height = (
        image.size
    )

    (
        input_tensor,
        scale,
        pad_x,
        pad_y,
    ) = preprocess_image(image)

    outputs = session.run(
        None,
        {
            input_name: input_tensor
        },
    )

    predictions = outputs[0]

    # Typical YOLOv8 export:
    # (1, 4 + num_classes, 8400)
    predictions = np.squeeze(
        predictions,
        axis=0,
    ).T

    boxes = predictions[:, :4]
    class_scores = predictions[:, 4:]

    class_ids = np.argmax(
        class_scores,
        axis=1,
    )

    confidences = np.max(
        class_scores,
        axis=1,
    )

    confidence_mask = (
        confidences
        >= DETECTOR_CONFIDENCE
    )

    boxes = boxes[confidence_mask]
    class_ids = class_ids[
        confidence_mask
    ]

    confidences = confidences[
        confidence_mask
    ]

    if len(boxes) == 0:
        return []

    nms_boxes = []

    for box in boxes:

        x1, y1, x2, y2 = (
            xywh_to_xyxy(box)
        )

        nms_boxes.append([
            float(x1),
            float(y1),
            float(x2 - x1),
            float(y2 - y1),
        ])

    indices = cv2.dnn.NMSBoxes(
        nms_boxes,
        confidences.tolist(),
        DETECTOR_CONFIDENCE,
        NMS_IOU_THRESHOLD,
    )

    if len(indices) == 0:
        return []

    candidates = []

    for index in np.array(
        indices
    ).flatten():

        class_id = int(
            class_ids[index]
        )

        # Reject unexpected classes.
        if class_id not in CANONICAL_CLASSES:
            continue

        box = xywh_to_xyxy(
            boxes[index]
        )

        restored_box = restore_box(
            box=box,
            scale=scale,
            pad_x=pad_x,
            pad_y=pad_y,
            image_width=image_width,
            image_height=image_height,
        )

        candidates.append({
            "class":
                CANONICAL_CLASSES[
                    class_id
                ],

            "confidence":
                float(
                    confidences[index]
                ),

            "bbox":
                restored_box,
        })

    candidates.sort(
        key=lambda candidate:
            candidate["confidence"],
        reverse=True,
    )

    return candidates


# ============================================================
# Primary-detection selection
# ============================================================

def select_primary_detection(
    candidates,
    image_width,
    image_height,
):

    if not candidates:
        return None

    image_area = (
        image_width * image_height
    )

    center_x_min = (
        image_width
        * (1 - CENTER_REGION_RATIO)
        / 2
    )

    center_x_max = (
        image_width - center_x_min
    )

    center_y_min = (
        image_height
        * (1 - CENTER_REGION_RATIO)
        / 2
    )

    center_y_max = (
        image_height - center_y_min
    )

    eligible = []

    for candidate in candidates:

        if (
            candidate["confidence"]
            < ACCEPTANCE_CONFIDENCE
        ):
            continue

        x1, y1, x2, y2 = (
            candidate["bbox"]
        )

        box_width = x2 - x1
        box_height = y2 - y1

        if (
            box_width <= 0
            or box_height <= 0
        ):
            continue

        box_area_ratio = (
            box_width
            * box_height
            / image_area
        )

        if (
            box_area_ratio
            < MIN_BOX_AREA_RATIO
        ):
            continue

        center_x = (
            x1 + x2
        ) / 2

        center_y = (
            y1 + y2
        ) / 2

        if not (
            center_x_min
            <= center_x
            <= center_x_max
            and
            center_y_min
            <= center_y
            <= center_y_max
        ):
            continue

        eligible.append(
            candidate
        )

    if not eligible:
        return None

    return max(
        eligible,
        key=lambda candidate:
            candidate["confidence"],
    )


# ============================================================
# API routes
# ============================================================

@app.get("/")
def root():
    return {
        "status":
            "Waste Detection API running",

        "runtime":
            "ONNX Runtime",
    }


@app.get("/health")
def health():
    return {
        "status": "ok",
        "model_loaded":
            session is not None,
        "runtime":
            "onnxruntime",
    }


@app.post("/predict")
async def predict(
    file: UploadFile = File(...)
):

    try:
        image_bytes = (
            await file.read()
        )

        if not image_bytes:
            raise HTTPException(
                status_code=400,
                detail="Empty image upload.",
            )

        if (
            len(image_bytes)
            > MAX_UPLOAD_BYTES
        ):
            raise HTTPException(
                status_code=413,
                detail="Image is too large.",
            )

        image = Image.open(
            BytesIO(image_bytes)
        )

        image = ImageOps.exif_transpose(
            image
        ).convert("RGB")

    except UnidentifiedImageError:

        raise HTTPException(
            status_code=400,
            detail="Invalid image file.",
        )

    image_width, image_height = (
        image.size
    )

    candidates = run_detector(
        image
    )

    primary_detection = (
        select_primary_detection(
            candidates=candidates,
            image_width=image_width,
            image_height=image_height,
        )
    )

    status = (
        "success"
        if primary_detection
        is not None
        else "no_detection"
    )

    return {
        "primary_detection":
            primary_detection,

        "candidate_count":
            len(candidates),

        "image_width":
            image_width,

        "image_height":
            image_height,

        "status":
            status,
    }