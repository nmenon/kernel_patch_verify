ARG BASE_DISTRO=debian:stable-slim
FROM $BASE_DISTRO

ARG INSTALL_GCC=0

# In case of Proxy based environment, leave the following enabled.
# in Direct internet cases, comment out the following two lines.
#--- PROXY SETUP START
# COPY proxy-configuration/ /
# RUN  export DEBIAN_FRONTEND=noninteractive;apt-get update;apt-get install -y apt-transport-https socket corkscrew apt-utils
#--- END START

ARG DEBIAN_FRONTEND noninteractive
RUN apt-get update && \
    apt-get install -y \
        build-essential \
        wget \
        gcc \
        ccache \
        ncurses-dev \
        xz-utils \
        libssl-dev \
        bc \
        flex \
        libelf-dev \
        bison \
        libyaml-dev \
        python3-pip \
        libcurl4-gnutls-dev \
        libexpat1-dev \
        gettext \
        libz-dev \
        libssl-dev \
        flex \
        bison \
        pkg-config \
        sqlite3 \
        libsqlite3-dev \
        llvm \
        autoconf \
        pkg-config \
        ocaml-nox \
        ocaml-findlib \
        menhir \
        libmenhir-ocaml-dev \
        ocaml-native-compilers \
        libpcre-ocaml-dev \
        libparmap-ocaml-dev \
        libpython3.9 \
        libpython3.9-dev \
        libgmp-dev \
        libmpc-dev \
        diffstat \
        yamllint \
        swig \
        python3 \
        python3-ruamel.yaml \
        aria2

RUN update-alternatives --install /usr/bin/python python /usr/bin/python3 1

COPY other-configs/ /

COPY build-env.sh /tmp
RUN  INSTALL_GCC=$INSTALL_GCC /tmp/build-env.sh

FROM $BASE_DISTRO

ARG INSTALL_GCC=0

# Publish the source repository
LABEL org.opencontainers.image.source https://github.com/nmenon/kernel_patch_verify

#--- PROXY SETUP START
# COPY proxy-configuration/ /
# RUN  export DEBIAN_FRONTEND=noninteractive;apt-get update;apt-get install -y apt-transport-https socket corkscrew apt-utils
#--- END START

# Add our llvm repo configs
COPY llvm-config /

ARG DEBIAN_FRONTEND noninteractive
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        gnupg2 \
        build-essential \
        wget \
        gcc \
        ccache \
        ncurses-dev \
        xz-utils \
        libssl-dev \
        bc \
        flex \
        libelf-dev \
        bison \
        libyaml-dev \
        python3-pip \
        libcurl4-gnutls-dev \
        libexpat1-dev \
        gettext \
        libz-dev \
        libssl-dev \
        flex \
        bison \
        pkg-config \
        sqlite3 \
        libsqlite3-dev \
        autoconf \
        pkg-config \
        ocaml-nox \
        ocaml-findlib \
        menhir \
        libmenhir-ocaml-dev \
        ocaml-native-compilers \
        libpcre-ocaml-dev \
        libparmap-ocaml-dev \
        libpython3.9 \
        libpython3.9-dev \
        libgmp-dev \
        libmpc-dev \
        diffstat \
        yamllint \
        swig \
        python3 \
        python3-ruamel.yaml \
        llvm \
        clang \
        lld && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN update-alternatives --install /usr/bin/python python /usr/bin/python3 1

COPY other-configs/ /

COPY --from=0 /usr/local/ /usr/local/

RUN ldconfig /usr/local/lib

COPY kernel_patch_verify /usr/bin/kernel_patch_verify

WORKDIR /workdir
