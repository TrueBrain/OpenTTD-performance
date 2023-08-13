#!/bin/sh

mkdir /build
cd /build

cmake /source \
    -DCMAKE_TOOLCHAIN_FILE=/vcpkg/scripts/buildsystems/vcpkg.cmake \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DOPTION_USE_ASSERTS=OFF \
    -DOPTION_PACKAGE_DEPENDENCIES=ON

cmake --build . -j $(nproc) --target openttd
cpack

rm -f bundles/*.sha256

cp bundles/* /bundles/
