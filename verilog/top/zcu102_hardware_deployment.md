# ZCU102 Hardware Deployment

`cnn_zynq_axi_master_wrapper` is the PL accelerator top for deployment.  It
contains the tiled regular or quire CNN, two on-chip feature-map BRAM banks,
an AXI4-Lite control interface, and a read-only AXI4 DDR master interface.

## Required Vivado setup

Install the Zynq UltraScale+ MPSoC / ZCU102 device support before creating the
deployment project. The target part is `xczu9eg-ffvb1156-2-e` and the board
part is `xilinx.com:zcu102:part0:3.4` in the installed Vivado board store.

From a Vivado Tcl console with no project open, source
`scripts/create_zcu102_deployment_project.tcl`. It creates a clean
`posit_cnn_accelerator_zcu102` project, a board-specific
`cnn_zcu102_system.bd`, all matching `cnn_zcu102_system_*.xci` IP files, and
the generated `cnn_zcu102_system_wrapper.v` implementation top. Do not rename
or edit generated `.bd`, `.xci`, or wrapper files by hand; regenerate them
through the Tcl script. After an RTL change, open that new project and source
`scripts/finalize_zcu102_system.tcl`.

The generated ZCU102 block design contains:

1. `zynq_ultra_ps_e` configured with the ZCU102 board preset and DDR enabled.
2. `cnn_zynq_axi_master_wrapper` as a module-reference/IP.
3. An AXI SmartConnect from `zynq_ultra_ps_e/M_AXI_HPM0_FPD` to the wrapper
   `S_AXI` port.
4. An AXI SmartConnect from the wrapper `M_AXI` port to
   `zynq_ultra_ps_e/S_AXI_HPC0_FPD`.  This is the PL-master path into PS DDR.
5. `pl_clk0` as `aclk`; use the associated active-low peripheral reset for
   `aresetn`.  Clock both SmartConnect instances from this clock.
6. Optionally connect `irq` to `pl_ps_irq0[0]`; polling `REG_STATUS` is also
   supported.

The wrapper has no external PL pins, so it needs no hand-written pin XDC. The
ZCU102 board preset owns DDR and PS clock/reset constraints. Therefore AXI
signals are internal nets, not bonded I/O, and the raw-wrapper IOB overuse
cannot occur at this implementation top.

## DDR buffer format

The PS software allocates three contiguous, cache-coherent or cache-managed
DDR buffers, writes their physical addresses to AXI-Lite, then writes the
control start bit.

| Buffer | AXI-Lite register | Layout |
| --- | --- | --- |
| Weights | `0x08` | Layers 0 through 11 concatenated; each layer is output-channel-major, matching the existing `.mem` exports. |
| Biases | `0x0C` | Layers 0 through 11 concatenated. |
| Image | `0x10` | 784 Posit<8,1> values in row-major MNIST order. |

Values are packed little-endian within each AXI word: with the default 64-bit
DDR port, byte 0 is `word[7:0]`, byte 1 is `word[15:8]`, and so on.  The
current control registers are 32-bit, therefore physical buffers must be
allocated below 4 GiB unless the address registers are widened in a later
revision.

## AXI-Lite register map

| Offset | Name | Meaning |
| --- | --- | --- |
| `0x00` | CONTROL | Bit 0 starts one image. Bit 1 clears sticky done/error. |
| `0x04` | STATUS | Bit 0 busy, bit 1 done, bit 2 error, bit 3 CNN-core busy. |
| `0x08` | WEIGHT_BASE | Physical DDR base of packed weights. |
| `0x0C` | BIAS_BASE | Physical DDR base of packed biases. |
| `0x10` | IMAGE_BASE | Physical DDR base of one packed input image. |
| `0x14` | TIMEOUT | Maximum inference clock cycles; zero disables timeout. |
| `0x18` | CLASS | Predicted class after done. |
| `0x1C` | LOGIT_ADDR | Logit index to inspect. |
| `0x20` | LOGIT_DATA | Posit<8,1> value at `LOGIT_ADDR`. |
| `0x24` | DEBUG_STATE | Wrapper FSM state. |
| `0x28` | DEBUG_INDEX | Image-loader index. |

## Runtime sequence

1. Load quantized Posit<8,1> weights and biases into DDR once.
2. Load one packed MNIST image into DDR.
3. Program the three physical base addresses and an appropriate timeout.
4. Write `1` to CONTROL, then poll STATUS bit 1 or wait for `irq`.
5. Read CLASS, and optionally the ten logits.
6. Clear status, replace only the image buffer, and start the next image.

Weights and biases are not copied into LUTs or registers.  The tiled CNN asks
for a weight/bias, the wrapper reads the corresponding packed DDR word, and
the two BRAM banks retain intermediate feature maps.  This preserves the
time-multiplexed resource-saving architecture.

## Before bitstream generation

Run behavioral simulation of the raw accelerator wrapper with AXI memory
responses, then synthesize the generated `cnn_zcu102_system_wrapper` as the
implementation top for `xczu9eg-ffvb1156-2-e`. Check that BRAM inference
occurs for `feature_bank0` and `feature_bank1`; the model parameters must stay
in DDR, not be initialized as HDL arrays. Use the Zynq-aware Vivado project
for implementation and bitstream generation.
