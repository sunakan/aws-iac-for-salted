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
include ./add-role-to-instance-profile-for-public.mk
include ./create-iam-policies-for-asahi-minimal-ssm.mk
include ./attach-role-policies-for-public-ec2.mk
include ./run-ec2-for-public.mk
include ./ssm.mk
include ./create-subnet-for-database.mk
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
	@echo --------[ add role to instance profile for public ]
	@make --no-print-directory add-role-to-instance-profile-for-public
	@echo --------[ create iam policies for public ec2 iam role ]
	@make --no-print-directory create-iam-policies-for-asahi-minimal-ssm
	@echo --------[ attach role policies for public ec2 ]
	@make --no-print-directory attach-role-policies-for-public-ec2
	@echo --------[ run ec2 for public ]
	@make --no-print-directory run-ec2-for-public
	@echo --------[ create vpc subnets for database ]
	@make --no-print-directory create-subnets-for-database

# input.jsonが無ければ作成、失敗したら削除する
input.json:
	( cat input.toml | rq --input-toml --output-json --format indented > input.json ) \
		|| rm input.json

# outputsディレクトリを作成
outputs:
	mkdir -p $(OUTPUT_BASE_PATH)

cleanup: ## 作成したAWSリソースを全削除
	@echo --------[ delete vpc subnets for database ]
	@make --no-print-directory delete-subnets-for-database
	@echo --------[ terminate ec2 for public ]
	@make --no-print-directory terminate-ec2-for-public
	@echo ----[ detach all policies from role for public ec2 ]
	@make detach-all-policies-from-role-for-public-ec2
	@echo ----[ delete iam policies for asahi minimal ssm ]
	@make delete-iam-policies-for-asahi-minimal-ssm
	@echo ----[ remove roles from instance profile ]
	@make remove-roles-from-instance-profile
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
