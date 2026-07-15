#!/usr/bin/env python3
"""Generate exhaustive, correctly rounded Posit<8,1> arithmetic vectors."""

from __future__ import annotations

import argparse
from bisect import bisect_left
from fractions import Fraction
from pathlib import Path


N = 8
ES = 1
NAR = 0x80


def decode(bits: int) -> Fraction | None:
    if bits == 0:
        return Fraction(0)
    if bits == NAR:
        return None

    negative = bool(bits & 0x80)
    magnitude = (-bits) & 0xFF if negative else bits
    payload = [(magnitude >> bit) & 1 for bit in range(6, -1, -1)]
    regime_bit = payload[0]
    run = 0
    while run < len(payload) and payload[run] == regime_bit:
        run += 1
    k = run - 1 if regime_bit else -run

    position = run + 1
    exponent = payload[position] if position < len(payload) else 0
    position += 1
    fraction = Fraction(1)
    place = Fraction(1, 2)
    while position < len(payload):
        if payload[position]:
            fraction += place
        place /= 2
        position += 1

    scale = (k << ES) + exponent
    value = fraction * (2**scale if scale >= 0 else Fraction(1, 2**(-scale)))
    return -value if negative else value


POSITIVE_VALUES = [decode(code) for code in range(128)]


def encode_nearest(value: Fraction | None) -> int:
    if value is None:
        return NAR
    if value == 0:
        return 0

    negative = value < 0
    magnitude = -value if negative else value
    index = bisect_left(POSITIVE_VALUES, magnitude)
    if index == 0:
        code = 0
    elif index >= len(POSITIVE_VALUES):
        code = 0x7F
    else:
        lower = index - 1
        upper = index
        lower_distance = magnitude - POSITIVE_VALUES[lower]
        upper_distance = POSITIVE_VALUES[upper] - magnitude
        if lower_distance < upper_distance:
            code = lower
        elif upper_distance < lower_distance:
            code = upper
        else:
            code = lower if (lower & 1) == 0 else upper

    return (-code) & 0xFF if negative else code


def write_vectors(path: Path, operation: str) -> None:
    decoded = [decode(code) for code in range(256)]
    with path.open("w", newline="\n") as output:
        for a in range(256):
            for b in range(256):
                if decoded[a] is None or decoded[b] is None:
                    result = None
                elif operation == "add":
                    result = decoded[a] + decoded[b]
                else:
                    result = decoded[a] * decoded[b]
                output.write(f"{encode_nearest(result):02x}\n")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output-dir", type=Path, default=Path("verification"))
    args = parser.parse_args()
    args.output_dir.mkdir(parents=True, exist_ok=True)
    write_vectors(args.output_dir / "posit8_add_expected.mem", "add")
    write_vectors(args.output_dir / "posit8_mul_expected.mem", "mul")
    print(f"Wrote exhaustive arithmetic vectors to {args.output_dir}")


if __name__ == "__main__":
    main()
