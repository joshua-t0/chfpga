---
name: vhdl-instantiation-hierarchy
description: Extracts full instantiation hierarchy from a VHDL file and generates a text tree plus static HTML with click-to-expand nodes and an entity list in dependency order. Use when the user wants a hierarchy of VHDL entity instantiations, an instantiation-order entity list, or a browsable tree from a top-level entity.
---

# VHDL instantiation hierarchy

## When to use

- User asks for a hierarchy of instantiations from a VHDL file or top-level entity.
- User wants an entity list in instantiation/dependency order (each entity after its dependencies).
- User wants a static HTML tree with expand/collapse to browse the hierarchy.

## Quick start

1. Identify the VHDL file and the **top-level entity** name (the root of the hierarchy).
2. Run the script from the project root:

```bash
python .cursor/skills/vhdl-instantiation-hierarchy/scripts/extract_hierarchy.py --vhd path/to/file.vhd --root TOP_ENTITY
```

To combine entities from multiple VHDL files (one ordered list and hierarchy from the first file’s root):

```bash
python .cursor/skills/vhdl-instantiation-hierarchy/scripts/extract_hierarchy.py --vhd file1.vhd file2.vhd [--root ENTITY]
```

If the top-level entity name matches the first file’s stem (e.g. `foo.vhd` → entity `foo`), you can omit `--root`.

3. Outputs (next to the VHDL file):
   - `*_hierarchy.txt` — full tree in plain text.
   - `*_hierarchy.html` — static HTML with click-to-expand tree and entity list in instantiation order.
   - `*_entities.txt` — ordered list of entities (one per line), with `(not used)` after unreached entities.

4. To serve the HTML (e.g. for Cursor Simple Browser):  
   `python -m http.server 8765` in the same directory as the HTML, then open  
   `http://localhost:8765/<basename>_hierarchy.html`.

## Script usage

```bash
python scripts/extract_hierarchy.py --vhd <path> [--root ENTITY] [--no-browser]
```

| Argument    | Description |
|------------|-------------|
| `--vhd`    | One or more paths to VHDL file(s) (required). With multiple files, entities and instantiations from all files are merged; output paths use the first file’s stem. |
| `--root`   | Top-level entity name. Default: stem of first `--vhd` file (e.g. `hirax_bit_growth_3dsp` for `hirax_bit_growth_3dsp.vhd`). |
| `--no-browser` | Do not open the generated HTML in the default browser. |

Output files are written next to the VHDL file:  
`<stem>_hierarchy.txt`, `<stem>_hierarchy.html`.

## What the script does

- Parses the VHDL file(s) for `entity NAME is` and `instance : entity lib.child` to build parent–child links (merged when multiple files are given).
- Builds a tree from the root entity and writes:
  - A full text tree (every instantiation, no abbreviations).
  - An HTML page with: expand/collapse tree (full width, sub-nodes below parent), “Entities in instantiation order” (dependency order), “(not used)” for entities not reachable from root, and a note on circular dependencies (none expected in valid VHDL).
- Detects circular instantiations; if any, reports them in the HTML.

## Adapting for other files

- Use `--vhd` and `--root` for any single-file hierarchy (e.g. SysGen-style VHDL with many entities in one file).
- The script assumes all entities are in the same file; instantiations of external libraries (e.g. `xil_defaultlib.foo`) are shown as leaves.
