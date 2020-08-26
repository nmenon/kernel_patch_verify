ARG BASE_DISTRO=SPECIFY_ME

FROM $BASE_DISTRO

ARG USER_UID=SPECIFY_ME
ARG INSTALL_GCC=SPECIFY_ME

USER root

# Add an ordinary user
RUN mkdir -p /workdir && groupadd -r swuser -g $USER_UID && \
useradd -u $USER_UID -r -g swuser -d /workdir -s /sbin/nologin -c "Docker image user" swuser && \
chown -R swuser:swuser /workdir && mkdir /ccache && chown -R swuser:swuser /ccache

# In case of Proxy based environment, leave the following enabled.
# in Direct internet cases, comment out the following two lines.
#--- PROXY SETUP START
COPY proxy-configuration/ /
RUN  export DEBIAN_FRONTEND=noninteractive;apt-get update;apt-get install -y apt-transport-https socket corkscrew apt-utils
#--- END START


RUN  export DEBIAN_FRONTEND=noninteractive;apt-get update;apt-get install -y build-essential wget gcc ccache \
			    ncurses-dev xz-utils libssl-dev bc flex libelf-dev bison libyaml-dev python3-pip \
			    libcurl4-gnutls-dev libexpat1-dev gettext libz-dev libssl-dev \
			    flex bison pkg-config \
			    sqlite3 libsqlite3-dev llvm \
			    autoconf pkg-config ocaml-nox ocaml-findlib menhir \
			    diffstat
COPY other-configs/ /
COPY build-env.sh /tmp

RUN  INSTALL_GCC=$INSTALL_GCC /tmp/build-env.sh

COPY kernel_patch_verify /usr/bin
USER swuser
WORKDIR /workdir
