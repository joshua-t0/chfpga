#!/usr/bin/env python3
"""
Check RST title underline/overline lengths and optionally fix them.

Fence lines (underlines/overlines) must match the associated title length
exactly. Valid fence characters: = - ` : ' " ~ ^ _ * + #

Usage:
  check_rst_fence_lengths.py [PATH ...]       Report mismatches only
  check_rst_fence_lengths.py --fix [PATH ...] Fix fence lengths to match titles

If no PATH is given, defaults to docs/ (recursive .rst).
"""

import argparse
import re
import sys
from pathlib import Path
from typing import List, Optional

# RST underline/overline characters (single repeated character)
FENCE_CHARS = r"=#*\-^\"'`:~_+"
# Character class: - at end to be literal; \ and ] escaped
_FENCE_CLASS = "".join("\\" + c if c in r"\]" else c for c in FENCE_CHARS)
FENCE_PATTERN = re.compile(r"^([" + _FENCE_CLASS + r"])\1*$")


def is_fence_line(line: str) -> bool:
    """True if line is non-empty and all the same valid fence character."""
    line = line.rstrip("\r\n")
    if not line or len(line) < 2:
        return False
    return bool(FENCE_PATTERN.match(line))


def fence_char(line: str) -> Optional[str]:
    """Return the fence character if line is a fence, else None."""
    line = line.rstrip("\r\n")
    if not line or len(line) < 2:
        return None
    m = FENCE_PATTERN.match(line)
    return m.group(1) if m else None


def collect_rst_files(paths: list[Path]) -> list[Path]:
    """Expand paths to a list of .rst files (directories searched recursively)."""
    out: list[Path] = []
    for p in paths:
        if p.is_file():
            if p.suffix.lower() == ".rst":
                out.append(p)
        elif p.is_dir():
            out.extend(sorted(p.rglob("*.rst")))
    return out


