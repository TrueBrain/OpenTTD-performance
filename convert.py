from collections import defaultdict

lcpu = defaultdict(lambda: 0)
lmemmax = defaultdict(lambda: 0)
ldate = defaultdict(lambda: "2200-01-01")

with open("result.csv") as fp:
    for line in fp.readlines()[1:]:
        (date, _, _, map, memmax, cpu, _) = line.strip().split(";")
        cpu = int(cpu)
        memmax = int(memmax)

        if ldate[map] > date:
            ldate[map] = date
            lcpu[map] = cpu
            lmemmax[map] = memmax

with open("result.csv") as fp:
    i = 0
    for line in fp.readlines():
        if i == 0:
            print(line)
            i = 1
            continue

        (date, a, b, map, memmax, cpu, _) = line.strip().split(";")
        print(f"{date};{a};{b};{map};{int(memmax) / lmemmax[map] - 1.0:.4f};{int(cpu) / lcpu[map] - 1.0:.4f};")
