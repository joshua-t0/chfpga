# Plan: Fix VSG Violations

## Summary
VSG found violations in 5 files that need to be fixed according to `hdl/vsg_rules.yaml` configuration.

## Files to Fix

### 1. `hdl/ct/chan_bin_sel.vhd` (6 errors)

**Rule: `instantiation_036` - Add architecture identifier**

Entity instantiations need architecture identifiers. Change from:
```vhdl
entity_name0: entity work.entity_name
```
to:
```vhdl
entity_name0: entity work.entity_name(architecture_name)
```

**Lines to fix:**
- Line 387: Entity instantiation
- Line 430: Entity instantiation
- Line 496: Entity instantiation
- Line 517: Entity instantiation
- Line 575: Entity instantiation
- Line 605: Entity instantiation

**Action:** Read each instantiation, identify the entity name, find its architecture name, and add `(architecture_name)` after the entity name.

---

### 2. `hdl/ct/shuffle_bin_sel.vhd` (8 errors)

**Rule: `instantiation_036` - Add architecture identifier**

**Lines to fix:**
- Line 404: Entity instantiation
- Line 448: Entity instantiation
- Line 469: Entity instantiation
- Line 488: Entity instantiation
- Line 529: Entity instantiation
- Line 555: Entity instantiation
- Line 576: Entity instantiation
- Line 606: Entity instantiation

**Action:** Same as above - add architecture identifiers to all entity instantiations.

---

### 3. `hdl/ct/remap.vhd` (14 errors)

**Rules: Spacing between labels and colons (should be 0 spaces)**

**Lines to fix:**

**Generic declarations (`generic_014`):**
- Line 35: `number_of_input_lanes :` → `number_of_input_lanes:`
- Line 36: `number_of_output_lanes :` → `number_of_output_lanes:`

**Port declarations (`port_020`):**
- Line 41: `s_axis_tvalid :` → `s_axis_tvalid:`
- Line 42: `s_axis_tdata :` → `s_axis_tdata:`
- Line 43: `s_axis_tlast :` → `s_axis_tlast:`
- Line 45: `m_axis_tvalid :` → `m_axis_tvalid:`
- Line 46: `m_axis_tdata :` → `m_axis_tdata:`
- Line 47: `m_axis_tlast :` → `m_axis_tlast:`
- Line 49: `lane_map :` → `lane_map:`
- Line 50: `clk :` → `clk:`
- Line 51: `rst :` → `rst:`

**Process declaration (`process_002`, `process_024`):**
- Line 62: `remap_proc: process(all)` - check spacing between `process` and `(`, and between `remap_proc` and `:`

**Variable declaration (`variable_006`):**
- Line 64: `source_lane :` → `source_lane:`

**Action:** Remove spaces between labels and colons in all declarations.

---

### 4. `hdl/ct/ucorn.vhd` (2 errors)

**Rule: `instantiation_036` - Add architecture identifier**

**Lines to fix:**
- Line 161: Entity instantiation
- Line 211: Entity instantiation

**Action:** Add architecture identifiers to entity instantiations.

---

### 5. `hdl/corr/UCMAC44_ARRAY.vhd` (130 errors)

**Rules: Spacing between labels and colons (should be 0 spaces)**

**Lines to fix:**

**Generic declarations (`generic_014`):**
- Lines 51-57: Remove spaces before colons in generic declarations
  - `ncmac :` → `ncmac:`
  - `nprod :` → `nprod:`
  - `autocorr_stride :` → `autocorr_stride:`
  - `corr_number :` → `corr_number:`
  - `ncorr :` → `ncorr:`
  - `uram_max :` → `uram_max:`
  - `readout_bin :` → `readout_bin:`

**Port declarations (`port_020`):**
- Lines 61-87: Remove spaces before colons in port declarations
  - All `s_axis_xy_*` ports (lines 61-64)
  - All control ports (lines 66-70)
  - All `m_axis_z_*` ports (lines 76-79)
  - All `s_axis_z_*` ports (lines 81-84)
  - `clk` and `rst` ports (lines 86-87)

**Attribute declarations (`attribute_declaration_101`):**
- Lines 155-160: Remove spaces before colons
  - `rpm_grid :` → `rpm_grid:`
  - `rloc :` → `rloc:`
  - `u_set :` → `u_set:`
  - `rloc_origin :` → `rloc_origin:`
  - `keep_hierarchy :` → `keep_hierarchy:`

**Constant declarations (`constant_006`):**
- Lines 164, 166: Remove spaces before colons
  - `bytes_per_product :` → `bytes_per_product:`
  - `log2_ncorr :` → `log2_ncorr:`

**Entity specification (`entity_specification_101`):**
- Line 168: `impl :` → `impl:`

**Signal declarations (`signal_006`):**
- Lines 170-192: Remove spaces before colons in all signal declarations
  - `rst_reg :` → `rst_reg:`
  - `ram_dout :` → `ram_dout:`
  - `ram_din :` → `ram_din:`
  - `ram_wr_addr :` → `ram_wr_addr:`
  - `ram_rd_addr :` → `ram_rd_addr:`
  - `ram_wr_en :` → `ram_wr_en:`
  - `ram_rd_en :` → `ram_rd_en:`
  - All `tvalid*` signals (lines 179-182)
  - All `tlast*` signals (lines 183-186)
  - `ro_word2 :` → `ro_word2:`
  - All `last_frame*` signals (lines 188-191)
  - `first_frame2 :` → `first_frame2:`
  - (Continue for remaining signal declarations)

**Action:** Remove all spaces between labels and colons throughout the file. This is a bulk find-and-replace operation.

---

## Implementation Strategy

1. **For spacing fixes (`remap.vhd`, `UCMAC44_ARRAY.vhd`):**
   - Use search-replace to remove spaces before colons in declarations
   - Pattern: `label :` → `label:`
   - Be careful to only affect declarations, not other uses of colons

2. **For architecture identifier fixes (`chan_bin_sel.vhd`, `shuffle_bin_sel.vhd`, `ucorn.vhd`):**
   - Read each entity instantiation
   - Find the corresponding entity file to determine the architecture name
   - Add `(architecture_name)` after the entity name
   - Common architecture names: `impl`, `behavioral`, `structural`, `rtl`

## Verification

After making changes, run VSG again to verify all violations are fixed:
```bash
vsg --file hdl/ct/chan_bin_sel.vhd hdl/ct/shuffle_bin_sel.vhd hdl/ct/remap.vhd hdl/ct/ucorn.vhd hdl/corr/UCMAC44_ARRAY.vhd --configuration hdl/vsg_rules.yaml
```


