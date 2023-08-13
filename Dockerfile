FROM quay.io/pypa/manylinux2014_x86_64

RUN yum install -y \
        autoconf-archive \
        perl-IPC-Cmd \
        wget \
        zip

# aclocal looks first in /usr/local/share/aclocal, and if that doesn't
# exist only looks in /usr/share/aclocal. We have files in both that
# are important. So copy the latter to the first, and we are good to
# go.
RUN cp /usr/share/aclocal/* /usr/local/share/aclocal/

# The yum variant of fluidsynth depends on all possible audio drivers,
# like jack, ALSA, pulseaudio, etc. This is not really useful for us,
# as we route the output of fluidsynth back via our sound driver, and
# as such do not use these audio driver outputs at all.
# The vcpkg variant of fluidsynth depends on ALSA. Similar issue here.
# So instead, we compile fluidsynth ourselves, with as few
# dependencies as possible. We do it before anything else is installed,
# to make sure it doesn't pick up on any of the drivers.

RUN wget https://github.com/FluidSynth/fluidsynth/archive/v2.3.3.tar.gz \
        && tar xf v2.3.3.tar.gz \
        && cd fluidsynth-2.3.3 \
        && mkdir build \
        && cd build \
        && cmake .. -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCMAKE_INSTALL_PREFIX=/usr \
        && cmake --build . -j $(nproc) \
        && cmake --install .

# These audio libs are to make sure the SDL version of vcpkg adds
# sound-support; these libraries are not added to the resulting
# binary, but the headers are used to enable them in SDL.
RUN yum install -y \
        alsa-lib-devel \
        jack-audio-connection-kit-devel \
        pulseaudio-libs-devel

COPY vcpkg.patch /vcpkg.patch

RUN git clone --depth=1 https://github.com/microsoft/vcpkg /vcpkg \
        && cd /vcpkg \
        && ./bootstrap-vcpkg.sh -disableMetrics \
        && patch -p1 < /vcpkg.patch \
        && ./vcpkg install python3 \
        && ln -sf /vcpkg/installed/x64-linux/tools/python3/python3.[0-9][0-9] /usr/bin/python3

RUN cd /vcpkg \
        && ./vcpkg install \
                curl[http2] \
                fontconfig \
                freetype \
                harfbuzz \
                icu \
                liblzma \
                libpng \
                nlohmann-json \
                sdl2 \
                zlib
# lzo failed to resolve

COPY build.sh /build.sh
