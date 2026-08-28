# 32-Tap FIR Filter (Verilog, AXI4-Stream + AXI4-Lite)

A pipelined 32-tap FIR filter implemented in Verilog for Xilinx 7-series
FPGAs (Vivado 2025.2). Samples come in over an AXI4-Stream interface,
coefficients and control are programmed over AXI4-Lite, and filtered
output is pushed back out over AXI4-Stream.

## Features

- 32-tap FIR filter, runtime-programmable coefficients (no re-synth needed)
- AXI4-Stream input/output for sample data
- AXI4-Lite control interface for enable, coefficient load, and status
- Pipelined multiply-accumulate tree (32 → 16 → 8 → 4 → 2 → 1) for timing closure
- Input/output AXI-Stream FIFOs for elastic buffering
- Self-checking testbench with a software reference model

## Module overview

| File | Description |
|---|---|
| `fir_top.v` | Top-level: wires together AXI-Lite control, input FIFO, delay line, DSP core, output FIFO |
| `fir_axi_lite.v` | AXI4-Lite slave: coefficient RAM, enable/load control registers, status readback |
| `fir_dsp.v` | Pipelined 32-tap multiply-accumulate datapath |
| `axis_fifo.v` | Generic circular-buffer AXI4-Stream FIFO (used for both input and output buffering) |
| `tb_fir_top.v` | Self-checking testbench: drives AXI-Lite writes/reads, streams samples, compares against a reference model |

## AXI4-Lite register map

| Address | Register | Access |
|---|---|---|
| `0x00` | Control (bit 0 = enable) | R/W |
| `0x04` | Load (write 1 to latch coefficients into the datapath) | R/W |
| `0x08` | Status (input/output FIFO full/empty flags) | R |
| `0x10`–`0x8C` | Coefficient RAM, coeff[0..31], 4 bytes apart | R/W |

## Getting started

1. Open `FIR Filter.xpr` in Vivado 2025.2 (or newer — update the target
   part in Project Settings if you're not targeting the Kintex-7
   `xc7k70tfbv676-1`).
2. Run behavioral simulation (`tb_fir_top` is the default sim top) to
   confirm `PASS: ALL TESTS PASSED`.
3. Run synthesis / implementation as normal.

## Programming sequence

1. Write each coefficient to `0x10 + 4*i` for `i = 0..31`.
2. Write `1` to `0x04` (Load) to latch coefficients into the datapath.
3. Write `1` to `0x00` (Control, bit 0) to enable the filter.
4. Stream samples in over `s_axis_*`; filtered results appear on `m_axis_*`.

## License

MIT — see `LICENSE`.
