#!/usr/bin/env python3
"""save-tool-result.py — clone-ui Phase 2 helper (cross-platform).

Slices a JSON object out of a Claude tool-result file and writes it to a
clone workspace location.

Usage:
    python3 ./scripts/save-tool-result.py --src <tool-result-path> --out <workspace-json-path> [--marker '```json']

Scope (kept narrow on purpose):
    - Reads ONLY the file path passed via --src.
    - Writes ONLY the file path passed via --out.
    - Does NOT mutate any user, agent, or IDE configuration.
    - Does NOT make any network calls.

Why this exists: chrome-devtools-mcp evaluate_script results often overflow
the LLM context window, so they're persisted as tool-result files on disk.
Phase 2 needs to slice the JSON payload from those files into typed
capture artifacts (section-styles.json, nav-states.json, etc). Doing this
inline with shell subexpressions triggers a permission prompt for every
save; routing through this single script means one allow-rule covers
every Phase 2 capture.
"""

from __future__ import annotations

import argparse
import os
import sys


def main() -> int:
    parser = argparse.ArgumentParser(description="Slice JSON from a tool-result file.")
    parser.add_argument("--src", required=True, help="path to the tool-result file")
    parser.add_argument("--out", required=True, help="path to write the JSON object to")
    parser.add_argument("--marker", default="```json", help="text marker preceding the JSON object")
    args = parser.parse_args()

    if not os.path.isfile(args.src):
        print(f"Source file not found: {args.src}", file=sys.stderr)
        return 1

    with open(args.src, "r", encoding="utf-8") as f:
        raw = f.read()

    marker_idx = raw.find(args.marker)
    search_from = marker_idx if marker_idx >= 0 else 0
    start = raw.find("{", search_from)
    end = raw.rfind("}")

    if start < 0 or end < start:
        print(f"No JSON object found in {args.src} (marker={args.marker!r})", file=sys.stderr)
        return 1

    payload = raw[start : end + 1]

    out_dir = os.path.dirname(args.out)
    if out_dir:
        os.makedirs(out_dir, exist_ok=True)

    with open(args.out, "w", encoding="utf-8") as f:
        f.write(payload)

    size = os.path.getsize(args.out)
    name = os.path.basename(args.out)
    print(f"{name}: {size} bytes")
    return 0


if __name__ == "__main__":
    sys.exit(main())
