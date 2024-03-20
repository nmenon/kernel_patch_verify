#!/bin/bash
set -e
export HOME=/tmp
source /etc/profile
shopt -s expand_aliases
NPROC=$(nproc)

# https://git.kernel.org/pub/scm/git/git.git/
export GIT_TAG=2.44.0
# https://git.kernel.org/pub/scm/utils/dtc/dtc.git
export DTC_TAG=v1.7.0
# https://git.kernel.org/pub/scm/devel/sparse/sparse.git
export SPARSE_TAG=v0.6.4
# https://repo.or.cz/smatch.git
export SMATCH_TAG=master
# https://github.com/coccinelle/coccinelle/tags
export COCCI_TAG=1.1.1
# https://github.com/devicetree-org/dt-schema/tags
export DTSCHEMA_REV=v2024.02

ARIA_OPTS=( --summary-interval=5 --timeout=180 --retry-wait=10 -m 0 -x 10 -j 10 )

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
	rm -rf "/tmp/.cache/"
}

clone_and_cd()
{
	cd /tmp &&
	git clone --progress --depth=1 --branch "$1" "$2" "$3" &&
	cd /tmp/"$3"
	return $?
}

download_build_install_dtc()
{
	local FILE URL
	FILE='dtc'
	URL="https://git.kernel.org/pub/scm/utils/dtc/dtc.git"

	clone_and_cd "$DTC_TAG" "$URL" "$FILE"
	make -j "$NPROC" PREFIX=/usr/local SETUP_PREFIX=/usr/local install NO_PYTHON=1
	cd /tmp
	rm -rf /tmp/"$FILE"
}

download_build_install_sparse()
{
	local FILE URL
	FILE='sparse'
	URL="https://git.kernel.org/pub/scm/devel/sparse/sparse.git"

	clone_and_cd "$SPARSE_TAG" "$URL" "$FILE"
	make -j "$NPROC" PREFIX=/usr/local install
	cd /tmp
	rm -rf /tmp/"$FILE"
}

download_build_install_smatch()
{
	local FILE URL
	FILE='smatch'
	URL="https://repo.or.cz/smatch.git"

	clone_and_cd "$SMATCH_TAG" "$URL" "$FILE"
	make -j "$NPROC" PREFIX=/usr/local/smatch install
	echo -e '#!/bin/bash\n/usr/local/smatch/bin/smatch -p=kernel $@'>/usr/local/smatch/bin/k_sm_check_script
	chmod +x /usr/local/smatch/bin/k_sm_check_script
	cd /tmp
	rm -rf /tmp/"$FILE"
}

download_build_install_coccinelle()
{
	local FILE URL
	FILE='coccinelle'
	URL="https://github.com/coccinelle/coccinelle.git"

	clone_and_cd "$COCCI_TAG" "$URL" "$FILE"
	./autogen
	./configure --prefix=/usr/local
	make install
	cd /tmp
	rm -rf /tmp/"$FILE"
}

download_build_install_git
download_build_install_python_deps
download_build_install_dtc
download_build_install_smatch
download_build_install_sparse
download_build_install_coccinelle
