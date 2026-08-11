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

- The ct_prober capture probe (cookie 0xA2, BSB port 6) captures the data
  payload only, flags-off, by explicit user decision: do not propose flag
  capture or FIFO headroom for it. Flags are captured from the channelizer
  probers when needed. Design operating point: frames_per_packet=1,
  send_flags=False (517-word packets, up to 3 per burst).
- BSB address hierarchy: top router bits 18:16, bct_engine router bits 15:14,
  crossbar routers bits 13:9 (5-bit port index, 9-bit space per port,
  matching pychfpga's `port << 9`). The crossbar ADDRESS_MASKs were fixed to
  this layout in 98bc0a73 — keep any new sub-router consistent with it.
- Several corner-turn status registers are declared but never driven in the
  RTL and always read zero: chan_crossbar's INPUT_FRAME_CTR/ALIGN_FRAME_CTR
  and lane monitor, and the GPU link's FRAME_CTR. Do not use them as dataflow
  indicators; the live counters are chan_bin_sel.IN_FRAME_CTR and the
  shuffle_crossbar INPUT/ALIGN/OUTPUT_FRAME_CTRs.
- Bring-up ordering matters: release the corner turn (corr_reset) before the
  channelizers (`chFPGA.reset()` does the canonical sequence), then trig and
  sync — otherwise the chan-to-CT stream never starts.
