from ultralytics import YOLO


model = YOLO("models/best.pt")

model.export(
    format="onnx",
    imgsz=640,
    simplify=True,
    dynamic=False,
)

print("ONNX export complete.")