#!/usr/bin/env bash

# Convert system-specific files into common format
./convert.sh

# Figure 1
./cost-running-time-tradeoff.sh

# Figure 2
./scaling-running-time.sh

# Figure 3
./particle-distribution.sh

# Figure 4
./systems.sh

# Unused figures
./asterixdb-format-tuning.sh
./scaling-cpu-time.sh
