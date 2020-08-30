include ./shared-variables.mk

.PHONY: create-internet-gateway-and-attach
create-internet-gateway-and-attach: init-variables-for-create-internet-gateway-and-attach
	make --no-print-directory output-internet-gateway-json-if-created > /dev/null 2>&1 \
	|| ( aws ec2 create-internet-gateway --tag-specifications "ResourceType=internet-gateway,Tags=[{Key=Name,Value=$(INTERNET_GATEWAY_TAG_NAME)}]" \
		| jq '.InternetGateway.InternetGatewayId' \
		| xargs -I {igw-id} aws ec2 attach-internet-gateway --vpc-id $(VPC_ID) --internet-gateway-id {igw-id} \
	)
	make --no-print-directory output-internet-gateway-json-if-created

.PHONY: output-internet-gateway-json-if-created
output-internet-gateway-json-if-created: init-variables-for-create-internet-gateway-and-attach
	$(eval INTERNET_GATEWAY := $(shell aws ec2 describe-internet-gateways --filters Name=attachment.vpc-id,Values=$(VPC_ID) Name=tag:Name,Values=$(INTERNET_GATEWAY_TAG_NAME) | jq --compact-output --raw-output '.InternetGateways[] | select(.InternetGatewayId)'))
	@[ -n '$(INTERNET_GATEWAY)' ] && ( echo '$(INTERNET_GATEWAY)' | jq '.' > $(INTERNET_GATEWAY_JSON_PATH))

.PHONY: init-variables-for-create-internet-gateway-and-attach
init-variables-for-create-internet-gateway-and-attach: input.json
	$(eval VPC_ID                    := $(shell cat $(VPC_JSON_PATH) | jq --compact-output --raw-output '.VpcId'))
	$(eval INTERNET_GATEWAY_TAG_NAME := $(shell cat input.json       | jq --compact-output --raw-output '.internet_gateway | select(.name!=null).name'))
	@[ -n "$(VPC_ID)" ] && [ -n "$(INTERNET_GATEWAY_TAG_NAME)" ]

.PHONY: delete-internet-gateway
delete-internet-gateway: init-variables-for-create-internet-gateway-and-attach
	$(eval INTERNET_GATEWAY_ID := $(shell aws ec2 describe-internet-gateways --filters Name=attachment.vpc-id,Values=$(VPC_ID) Name=tag:Name,Values=$(INTERNET_GATEWAY_TAG_NAME) | jq --compact-output --raw-output '.InternetGateways[] | select(.InternetGatewayId).InternetGatewayId'))
	[ -n "$(INTERNET_GATEWAY_ID)" ] && aws ec2 detach-internet-gateway --internet-gateway-id $(INTERNET_GATEWAY_ID) --vpc-id $(VPC_ID)
	[ -n "$(INTERNET_GATEWAY_ID)" ] && aws ec2 delete-internet-gateway --internet-gateway-id $(INTERNET_GATEWAY_ID)