def check_file(path: Path, fix: bool) -> List[dict]:
    """
    Check (and optionally fix) fence lengths in one RST file.
    Returns list of issues: {path, line_no, title_sample, expected_len, actual_len, role}
    """
    try:
        text = path.read_text(encoding="utf-8", errors="replace")
    except OSError as e:
        return [{"error": str(e), "path": path}]

    lines = text.splitlines()
    issues: list[dict] = []
    i = 0

    while i < len(lines):
        line = lines[i]
        stripped = line.rstrip("\r\n")
        i += 1

        # Current line is a fence
        if is_fence_line(line):
            char = fence_char(line)
            actual_len = len(stripped)
            fence_idx = i - 1  # 0-based index of this fence line

            # Case 1: Overline — next line is title (fix top rail to match title)
            if i < len(lines):
                title_line = lines[i]
                title_stripped = title_line.rstrip("\r\n")
                if title_stripped and not is_fence_line(title_line):
                    expected_len = len(title_stripped)
                    original_overline = stripped  # keep for underline issue so it shows pre-fix state
                    if actual_len != expected_len:
                        top_rail = stripped
                        bottom_rail = None
                        if i + 1 < len(lines) and is_fence_line(lines[i + 1]) and fence_char(lines[i + 1]) == char:
                            bottom_rail = lines[i + 1].rstrip("\r\n")
                        fixed_rail = char * expected_len
                        issue = {
                            "path": path,
                            "line_no": i,  # 1-based
                            "title_full": title_stripped,
                            "title_sample": title_stripped[:60] + ("..." if len(title_stripped) > 60 else ""),
                            "expected_len": expected_len,
                            "actual_len": actual_len,
                            "role": "overline",
                            "top_rail": top_rail,
                            "bottom_rail": bottom_rail,
                        }
                        issues.append(issue)
                        if fix:
                            # Only fix overline if there is a blank line above it
                            has_blank_above = fence_idx == 0 or not lines[fence_idx - 1].strip()
                            if has_blank_above:
                                lines[fence_idx] = fixed_rail
                    # Look at line after title (underline)
                    i += 1
                    if i < len(lines) and is_fence_line(lines[i]) and fence_char(lines[i]) == char:
                        under = lines[i]
                        under_stripped = under.rstrip("\r\n")
                        under_actual = len(under_stripped)
                        if under_actual != expected_len:
                            # Use original overline so we show pre-fix state (lines[fence_idx] may already be fixed)
                            top_rail = original_overline if fence_idx >= 0 else None
                            fixed_rail = char * expected_len
                            issue = {
                                "path": path,
                                "line_no": i + 1,
                                "title_full": title_stripped,
                                "title_sample": title_stripped[:60] + ("..." if len(title_stripped) > 60 else ""),
                                "expected_len": expected_len,
                                "actual_len": under_actual,
                                "role": "underline",
                                "top_rail": top_rail,
                                "bottom_rail": under_stripped,
                            }
                            issues.append(issue)
                            if fix:
                                # Only fix underline if there is a blank line below it
                                has_blank_below = i + 1 >= len(lines) or not lines[i + 1].strip()
                                if has_blank_below:
                                    lines[i] = fixed_rail
                        # Require blank line after underline
                        if i + 1 < len(lines) and lines[i + 1].strip():
                            next_line = lines[i + 1].rstrip("\r\n")
                            issues.append({
                                "path": path,
                                "line_no": i + 2,  # 1-based: fence is at i+1 (0-based i)
                                "role": "missing_blank_after_fence",
                                "title_full": title_stripped,
                                "next_line": next_line[:60] + ("..." if len(next_line) > 60 else ""),
                            })
                            if fix:
                                lines.insert(i + 1, "")
                        i += 1  # skip underline so we don't process it again in Case 2
                    continue

            # Case 2: Underline only — previous line is title (no overline above)
            if i >= 2:
                prev = lines[i - 2]
                prev_stripped = prev.rstrip("\r\n")
                if prev_stripped and not is_fence_line(prev):
                    expected_len = len(prev_stripped)
                    if actual_len != expected_len:
                        top_rail = lines[fence_idx - 2].rstrip("\r\n") if fence_idx >= 2 and is_fence_line(lines[fence_idx - 2]) else None
                        fixed_rail = char * expected_len
                        issue = {
                            "path": path,
                            "line_no": i,
                            "title_full": prev_stripped,
                            "title_sample": prev_stripped[:60] + ("..." if len(prev_stripped) > 60 else ""),
                            "expected_len": expected_len,
                            "actual_len": actual_len,
                            "role": "underline",
                            "top_rail": top_rail,
                            "bottom_rail": stripped,
                        }
                        issues.append(issue)
                        if fix:
                            # Only fix underline if there is a blank line below it
                            has_blank_below = fence_idx + 1 >= len(lines) or not lines[fence_idx + 1].strip()
                            if has_blank_below:
                                lines[fence_idx] = fixed_rail
                    # Require blank line after underline
                    if fence_idx + 1 < len(lines) and lines[fence_idx + 1].strip():
                        next_line = lines[fence_idx + 1].rstrip("\r\n")
                        issues.append({
                            "path": path,
                            "line_no": fence_idx + 2,  # 1-based line number of fence
                            "role": "missing_blank_after_fence",
                            "title_full": prev_stripped,
                            "next_line": next_line[:60] + ("..." if len(next_line) > 60 else ""),
                        })
                        if fix:
                            lines.insert(fence_idx + 1, "")
        i += 0  # no-op; we already incremented

    if fix and issues:
        new_text = "\n".join(lines)
        if not new_text.endswith("\n") and lines:
            new_text += "\n"
        path.write_text(new_text, encoding="utf-8")

    return issues


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Check RST title fence lengths; use --fix to correct them."
    )
    parser.add_argument(
        "paths",
        nargs="*",
        type=Path,
        default=[Path("docs")],
        help="Files or directories to check (default: docs/)",
    )
    parser.add_argument(
        "--fix",
        action="store_true",
        help="Fix fence lines to match title length",
    )
    args = parser.parse_args()

    files = collect_rst_files(args.paths)
    if not files:
        print("No .rst files found.", file=sys.stderr)
        return 1

    all_issues: List[dict] = []
    for f in files:
        issues = check_file(f, fix=args.fix)
        for issue in issues:
            if "error" in issue:
                print(f"Error reading {issue['path']}: {issue['error']}", file=sys.stderr)
                continue
            all_issues.append(issue)

    if not all_issues:
        print("All RST fence lengths match their title lengths.")
        return 0

    if args.fix:
        print(f"Fixed {len(all_issues)} issue(s):")
    else:
        print("RST fence issue(s) (run with --fix to correct):")
    print()

    for u in all_issues:
        path = u["path"]
        line_no = u["line_no"]
        role = u["role"]
        action = "Fixed" if args.fix else "Error"
        if role == "missing_blank_after_fence":
            print(f"  {path}:{line_no} [missing_blank_after_fence] {action}: fence not followed by blank line")
            print(u["title_full"])
            print(f"  next line: {u['next_line']}")
        else:
            expected = u["expected_len"]
            actual = u["actual_len"]
            print(f"  {path}:{line_no} [{role}] {action}: title length {expected}, fence length {actual}")
            if u.get("top_rail"):
                print(u["top_rail"])
            print(u["title_full"])
            if u.get("bottom_rail"):
                print(u["bottom_rail"])
        print()

    return 0 if args.fix else 1


if __name__ == "__main__":
    sys.exit(main())
