from posit_encoder import float_to_posit16_1

test_values = [
    -8.0,
    -4.0,
    -3.25,
    -2.0,
    -1.0,
    -0.5,
    0.0,
    0.5,
    1.0,
    2.0,
    3.25,
    4.0,
    8.0
]

with open("posit16_1_vectors.txt", "w") as f:

    f.write("value,posit_bits\n")

    for val in test_values:

        posit = float_to_posit16_1(val)

        f.write(
            f"{val},{format(posit,'016b')}\n"
        )

print("Generated posit16_1_vectors.txt")