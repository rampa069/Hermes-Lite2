#!/usr/bin/env python3
"""Make simulation copies of RTL files that Verilator/Icarus reject.

Usage: rtl_compat.py <in.f> <out.f> <compat_dir>

The RTL is not modified. Files that need a change are copied to compat_dir
(keeping their relative path) with the rewrites below applied, and the command
file is rewritten to use the copies. Every rewrite keeps the behavior of the
original code; each one is reported so it can be fixed in the RTL if wanted.

  1. "output x = v;" in a non-ANSI port declaration -> "output x; assign x = v;"
  2. generate block labels equal to a parameter name -> label gets "_blk" suffix
  3. "parameter X;" with no default -> "parameter X = 0;"
  4. unpacked array "= '{default: '0}" initializer -> initial foreach loop
  5. based literal starting with "_" ("80'h_0806") -> underscore removed
"""
import os
import re
import sys


def rewrite(text):
    notes = []

    def sub(pattern, repl, s, note, flags=0):
        new, n = re.subn(pattern, repl, s, flags=flags)
        if new != s:
            notes.append("%s (%d)" % (note, n))
        return new

    text = sub(r"^(\s*)output(\s+)(\w+)\s*=\s*([^;]+);",
               r"\1output\2\3; assign \3 = \4;", text,
               "initialized non-ANSI output port", re.M)

    # Non-ANSI "output [r] a, b;" without a data type, and no separate
    # reg/logic declaration of the name: make it a variable so it can be
    # assigned from always blocks (Quartus accepts this, the LRM does not).
    def outvar(m):
        indent, rng, names = m.group(1), m.group(2) or "", m.group(3)
        out = []
        for n in [x.strip() for x in names.split(",")]:
            redecl = re.search(r"\b(reg|logic|wire|integer)\b[^;]*\b%s\b" % n, text)
            out.append("%soutput %s%s%s;" % (indent, "" if redecl else "logic ", rng, n))
        return "\n".join(out)
    text = sub(r"^(\s*)output\s+(\[[^\]]*\]\s*)?(\w+(?:\s*,\s*\w+)*)\s*;", outvar, text,
               "non-ANSI output port without data type", re.M)

    # Same for ANSI "output [r] name," when name is assigned procedurally
    def ansi_outvar(m):
        indent, sp, rng, name, tail = m.groups()
        proc = re.search(r"^(?!\s*assign\b)\s*(?:if\s*\(.*\)\s*|else\s+)?%s\s*(\[[^\]]*\]\s*)?<?=(?!=)" % name,
                         text, re.M)
        if not proc:
            return m.group(0)
        return "%soutput%slogic %s%s%s" % (indent, sp, rng or "", name, tail)
    text = sub(r"^(\s*)output(\s+)(\[[^\]]*\]\s*)?(\w+)(\s*(?:,|\)|$))", ansi_outvar, text,
               "ANSI output port without data type assigned procedurally", re.M)

    params = set(re.findall(r"\b(?:parameter|localparam)\s+(?:\w+\s+)?(?:\[[^\]]*\]\s*)?(\w+)", text))
    for p in sorted(params):
        text = sub(r"\bbegin\s*:\s*%s\b" % p, "begin: %s_blk" % p, text,
                   "generate label '%s' equal to a parameter" % p)
        text = sub(r"\bend\s*:\s*%s\b" % p, "end: %s_blk" % p, text,
                   "generate end label '%s' equal to a parameter" % p)

    text = sub(r"^(\s*)parameter(\s+)(\w+)\s*;", r"\1parameter\2\3 = 0;", text,
               "parameter without default", re.M)

    def init_pattern(m):
        decl, name = m.group(1), m.group(2)
        return "%s;\ninitial foreach (%s[i]) %s[i] = '0;" % (decl, name, name)
    text = sub(r"^(\s*reg\b[^;=]*?\b(\w+)\s*\[[^\]]*\])\s*=\s*'\{\s*default\s*:\s*'0\s*\}\s*;",
               init_pattern, text, "'{default:'0} array initializer", re.M)

    text = sub(r"('[sS]?[hHdDbBoO])_", r"\1", text, "based literal starting with '_'")

    def reorder(m):
        body = m.group(2)
        items = [i for i in re.split(r",(?![^()]*\))", body)]
        parsed = []
        for it in items:
            code = re.sub(r"//[^\n]*", "", it)
            pm = re.match(r"\s*(\w+)\s*=", code)
            if not pm:
                return m.group(0)
            parsed.append((pm.group(1), it))
        names = [n for n, _ in parsed]
        done, order = set(), []
        while len(order) < len(parsed):
            progress = False
            for n, it in parsed:
                if n in done:
                    continue
                rhs = re.sub(r"//[^\n]*", "", it).split("=", 1)[1]
                deps = [d for d in names if d != n and re.search(r"\b%s\b" % d, rhs)]
                if all(d in done for d in deps):
                    done.add(n)
                    order.append(it.strip())
                    progress = True
            if not progress:
                return m.group(0)
        if order == [it.strip() for _, it in parsed]:
            return m.group(0)
        return m.group(1) + "\n    " + ",\n    ".join(
            re.sub(r"\s*(//[^\n]*)$", "", o) for o in order) + ";"
    text = sub(r"(\bparameter\b)(\s*\n[^;]*?);", reorder, text, "parameter used before declaration")
    return text, notes


def main():
    fin, fout, cdir = sys.argv[1:4]
    out = []
    for line in open(fin):
        line = line.rstrip("\n")
        if not line or line.startswith("+"):
            out.append(line)
            continue
        text = open(line).read()
        new, notes = rewrite(text)
        if new != text:
            dst = os.path.join(cdir, os.path.normpath(line).lstrip("./").replace("../", ""))
            os.makedirs(os.path.dirname(dst), exist_ok=True)
            open(dst, "w").write(new)
            sys.stderr.write("compat: %s: %s\n" % (line, "; ".join(notes)))
            out.append(dst)
        else:
            out.append(line)
    open(fout, "w").write("\n".join(out) + "\n")


if __name__ == "__main__":
    main()
