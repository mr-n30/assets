#!/usr/bin/env python3
import sys

for line in sys.stdin:
    domain = line.strip()
    print(domain.lower())
