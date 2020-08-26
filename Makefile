.PHONY: all

BASE_DISTRO=debian:stable-slim
IMAGE_TOBUILD=arm-kernel-dev

REPO ?=
INSTALL_GCC ?= 0
USER_ID ?=$(shell id -u)

all:
	docker build -t ${IMAGE_TOBUILD} --build-arg BASE_DISTRO=${BASE_DISTRO} \
		--build-arg USER_UID=${USER_ID} \
		--build-arg INSTALL_GCC=${INSTALL_GCC} \
		--pull .

clean:
	docker container prune; \
	docker image ls|grep none|sed -e "s/\s\s*/ /g"|cut -d ' ' -f3|xargs docker rmi ${IMAGE_TOBUILD}

deploy:
	docker push ${REPO}:${IMAGE_TOBUILD}
