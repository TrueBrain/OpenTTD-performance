# OpenTTD performance

This repository monitors OpenTTD's performance day-to-day, to ensure that the developers are made aware of any regression in terms of CPU or memory.

These performance tests are automatically executed every night, with the last commit since midnight.

## Running the performance tests

### Method of measuring

Measuring performance is not trivial, as it strongly depends on the CPU and other hardware.
But even with the exact same hardware, performance can differ (CPU branch-prediction etc).

For memory, GNU time is used to find the peak memory usage, in KiB.
This value is accurate within +/- 1% between runs.

For CPU, "perf" is used to measure user-time.
For each performance test, OpenTTD is ran 5 times, and it is validated the deviation between the runs isn't more than 0.5%.
If it is, the test is restarted, until it is within 0.5%.

Additionally, as we use GitHub Runners to execute the performance tests, we also have to account for different hardware.
Lastly, dependencies might be different from day-to-day.
To compensate as much as possible for these differences, each savegame is run in multiple different setups:

1) a pre-compiled 12.0 binary that is identical between every run.
   This is used to normalize the results between different days.
2) a freshly compiled 12.0 binary, to validate if the dependencies / compiler have any influence on the result.
3) yesterday's version, to compare today's version against.
4) today's version.

With gathering these four results for every savegame in this performance suite every night, we should be able to discover trends, and which night CPU / memory changed.

### OpenTTD's configuration

Every performance test is run based on the last commit of that day.
It is compiled as `Release` build with `assert()` turned off.
We also forcefully disable the use of threads, as they are a known source of CPU timing difference (most commonly when linkgraph is enabled).

Additionally, a configuration is loaded to disable autosaves.
Lastly, patches are loaded to make OpenTTD compile with modern compilers / dependencies.

OpenGFX 7.1 is used; not that it really matters, but a BaseGraphics is required for OpenTTD to run.

OpenTTD is run with `-X -c performance-config/openttd.cfg -x -snull -mnull -vnull:ticks=${ticks} -g ${map}`, where `${ticks}` and `${map}` is depending on the savegame.
The amount of ticks are given such that each run takes ~10 seconds.

As each savegame is ran 5 times to get an accurate CPU time, this means it takes ~1 minutes for a single benchmark to finish.

### CPU / Memory profiling

Additional to measuring performance difference, we also create a profile of the CPU usage and memory usage, to quickly spot what changed.

For memory, this requires us to link against `tcmalloc` library.
This should have no impact on performance normally, but does allow us to turn on memory profiling.

In both cases, we make use of gperftools, to capture a CPU and memory profile.
They are stored as pprof blobs, and can be analyzed with pprof.
For this you need golang installed.

```bash
go tool prof -http :8080 <https-link-to-raw-file-on-github>
```

You can also compare two versions with each other, by using `-base <link>` first.

Note: memory profiling is done with fewer ticks than CPU profiling.
We do a lot of heap activity, slowing down the game by a lot, making it impractical to run memory profiling for longer.

## Savegames

This performance suite contains a wide variation of savegames, ranging from very large maps, to very busy networks, etc.
We are constantly looking for good maps to add to the performance suite.
But, as every map takes ~10 minutes to run, we do need to be realistic in how many savegames we want to benchmark against.
Some savegames simply do not give new information, as they are very similar to other savegames, and show identical behaviour.
