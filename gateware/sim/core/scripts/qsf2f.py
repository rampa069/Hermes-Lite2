#!/usr/bin/env python3
"""Build an Icarus Verilog command file from a variant's Quartus project.

Usage: qsf2f.py <variant_dir> > variant.f

Follows "source" lines (board tcl files) and QIP_FILE includes, collects
VERILOG_MACRO defines and the VERILOG/SYSTEMVERILOG source files in the order
Quartus sees them. Paths are written relative to the current directory.
"""
import os
import re
import sys


def parse(path, base, macros, files, seen):
    path = os.path.normpath(path)
    if path in seen:
        return
    seen.add(path)
    for line in open(path):
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        m = re.match(r"source\s+(\S+)", line)
        if m:
            parse(os.path.join(base, m.group(1)), base, macros, files, seen)
            continue
        m = re.search(r'-name\s+VERILOG_MACRO\s+"([^"]+)"', line)
        if m:
            macros.append(m.group(1))
            continue
        m = re.search(r"-name\s+(SYSTEMVERILOG|VERILOG)_FILE\s+(.+)$", line)
        if m:
            f = m.group(2).strip()
            q = re.match(r'\[file join \$::quartus\(qip_path\) "([^"]+)"\]', f)
            if q:
                f = os.path.join(os.path.dirname(path), q.group(1))
            else:
                f = os.path.join(base, f.strip('"'))
            f = os.path.normpath(f)
            if f not in files:
                files.append(f)
            continue
        m = re.search(r"-name\s+QIP_FILE\s+(\S+)", line)
        if m:
            parse(os.path.join(base, m.group(1)), base, macros, files, seen)


def main():
    vdir = sys.argv[1]
    macros, files = [], []
    parse(os.path.join(vdir, "hermeslite.qsf"), vdir, macros, files, set())
    for m in macros:
        print("+define+" + m)
    for f in files:
        print(os.path.relpath(f))


if __name__ == "__main__":
    main()
