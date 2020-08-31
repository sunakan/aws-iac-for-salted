include ./shared-variables.mk

.PHONY: create-database-subnet-group
create-database-subnet-group: init-variables-for-database-subnet-group
	make --no-print-directory output-database-subnet-group > /dev/null 2>&1 \
	|| aws rds create-db-subnet-group --db-subnet-group-name $(DB_SUBNET_GROUP_NAME) --db-subnet-group-description '$(DB_SUBNET_GROUP_DESCRIPTION)' --subnet-ids '$(VPC_SUBNET_IDS_FOR_DATABASE)' > /dev/null
	make --no-print-directory output-database-subnet-group

.PHONY: output-database-subnet-group
output-database-subnet-group: init-variables-for-database-subnet-group
	$(eval DB_SUBNET_GROUP := $(shell aws rds describe-db-subnet-groups --db-subnet-group-name $(DB_SUBNET_GROUP_NAME) | jq --compact-output --raw-output '.DBSubnetGroups | select(length > 0) | .[0]'))
	@[ -n '$(DB_SUBNET_GROUP)' ] && ( echo '$(DB_SUBNET_GROUP)' | jq '.' > $(DATABASE_SUBNET_GROUP_JSON_PATH) )

.PHONY: init-variables-for-database-subnet-group
init-variables-for-database-subnet-group: input.json
	$(eval VPC_SUBNET_IDS_FOR_DATABASE := $(shell cat $(VPC_SUBNETS_FOR_DATABASE_JSON_PATH) | jq --compact-output --raw-output '[.[] | select(.SubnetId).SubnetId]' | awk '$$0!="[]"'))
	$(eval DB_SUBNET_GROUP_NAME := $(shell cat input.json | jq --raw-output '.database_subnet_group.group_name'))
	$(eval DB_SUBNET_GROUP_DESCRIPTION := $(shell cat input.json | jq --raw-output '.database_subnet_group.description'))
	$(eval DB_SUBNET_GROUP_TAG_NAME := $(shell cat input.json | jq --raw-output '.database_subnet_group.name'))
	@[ -n '$(VPC_SUBNET_IDS_FOR_DATABASE)' ] && [ -n '$(DB_SUBNET_GROUP_NAME)' ] \
	&& [ -n '$(DB_SUBNET_GROUP_TAG_NAME)' ] && [ -n '$(DB_SUBNET_GROUP_DESCRIPTION)' ]

.PHONY: delete-database-subnet-group
delete-database-subnet-group: init-variables-for-database-subnet-group
	aws rds describe-db-subnet-groups --db-subnet-group-name $(DB_SUBNET_GROUP_NAME) \
		| jq --raw-output '.DBSubnetGroups | select(length > 0) | .[0].DBSubnetGroupName' \
		| xargs -I {group-name} aws rds delete-db-subnet-group --db-subnet-group-name {group-name}
