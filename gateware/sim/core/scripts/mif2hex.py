#!/usr/bin/env python3
"""Convert Altera .mif memory init files to $readmemh files.

Usage: mif2hex.py OUTDIR file.mif [file.mif ...]

Writes OUTDIR/<basename>.hex, the name the altsyncram simulation model loads.
Supports ADDRESS_RADIX / DATA_RADIX HEX, DEC, UNS, BIN, OCT, "--" comments,
"addr : value;", "addr : v0 v1 ...;" and "[a..b] : value;" entries.
"""
import os
import re
import sys

RADIX = {"HEX": 16, "DEC": 10, "UNS": 10, "BIN": 2, "OCT": 8}


def convert(path, outdir):
    text = open(path).read()
    text = re.sub(r"--[^\n]*", "", text)
    text = re.sub(r"%[^%]*%", "", text)
    hdr = {}
    for key in ("DEPTH", "WIDTH", "ADDRESS_RADIX", "DATA_RADIX"):
        m = re.search(key + r"\s*=\s*(\w+)\s*;", text, re.I)
        if m:
            hdr[key] = m.group(1).upper()
    width = int(hdr["WIDTH"])
    depth = int(hdr["DEPTH"])
    arad = RADIX[hdr.get("ADDRESS_RADIX", "HEX")]
    drad = RADIX[hdr.get("DATA_RADIX", "HEX")]
    body = re.search(r"CONTENT\s+BEGIN(.*?)\bEND\b\s*;?", text, re.S | re.I).group(1)

    mem = [0] * depth
    mask = (1 << width) - 1
    for entry in body.split(";"):
        entry = entry.strip()
        if not entry:
            continue
        addr, data = [s.strip() for s in entry.split(":", 1)]
        values = [int(v, drad) & mask for v in data.split()]
        m = re.match(r"\[\s*(\w+)\s*\.\.\s*(\w+)\s*\]", addr)
        if m:
            lo, hi = int(m.group(1), arad), int(m.group(2), arad)
            for a in range(lo, hi + 1):
                mem[a] = values[(a - lo) % len(values)]
        else:
            a = int(addr, arad)
            for i, v in enumerate(values):
                mem[a + i] = v

    digits = (width + 3) // 4
    name = os.path.splitext(os.path.basename(path))[0] + ".hex"
    with open(os.path.join(outdir, name), "w") as f:
        for v in mem:
            f.write("%0*x\n" % (digits, v))


def main():
    outdir = sys.argv[1]
    for path in sys.argv[2:]:
        convert(path, outdir)


if __name__ == "__main__":
    main()
