#!/bin/bash

if [ "$1" == "-n" ]
then
        n="$2"
        n=$((n+0))
        shift 2
else
        n=1
fi

if [ "$n" -lt 1 ] || [ -z "$1" ]
then
        echo "usage: $0 [-n <number of trials>] <benchmark number> [input file] [multithreading]"
        exit 1
fi

macro_name="benchmark$1"
macro_path="$(dirname $0)/../macros/$macro_name.C"

if [ $# -lt 2 ]
then
        macro_call="$macro_name()"
elif [ $# -lt 3 ]
then
        macro_call="$macro_name(\"$2\")"
else
        macro_call="$macro_name(\"$2\", $3)"
fi

root -b -l <<EOF
try {
        .L $macro_path
        std::cout << "CLK_TCK: "; std::flush(std::cout);
        system("getconf CLK_TCK");
        pid_t pid = getpid();
        char stat_cmd[32];
        sprintf(stat_cmd, "cat /proc/%i/stat", pid);
        for (auto i = 0; i < $n; ++i) {
                system("cat /proc/diskstats");
                system(stat_cmd);
                auto start = std::chrono::steady_clock::now();
                $macro_call;
                auto stop = std::chrono::steady_clock::now();
                std::chrono::duration<double> interval = stop - start;
                std::cout << interval.count() << " s" << std::endl;
        }
        system("cat /proc/diskstats");
        system(stat_cmd);
} catch (...) {
        exit(1);
}
EOF
