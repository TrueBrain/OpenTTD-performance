import csv
import glob
import json

def main():
    cpu_diff_stats = {}
    cpu_overtime_stats = {}
    mem_stats = {}

    for filename in glob.glob("reports/*/*/*.performance.csv"):
        # Example: reports/2020/01/20200101.performance.csv
        date = filename.split("/")[3].split(".")[0]

        f = csv.reader(open(filename))
        header = next(f)

        savegames = {}
        for row in f:
            data = dict(zip(header, row))

            # Use the memory of today.
            if data["version"] == "today" and data["memory"] != "crash":
                mem_stats.setdefault(data["savegame"], []).append((date, int(data["memory"])))

            savegames.setdefault(data["savegame"], {})[data["version"]] = data["cpu"]

        for savegame, data in savegames.items():
            if data["today"] == "crash":
                continue

            # We assume that "baseline" is 100%. Stable is a recompiled baseline,
            # so their difference is due to new compiler or dependencies.
            # We can now normalize today / yesterday to be relative to the baseline.
            baseline_factor = float(data["stable"]) / float(data["baseline"])

            # Track how we do compared against the baseline.
            today = float(data["today"]) / baseline_factor
            cpu_overtime = today / float(data["baseline"])

            # Track how much we increased/decreased compared to yesterday,
            if data["yesterday"] != "crash":
                yesterday = float(data["yesterday"]) / baseline_factor
                cpu_diff = (today - yesterday) / yesterday

            cpu_diff_stats.setdefault(savegame, []).append((date, cpu_diff))
            cpu_overtime_stats.setdefault(savegame, []).append((date, cpu_overtime))

        for savegame, data in cpu_overtime_stats.items():
            print(savegame, json.dumps(sorted(data, key=lambda x: x[0]), indent=4))

if __name__ == '__main__':
    main()
