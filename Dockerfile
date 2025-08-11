ARG BASE_DISTRO=debian:stable-slim
FROM $BASE_DISTRO

ARG INSTALL_GCC=0

ARG DEBIAN_FRONTEND noninteractive
RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
		aria2 \
		autoconf \
		automake \
		bc \
		bison \
		build-essential \
		ca-certificates \
		ccache \
		codespell \
		diffstat \
		dumb-init \
		flex \
		gcc \
		gettext \
		gnupg2 \
		gosu \
		libcurl4-gnutls-dev \
		libelf-dev \
		libexpat1-dev \
		libgmp-dev \
		libmpc-dev \
		libpython3.13 \
		libpython3.13-dev \
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
		python3-venv \
		python3-ruamel.yaml \
		sqlite3 \
		swig \
		wget \
		xz-utils \
		yamllint \
		kmod \
		pixz \
		coccinelle \
	&& echo "**** cleanup ****" \
	&& apt-get autoremove -y\
	&& apt-get clean -y\
	&& rm -rf \
		/tmp/* \
		/var/lib/apt/lists/* \
		/var/tmp/* \
		/var/log/*

RUN python3 -m venv /opt/venv
RUN . /opt/venv/bin/activate

RUN --mount=type=bind,source=build-env.sh,target=/tmp/build-env.sh \
	INSTALL_GCC=$INSTALL_GCC /tmp/build-env.sh

# Publish the source repository
LABEL org.opencontainers.image.source=https://github.com/nmenon/kernel_patch_verify

# Add our llvm repo configs
COPY llvm-config /
RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
		llvm \
		clang \
		lld \
	&& echo "**** cleanup ****" \
	&& apt-get autoremove -y\
	&& apt-get clean -y\
	&& rm -rf \
		/tmp/* \
		/var/lib/apt/lists/* \
		/var/tmp/* \
		/var/log/*

COPY other-configs/ /

RUN echo "**** create developer user and make our folders ****" \
	&& useradd -u 1000 -U -d /config -s /bin/false developer \
	&& usermod -G users developer \
	&& mkdir /workdir && chown developer:developer /workdir \
	&& mkdir /ccache && chown developer:developer /ccache \
	&& mkdir /config && chown developer:developer /config

ENTRYPOINT ["/init"]

CMD ["/usr/bin/bash"]

VOLUME /workdir

COPY kernel_patch_verify /usr/bin/kernel_patch_verify

WORKDIR /workdir
