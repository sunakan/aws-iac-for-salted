include ./shared-variables.mk

.PHONY: create-security-group-for-public
create-security-group-for-public: init-variables-for-create-security-group-for-public
	make --no-print-directory output-security-group-for-public-json-if-created > /dev/null 2>&1 \
	|| aws ec2 create-security-group --group-name $(SECURITY_GROUP_NAME) --description "$(SECURITY_GROUP_DESCRIPTION)" --vpc-id $(VPC_ID) --tag-specifications "ResourceType=security-group,Tags=[{Key=Name,Value=$(SECURITY_GROUP_TAG_NAME)}]" > /dev/null
	make --no-print-directory output-security-group-for-public-json-if-created

.PHONY: output-security-group-for-public-json-if-created
output-security-group-for-public-json-if-created: init-variables-for-create-security-group-for-public
	$(eval SECURITY_GROUP := $(shell aws ec2 describe-security-groups --filters Name=vpc-id,Values=$(VPC_ID) Name=group-name,Values=$(SECURITY_GROUP_NAME) | jq --compact-output '.SecurityGroups[]'))
	@[ -n '$(SECURITY_GROUP)' ] && ( echo '$(SECURITY_GROUP)' | jq '.' > $(SECURITY_GROUP_FOR_PUBLIC_JSON_PATH) )

.PHONY: init-variables-for-create-security-group-for-public
init-variables-for-create-security-group-for-public: input.json
	$(eval VPC_ID := $(shell cat $(VPC_JSON_PATH) | jq --compact-output --raw-output 'select(.VpcId!=null).VpcId'))
	$(eval SECURITY_GROUP_NAME := $(shell cat input.json | jq --raw-output '.custom_security_group_for_public.group_name'))
	$(eval SECURITY_GROUP_TAG_NAME := $(shell cat input.json | jq --raw-output '.custom_security_group_for_public.name'))
	$(eval SECURITY_GROUP_DESCRIPTION := $(shell cat input.json | jq --raw-output '.custom_security_group_for_public.description'))
	@[ -n "$(VPC_ID)" ] && [ -n "$(SECURITY_GROUP_NAME)" ] && [ -n "$(SECURITY_GROUP_TAG_NAME)" ]

.PHONY: delete-security-group-for-public
delete-security-group-for-public: init-variables-for-create-security-group-for-public
	aws ec2 describe-security-groups --filters Name=vpc-id,Values=$(VPC_ID) Name=group-name,Values=$(SECURITY_GROUP_NAME) \
		| jq '.SecurityGroups[].GroupId' \
		| xargs -I {group-id} aws ec2 delete-security-group --group-id {group-id}
