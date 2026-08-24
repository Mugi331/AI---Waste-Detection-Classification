from fastapi import FastAPI, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware

from ultralytics import YOLO
from PIL import Image

from io import BytesIO


app = FastAPI(
    title="Waste Detection API"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],   # tighten later
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

model = YOLO(
    "models/best.pt"
)


@app.get("/")
def root():
    return {
        "status": "Waste Detection API running"
    }


@app.post("/predict")
async def predict(
    file: UploadFile = File(...)
):
    image_bytes = await file.read()

    image = Image.open(
        BytesIO(image_bytes)
    ).convert("RGB")

    # Get original image dimensions
    image_width, image_height = image.size

    results = model.predict(
        source=image,
        conf=0.50,
        verbose=False
    )

    detections = []

    result = results[0]

    for box in result.boxes:
        class_id = int(
            box.cls[0].item()
        )

        confidence = float(
            box.conf[0].item()
        )

        x1, y1, x2, y2 = (
            box.xyxy[0]
            .cpu()
            .tolist()
        )

    detections.append({
        "class": model.names[class_id],
        "confidence": confidence,
        "bbox": [x1, y1, x2, y2]
    })

    return {
        "detections": detections,
        "image_width": image_width,
        "image_height": image_height
    }