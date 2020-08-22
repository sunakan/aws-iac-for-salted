include ../makefiles/help.mk

################################################################################
# 変数
################################################################################
DOCKER_IMAGE := asciidoctor/docker-asciidoctor:1.1.0
WORKDIR      := $(shell docker run --rm --tty --entrypoint 'pwd' $(DOCKER_IMAGE))

################################################################################
# タスク
################################################################################
html:
	mkdir -p html

.PHONY: docs
docs: html
	docker run \
		--interactive \
		--tty \
		--user `id -u`:`id -g` \
		--mount type=bind,source=$(PWD)/,target=$(WORKDIR)/ \
		$(DOCKER_IMAGE) asciidoctor --require asciidoctor-diagram --out-file html/index.html README.adoc

.PHONY: nginx
nginx:
	docker run \
		--rm \
		--interactive \
		--tty \
		--publish 80:80 \
		--mount type=bind,source=$(PWD)/html/,target=/usr/share/nginx/html/,readonly \
		nginx:stable
