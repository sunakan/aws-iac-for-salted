include ./shared-variables.mk

.PHONY: create-vpc
create-vpc: init-variables-for-create-vpc ## VPCを作成
	make --no-print-directory output-vpc-json-if-created > /dev/null 2>&1 \
	|| aws ec2 create-vpc --cidr-block $(VPC_CIDR) --tag-specifications "ResourceType=vpc,Tags=[{Key=Name,Value=$(VPC_TAG_NAME)}]" > /dev/null
	make --no-print-directory output-vpc-json-if-created

.PHONY: output-vpc-json-if-created
output-vpc-json-if-created: init-variables-for-create-vpc outputs ## もしVPCを作成済みならjsonで出力
	$(eval VPC := $(shell aws ec2 describe-vpcs --filters Name=cidr,Values=$(VPC_CIDR) Name=tag:Name,Values=$(VPC_TAG_NAME) | jq --compact-output --raw-output '.Vpcs[]'))
	@[ -n '$(VPC)' ] && ( echo '$(VPC)' | jq '.' > $(VPC_JSON_PATH) )

# VPC作成に必要な変数の定義
.PHONY: init-variables-for-create-vpc
init-variables-for-create-vpc: input.json
	$(eval VPC_TAG_NAME := $(shell cat input.json | jq --raw-output '.vpc | select(.name).name'))
	$(eval VPC_CIDR     := $(shell cat input.json | jq --raw-output '.vpc | select(.cidr).cidr'))
	@[ -n "$(VPC_TAG_NAME)" ] && [ -n "$(VPC_CIDR)" ]

.PHONY: delete-created-vpc
delete-created-vpc: init-variables-for-create-vpc
	aws ec2 describe-vpcs --filters Name=cidr,Values=$(VPC_CIDR) Name=tag:Name,Values=$(VPC_TAG_NAME) \
		| jq --compact-output '.Vpcs[].VpcId' \
		| xargs -I {vpc-id} aws ec2 delete-vpc --vpc-id {vpc-id}
