# OpenTTD performance

Often I wonder: did our CPU usage or memory consumption change over the years?
And never there is an easy way to answer.

No more!

This repository contains scripts to run performance measurements, in a reproduceable way, over multiple versions of OpenTTD.

## Caveats

- Although "perf" returns the "instructions executed" with a 0.1% accuracy, there is still a small jitter.
- All builds are made with the same dependencies; if any dependency changes, all runs need to be redone.
- This only works for OpenTTD versions that are compilable with CMake in the linux-generic build environment.
  Two patches are applied to make the result more predictable, but there is a limit how far back this works.

## Usage

```bash
podman build -t openttd .
python3 bisect-run.py 2021-08-12 2023-08-12
```

The first command creates a container image used to build OpenTTD.
The second command starts compiling and running OpenTTD versions between 2021-08-12 and 2023-08-12.

This will create a `bundles` folder which contains all binaries, for faster re-runs.
There will also be a `result.csv` with the resulting metrics.

## Savegames

In `performance.matrix` are all the savegames to load, and how many ticks to run them for.

Make sure the savegames are in `performance-config` and that any dependency (AIs, GSes, NewGRFs) are also in that folder.
And, of course, make sure you have distribution rights if you create a Pull Request to extend this repository.
