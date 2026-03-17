#!/usr/bin/env python3
"""
Extract full instantiation hierarchy from one or more VHDL files.
Output: text tree and static HTML with click-to-expand nodes and entity list in dependency order.

Usage:
  python extract_hierarchy.py --vhd path/to/file.vhd [--root ENTITY] [--no-browser]
  python extract_hierarchy.py --vhd file1.vhd file2.vhd [--root ENTITY] [--no-browser]
"""
import argparse
import html
import re
import webbrowser
from pathlib import Path

# Set by main() from CLI args
VHD_PATHS = None
OUT_PATH = None
HTML_PATH = None
ENTITIES_PATH = None
ROOT_ENTITY = None


def build_tree(get_children_list, entities_in_file, root_entity):
    """Build a tree of dicts: { label, entity, lib, in_file, children: [] }."""
    def node(label, lib, child_entity):
        child_in_file = child_entity in entities_in_file
        children = []
        if child_in_file:
            for (clabel, clib, cent) in get_children_list(child_entity):
                children.append(node(clabel, clib, cent))
        return {
            "label": label,
            "entity": child_entity,
            "lib": lib,
            "in_file": child_in_file,
            "children": children,
        }
    root_children = []
    for (label, lib, child_entity) in get_children_list(root_entity):
        root_children.append(node(label, lib, child_entity))
    return {"label": "", "entity": root_entity, "lib": None, "in_file": True, "children": root_children}


def escape(s):
    return html.escape(s, quote=True)


def render_html_node(n, is_root=False, default_expanded=False):
    if is_root:
        label_entity = escape(n["entity"])
    else:
        if n.get("in_file"):
            label_entity = f"{escape(n['label'])} : {escape(n['entity'])}"
        else:
            label_entity = f"{escape(n['label'])} : {escape(n['lib'] + '.' + n['entity'])}"
    has_children = len(n["children"]) > 0
    extra_class = " root" if is_root else ""
    extra_class += " expanded" if default_expanded else ""
    child_class = " expanded" if default_expanded else ""
    children_html = ""
    if has_children:
        children_html = f'<ul class="children{child_class}">'
        for c in n["children"]:
            children_html += "<li>" + render_html_node(c, False, False) + "</li>"
        children_html += "</ul>"
    return (
        f'<div class="tree-node{extra_class}" data-has-children="{str(has_children).lower()}">'
        '<span class="node-toggle" aria-hidden="true"></span>'
        f'<span class="node-label">{label_entity}</span>'
        f'{children_html}'
        "</div>"
    )


def entity_list_instantiation_order(get_children_list, entities_in_file, root_entity):
    """Return (entity_list, unreached_set, cycle)."""
    result = []
    seen = set()
    in_path = set()
    path_order = []
    cycle_found = None

    def post_order(entity_name):
        nonlocal cycle_found
        if entity_name in in_path:
            idx = path_order.index(entity_name)
            cycle_found = path_order[idx:] + [entity_name]
            return
        if entity_name in seen:
            return
        seen.add(entity_name)
        in_path.add(entity_name)
        path_order.append(entity_name)
        for (_label, _lib, child_entity) in get_children_list(entity_name):
            if child_entity in entities_in_file:
                post_order(child_entity)
        path_order.pop()
        in_path.discard(entity_name)
        result.append(entity_name)

    post_order(root_entity)
    unreached = {e for e in entities_in_file if e not in seen}
    # Append unreached in dependency order: A instantiates B => B must come before A.
    # Kahn: in_degree[A] = number of unreached children of A; when we output B, decrement in_degree for each A that has B as child.
    next_list = {e: [] for e in unreached}
    for parent in unreached:
        for (_l, _lib, child) in get_children_list(parent):
            if child in unreached:
                next_list[child].append(parent)
    in_degree = {e: 0 for e in unreached}
    for parent in unreached:
        for (_l, _lib, child) in get_children_list(parent):
            if child in unreached:
                in_degree[parent] += 1
    queue = [e for e in unreached if in_degree[e] == 0]
    unreached_order = []
    while queue:
        n = queue.pop(0)
        unreached_order.append(n)
        for parent in next_list[n]:
            in_degree[parent] -= 1
            if in_degree[parent] == 0:
                queue.append(parent)
    for e in unreached_order:
        result.append(e)
    return result, unreached, cycle_found


