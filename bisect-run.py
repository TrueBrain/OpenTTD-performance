import datetime
import shlex
import subprocess
import sys

dates_done = set()

def str_to_date(str):
    return datetime.date.fromisoformat(str)

def get_commit_date(date):
    commit_hash = subprocess.run(shlex.split(f"git rev-list -n 1 --first-parent --before='{date}' master"), cwd="./OpenTTD", stdout=subprocess.PIPE).stdout.decode().strip()
    commit_date = subprocess.run(shlex.split(f"git show -s --format=%ci {commit_hash}"), cwd="./OpenTTD", stdout=subprocess.PIPE).stdout.decode().strip().split(" ")[0]
    return str_to_date(commit_date)

def run(date):
    commit_date = get_commit_date(date)
    if commit_date in dates_done:
        return
    dates_done.add(commit_date)

    subprocess.run(shlex.split(f"./run.sh {date}"))

def bisect(start, end):
    mid = start + (end - start) / 2
    if mid == start or mid == end:
        return
    run(mid)
    yield

    left = bisect(start, mid)
    right = bisect(mid, end)

    while right or left:
        if left:
            try:
                next(left)
            except StopIteration:
                left = None

        if right:
            try:
                next(right)
            except StopIteration:
                right = None

        yield

with open("result.csv") as fp:
    for line in fp.readlines()[1:]:
        date = str_to_date(line.split(";")[0])
        dates_done.add(date)

start = str_to_date(sys.argv[1])
end = str_to_date(sys.argv[2])

run(start)
run(end)

for i in bisect(start, end):
    pass
