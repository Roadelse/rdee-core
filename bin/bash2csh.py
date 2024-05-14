#!/usr/bin/env python
# coding=utf-8

import sys
import os
import os.path
import re

def main():
    ifile: str = sys.argv[1]
    assert os.path.exists(ifile)
    if ifile.endswith(".sh"):
        ofile: str = ifile[:-2] + "csh"
    else:
        ofile: str = ifile + ".csh"
    lines: list[str] = open(ifile).read().splitlines()
    with open(ofile, "w") as f:
        f.write("#!/bin/csh\n\n")
        for L in lines:
            L = L.strip()
            if L.startswith("#"):
                f.write("# ")
            elif L.startswith("export "):
                vn, vv = re.search(r"export +([^ ]*)=(.*)$", L).groups()
                f.write(f"setenv {vn} {vv}\n")
            else:
                raise NotImplementedError("Unknown statement by now, please update teh code")


if __name__ == "__main__":
    main()