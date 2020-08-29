include ./sts.mk
include ./create-vpc.mk
include ./revoke-default-security-group-rules.mk
include ./create-subnet-for-public.mk
include ./create-internet-gateway-and-attach.mk
include ./create-custom-route-table-for-public.mk
include ./create-route-for-public.mk
include ./associate-route-table-and-modify-subnets-for-public.mk
include ./create-security-group-for-public.mk
include ./create-instance-profile-for-public.mk
include ./create-iam-role-for-instance-profile.mk
include ./help.mk

.DEFAULT_GOAL := all
.PHONY: all
all: input.json outputs
	@echo --------[ create vpc ]
	@make --no-print-directory create-vpc
	@echo --------[ revoke default security group rules ]
	@make --no-print-directory revoke-default-security-group-rules
	@echo --------[ create subnets for public ]
	@make --no-print-directory create-subnets-for-public
	@echo --------[ create internet gateway and attach ]
	@make --no-print-directory create-internet-gateway-and-attach
	@echo --------[ create custom route table ]
	@make --no-print-directory create-custom-route-table-for-public
	@echo --------[ create route for public ]
	@make --no-print-directory create-route-for-public
	@echo --------[ associate route table and modify subnets for public ]
	@make --no-print-directory associate-route-table-and-modify-subnets-for-public
	@echo --------[ create security group for public ]
	@make --no-print-directory create-security-group-for-public
	@echo --------[ create instance profile for public ]
	@make --no-print-directory create-instance-profile-for-public
	@echo --------[ create iam role for instance profile public ]
	@make --no-print-directory create-iam-role-for-instance-profile

# input.jsonが無ければ作成、失敗したら削除する
input.json:
	( cat input.toml | rq --input-toml --output-json --format indented > input.json ) \
		|| rm input.json

# outputsディレクトリを作成
outputs:
	mkdir -p $(OUTPUT_BASE_PATH)

cleanup: ## 作成したAWSリソースを全削除
	@echo ----[ delete iam role for instance profile ]
	@make delete-iam-role-for-instance-profile || true
	@echo ----[ delete delete instance profile for public ]
	@make delete-instance-profile-for-public || true
	@echo ----[ delete security group for public ]
	@make --no-print-directory delete-security-group-for-public || true
	@echo ----[ delete associations of public route -table ]
	@make --no-print-directory delete-associations-of-public-route-table || true
	@echo ----[ delete custom route table for public ]
	@make --no-print-directory delete-custom-route-table-for-public || true
	@echo ----[ delete internet gateway ]
	@make --no-print-directory delete-internet-gateway || true
	@echo ----[ delete subnets for public ]
	@make --no-print-directory delete-subnets-for-public || true
	@echo ----[ delete vpc ]
	@make --no-print-directory delete-created-vpc
	rm --force input.json
