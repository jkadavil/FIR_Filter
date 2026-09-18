# 32-Tap Pipelined FIR Accelerator

A synthesizable fixed-point FIR accelerator with AXI4-Stream data interfaces,
AXI4-Lite coefficient programming, FIFO buffering, and a fully pipelined
parallel multiply-accumulate datapath.

## Highlights

* 32 signed 16-bit samples and coefficients
* 40-bit accumulator output
* 32 parallel multipliers and a five-level registered adder tree
* One-sample-per-cycle peak throughput
* Correct AXI4-Stream backpressure from output to input
* Input and output FIFOs with simultaneous push/pop support
* Shadow coefficient registers with atomic software-controlled commit
* Self-checking testbenches, including signed arithmetic and randomized output
  backpressure

## Architecture

```mermaid
flowchart LR
    IN[AXI4-Stream input] --> IF[Input FIFO]
    IF --> DL[32-sample delay line]
    DL --> DSP[Parallel FIR pipeline]
    AXI[AXI4-Lite control] --> COEF[Shadow and active coefficients]
    COEF --> DSP
    DSP --> OF[Output FIFO]
    OF --> OUT[AXI4-Stream output]
```

The datapath computes

```text
y[n] = sum(k=0..31) h[k] * x[n-k]
```

The current input is used as `x[n]`; no artificial leading-zero output is
inserted. With no stalls, the DSP accepts one sample every clock. The result is
available at the output FIFO six clocks after the corresponding delay-line/DSP
transfer.

## Register Map

| Address     | Name       | Access | Description                                                        |
| ----------- | ---------- | ------ | ------------------------------------------------------------------ |
| `0x00`      | CONTROL    | R/W    | Bit 0 enables input processing                                     |
| `0x04`      | COEFF_LOAD | W      | Any write atomically copies shadow coefficients to the active bank |
| `0x08`      | STATUS     | R      | Bits 0–3: input full, input empty, output full, output empty       |
| `0x10 + 4k` | COEFF[k]   | R/W    | Signed coefficient shadow register, `k = 0..31`                    |

Software should write all desired shadow coefficients, write `COEFF_LOAD`, and
then enable the filter. Later shadow writes do not affect filtering until the
next load command.

## Source Files

| File             | Purpose                                    |
| ---------------- | ------------------------------------------ |
| `fir_top.v`      | Accelerator integration and delay line     |
| `fir_dsp.v`      | Pipelined multipliers and adder tree       |
| `axis_fifo.v`    | Parameterized ready/valid FIFO             |
| `fir_axi_lite.v` | Control, status, and coefficient registers |
| `tb_fir_top.v`   | End-to-end self-checking stress test       |
| `tb_fir_dsp.v`   | FIR datapath unit test                     |
| `tb_axis_fifo.v` | FIFO unit test                             |

## Simulation

Example with Icarus Verilog:

```bash
iverilog -g2012 -s tb_axis_fifo -o sim_fifo axis_fifo.v tb_axis_fifo.v
vvp sim_fifo

iverilog -g2012 -s tb_fir_dsp -o sim_dsp fir_dsp.v tb_fir_dsp.v
vvp sim_dsp

iverilog -g2012 -s tb_fir_top -o sim_top \
  axis_fifo.v fir_dsp.v fir_axi_lite.v fir_top.v tb_fir_top.v
vvp sim_top
```

## Implementation Notes

The arithmetic is two's-complement signed. `ACC_WIDTH` must be selected to
avoid overflow for the intended sample and coefficient ranges. The current
top-level datapath exposes 32 explicit sample ports to the DSP module, so
`NUM_TAPS=32` is the supported integrated configuration.

For a portfolio release, add the Vivado device and clock constraint used for
synthesis, then report post-synthesis/post-implementation LUT, FF, DSP, BRAM,
Fmax, and power results here. Those numbers are intentionally not claimed
without a reproducible implementation run.
