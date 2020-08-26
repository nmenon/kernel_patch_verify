Introduction
============

Many times we need to build quite a bunch of applications to get the very latest
tools and environment. So, instead of hand holding every developer to get
the latest environment, provide a Docker environment to build things up
from scratch for the environment setup.

Proxy Setup Step
================

If you are working in an environment, where http proxy is necessary,
update the files in proxy-configuration to match up with what your
environment needs are With out this, ofocourse, you cannot install the
various packages needed to build up the docker image

Versions of packages
====================

Update the script build-env.sh to pick up the various latest tags and
versions of the apps needed

Choose if you are going to local toolchain
==========================================

ARM Toolchain installs can be big.. 2.8G or so.., I do provide an
option to build with docker image having the tool chain installed
(downloaded from ARM's site), I would recommend doing it locally and
pointing kpv to that folder (I have assumed you have all compilers
available in /opt/cross-gcc-linux-9/bin - customize as desired).

Building the docker image
=========================

Dependency to build docker is:
* docker.io
* proxy settings for docker to pull in required images

make takes the following override variables:
* INSTALL_GCC (0 is default - aka, wont install gcc, you can pick 1, where it downloads gcc)
* USER_ID (takes the current user's uid for the docker environment, you can override this if desired)
* REPO (if you have your own Docker registry, you can use this along with the make deploy rule)

Build commands:
* make : build image arm-kernel-dev
* make clean : I strongly recommend NOT to use my version if you have other docker images running in your system.
* make deploy REPO=xyz : Deploy image to an docker registry

Using the Docker image with kernel_patch_verify
===============================================

Use the script `kpv` packaged here just like you would use kernel_patch_verify on your local PC
kpv provides a wrapper through docker to execute the script

though you could, in theory start up a shell with the same set of script steps documented in kpv
