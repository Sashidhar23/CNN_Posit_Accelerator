# Real Digital Boolean Hardware Deployment

## Target and architecture

- Board: Real Digital Boolean
- FPGA: `xc7s50csga324-1`
- Clock: 100 MHz oscillator on F14
- Nonvolatile memory: 16 MiB S25FL128S QSPI flash
- Accelerator: one time-multiplexed 4x4 systolic engine, regular or quire mode
- Control: autonomous ten-image accuracy batch after each reset release

This board has no DDR. The deployment therefore uses AXI Quad SPI in XIP mode
as a read-only backing store for images, weights, and biases. The CNN arithmetic,
layer schedule, tiled parameter requests, and two on-chip BRAM feature banks are
unchanged. Only the external-memory transport is different.

The 100 MHz board clock is converted to a 5 MHz accelerator/AXI clock and a
50 MHz AXI Quad SPI reference clock. The SPI core produces a 25 MHz QSPI clock.
The conservative 5 MHz core clock preserves the timing margin required by the
current combinational Posit datapath.

## Flash layout

`pack_boolean_flash.py` validates every `.mem` file and creates one byte-packed
binary. Each Posit<8,1> value occupies one byte.

| Flash address | Contents | Size |
| ---: | --- | ---: |
| `0x00000000` | FPGA configuration bitstream region | 4 MiB reserved |
| `0x00400000` | all 12 layer weight tensors | 7,765,056 bytes |
| `0x00B67C40` | all 12 layer bias tensors | 2,954 bytes |
| `0x00B687CC` | ten 28x28 MNIST images | 7,840 bytes |

The last used address is below `0x00B6A66C`, so the complete bitstream, model,
and ten-image test set fit in the 16 MiB device. Parameters are not instantiated
as FPGA logic. AXI XIP reads one aligned 32-bit word at a time, and the wrapper's
one-word cache serves its four packed Posit8 values without four flash accesses.

## Board I/O

| Signal | Boolean pin | Purpose |
| --- | --- | --- |
| `mclk` | F14 | 100 MHz oscillator |
| `reset` | J2 | BTN0, active-high reset request |
| `led_class[3:0]` | G1, G2, F1, F2 | current class; final correct-count after batch |
| `led_busy` | E1 | ten-image batch is active |
| `led_done` | E2 | all ten images are complete |
| `led_error` | E3 | AXI/timeout failure |
| `led_clock_locked` | E5 | generated clocks are locked |
| QSPI DQ0..DQ3 | K17, K18, L14, M15 | flash data |
| QSPI CS | M13 | flash chip select |

QSPI SCK uses the dedicated configuration CCLK pin through `STARTUPE2`, so it
does not appear as an ordinary top-level port.

## Autonomous control

`boolean_batch_controller.v` writes the accelerator registers at `0x80000000`.
It clears stale status, selects image `0..9`, starts inference, waits for done,
compares the class against `{7,2,1,0,4,1,4,9,5,9}`, and advances to the next
image. No software processor or in-fabric JTAG debug core is required.

| Offset | Register | Meaning |
| ---: | --- | --- |
| `0x00` | CONTROL | bit 0 start, bit 1 clear done/error |
| `0x04` | STATUS | bit 0 busy, bit 1 done, bit 2 error, bit 3 core busy |
| `0x08` | WEIGHT_BASE | default `0x00400000` |
| `0x0C` | BIAS_BASE | default `0x00B67C40` |
| `0x10` | IMAGE_BASE | selected image address |
| `0x14` | TIMEOUT | zero disables timeout |
| `0x18` | CLASS | inferred class index |
| `0x1C` | LOGIT_ADDR | logit selector |
| `0x20` | LOGIT_DATA | selected Posit8 logit |
| `0x24` | DEBUG_STATE | memory-wrapper FSM state |
| `0x28` | DEBUG_INDEX | input image-load index |

Image `i` begins at `0x00B687CC + i*784`, for `i=0..9`. During processing the
four result LEDs show the current class. When `led_done` lights, they show the
number of correct images as a four-bit binary value from 0 through 10. Pressing
BTN0 resets the design; releasing it starts a fresh ten-image run.

## Build

From PowerShell in the repository:

```powershell
.\scripts\launch_boolean_deployment.ps1 -UseQuire 1 -BuildBitstream
```

Use `-UseQuire 0` for regular Posit accumulation. The generated project is:

`D:\BooleanBuild\posit_cnn_accelerator_boolean\posit_cnn_accelerator_boolean.xpr`

Important outputs are:

- `boolean_accelerator_wrapper.bit`
- `flash\boolean_model_images.bin`
- `flash\boolean_flash_layout.json`
- `posit_cnn_accelerator_boolean.mcs`
- `reports\utilization_implemented.rpt`
- `reports\timing_implemented.rpt`

Program the combined `.mcs` into the onboard S25FL128S using SPIx4, then power
cycle or issue a configuration reset. Programming only the `.bit` over JTAG does
not install the model payload, so inference cannot work unless the QSPI data is
already present.

After the board boots from the combined flash image, the self-checking hardware
run begins automatically and does not record waveforms.

## Timing and checks

The implementation is acceptable only when the post-route timing report has
nonnegative setup and hold WNS and the DRC report has no errors. The XDC defines
the 100 MHz input clock, synchronizes the active-high reset through
`proc_sys_reset`, and false-paths only the asynchronous reset request and
human-visible LED outputs. No fabricated input/output delays are applied.

The synthesis-only validation command is:

```powershell
$env:BOOLEAN_BUILD_DIR='D:/BooleanBuild/posit_cnn_accelerator_boolean'
$env:XILINX_TCLAPP_REPO='D:/AMDDesignTools/2025.2/Vivado/data/XilinxTclStore'
& 'D:\AMDDesignTools\2025.2\Vivado\bin\vivado.bat' -mode batch `
  -source '.\scripts\run_boolean_synthesis.tcl'
```

## Latest numerical verification

The parameter exports use a legacy sign/magnitude representation for negative
weights and biases. `pack_boolean_flash.py` converts those bytes exactly once
to standard Posit<8,1> encoding before the hardware reads them. Pixels are
already standard Posit bytes and are not converted.

The current arithmetic and quire path pass:

- 131,072 exhaustive Posit add/multiply checks
- all 256 Posit-to-quire-to-Posit conversions
- 65,536 exhaustive quire PE products
- a ten-image full reduced-VGG numerical reference with predictions
  `{7,2,1,0,4,1,4,9,5,9}`

Post-correction isolated XC7S50 synthesis uses 13,911 LUTs and 93 DSPs for the
regular core, and 11,278 LUTs and 73 DSPs for the quire core. These are core-only
figures; rerun the complete Boolean wrapper implementation before relying on
board-level utilization or timing numbers.

The focused Boolean batch-controller testbench passes ten images, thirty AXI
writes, and a final correct-count of ten for its all-correct response model.
