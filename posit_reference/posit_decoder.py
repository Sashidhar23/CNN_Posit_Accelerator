import math
NBITS = 16
ES = 1
USEED = 2 ** (2 ** ES)   # 4
def posit16_1_to_float(p):

    if p == 0:
        return 0.0

    sign = (p >> 15) & 1

    payload = p & 0x7FFF

    bitstr = format(payload, '015b')

    idx = 0

    # -------------------------
    # Regime
    # -------------------------

    first = bitstr[0]

    run = 0

    while idx < len(bitstr) and bitstr[idx] == first:
        run += 1
        idx += 1

    idx += 1  # skip terminating bit

    if first == '1':
        k = run - 1
    else:
        k = -run

    # -------------------------
    # Exponent
    # -------------------------

    exponent = 0

    if idx < len(bitstr):
        exponent = int(bitstr[idx])
        idx += 1

    # -------------------------
    # Fraction
    # -------------------------

    fraction = 1.0

    power = 0.5

    while idx < len(bitstr):

        if bitstr[idx] == '1':
            fraction += power

        power /= 2
        idx += 1

    value = (USEED ** k) * (2 ** exponent) * fraction

    if sign:
        value = -value

    return value