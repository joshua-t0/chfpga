# Agent notes — chfpgalite

Standing instructions and durable knowledge for AI agents working in this
repository. Maintained at the user's request; keep this file curated and
concise.

## Ground rules

- **Never create git commits unless explicitly asked.** Implement changes in
  the working tree and report; the user decides when to commit. When asked,
  use atomic commits with descriptive messages in the `type (scope): summary`
  style; bug fixes go in separate commits explaining both cause and solution.
- Store durable repo knowledge in this file, not in custom side files.
- The user compiles bitstreams themselves; prepare sources and verify, then
  hand off.

## Build environment

- Vivado 2022.2: `source /tools/Xilinx/Vivado/2022.2/settings64.sh` (user
  alias: `act_vivado_2022`). The environment does not persist between shell
  invocations — source it in every command that needs Vivado tools.
- Projects are script-generated (`tcl/project_sources.tcl` +
  `create_project.tcl`); never GUI-edit `.xpr` files. `make <config>
  project|bitstream|clean`.
- Style: `cd hdl && vsg -c vsg_rules.yaml -f <files>` (vsg at
  /usr/local/bin/vsg). Beware `vsg --fix`: it mass-reformats legacy files far
  beyond whitespace — do not mix that churn into functional commits.
- `xvhdl` aborts the whole invocation at the first failing file, and units
  depending on ungenerated Xilinx IP cannot be analyzed outside the project —
  "not compiled in library" cascades there are expected, not code errors.
- Vivado cannot pass VHDL enum generics via the project `generic` property
  (values get ASCII-encoded), so testbench projects needing enum generics are
  sim-only.

## Corner turn / ct_prober

- The ct_prober capture probe (cookie 0xA2, BSB port 6) captures whole CT
  packets verbatim (TLAST-delimited, size-agnostic), so it sees the flags
  blocks whenever the corner turn is configured with send_flags. shuffle16
  packet sizes: 517/1029 words (1/2 frames per packet, flags off) and
  582/1159 words (flags on) — all fit the 2048-word capture FIFO
  (3/1/3/1 packets per burst respectively). The header comment table in
  ct_prober.vhd previously claimed 597/1221 and that flags-on fpp=2 does
  not fit; those numbers were wrong and are corrected in the working tree.
  The pychfpga ct_prober test suite uses flags-off fpp=1 as its canonical
  algorithm-test operating point and reconfigures to flags-on for the
  flags tests.
- Known defect, characterized but deliberately NOT fixed (needs a TUSER
  repack + recompile): the CT packet's per-bin data-flags words do not
  carry scaler overflow flags. chan.vhd:695 truncates the scaler's 5-bit
  TUSER to 3:0 (dropping the high-bin scaler overflow), and chan_bin_sel
  samples stale constants (chfpga_package.vhd:534-540: SCALER_LOW collides
  with FFT_OVERFLOW=1, SCALER_HIGH with GAINBANK=2), so it reads the
  gain-bank and FFT-overflow bits instead — both asserted only at frame
  end, leaving the data-flags block ~all-zero. Confirmed on silicon under
  maximal flag forcing: only lane 7's final flags word goes nonzero
  (0xFFFF, the FFT-overflow flag on the frame's TLAST word); lane 6's
  gain-bank read stays 0 for the default bank. The per-frame frame-flags
  word (ADC + FFT overflow per channel) is correctly wired and verified
  bit-exactly by pychfpga's ct_prober_test.py flags tests.
- Known defect #2 (reconnected GPU path, found on the bench, NOT yet
  fixed): a GPU core reset (GPU.RESET pulse) released while the
  corner-turn stream is running intermittently (~1 attempt in 3) leaves
  one lane's 10G TX FIFO permanently wedged - the MAC accepts s_axis
  words the moment the fabric reset deasserts while the FIFO/GTX are
  still completing reset; the dropped words desynchronize the header and
  data FIFOs and both overflow continuously (stickies re-assert within
  100 ms of every OVERFLOW_RESET) until the next core reset. Candidate
  RTL fix: hold the axis_gpu tvalid gate until TX resetdone AND the FIFO
  wr_rst_busy are clear, and re-enable only at a packet (TLAST) boundary.
  Software workaround until then: retry the core reset until the overflow
  flags stay quiet (see _gpu_clean_start in pychfpga's ct_prober_test.py).
  Not rate- or packet-size-dependent (flags-on fpp=1 and fpp=2 behave
  identically; TEST_ENABLE off).
- BSB address hierarchy: top router bits 18:16, bct_engine router bits 15:14,
  crossbar routers bits 13:9 (5-bit port index, 9-bit space per port,
  matching pychfpga's `port << 9`). The crossbar ADDRESS_MASKs were fixed to
  this layout in 98bc0a73 — keep any new sub-router consistent with it.
- Several corner-turn status registers are declared but never driven in the
  RTL and always read zero: chan_crossbar's INPUT_FRAME_CTR/ALIGN_FRAME_CTR
  and lane monitor. Do not use them as dataflow indicators; the live
  counters are chan_bin_sel.IN_FRAME_CTR and the shuffle_crossbar
  INPUT/ALIGN/OUTPUT_FRAME_CTRs. The GPU link's FRAME_CTR counts frames
  entering the 10G MAC TX path: dead on bitstreams predating the aug11
  ct_out reconnection, live since. CROSSBAR3.OUTPUT_FRAME_CTR remains the
  canonical corner-turn dataflow indicator (works with or without GPU
  links).
- Bring-up ordering matters: release the corner turn (corr_reset) before the
  channelizers (`chFPGA.reset()` does the canonical sequence), then trig and
  sync — otherwise the chan-to-CT stream never starts.
- shuffle256 output packet (per lane k, slot s 1-based, crate c): 4-word
  header with w0 = STREAM_ID16<<16 | 0x14CF, STREAM_ID16 = 0x2000 | c<<8 |
  (s-1)<<4 | k; w1 carries only the send_flags bit reliably — the CB2/CB3
  header-population registers (four_bits, bins, channels) are never written
  by software and read zero. Data: per frame 8 bins x 64 words, each bin =
  256 bytes in ascending global channel order (LSB byte first). Flags: per
  frame 64 data-flags words (word L of a bin covers channels 32L..32L+31)
  and 16 frame-flags words (words 2L/2L+1 = source slots 2L+1/2L+2, each
  {FFT[31:16], ADC[15:0]}). One packet-flags trailer word: bits 0-7 =
  per-CB3-input-lane error, 8 = missing/short frame, 9 = overlong,
  10 = CRC, 11 = FIFO overflow, bits 12+ = CB2's packet flags shifted.
  Totals: 597/1189 words (flags on, 1/2 frames per packet), 517/1029 off.
  The bin at packet position p is absolute bin 16p + (s-1).
- More dead/never-driven status in the shuffle path (verified in RTL):
  shuffle_crossbar's DATA_TIMEOUT_MON (status0 bit7), HAD_TIMEOUT,
  CAPTURE_DONE, TIMEOUT_PERIOD/USE_TIMEOUT controls (unused), and
  xglink_array's rx_frame_ctr (assignment commented out). The live
  lane-absent indicator is MISSING_FRAME (align32's SOF-window check).
  align32 is instantiated without ENABLE_MONITORING_LOGIC, so the
  LANE_MONITOR_SOURCE machinery is inert. LANE_MONITOR_SEL values above 7
  index past the OUTPUT_FRAME_CTR/PACKET_ERROR_CTR arrays.
