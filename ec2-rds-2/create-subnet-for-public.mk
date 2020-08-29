include ./shared-variables.mk

.PHONY: create-subnets-for-public
create-subnets-for-public: init-variables-for-create-subnets-for-public
	echo '$(VPC_SUBNETS)' \
	| jq --raw-output --compact-output '.[]' \
	| while read -r subnet; do \
		cidr=$$(echo "$$subnet" | jq --raw-output '.cidr' ); \
		az=$$(echo "$$subnet" | jq --raw-output '.az' ); \
		name=$$(echo "$$subnet" | jq --raw-output '.name' ); \
		subnet_count=$$(aws ec2 describe-subnets --filters Name=cidr-block,Values="$$cidr" Name=vpc-id,Values=$(VPC_ID) | jq --raw-output '.Subnets | length'); \
		if [ "$$subnet_count" -eq 0 ]; then \
			aws ec2 create-subnet --vpc-id $(VPC_ID) --cidr-block "$$cidr" --availability-zone "$$az" --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=\"$$name\"}]" > /dev/null; \
		fi \
	done
	@make --no-print-directory output-subnets-for-public-json

.PHONY: output-subnets-for-public-json
output-subnets-for-public-json: init-variables-for-create-subnets-for-public
	echo '$(VPC_SUBNETS)' \
	| jq --raw-output --compact-output '[.[].cidr] | @csv' \
	| xargs -I {cidr-list} aws ec2 describe-subnets --filters Name=cidrBlock,Values={cidr-list} Name=vpc-id,Values=$(VPC_ID) \
	| jq --raw-output '.Subnets' > $(VPC_SUBNETS_FOR_PUBLIC_JSON_PATH)

.PHONY: init-variables-for-create-subnets-for-public
init-variables-for-create-subnets-for-public: input.json
	$(eval VPC_ID      := $(shell cat $(VPC_JSON_PATH) | jq --compact-output --raw-output 'select(.VpcId!=null).VpcId'))
	$(eval VPC_SUBNETS := $(shell cat input.json       | jq --compact-output --raw-output '.vpc_public_subnets.subnets'))
	@[ -n "$(VPC_ID)" ] && [ -n "$(VPC_SUBNETS)" ]

.PHONY: delete-subnets-for-public
delete-subnets-for-public:
	cat $(VPC_SUBNETS_FOR_PUBLIC_JSON_PATH) | jq '.[].SubnetId' | xargs -I {subnet-id} aws ec2 delete-subnet --subnet-id {subnet-id}
