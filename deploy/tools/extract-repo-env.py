#!/usr/bin/env python
# coding=utf-8

import sys
import os
from os.path import dirname, basename, abspath
import re

def main(ifile: str, ofile: str):
    # print(ifile)
    if ifile.endswith(".sh"):
        proj: str = basename(ifile).split(".")[1]
        # print(ifile, proj)
        rst = f"# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> [{proj}]\n"
        for L in open(ifile).readlines():
            if L.startswith("#") or L.strip() == "":
                continue
            if L.startswith("export PATH="):
                paths = re.search(r"PATH=(.*):\$PATH$", L).groups()[0]
                for p in paths.split(":"):
                    print(p)
                assert L.count(":") == 1, "Multiple ':' in one export PATH=... statement! L=" + L
                continue
            rst += L
        with open(ofile, "w") as f:
            f.write(rst + "\n")
    else:
        assert basename(ifile) == "default", f"{ifile=}"
        proj: str = basename(dirname(abspath(ifile)))
        rst = f"# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> [{proj}]\n"
        for L in open(ifile).readlines():
            if L.startswith("#") or L.strip() == "":
                continue
            if L.startswith("prepend-path PATH "):
                paths = re.search(r"prepend-path PATH (.*)", L).groups()
                print(paths[0])
                continue
            rst += L
        with open(ofile, "w") as f:
            f.write(rst + "\n")


if __name__ == "__main__":
    if len(sys.argv) == 3:
        main(sys.argv[1], sys.argv[2])
    elif len(sys.argv) == 2:
        main(sys.argv[1], ".temp")
    else:
        raise TypeError