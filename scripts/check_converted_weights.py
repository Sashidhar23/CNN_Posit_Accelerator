import os
import numpy as np

PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

FILE = os.path.join(
    PROJECT_ROOT,
    "converted_weights",
    "convnext_mnist_posit16_1.npy"
)

data = np.load(
    FILE,
    allow_pickle=True
).item()

for layer_name, tensor in data.items():

    print("\nLayer:", layer_name)
    print("Shape:", tensor.shape)

    flat = tensor.flatten()

    print("\nFirst 10 posit values:")

    for i in range(min(10, len(flat))):
        print(format(int(flat[i]), '016b'))

    break