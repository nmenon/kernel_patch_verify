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
		curl \
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
		libstdc++6 \
		libgcc-s1 \
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
		protobuf-compiler \
		libprotobuf-dev \
		ripgrep \
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

RUN python3 -m venv /usr/local/venv
RUN . /usr/local/venv/bin/activate

# Add our llvm repo configs
COPY llvm-config /

RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
		llvm \
		clang \
		clangd \
		libclang-dev \
		lld \
		llvm-dev \
	&& apt-get autoremove -y\
	&& apt-get clean -y\
	&& rm -rf \
		/tmp/* \
		/var/lib/apt/lists/* \
		/var/tmp/* \
		/var/log/*

COPY other-configs/tmp /tmp

RUN --mount=type=bind,source=build-env.sh,target=/tmp/build-env.sh \
	INSTALL_GCC=$INSTALL_GCC /tmp/build-env.sh

# Publish the source repository
LABEL org.opencontainers.image.source=https://github.com/nmenon/kernel_patch_verify

# Install patchwise dependencies
RUN apt-get update \
	&& . /usr/local/venv/bin/activate \
	&& patchwise --install \
	&& echo "**** cleanup ****" \
	&& apt-get autoremove -y\
	&& apt-get clean -y\
	&& rm -rf \
		/tmp/* \
		/var/lib/apt/lists/* \
		/var/tmp/* \
		/var/log/*

COPY other-configs/ /

# HACK for codespell path change in trixie
RUN mkdir -p /usr/share/codespell \
	&& ln -s /usr/lib/python3/dist-packages/codespell_lib/data/dictionary.txt /usr/share/codespell/dictionary.txt

# Install developer user and folders
RUN echo "**** create developer user and make our folders ****" \
	&& useradd -u 1000 -U -d /config -s /bin/false developer \
	&& usermod -G users developer \
	&& mkdir /workdir && chown -R developer:developer /workdir \
	&& mkdir /ccache && chown -R developer:developer /ccache \
	&& mkdir -p /config && chown -R developer:developer /config

ENTRYPOINT ["/init"]

CMD ["/usr/bin/bash"]

VOLUME /workdir

COPY kernel_patch_verify /usr/bin/kernel_patch_verify

WORKDIR /workdir
