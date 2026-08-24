from ultralytics import YOLO

PT_MODEL = "models/best.pt"
ONNX_MODEL = "models/best.onnx"

IMAGE_PATH = "test_image.jpg"   # change this to one real image


print("Loading PyTorch model...")
pt_model = YOLO(PT_MODEL)

print("Loading ONNX model...")
onnx_model = YOLO(ONNX_MODEL)


print("\nRunning .pt inference...")
pt_results = pt_model.predict(
    source=IMAGE_PATH,
    conf=0.25,
    verbose=False,
)

print("\nRunning .onnx inference...")
onnx_results = onnx_model.predict(
    source=IMAGE_PATH,
    conf=0.25,
    verbose=False,
)


def print_detections(name, results):
    print(f"\n{name}")

    result = results[0]

    if len(result.boxes) == 0:
        print("No detections.")
        return

    for i, box in enumerate(result.boxes):
        class_id = int(box.cls[0].item())
        confidence = float(box.conf[0].item())
        bbox = box.xyxy[0].tolist()

        print(
            f"{i + 1}. "
            f"class={result.names[class_id]} | "
            f"confidence={confidence:.4f} | "
            f"bbox={bbox}"
        )


print_detections("PyTorch (.pt)", pt_results)
print_detections("ONNX (.onnx)", onnx_results)