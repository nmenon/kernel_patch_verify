Introduction
============

Quite often we need to build quite a bunch of applications to get the very
latest tools and environment. Instead of hand holding every developer to get the
latest environment, let's use Docker to bootstrap a common build environment.

Versions of packages
====================

Update the script `build-env.sh` to pick up the various latest tags and versions
of the app as needed.

Using a local toolchain
=======================

I do provide an option to build a Docker image with tool chain installed
(downloaded from ARM's site), but ARM Toolchain installs can be big (2.8G or
so). Because of this, I would recommend installing them on the host, mounting
the install as a volume, and pointing kpv to that folder. I have assumed you
have all compilers available in `/opt/cross-gcc-linux-9/bin` - customize as
desired.

Building the docker image
=========================

The dependencies to build docker are:
* `docker` or `docker.io` on Debian/Ubuntu
* Proxy settings for docker to pull in required images (if you are behind a
  proxy)

The image Makefile takes the following override variables:
* `INSTALL_GCC` : 0 is default - aka, wont install gcc, you can pick 1, where it
  downloads gcc
* `USER_ID` : takes the current user's uid for the docker environment, you can
  override this if desired
* `REPO` : if you have your own Docker registry, you can use this along with the
  make deploy rule

Build commands:
* `make` : build image arm-kernel-dev
* `make clean` : I strongly recommend NOT to use my version if you have other
  docker images running in your system.
* `make deploy REPO=xyz` : Deploy image to an docker registry

Using the Docker image with `kernel_patch_verify`
=================================================

Use the script `kpv` packaged here just like you would use `kernel_patch_verify`
on your local PC. The `kpv` script is just a wrapper around Docker to run the
container and execute `kernel_patch_verify`.

You can also start up a shell with the same set of script steps documented in
`kpv` manually.