def write_html(tree, entity_order, unreached, cycle, out_path, vhd_path_str):
    root_part = render_html_node(tree, is_root=True, default_expanded=True)
    not_used_span = ' <span class="not-used">(not used)</span>'
    entity_list_items = "".join(
        f'    <li>{escape(e)}{not_used_span if e in unreached else ""}</li>\n'
        for e in entity_order
    )
    cycle_note = ""
    if cycle:
        cycle_note = f'    <p class="cycle-warning">Circular dependency detected: {" → ".join(escape(x) for x in cycle)}</p>\n'
    else:
        cycle_note = '    <p class="source">No circular instantiations detected. Order is valid (each entity appears after all entities it depends on).</p>\n'

    html_content = f"""<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>{escape(ROOT_ENTITY)} hierarchy</title>
  <style>
    * {{ box-sizing: border-box; }}
    body {{ font-family: ui-monospace, "Cascadia Code", "Source Code Pro", Monaco, monospace; font-size: 13px; margin: 1rem 1.5rem; background: #1e1e1e; color: #d4d4d4; line-height: 1.45; }}
    h1 {{ font-size: 1.1rem; font-weight: 600; color: #e0e0e0; margin-bottom: 0.25rem; }}
    .source {{ font-size: 0.85rem; color: #858585; margin-bottom: 1rem; }}
    .tree {{ margin: 0; padding: 0; list-style: none; width: 100%; }}
    .tree ul {{ margin: 0; margin-top: 0.2rem; margin-left: 1rem; padding: 0; list-style: none; display: block; width: 100%; }}
    .tree li {{ margin: 0.2rem 0; display: block; width: 100%; }}
    .tree-node {{ display: block; width: 100%; }}
    .tree-node > .node-toggle {{ cursor: pointer; user-select: none; color: #569cd6; width: 1.2em; display: inline-block; vertical-align: middle; }}
    .tree-node > .node-toggle:hover {{ color: #9cdcfe; }}
    .tree-node > .node-label {{ display: inline; word-break: break-word; }}
    .tree-node .node-label .ext {{ color: #858585; }}
    .tree-node.root > .node-label {{ font-weight: 600; color: #4ec9b0; }}
    .tree-node ul.children {{ display: none; }}
    .tree-node.expanded > ul.children {{ display: block; }}
    .tree-node:not(.expanded) > .node-toggle::before {{ content: "▶"; }}
    .tree-node.expanded > .node-toggle::before {{ content: "▼"; }}
    .tree-node:not([data-has-children="true"]) > .node-toggle {{ visibility: hidden; }}
    .tree-node:not([data-has-children="true"]) > .node-label {{ margin-left: 1.2em; }}
    .controls {{ margin-bottom: 0.75rem; }}
    .controls button {{ font-family: inherit; font-size: 0.85rem; cursor: pointer; padding: 0.25rem 0.5rem; margin-right: 0.5rem; background: #2d2d2d; color: #d4d4d4; border: 1px solid #404040; border-radius: 3px; }}
    .entity-list-section {{ margin-top: 2rem; padding-top: 1.5rem; border-top: 1px solid #404040; }}
    .entity-list-section h2 {{ font-size: 1rem; font-weight: 600; color: #e0e0e0; margin-bottom: 0.5rem; }}
    .entity-list-section ol {{ margin: 0; padding-left: 1.5rem; color: #d4d4d4; }}
    .entity-list-section li {{ margin: 0.2rem 0; }}
    .entity-list-section .not-used {{ color: #858585; font-style: italic; }}
    .entity-list-section .cycle-warning {{ color: #ce9178; font-weight: 500; margin-bottom: 0.5rem; }}
  </style>
</head>
<body>
  <h1>{escape(ROOT_ENTITY)} — instantiation hierarchy</h1>
  <p class="source">Source: {escape(vhd_path_str)}</p>
  <div class="controls">
    <button type="button" id="expandAll">Expand all</button>
    <button type="button" id="collapseAll">Collapse all</button>
  </div>
  <div class="tree" id="tree">
    {root_part}
  </div>
  <section class="entity-list-section" aria-label="Entities in instantiation order">
    <h2>Entities in instantiation order</h2>
    <p class="source">Each entity appears below all entities it depends on (instantiation / dependency order).</p>
{cycle_note}
    <ol>
{entity_list_items}
    </ol>
  </section>
  <script>
    (function() {{
      var tree = document.getElementById("tree");
      function onToggle(e) {{
        var t = e.target;
        if (!t.classList.contains("node-toggle")) return;
        var node = t.closest(".tree-node");
        if (!node || node.getAttribute("data-has-children") !== "true") return;
        node.classList.toggle("expanded");
      }}
      tree.addEventListener("click", onToggle);
      document.getElementById("expandAll").addEventListener("click", function() {{
        tree.querySelectorAll(".tree-node").forEach(function(n) {{ n.classList.add("expanded"); }});
      }});
      document.getElementById("collapseAll").addEventListener("click", function() {{
        tree.querySelectorAll(".tree-node").forEach(function(n) {{ n.classList.remove("expanded"); }});
        tree.querySelector(".tree-node.root").classList.add("expanded");
      }});
    }})();
  </script>
</body>
</html>
"""
    with open(out_path, "w", encoding="utf-8") as f:
        f.write(html_content)
    return out_path


