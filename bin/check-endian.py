#!/usr/bin/env python
# coding=utf-8


import sys
import os
import os.path
import struct

dtype = 'i4'
targetFile = sys.argv[1]

if not os.path.exists(targetFile):
    print("File doesn't exist!")
    sys.exit(101)

with open(targetFile, 'rb') as f:
    data = f.read()

vals_be = struct.unpack('>' + 'i' * (len(data) // 4), data)
vals_le = struct.unpack('<' + 'i' * (len(data) // 4), data)

N = len(vals_be)
avg_be = sum(vals_be) / N
avg_le = sum(vals_le) / N
std_be = (sum([(x - avg_be)**2 for x in vals_be]) / N) ** 0.5
std_le = (sum([(x - avg_le)**2 for x in vals_le]) / N) ** 0.5

print(f'stddev for big-endian assumption is {std_be}')
print(f'stddev for little-endian assumption is {std_le}')
if std_be < std_le:
    print(f"More likely to be big-endian")
else:
    print(f"More likely to be little-endian")
