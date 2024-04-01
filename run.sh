#!/bin/sh

if [ -z "${1}" ] || [ -z "${2}" ]; then
    echo "Usage: $0 <ticks> <savegame>"
    exit 1
fi

ticks=${1}
savegame=${2}

rm -f result.csv

# Try five times to get a good CPU reading.
for i in $(seq 1 5); do
    echo "Attempt #${i} for stable performance measurement ..."

    rm -f stat.csv memory

    /usr/bin/time -o memory -f "%M" perf stat -x\; -o stat.csv -r5 ./openttd -X -c openttd.cfg -x -snull -mnull -vnull:ticks=${ticks} -g save/${savegame}
    if [ "$?" != "0" ] || [ ! -e "stat.csv" ] || [ ! -e "memory" ]; then
        reason="crash"
        break
    fi

    # Check if the stddev is less than 0.5%.
    stddev=$(cat stat.csv | grep task-clock | cut -d\; -f4 | rev | cut -b2- | rev)
    echo ${stddev} | python3 -c "import sys; sys.exit(float(sys.stdin.read().strip()) > 0.9)"
    if [ "$?" = "0" ]; then
        reason="success"
        break
    fi

    echo "High CPU timing stddev detected: ${stddev}% after $(cat stat.csv | grep task-clock | cut -d\; -f1) ms"
    reason="stddev"
done

if [ "${reason}" = "stddev" ]; then
    echo "Performance measurement failed: CPU timing deviates too much."
    exit 1
elif [ "${reason}" = "crash" ]; then
    cpu="crash"
    cpu_stdev="crash"
    memory="crash"

    echo "Performance measurement failed: savegame crashes the game."
else
    cpu=$(cat stat.csv | grep task-clock | cut -d\; -f1)
    cpu_stdev=$(cat stat.csv | grep task-clock | cut -d\; -f4 | rev | cut -b2- | rev)
    memory=$(cat memory)

    echo "CPU: ${cpu} ms (+/- ${cpu_stdev}%)"
    echo "Memory: ${memory} KiB"
fi

echo "cpu=${cpu}" >> $GITHUB_OUTPUT
echo "cpu_stdev=${cpu_stdev}" >> $GITHUB_OUTPUT
echo "memory=${memory}" >> $GITHUB_OUTPUT
