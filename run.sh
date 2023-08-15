#!/bin/sh

if [ -z "${1}" ]; then
    echo "Usage: ${0} <date>"
    exit 1
fi

date=${1}

if [ ! -e OpenTTD ]; then
    echo "Missing OpenTTD source; cloning now ..."
    git clone https://github.com/OpenTTD/OpenTTD
fi

cd OpenTTD

commit_hash=$(git rev-list -n 1 --first-parent --before="${date}T23:59:59Z" master | cut -b -10)
commit_date=$(git show -s --format=%ci ${commit_hash} | cut -d\  -f1)
version=$(echo ${commit_date} | sed s/-//g)--m${commit_hash}

echo "Latest OpenTTD version before ${date} is ${version}"

if [ ! -e "../bundles/openttd-${version}-linux-generic-amd64.tar.xz" ]; then
    echo "This version hasn't been build yet; building now ..."

    git reset --hard
    git checkout ${commit_hash}

    if [ -z "$(grep data cmake/FindICU.cmake)" ]; then
        patch -p1 < ../cmake-icu.patch
    fi
    patch -p1 < ../cmake-version.patch

    mkdir -p ../bundles
    podman run --rm -v $(pwd):/source:ro -v $(pwd)/../bundles:/bundles openttd /build.sh
fi

if [ ! -e "../bundles/openttd-${version}-linux-generic-amd64.tar.xz" ]; then
    echo "Failed to compile ${version}."
    exit 1
fi

cd ..

for line in $(cat performance.matrix); do
    map=$(echo ${line} | cut -d\; -f1)
    ticks=$(echo ${line} | cut -d\; -f2)

    echo "Testing ${map} for ${ticks} ticks ..."

    tmp=$(mktemp -d)
    cur=$(pwd)

    (
        cd ${tmp}
        tar xf ${cur}/bundles/openttd-${version}-linux-generic-amd64.tar.xz
        cd openttd-${version}-linux-generic-amd64

        mkdir config
        cp -R ${cur}/performance-config/* config/

        echo "${commit_date}" > result
        echo "${commit_hash}" >> result
        echo "${ticks}" >> result
        echo "${map}" >> result

        /usr/bin/time -o memory -f "%M" perf stat -x\; -o cpu.csv -r5 ./openttd -X -c config/openttd.cfg -x -snull -mnull -vnull:ticks=${ticks} -g ${map}
        if [ "$?" != "0" ] || [ ! -e "cpu.csv" ] || [ ! -e "memory" ]; then
            echo "crash" >> result
            echo "crash" >> result
        else
            cat memory >> result
            cat cpu.csv | grep "instructions" | cut -d\; -f1 >> result
            rm -f result.csv
        fi

        cat result | tr '\n' ';' >> ${cur}/result.csv
        echo "" >> ${cur}/result.csv
    )

    rm -rf ${tmp}
done

cp result.csv result_tot.csv
python3 convert.py > result_per.csv
