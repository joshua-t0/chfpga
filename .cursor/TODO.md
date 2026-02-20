# Project TODO

> **AI usage:** This file is scanned by the AI to understand pending work. The AI may suggest items from this list but will only start implementing when you explicitly request it.
>
> **IDs:** Each item has a unique ID (T001, T002, …) for easy reference in discussions. Use the next available number when adding items.

---

## Bugs

<!-- Add discovered bugs here. Format: - [ ] **T### Brief title** — Description (added YYYY-MM-DD) -->

*None yet.*

---

## Refactor

<!-- Code quality improvements, cleanup, consolidation without changing behavior. Format: - [ ] **T### Brief title** — Description (added YYYY-MM-DD) -->

- [ ] **T002 Replace IP FIFOs with generic_fifo** — Replace IP FIFOs with generic_fifo. Start with small standalone FIFOs (ADCDAQ, CHAN_ARRAY). If it works, replace FIFO arrays in the CT engine (added 2025-02-19)
  - Context: `hdl/common/generic_fifo.vhd`; ADCDAQ, CHAN_ARRAY, CT engine

---

## Features

<!-- New functionality or enhancements. Format: - [ ] **T### Brief title** — Description (added YYYY-MM-DD) -->

- [ ] **T001 Merge PROBER outputs in chan_array** — Use best axis_merge version to merge PROBER outputs in chan_array so we can have a single stream output from either UCAP or the PROBERS (added 2025-02-19)
  - Context: `chan_array.vhd`, `axis_merge` / `axis_merge2` in `hdl/common/`

---

## Testbenches

<!-- Testbench work: new testbenches, coverage improvements, simulation fixes. Format: - [ ] **T### Brief title** — Description (added YYYY-MM-DD) -->

*None yet.*

---

## Nice-to-have

<!-- Lower priority improvements, polish, documentation. Format: - [ ] **T### Brief title** — Description (added YYYY-MM-DD) -->

*None yet.*

---

## Documentation

<!-- Docs, comments, README updates. Format: - [ ] **T### Brief title** — Description (added YYYY-MM-DD) -->

*None yet.*

---

## Maintenance

<!-- Dependency updates, tooling, CI/CD, project config. Format: - [ ] **T### Brief title** — Description (added YYYY-MM-DD) -->

*None yet.*

---

## Template for new items

```markdown
- [ ] **T### Short title** — One-line description (added YYYY-MM-DD)
  - Optional: module/file context
  - Optional: notes or blockers
```

*Use the next sequential ID (T002, T003, …) when adding.*
