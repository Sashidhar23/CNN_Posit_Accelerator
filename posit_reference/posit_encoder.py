import math

NBITS = 16
ES = 1
USEED = 2 ** (2 ** ES)   # 4


def float_to_posit16_1(x):

    if x == 0:
        return 0

    sign = 0
    if x < 0:
        sign = 1
        x = -x

    # -------------------------
    # Compute regime k
    # -------------------------

    k = 0

    if x >= 1:

        while x >= USEED:
            x /= USEED
            k += 1

    else:

        while x < 1:
            x *= USEED
            k -= 1

    # -------------------------
    # Exponent
    # -------------------------

    exponent = 0

    if x >= 2:
        exponent = 1
        x /= 2

    # x is now in [1,2)

    fraction = x - 1

    # -------------------------
    # Regime bits
    # -------------------------

    bits = ""

    if k >= 0:
        bits += "1" * (k + 1)
        bits += "0"
    else:
        bits += "0" * (-k)
        bits += "1"

    # -------------------------
    # Exponent bit
    # -------------------------

    bits += str(exponent)

    # -------------------------
    # Fraction bits
    # -------------------------

    remaining = NBITS - 1 - len(bits)

    for _ in range(max(0, remaining)):

        fraction *= 2

        if fraction >= 1:
            bits += "1"
            fraction -= 1
        else:
            bits += "0"

    bits = bits[:15]

    posit_bits = (sign << 15) | int(bits.ljust(15, '0'), 2)

    return posit_bits