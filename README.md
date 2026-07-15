# Posit CNN Accelerator

Verilog implementation of a reduced VGG16 MNIST accelerator using Posit<8,1>
arithmetic, regular or quire accumulation, a time-multiplexed 4x4
weight-stationary systolic engine, and tiled parameter/feature-map storage.

## Current architecture

- Ten convolution layers with ReLU and four 2x2 max-pooling stages
- `512 -> 256 -> 10` classifier
- One reusable 4x4 systolic engine rather than one hardware engine per layer
- On-chip ping-pong feature buffers
- External tiled weight, bias, and image requests
- Optional full-dot quire accumulation with one final Posit rounding

## Repository layout

- `verilog/`: RTL, self-checking testbenches, and Posit parameter files
- `verilog/top/`: AXI wrapper, Boolean batch controller, and deployment tests
- `constraints/`: Real Digital Boolean board XDC
- `scripts/`: flash packing, Vivado project generation, synthesis, and simulation
- `docs/`: hardware deployment instructions
- `verification/`: exhaustive Posit arithmetic reference vectors

## Numerical encoding

The checked-in model parameter files use the original exporter’s legacy
sign/magnitude encoding for negative weights and biases. Hardware uses standard
Posit encoding. `scripts/pack_boolean_flash.py` performs this conversion while
building the flash payload. Do not pre-convert the source `.mem` files or apply
the conversion again in the Boolean testbench.

## Boolean-board deployment

The target is the Real Digital Boolean board (`xc7s50csga324-1`) with its 16 MiB
QSPI flash used as read-only model and image storage. The autonomous controller
runs ten images and displays the result and status on LEDs.

```powershell
.\scripts\launch_boolean_deployment.ps1 -UseQuire 1 -BuildBitstream
```

Set `VIVADO_BIN` or `PYTHON_BIN` when the tools are not available from `PATH` or
the default D-drive Vivado installation. See
`docs/boolean_hardware_deployment.md` for pinout, flash layout, and programming.

## Verification

The latest revision passes exhaustive Posit arithmetic, conversion, and quire
PE tests. The corrected full-network numerical reference predicts the ten
checked-in MNIST samples as `7,2,1,0,4,1,4,9,5,9`.

```powershell
.\scripts\run_numeric_unit_tests.ps1
python .\scripts\verify_vgg_posit_reference.py --images 10
```
