from pathlib import Path

from PIL import Image, ImageOps

from app import (
    run_detector,
    select_primary_detection,
    ACCEPTANCE_CONFIDENCE,
    MIN_BOX_AREA_RATIO,
    CENTER_REGION_RATIO,
)


IMAGE_PATH = Path("test_image.jpg")


# ============================================================
# LOAD IMAGE EXACTLY LIKE /predict
# ============================================================

image = Image.open(
    IMAGE_PATH
)

image = ImageOps.exif_transpose(
    image
).convert("RGB")

image_width, image_height = image.size


print("=" * 70)
print("WE SNAP BACKEND INFERENCE DEBUG")
print("=" * 70)

print(
    f"Image: {IMAGE_PATH}"
)

print(
    f"Image size: "
    f"{image_width} x {image_height}"
)


# ============================================================
# RUN RAW BACKEND DETECTOR
# ============================================================

candidates = run_detector(
    image
)


print(
    f"\nCandidates after YOLO confidence + NMS: "
    f"{len(candidates)}"
)


if not candidates:

    print(
        "\n❌ No candidate survived "
        "DETECTOR_CONFIDENCE."
    )

else:

    image_area = (
        image_width
        * image_height
    )

    center_x_min = (
        image_width
        * (1 - CENTER_REGION_RATIO)
        / 2
    )

    center_x_max = (
        image_width
        - center_x_min
    )

    center_y_min = (
        image_height
        * (1 - CENTER_REGION_RATIO)
        / 2
    )

    center_y_max = (
        image_height
        - center_y_min
    )


    for i, candidate in enumerate(
        candidates,
        start=1,
    ):

        x1, y1, x2, y2 = (
            candidate["bbox"]
        )

        box_width = (
            x2 - x1
        )

        box_height = (
            y2 - y1
        )

        box_area_ratio = (
            box_width
            * box_height
            / image_area
        )

        center_x = (
            x1 + x2
        ) / 2

        center_y = (
            y1 + y2
        ) / 2


        passes_confidence = (
            candidate["confidence"]
            >= ACCEPTANCE_CONFIDENCE
        )

        passes_area = (
            box_area_ratio
            >= MIN_BOX_AREA_RATIO
        )

        passes_center = (
            center_x_min
            <= center_x
            <= center_x_max
            and
            center_y_min
            <= center_y
            <= center_y_max
        )


        print(
            f"\nCandidate {i}"
        )

        print(
            "-" * 50
        )

        print(
            "Class:",
            candidate["class"]
        )

        print(
            "Confidence:",
            round(
                candidate["confidence"],
                4,
            )
        )

        print(
            "BBox:",
            [
                round(value, 2)
                for value
                in candidate["bbox"]
            ]
        )

        print(
            "Box area ratio:",
            round(
                box_area_ratio,
                4,
            )
        )

        print(
            "Centre:",
            (
                round(center_x, 2),
                round(center_y, 2),
            )
        )

        print(
            "\nAcceptance checks:"
        )

        print(
            f"Confidence >= "
            f"{ACCEPTANCE_CONFIDENCE}: "
            f"{passes_confidence}"
        )

        print(
            f"Area >= "
            f"{MIN_BOX_AREA_RATIO}: "
            f"{passes_area}"
        )

        print(
            "Inside centre region:",
            passes_center
        )


# ============================================================
# FINAL WE SNAP SELECTION
# ============================================================

primary_detection = (
    select_primary_detection(
        candidates=candidates,
        image_width=image_width,
        image_height=image_height,
    )
)


print(
    "\n" + "=" * 70
)

print(
    "FINAL PRIMARY DETECTION"
)

print(
    "=" * 70
)

print(
    primary_detection
)