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
RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
		aria2 \
		autoconf \
		bc \
		bison \
		build-essential \
		ca-certificates \
		ccache \
		diffstat \
		flex \
		gcc \
		gettext \
		gnupg2 \
		libcurl4-gnutls-dev \
		libelf-dev \
		libexpat1-dev \
		libgmp-dev \
		libmenhir-ocaml-dev \
		libmpc-dev \
		libparmap-ocaml-dev \
		libpcre-ocaml-dev \
		libpython3.11 \
		libpython3.11-dev \
		libsqlite3-dev \
		libssl-dev \
		libyaml-dev \
		libz-dev \
		menhir \
		ncurses-dev \
		ocaml-findlib \
		ocaml-native-compilers \
		ocaml-nox \
		pkg-config \
		python-is-python3 \
		python3 \
		python3-dev \
		python3-pip \
		python3-ruamel.yaml \
		sqlite3 \
		swig \
		wget \
		xz-utils \
		yamllint \
	&& echo "**** cleanup ****" \
	&& apt-get autoremove \
	&& apt-get clean \
	&& rm -rf \
		/tmp/* \
		/var/lib/apt/lists/* \
		/var/tmp/* \
		/var/log/*

COPY build-env.sh /tmp
RUN  INSTALL_GCC=$INSTALL_GCC /tmp/build-env.sh

# Publish the source repository
LABEL org.opencontainers.image.source https://github.com/nmenon/kernel_patch_verify

# Add our llvm repo configs
COPY llvm-config /
RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
		llvm \
		clang \
		lld \
	&& echo "**** cleanup ****" \
	&& apt-get autoremove \
	&& apt-get clean \
	&& rm -rf \
		/tmp/* \
		/var/lib/apt/lists/* \
		/var/tmp/* \
		/var/log/*

COPY other-configs/ /

COPY kernel_patch_verify /usr/bin/kernel_patch_verify

WORKDIR /workdir
