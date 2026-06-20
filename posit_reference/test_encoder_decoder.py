from posit_encoder import float_to_posit16_1
from posit_decoder import posit16_1_to_float

test_values = [
    0.0,
    0.25,
    0.5,
    1.0,
    2.0,
    3.25,
    8.0,
    -0.5,
    -3.25
]

print("-" * 70)
print(f"{'Value':>10} {'Posit Bits':>20} {'Decoded':>15}")
print("-" * 70)

for val in test_values:

    posit = float_to_posit16_1(val)

    decoded = posit16_1_to_float(posit)

    print(
        f"{val:>10.4f} "
        f"{format(posit,'016b'):>20} "
        f"{decoded:>15.6f}"
    )

print("-" * 70)