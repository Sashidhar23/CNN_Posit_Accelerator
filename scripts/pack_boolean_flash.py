#!/usr/bin/env python3
"""Pack Posit8 VGG parameters and MNIST images for Boolean-board QSPI."""

from __future__ import annotations

import argparse
import json
from pathlib import Path


FLASH_DATA_OFFSET = 0x00400000
IMAGE_ALIGNMENT = 4

LAYERS = (
    ("features_0", 576, 64),
    ("features_2", 36864, 64),
    ("features_5", 73728, 128),
    ("features_7", 147456, 128),
    ("features_10", 294912, 256),
    ("features_12", 589824, 256),
    ("features_14", 589824, 256),
    ("features_17", 1179648, 512),
    ("features_19", 2359296, 512),
    ("features_21", 2359296, 512),
    ("classifier_0", 131072, 256),
    ("classifier_3", 2560, 10),
)


def legacy_sign_magnitude_to_standard_posit8(value: int) -> int:
    """Convert the parameter export's sign+magnitude byte to standard Posit8."""
    if value & 0x80:
        magnitude = value & 0x7F
        return 0 if magnitude == 0 else (-magnitude) & 0xFF
    return value


def read_mem(
    path: Path,
    expected: int,
    *,
    parameter_encoding: str = "standard-posit",
) -> bytes:
    values = []
    for line_number, raw_line in enumerate(path.read_text().splitlines(), 1):
        token = raw_line.split("//", 1)[0].split("#", 1)[0].strip()
        if not token:
            continue
        if token.startswith("@"):
            raise ValueError(f"{path}:{line_number}: address directives are unsupported")
        value = int(token, 16)
        if value > 0xFF:
            raise ValueError(f"{path}:{line_number}: {token} is not a Posit8 byte")
        if parameter_encoding == "legacy-sign-magnitude":
            value = legacy_sign_magnitude_to_standard_posit8(value)
        values.append(value)
    if len(values) != expected:
        raise ValueError(f"{path}: expected {expected} values, found {len(values)}")
    return bytes(values)


def align_up(value: int, alignment: int) -> int:
    return (value + alignment - 1) // alignment * alignment


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--model-dir", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--layout", type=Path, required=True)
    parser.add_argument(
        "--parameter-encoding",
        choices=("legacy-sign-magnitude", "standard-posit"),
        default="legacy-sign-magnitude",
        help=(
            "encoding used by weight/bias .mem files; the current PyTorch export "
            "uses legacy-sign-magnitude while the RTL uses standard Posit"
        ),
    )
    parser.add_argument(
        "--mem-output",
        type=Path,
        help="optional one-byte-per-line hex image for Verilog simulation",
    )
    args = parser.parse_args()

    weights = bytearray()
    biases = bytearray()
    for stem, weight_count, bias_count in LAYERS:
        weights.extend(read_mem(
            args.model_dir / f"{stem}_weight_posit8_1.mem",
            weight_count,
            parameter_encoding=args.parameter_encoding,
        ))
        biases.extend(read_mem(
            args.model_dir / f"{stem}_bias_posit8_1.mem",
            bias_count,
            parameter_encoding=args.parameter_encoding,
        ))

    images = read_mem(args.model_dir / "mnist_pixels_posit8_1.mem", 10 * 28 * 28)
    weight_base = FLASH_DATA_OFFSET
    bias_base = weight_base + len(weights)
    image_base = align_up(bias_base + len(biases), IMAGE_ALIGNMENT)

    payload = bytearray(weights)
    payload.extend(biases)
    payload.extend(b"\xFF" * (image_base - (FLASH_DATA_OFFSET + len(payload))))
    payload.extend(images)

    flash_end = FLASH_DATA_OFFSET + len(payload)
    if flash_end > 16 * 1024 * 1024:
        raise ValueError(f"payload ends at 0x{flash_end:08X}, beyond the 16 MiB flash")

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.layout.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_bytes(payload)
    if args.mem_output is not None:
        args.mem_output.parent.mkdir(parents=True, exist_ok=True)
        with args.mem_output.open("w", newline="\n") as mem_file:
            for value in payload:
                mem_file.write(f"{value:02x}\n")
    layout = {
        "flash_size_bytes": 16 * 1024 * 1024,
        "bitstream_reserved_end": FLASH_DATA_OFFSET,
        "weight_base": weight_base,
        "weight_bytes": len(weights),
        "bias_base": bias_base,
        "bias_bytes": len(biases),
        "image_base": image_base,
        "image_count": 10,
        "image_bytes_each": 28 * 28,
        "source_parameter_encoding": args.parameter_encoding,
        "packed_parameter_encoding": "standard-posit",
        "payload_bytes": len(payload),
        "flash_data_end": flash_end,
    }
    if args.mem_output is not None:
        layout["simulation_mem"] = str(args.mem_output)
    args.layout.write_text(json.dumps(layout, indent=2) + "\n")
    print(json.dumps(layout, indent=2))


if __name__ == "__main__":
    main()
