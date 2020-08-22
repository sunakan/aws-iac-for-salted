################################################################################
# 変数
################################################################################
SYSTEM_INFORMATION := $(shell uname | tr '[:upper:]' '[:lower:]')
RQ_VERSION := v1.0.2
RQ_SUFFIX  := $(shell bash -c 'if [ "$(SYSTEM_INFORMATION)" == "linux" ]; then echo x86_64-unknown-linux-gnu; else echo x86_64-apple-darwin; fi')
RQ_URL     := https://github.com/dflemstr/rq/releases/download/$(RQ_VERSION)/rq-$(RQ_VERSION)-$(RQ_SUFFIX).tar.gz

################################################################################
# タスク
################################################################################
.PHONY: install-rq
install-rq: /tmp/rq.tar.gz
	command -v ./rq \
	|| curl --location --output /tmp/rq.tar.gz $(RQ_URL) \
	&& tar --ungzip --extract --verbose --file /tmp/rq.tar.gz

.PHONY: uninstall-rq
uninstall-rq: ## rqのアンインストール
	command -v ./rq && rm ./rq
