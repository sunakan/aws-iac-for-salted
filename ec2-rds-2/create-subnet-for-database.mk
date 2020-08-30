include ./shared-variables.mk

.PHONY: create-subnets-for-database
create-subnets-for-database: init-variables-for-create-subnets-for-database
	make --no-print-directory output-subnets-for-database > /dev/null 2>&1 \
	|| ( echo '$(VPC_SUBNETS)' \
		| jq --raw-output --compact-output '.[]' \
		| while read subnet; do \
			cidr=$$(echo "$$subnet" | jq --raw-output '.cidr' ); \
			az=$$(echo "$$subnet" | jq --raw-output '.az' ); \
			name=$$(echo "$$subnet" | jq --raw-output '.name' ); \
			subnet_count=$$(aws ec2 describe-subnets --filters Name=cidr-block,Values="$$cidr" Name=vpc-id,Values=$(VPC_ID) | jq --raw-output '.Subnets | length'); \
			if [ "$$subnet_count" -eq 0 ]; then \
				aws ec2 create-subnet --vpc-id $(VPC_ID) --cidr-block "$$cidr" --availability-zone "$$az" --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=\"$$name\"}]" > /dev/null; \
			fi \
		done )
	make --no-print-directory output-subnets-for-database

.PHONY: output-subnets-for-database
output-subnets-for-database: init-variables-for-create-subnets-for-database
	$(eval CREATED_VPC_SUBNETS := $(shell echo '$(VPC_SUBNETS)' \
		| jq --raw-output --compact-output '[.[].cidr] | @csv' \
		| xargs -I {cidr-list} aws ec2 describe-subnets --filters Name=cidrBlock,Values={cidr-list} Name=vpc-id,Values=$(VPC_ID) \
		| jq --raw-output '.Subnets' \
		| awk '$$0!="[]"'))
	@[ -n '$(CREATED_VPC_SUBNETS)' ] && ( echo '$(CREATED_VPC_SUBNETS)' | jq '.' > $(VPC_SUBNETS_FOR_DATABASE_JSON_PATH) )

.PHONY: init-variables-for-create-subnets-for-database
init-variables-for-create-subnets-for-database: input.json
	$(eval VPC_ID      := $(shell cat $(VPC_JSON_PATH) | jq --compact-output --raw-output 'select(.VpcId!=null).VpcId'))
	$(eval VPC_SUBNETS := $(shell cat input.json       | jq --compact-output --raw-output '.vpc_database_subnets.subnets'))
	@[ -n '$(VPC_ID)' ] && [ -n '$(VPC_SUBNETS)' ]

.PHONY: delete-subnets-for-database
delete-subnets-for-database: init-variables-for-create-subnets-for-database
	echo '$(VPC_SUBNETS)' \
		| jq --raw-output --compact-output '[.[].cidr] | @csv' \
		| xargs -I {cidr-list} aws ec2 describe-subnets --filters Name=cidrBlock,Values={cidr-list} Name=vpc-id,Values=$(VPC_ID) \
		| jq --raw-output '.Subnets[].SubnetId' \
		| xargs -I {subnet-id} aws ec2 delete-subnet --subnet-id {subnet-id}
