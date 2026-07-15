#!/usr/bin/env python3
"""Fast numerical reference for the corrected Posit<8,1> quire RTL path."""

from __future__ import annotations

import argparse
from pathlib import Path

import numpy as np


LAYERS = (
    ("features_0", 1, 64, False),
    ("features_2", 64, 64, True),
    ("features_5", 64, 128, False),
    ("features_7", 128, 128, True),
    ("features_10", 128, 256, False),
    ("features_12", 256, 256, False),
    ("features_14", 256, 256, True),
    ("features_17", 256, 512, False),
    ("features_19", 512, 512, False),
    ("features_21", 512, 512, True),
)
EXPECTED_LABELS = (7, 2, 1, 0, 4, 1, 4, 9, 5, 9)


def decode_standard(values: np.ndarray) -> np.ndarray:
    source = np.asarray(values, dtype=np.uint8)
    result = np.empty(source.shape, dtype=np.float64)
    for index, raw in enumerate(source.ravel()):
        code = int(raw)
        if code == 0:
            result.ravel()[index] = 0.0
            continue
        if code == 0x80:
            result.ravel()[index] = np.nan
            continue

        negative = bool(code & 0x80)
        magnitude = (-code) & 0xFF if negative else code
        bits = [(magnitude >> bit) & 1 for bit in range(6, -1, -1)]
        regime_bit = bits[0]
        run = 0
        while run < 7 and bits[run] == regime_bit:
            run += 1
        k = run - 1 if regime_bit else -run
        position = run + 1
        exponent = bits[position] if position < 7 else 0
        position += 1
        fraction = 1.0
        place = 0.5
        for bit in bits[position:]:
            fraction += bit * place
            place *= 0.5
        result.ravel()[index] = (
            (-1.0 if negative else 1.0) * (2.0 ** ((2 * k) + exponent)) * fraction
        )
    return result


POSITIVE_POSITS = decode_standard(np.arange(128, dtype=np.uint8))


def quantize(values: np.ndarray) -> np.ndarray:
    source = np.asarray(values, dtype=np.float64)
    negative = source < 0
    magnitude = np.abs(source)
    upper = np.clip(np.searchsorted(POSITIVE_POSITS, magnitude), 0, 127)
    lower = np.maximum(upper - 1, 0)
    lower_distance = magnitude - POSITIVE_POSITS[lower]
    upper_distance = POSITIVE_POSITS[upper] - magnitude
    choose_upper = (upper_distance < lower_distance) | (
        (upper_distance == lower_distance) & ((lower & 1) == 1)
    )
    code = np.where(choose_upper, upper, lower).astype(np.uint8)
    code = np.where(negative, (-code) & 0xFF, code).astype(np.uint8)
    return decode_standard(code)


def read_mem(path: Path) -> np.ndarray:
    return np.array(
        [int(line, 16) for line in path.read_text().splitlines() if line.strip()],
        dtype=np.uint8,
    )


def read_parameter(model_dir: Path, stem: str, kind: str, shape: tuple[int, ...]) -> np.ndarray:
    source = read_mem(model_dir / f"{stem}_{kind}_posit8_1.mem")
    magnitude = source & 0x7F
    canonical = np.where(source & 0x80, (-magnitude) & 0xFF, source).astype(np.uint8)
    return decode_standard(canonical).reshape(shape)


def convolution(feature: np.ndarray, weight: np.ndarray, bias: np.ndarray) -> np.ndarray:
    channels, height, width = feature.shape
    padded = np.pad(feature, ((0, 0), (1, 1), (1, 1)))
    windows = np.lib.stride_tricks.sliding_window_view(
        padded, (3, 3), axis=(1, 2)
    )
    patches = windows.transpose(1, 2, 0, 3, 4).reshape(height * width, -1)
    output = quantize(patches @ weight.reshape(len(bias), -1).T + bias)
    return np.maximum(output, 0.0).T.reshape(len(bias), height, width)


def max_pool(feature: np.ndarray) -> np.ndarray:
    channels, height, width = feature.shape
    out_height = ((height - 2) // 2) + 1
    out_width = ((width - 2) // 2) + 1
    cropped = feature[:, : out_height * 2, : out_width * 2]
    return cropped.reshape(channels, out_height, 2, out_width, 2).max(axis=(2, 4))


def main() -> int:
    parser = argparse.ArgumentParser()
    default_model_dir = Path("VGG16_MNIST_Epoch20")
    if not default_model_dir.exists():
        default_model_dir = Path("verilog/params")
    parser.add_argument(
        "--model-dir", type=Path, default=default_model_dir
    )
    parser.add_argument("--images", type=int, default=10)
    args = parser.parse_args()
    image_count = max(1, min(args.images, len(EXPECTED_LABELS)))

    layer_parameters = [
        (
            read_parameter(args.model_dir, stem, "weight", (out_ch, in_ch, 3, 3)),
            read_parameter(args.model_dir, stem, "bias", (out_ch,)),
        )
        for stem, in_ch, out_ch, _ in LAYERS
    ]
    fc0_weight = read_parameter(args.model_dir, "classifier_0", "weight", (256, 512))
    fc0_bias = read_parameter(args.model_dir, "classifier_0", "bias", (256,))
    fc3_weight = read_parameter(args.model_dir, "classifier_3", "weight", (10, 256))
    fc3_bias = read_parameter(args.model_dir, "classifier_3", "bias", (10,))
    pixels = decode_standard(
        read_mem(args.model_dir / "mnist_pixels_posit8_1.mem")
    ).reshape(10, 1, 28, 28)

    predictions: list[int] = []
    for image_index in range(image_count):
        feature = pixels[image_index]
        for (_, _, _, pool_after), (weight, bias) in zip(LAYERS, layer_parameters):
            feature = convolution(feature, weight, bias)
            if pool_after:
                feature = max_pool(feature)
        hidden = np.maximum(
            quantize(fc0_weight @ feature.reshape(-1) + fc0_bias), 0.0
        )
        logits = quantize(fc3_weight @ hidden + fc3_bias)
        prediction = int(np.argmax(logits))
        predictions.append(prediction)
        print(
            f"image {image_index}: predicted={prediction} "
            f"expected={EXPECTED_LABELS[image_index]}"
        )

    correct = sum(
        predicted == expected
        for predicted, expected in zip(predictions, EXPECTED_LABELS)
    )
    print(f"reference accuracy: {correct}/{image_count}")
    return 0 if correct == image_count else 1


if __name__ == "__main__":
    raise SystemExit(main())
