#!/bin/bash
set -e
export HOME=/tmp
source /etc/profile
shopt -s expand_aliases
NPROC=`nproc`

# https://git.kernel.org/pub/scm/git/git.git/
export GIT_TAG=2.29.0
# https://git.kernel.org/pub/scm/utils/dtc/dtc.git
export DTC_TAG=v1.6.0
# https://git.kernel.org/pub/scm/devel/sparse/sparse.git
export SPARSE_TAG=v0.6.2
# https://repo.or.cz/smatch.git
export SMATCH_TAG=master
# https://github.com/coccinelle/coccinelle/tags
export COCCI_TAG=1.0.8
# https://github.com/devicetree-org/dt-schema/tags
export DTSCHEMA_REV=v2020.08.1

ARIA_OPTS="--timeout=180 --retry-wait=10 -m 0 -x 10 -j 10"

download_build_install_git()
{
	cd /tmp/
	FILE=git-"$GIT_TAG".tar.gz
	URL="https://git.kernel.org/pub/scm/git/git.git/snapshot/${FILE}"
	aria2c $ARIA_OPTS -o "$FILE" "$URL"
	mkdir /tmp/git
	tar -C /tmp/git --strip-components=1 -xvf "$FILE"
	rm $FILE
	cd /tmp/git
	make -j "$NPROC" prefix=/usr/local
	make -j "$NPROC" prefix=/usr/local install
	cd /tmp
	rm -rf /tmp/git*
}

download_build_install_python_deps()
{
	# Get latest pip
	python -m pip install --upgrade pip
	python -m pip install --upgrade setuptools
	python -m pip install --upgrade six jsonschema
	python -m pip install git+https://github.com/devicetree-org/dt-schema.git@$DTSCHEMA_REV
}

download_build_install_dtc()
{
	cd /tmp/
	URL="git://git.kernel.org/pub/scm/utils/dtc/dtc.git"
	git clone --depth=1 --branch "$DTC_TAG" "$URL"
	cd /tmp/dtc
#make -j $NPROC PREFIX=/usr SETUP_PREFIX=/usr install NO_PYTHON=1
	make -j $NPROC PREFIX=/usr/local SETUP_PREFIX=/usr/local install
	cd /tmp
	rm -rf /tmp/dtc
}

download_build_install_sparse()
{
	cd /tmp/
	URL="git://git.kernel.org/pub/scm/devel/sparse/sparse.git"
	git clone --depth=1 --branch "$SPARSE_TAG" "$URL"
	cd /tmp/sparse
	make -j $NPROC PREFIX=/usr/local install
	cd /tmp
	rm -rf /tmp/sparse
}

download_build_install_smatch()
{
	cd /tmp/
	URL="git://repo.or.cz/smatch"
	git clone --depth=1 --branch "$SMATCH_TAG" "$URL"
	cd /tmp/smatch
	make -j $NPROC PREFIX=/usr/local install
	cd /tmp
	rm -rf /tmp/smatch
}

download_build_install_coccinelle()
{
	cd /tmp/
	URL="https://github.com/coccinelle/coccinelle.git"
	git clone --depth=1 --branch "$COCCI_TAG" "$URL"
	cd /tmp/coccinelle
	./autogen
	./configure --prefix=/usr/local
	make install
	cd /tmp
	rm -rf /tmp/coccinelle
}

download_and_install_armgcc()
{
	cd /tmp
	mkdir -p /opt/cross-gcc-linux-9/
	#aarch64
	F64='aarch64-gcc.tar.xz'
	URL="https://developer.arm.com/-/media/Files/downloads/gnu-a/9.2-2019.12/binrel/gcc-arm-9.2-2019.12-x86_64-aarch64-none-linux-gnu.tar.xz?revision=61c3be5d-5175-4db6-9030-b565aae9f766&la=en&hash=0A37024B42028A9616F56A51C2D20755C5EBBCD7"
	aria2c $ARIA_OPTS -o "$F64" "$URL"
	tar -C /opt/cross-gcc-linux-9/ --strip-components=1 -xvf "$F64"
	rm -f "$F64"

	#arch32
	F32='aarch32-gcc.tar.xz'
	URL="https://developer.arm.com/-/media/Files/downloads/gnu-a/9.2-2019.12/binrel/gcc-arm-9.2-2019.12-x86_64-arm-none-linux-gnueabihf.tar.xz?revision=fed31ee5-2ed7-40c8-9e0e-474299a3c4ac&la=en&hash=76DAF56606E7CB66CC5B5B33D8FB90D9F24C9D20"
	aria2c $ARIA_OPTS -o "$F32" "$URL"
	tar -C /opt/cross-gcc-linux-9/ --strip-components=1 -xvf "$F32"
	rm -f "$F32"
}

download_build_install_git
download_build_install_python_deps
download_build_install_dtc
download_build_install_sparse
download_build_install_smatch
download_build_install_coccinelle
if [ "$INSTALL_GCC" == "1" ]; then
	download_and_install_armgcc
else
	echo "Skipping install GCC. INSTALL_GCC!=1. make sure that /opt/cross-gcc-linux-9/bin has aarch64-none-linux-gnu- and arm-none-linux-gnueabihf-"
fi

rm $0
