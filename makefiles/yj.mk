################################################################################
# 変数
################################################################################
SYSTEM_INFORMATION := $(shell uname | tr '[:upper:]' '[:lower:]')
YJ_VERSION         := v5.0.0
YJ_SUFFIX          := $(shell bash -c 'if [ "$(SYSTEM_INFORMATION)" == "linux" ]; then echo linux; else echo macos; fi')
YJ_URL             := https://github.com/sclevine/yj/releases/download/$(YJ_VERSION)/yj-$(YJ_SUFFIX)

################################################################################
# タスク
################################################################################
.PHONY: install-yj
install-yj:
	( command -v ./yj ) \
	|| curl --location -o yj $(YJ_URL)
	chmod +x ./yj

.PHONY: uninstall-yj
uninstall-yj: ## yjのアンインストール
	command -v ./yj && rm ./yj
