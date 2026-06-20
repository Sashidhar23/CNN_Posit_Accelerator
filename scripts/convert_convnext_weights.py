import os
import sys
import torch
import numpy as np

# Add posit_reference folder to Python path
PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

sys.path.append(
    os.path.join(PROJECT_ROOT, "posit_reference")
)

from posit_encoder import float_to_posit16_1


WEIGHTS_PATH = os.path.join(
    PROJECT_ROOT,
    "models",
    "convnext_mnist_weights.pth"
)

OUTPUT_PATH = os.path.join(
    PROJECT_ROOT,
    "converted_weights",
    "convnext_mnist_posit16_1.npy"
)

print("Loading model...")

state_dict = torch.load(
    WEIGHTS_PATH,
    map_location="cpu",
    weights_only=True
)

posit_state_dict = {}

total_params = 0

for name, tensor in state_dict.items():

    arr = tensor.cpu().numpy()

    posit_arr = np.vectorize(
        float_to_posit16_1
    )(arr)

    posit_state_dict[name] = posit_arr

    total_params += arr.size

    print(
        f"{name:<60} "
        f"{str(arr.shape):<20} "
        f"{arr.size:>10}"
    )

np.save(
    OUTPUT_PATH,
    posit_state_dict,
    allow_pickle=True
)

print("\nConversion Complete")
print(f"Total Parameters : {total_params:,}")
print(f"Saved To         : {OUTPUT_PATH}")