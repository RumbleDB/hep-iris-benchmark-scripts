#!/bin/bash

# Default parameter values
NUM_TRIALS=1
ENABLE_MULTITHREADING=true
ENABLE_OPTIMIZATIONS=true
VERBOSE=false
INPUT_FILES=()

function print_usage() {
    echo "Usage: $0 -b <benchmark ID> [-n <#trials>] [-m <multithreading>] [-o <optimizations>] [input file]"
}

function read_value() {
    if [[ $# -lt 2 ]]
    then
        echo "Argument $1 requires a value." >&2
        print_usage >&2
        exit 1
    fi
    printf "%s" "$2"
}

# Parse command line arguments
while [[ $# -gt 0 ]]
do
    key="$1"

    case $key in
      -h|--help)
        print_usage
        exit
        ;;
      -n|--num-trials)
        NUM_TRIALS="$(read_value "$@")" || exit 1
        shift # past argument
        shift # past value
        ;;
      -b|--benchmark-id)
        BENCHMARK_ID="$2"
        shift # past argument
        shift # past value
        ;;
      -m|--enable-multithreading)
        ENABLE_MULTITHREADING="$2"
        shift # past argument
        shift # past value
        ;;
      -o|--enable-optimizations)
        ENABLE_OPTIMIZATIONS="$2"
        shift # past argument
        shift # past value
        ;;
      -v|--verbose)
        VERBOSE=true
        shift # past argument
        ;;
      *)
        INPUT_FILES=("$@")
        break
        ;;
    esac
done

if $VERBOSE
then
    echo "Num trials: $NUM_TRIALS"
    echo "Benchmark ID: $BENCHMARK_ID"
    echo "Enable multi-threading: $ENABLE_MULTITHREADING"
    echo "Enable optimizations: $ENABLE_OPTIMIZATIONS"
    echo "Files: ${INPUT_FILES[@]}"
fi

# Assemble call to macro
macro_name="benchmark$BENCHMARK_ID"
macro_path="$(dirname $0)/../macros/$macro_name.C"

if [[ ${#INPUT_FILES[@]} -eq 0 && "$ENABLE_MULTITHREADING" != "true" ]]
then
    echo "Cannot disable multi-threading if no explit input files are given." >&2
    exit 1
elif [[ ${#INPUT_FILES[@]} -eq 0 ]]
then
    macro_call="$macro_name()"
else
    files_arg="$(for f in ${INPUT_FILES[@]}; do echo "\"$f\""; done | paste -s -d, -)"
    macro_call="$macro_name({$files_arg}, $ENABLE_MULTITHREADING)"
fi

# Assemble ROOT options
root_options=('-b' '-l')

if [[ $ENABLE_OPTIMIZATIONS ]]
then
	root_options+=('-e' '.L /opt/root/lib/libROOTDataFrame.so' '-e' ".L $macro_path+O")
else
	root_options+=('-e' ".L $macro_path")
fi

root "${root_options[@]}" <<EOF
try {
        std::cout << "CLK_TCK: "; std::flush(std::cout);
        system("getconf CLK_TCK");
        pid_t pid = getpid();
        char stat_cmd[32];
        sprintf(stat_cmd, "cat /proc/%i/stat", pid);
        for (auto i = 0; i < $NUM_TRIALS; ++i) {
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
