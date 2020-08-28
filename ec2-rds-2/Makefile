include ./sts.mk
include ./create-vpc.mk
include ./help.mk

.DEFAULT_GOAL := all
.PHONY: all
all: input.json outputs
	@echo ----[ create-vpc ]
	@make --no-print-directory create-vpc

# input.jsonが無ければ作成、失敗したら削除する
input.json:
	( cat input.toml | rq --input-toml --output-json --format indented > input.json ) \
		|| rm input.json

# outputsディレクトリを作成
outputs:
	mkdir -p $(OUTPUT_BASE_PATH)

cleanup: ## 作成したAWSリソースを全削除
	@echo ----[ delete-created-vpc ]
	@make --no-print-directory delete-created-vpc
	rm --force input.json
