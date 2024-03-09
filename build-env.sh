#!/bin/bash
set -e
export HOME=/tmp
source /etc/profile
shopt -s expand_aliases
NPROC=$(nproc)

# https://git.kernel.org/pub/scm/git/git.git/
export GIT_TAG=2.43.0
# https://git.kernel.org/pub/scm/utils/dtc/dtc.git
export DTC_TAG=v1.7.0
# https://git.kernel.org/pub/scm/devel/sparse/sparse.git
export SPARSE_TAG=v0.6.4
# https://repo.or.cz/smatch.git
export SMATCH_TAG=master
# https://github.com/coccinelle/coccinelle/tags
export COCCI_TAG=1.1.1
# https://github.com/devicetree-org/dt-schema/tags
export DTSCHEMA_REV=v2023.11

ARIA_OPTS=(--timeout=180 --retry-wait=10 -m 0 -x 10 -j 10)

download_build_install_git()
{
	local FILE URL
	FILE=git-"$GIT_TAG".tar.gz
	URL="https://git.kernel.org/pub/scm/git/git.git/snapshot/${FILE}"

	cd /tmp/
	aria2c "${ARIA_OPTS[@]}" -o "$FILE" "$URL"
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
	python -m pip install --upgrade  --break-system-packages pip
	python -m pip install --upgrade  --break-system-packages setuptools
	python -m pip install --upgrade  --break-system-packages six jsonschema
	# scripts/spdxcheck.py dependencies
	python -m pip install --upgrade  --break-system-packages ply gitpython yamllint rfc3987 pylibfdt
	python -m pip install  --break-system-packages git+https://github.com/devicetree-org/dt-schema.git@$DTSCHEMA_REV
}

download_build_install_dtc()
{
	local URL
	URL="https://git.kernel.org/pub/scm/utils/dtc/dtc.git"

	cd /tmp/
	git clone --depth=1 --branch "$DTC_TAG" "$URL"
	cd /tmp/dtc
	make -j "$NPROC" PREFIX=/usr/local SETUP_PREFIX=/usr/local install NO_PYTHON=1
	cd /tmp
	rm -rf /tmp/dtc
}

download_build_install_sparse()
{
	local URL
	URL="https://git.kernel.org/pub/scm/devel/sparse/sparse.git"

	cd /tmp/
	git clone --depth=1 --branch "$SPARSE_TAG" "$URL"
	cd /tmp/sparse
	make -j "$NPROC" PREFIX=/usr/local install
	cd /tmp
	rm -rf /tmp/sparse
}

download_build_install_smatch()
{
	local URL
	URL="https://repo.or.cz/smatch.git"

	cd /tmp/
	git clone --depth=1 --branch "$SMATCH_TAG" "$URL"
	cd /tmp/smatch
	make -j "$NPROC" PREFIX=/usr/local/smatch install
	echo -e '#!/bin/bash\n/usr/local/smatch/bin/smatch -p=kernel $@'>/usr/local/smatch/bin/k_sm_check_script
	chmod +x /usr/local/smatch/bin/k_sm_check_script
	cd /tmp
	rm -rf /tmp/smatch
}

download_build_install_coccinelle()
{
	local URL
	URL="https://github.com/coccinelle/coccinelle.git"

	cd /tmp/
	git clone --depth=1 --branch "$COCCI_TAG" "$URL"
	cd /tmp/coccinelle
	./autogen
	./configure --prefix=/usr/local
	make install
	cd /tmp
	rm -rf /tmp/coccinelle
}

download_and_install_armgcc_64()
{
	cd /tmp
	mkdir -p /opt/cross-gcc-linux-9/
	#aarch64
	F64='aarch64-gcc.tar.xz'
	URL="https://developer.arm.com/-/media/Files/downloads/gnu-a/9.2-2019.12/binrel/gcc-arm-9.2-2019.12-x86_64-aarch64-none-linux-gnu.tar.xz?revision=61c3be5d-5175-4db6-9030-b565aae9f766&la=en&hash=0A37024B42028A9616F56A51C2D20755C5EBBCD7"
	aria2c "${ARIA_OPTS[@]}" -o "$F64" "$URL"
	tar -C /usr/local/cross-gcc-linux-9/ --strip-components=1 -xf "$F64"
	rm -f "$F64"
}

download_and_install_armgcc_32()
{
	cd /tmp
	mkdir -p /opt/cross-gcc-linux-9/
	#arch32
	F32='aarch32-gcc.tar.xz'
	URL="https://developer.arm.com/-/media/Files/downloads/gnu-a/9.2-2019.12/binrel/gcc-arm-9.2-2019.12-x86_64-arm-none-linux-gnueabihf.tar.xz?revision=fed31ee5-2ed7-40c8-9e0e-474299a3c4ac&la=en&hash=76DAF56606E7CB66CC5B5B33D8FB90D9F24C9D20"
	aria2c "${ARIA_OPTS[@]}" -o "$F32" "$URL"
	tar -C /usr/local/cross-gcc-linux-9/ --strip-components=1 -xf "$F32"
	rm -f "$F32"
}

download_build_install_git
download_build_install_python_deps
download_build_install_dtc
download_build_install_smatch
download_build_install_sparse
download_build_install_coccinelle
if [ "$INSTALL_GCC" == "1" ]; then
	download_and_install_armgcc_64
	download_and_install_armgcc_32
else
	echo "Skipping install GCC. INSTALL_GCC!=1. make sure that /opt/cross-gcc-linux-9/bin has aarch64-none-linux-gnu- and arm-none-linux-gnueabihf-"
fi