def main():
    global VHD_PATHS, OUT_PATH, HTML_PATH, ENTITIES_PATH, ROOT_ENTITY
    parser = argparse.ArgumentParser(description="Extract VHDL instantiation hierarchy to text and HTML.")
    parser.add_argument("--vhd", required=True, type=Path, nargs="+", help="Path(s) to VHDL file(s)")
    parser.add_argument("--root", default=None, help="Top-level entity name (default: stem of first --vhd file)")
    parser.add_argument("--no-browser", action="store_true", help="Do not open HTML in browser")
    args = parser.parse_args()

    VHD_PATHS = [p.resolve() for p in args.vhd]
    for p in VHD_PATHS:
        if not p.exists():
            raise SystemExit(f"VHDL file not found: {p}")
    stem = VHD_PATHS[0].stem
    out_dir = VHD_PATHS[0].parent
    OUT_PATH = out_dir / f"{stem}_hierarchy.txt"
    HTML_PATH = out_dir / f"{stem}_hierarchy.html"
    ENTITIES_PATH = out_dir / f"{stem}_entities.txt"
    ROOT_ENTITY = args.root if args.root is not None else stem

    entity_re = re.compile(r"^\s*entity\s+(\w+)\s+is\s*$")
    inst_re = re.compile(r"^\s*(\w+)\s*:\s*entity\s+(\w+)\.(\w+)\s*")

    all_entities = set()
    per_file_entity_starts = []
    per_file_insts = []

    for vhd_path in VHD_PATHS:
        with open(vhd_path, "r") as f:
            lines = f.readlines()
        entity_starts = []
        for i, line in enumerate(lines):
            m = entity_re.match(line)
            if m:
                entity_starts.append((i + 1, m.group(1)))
                all_entities.add(m.group(1))
        per_file_entity_starts.append(entity_starts)
        insts = []
        for i, line in enumerate(lines):
            m = inst_re.match(line)
            if m:
                insts.append((i + 1, m.group(1), m.group(2), m.group(3)))
        per_file_insts.append(insts)

    entities_in_file = all_entities

    def parent_entity_for_starts(entity_starts, line_num):
        for i in range(len(entity_starts)):
            if entity_starts[i][0] > line_num:
                return entity_starts[i - 1][1] if i > 0 else None
        return entity_starts[-1][1] if entity_starts else None

    order = {}
    for file_idx, insts in enumerate(per_file_insts):
        entity_starts = per_file_entity_starts[file_idx]
        for line_num, label, lib, child in insts:
            parent = parent_entity_for_starts(entity_starts, line_num)
            if parent is None:
                continue
            if parent not in order:
                order[parent] = []
            order[parent].append((line_num, label, lib, child))
    for p in order:
        order[p].sort(key=lambda x: x[0])

    def get_children_list(parent):
        if parent not in order:
            return []
        return [(label, lib, child) for _, label, lib, child in order[parent]]

    def full_name(lib, child):
        return f"{lib}.{child}"

    out_lines = []
    vhd_names = ", ".join(p.name for p in VHD_PATHS)
    out_lines.append(f"Full instantiation hierarchy in {vhd_names}")
    out_lines.append("=" * 70)
    out_lines.append(f"Source: {', '.join(str(p) for p in VHD_PATHS)}")
    out_lines.append("Every entity and every instantiation; no abbreviations.")
    out_lines.append("")

    def visit(entity_name, indent):
        child_list = get_children_list(entity_name)
        for idx, (label, lib, child) in enumerate(child_list):
            is_last = idx == len(child_list) - 1
            branch = "└── " if is_last else "├── "
            prefix = indent + branch
            child_in_file = child in entities_in_file
            if child_in_file:
                line = f"{prefix}{label} : {child}"
            else:
                line = f"{prefix}{label} : {full_name(lib, child)}"
            out_lines.append(line)
            if child_in_file:
                ext = "    " if is_last else "│   "
                visit(child, indent + ext)

    out_lines.append(ROOT_ENTITY)
    visit(ROOT_ENTITY, "")

    with open(OUT_PATH, "w", encoding="utf-8") as f:
        f.write("\n".join(out_lines))
    print("Wrote", OUT_PATH, "with", len(out_lines), "lines")

    tree = build_tree(get_children_list, entities_in_file, ROOT_ENTITY)
    entity_order, unreached, cycle = entity_list_instantiation_order(get_children_list, entities_in_file, ROOT_ENTITY)
    vhd_path_str = ", ".join(str(p) for p in VHD_PATHS)
    html_path = write_html(tree, entity_order, unreached, cycle, HTML_PATH, vhd_path_str)
    print("Wrote", html_path)

    with open(ENTITIES_PATH, "w", encoding="utf-8") as f:
        for e in entity_order:
            line = e + (" (not used)\n" if e in unreached else "\n")
            f.write(line)
    print("Wrote", ENTITIES_PATH, "with", len(entity_order), "entities")

    if not args.no_browser:
        webbrowser.open(html_path.resolve().as_uri())


if __name__ == "__main__":
    main()
