#!/bin/sh

if [ -z "${1}" ] || [ -z "${2}" ] || [ -z "${3}" ]; then
    echo "Usage: $0 cpu|mem <ticks> <savegame>"
    exit 1
fi

type=${1}
ticks=${2}
savegame=${3}

case ${type} in
    cpu)
        CPUPROFILE=openttd.cpu-prof LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libprofiler.so ./openttd -X -c openttd.cfg -x -snull -mnull -vnull:ticks=${ticks} -g save/${savegame}
        if [ "$?" != "0" ] || [ ! -e "openttd.cpu-prof" ]; then
            echo "Failed to create CPU profile"
            touch ${savegame}.cpu-prof
            exit 0
        fi

        ~/go/bin/pprof -proto -output ${savegame}.cpu-prof.gz openttd.cpu-prof

        ;;

    mem)
        # Take a snapshot of the current heap usage every second. We only run for 50 ticks, as memory profiling is slow (as we do a lot of mallocs).
        HEAPPROFILE=openttd.mem-prof HEAP_PROFILE_ALLOCATION_INTERVAL=0 HEAP_PROFILE_INUSE_INTERVAL=0 HEAP_PROFILE_TIME_INTERVAL=1 LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libtcmalloc.so ./openttd -X -c openttd.cfg -x -snull -mnull -vnull:ticks=${ticks} -g save/${savegame}
        if [ "$?" != "0" ] || [ ! -e "openttd.mem-prof.0001.heap" ]; then
            echo "Failed to create memory profile"
            touch ${savegame}.mem-prof
            exit 0
        fi

        # We only use the 2nd to last snapshot, as the last two snapshots are those of shutting down.
        stable=$(ls openttd.mem-prof.* | sort -n | tail -n3 | head -n1)
        echo "Using ${stable} as stable snapshot"

        ~/go/bin/pprof -proto -output ${savegame}.mem-prof.gz ${stable}

        ;;

    *)
        echo "Invalid type: ${type}"
        exit 1
        ;;
esac
