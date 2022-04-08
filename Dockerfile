ARG BASE_DISTRO=debian:stable-slim
FROM $BASE_DISTRO

ARG USER_UID=1000
ARG INSTALL_GCC=0

USER root

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
COPY other-configs/ /opt/other-configs
COPY build-env.sh /tmp

RUN  INSTALL_GCC=$INSTALL_GCC /tmp/build-env.sh

RUN cp -rvfa /usr/local /opt/local

FROM $BASE_DISTRO

ARG USER_UID=1000
ARG INSTALL_GCC=0

USER root

# Publish the source repository
LABEL org.opencontainers.image.source https://github.com/nmenon/kernel_patch_verify

#--- PROXY SETUP START
# COPY proxy-configuration/ /
# RUN  export DEBIAN_FRONTEND=noninteractive;apt-get update;apt-get install -y apt-transport-https socket corkscrew apt-utils
#--- END START

# Add an ordinary user - This is not going to change
RUN mkdir -p /workdir && groupadd -r swuser -g $USER_UID && \
useradd -u $USER_UID -r -g swuser -d /workdir -s /sbin/nologin -c "Docker kernel patch user" swuser && \
chown -R swuser:swuser /workdir && mkdir /ccache && chown -R swuser:swuser /ccache

COPY llvm-config/ /tmp/llvm

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
        python3-ruamel.yaml && \
    wget -q -O - 'https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x15CF4D18AF4F7421' | apt-key add - && \
    cp -rvf /tmp/llvm/etc/* /etc/ && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        llvm \
        clang \
        lld && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    update-alternatives --install /usr/bin/python python /usr/bin/python3 1

COPY --from=0 /opt /opt

RUN cp -rvfa /opt/other-configs/* / && rm -rvf /opt/other-configs/ && \
    cp -rvfa /opt/local/* /usr/local/ && rm -rf /opt/local && \
    ldconfig /usr/local/lib

COPY kernel_patch_verify /usr/bin/kernel_patch_verify


USER swuser
WORKDIR /workdir
