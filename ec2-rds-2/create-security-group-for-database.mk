include ./shared-variables.mk

.PHONY: create-security-group-for-database
create-security-group-for-database: init-variables-for-security-group-for-database
	make --no-print-directory output-security-group-for-database > /dev/null 2>&1 \
	|| aws ec2 create-security-group --group-name $(SECURITY_GROUP_NAME) --description "$(SECURITY_GROUP_DESCRIPTION)" --vpc-id $(VPC_ID) --tag-specifications "ResourceType=security-group,Tags=[{Key=Name,Value=$(SECURITY_GROUP_TAG_NAME)}]" > /dev/null
	make --no-print-directory output-security-group-for-database

.PHONY: output-security-group-for-database
output-security-group-for-database: init-variables-for-security-group-for-database
	$(eval SECURITY_GROUP := $(shell aws ec2 describe-security-groups --filters Name=vpc-id,Values=$(VPC_ID) Name=group-name,Values=$(SECURITY_GROUP_NAME) | jq --compact-output '.SecurityGroups[]'))
	@[ -n '$(SECURITY_GROUP)' ] && ( echo '$(SECURITY_GROUP)' | jq '.' > $(SECURITY_GROUP_FOR_DATABASE_JSON_PATH) )

.PHONY: init-variables-for-security-group-for-database
init-variables-for-security-group-for-database: input.json
	$(eval VPC_ID := $(shell cat $(VPC_JSON_PATH) | jq --compact-output --raw-output 'select(.VpcId!=null).VpcId'))
	$(eval SECURITY_GROUP_NAME := $(shell cat input.json | jq --raw-output '.custom_security_group_for_database.group_name'))
	$(eval SECURITY_GROUP_TAG_NAME := $(shell cat input.json | jq --raw-output '.custom_security_group_for_database.name'))
	$(eval SECURITY_GROUP_DESCRIPTION := $(shell cat input.json | jq --raw-output '.custom_security_group_for_database.description'))
	@[ -n "$(VPC_ID)" ] && [ -n "$(SECURITY_GROUP_NAME)" ] && [ -n "$(SECURITY_GROUP_TAG_NAME)" ]

.PHONY: delete-security-group-for-database
delete-security-group-for-database: init-variables-for-security-group-for-database
	aws ec2 describe-security-groups --filters Name=vpc-id,Values=$(VPC_ID) Name=group-name,Values=$(SECURITY_GROUP_NAME) \
		| jq '.SecurityGroups[].GroupId' \
		| xargs -I {group-id} aws ec2 delete-security-group --group-id {group-id}
