include ./shared-variables.mk

.PHONY: create-custom-route-table-for-public
create-custom-route-table-for-public: init-variables-for-create-custom-route-table-for-public
	make --no-print-directory output-custom-route-table-for-public-if-created > /dev/null 2>&1 \
	|| aws ec2 create-route-table --vpc-id $(VPC_ID) --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=$(CUSTOM_ROUTE_TABLE_TAG_NAME)}]" > /dev/null
	make --no-print-directory output-custom-route-table-for-public-if-created

.PHONY: output-custom-route-table-for-public-if-created
output-custom-route-table-for-public-if-created: init-variables-for-create-custom-route-table-for-public
	$(eval CUSTOM_ROUTE_TABLE := $(shell aws ec2 describe-route-tables --filters Name=vpc-id,Values=$(VPC_ID) | jq --compact-output '.RouteTables[] | select(.RouteTableId != "$(MAIN_ROUTE_TABLE_ID)")'))
	@[ -n "$(CUSTOM_ROUTE_TABLE)" ] && ( echo '$(CUSTOM_ROUTE_TABLE)' | jq '.' > $(CUSTOM_ROUTE_TABLE_FOR_PUBLIC_JSON_PATH) )

.PHONY: init-variables-for-create-custom-route-table-for-public
init-variables-for-create-custom-route-table-for-public: input.json
	$(eval VPC_ID                      := $(shell cat $(VPC_JSON_PATH) | jq --compact-output --raw-output 'select(.VpcId!=null).VpcId'))
	$(eval CUSTOM_ROUTE_TABLE_TAG_NAME := $(shell cat input.json       | jq --compact-output --raw-output '.custom_route_table | select(.name!=null).name'))
	$(eval MAIN_ROUTE_TABLE_ID         := $(shell aws ec2 describe-route-tables --filters Name=vpc-id,Values=$(VPC_ID) Name=association.main,Values=true | jq --compact-output --raw-output '.RouteTables[] | select(.RouteTableId).RouteTableId'))
	@[ -n "$(VPC_ID)" ] && [ -n "$(CUSTOM_ROUTE_TABLE_TAG_NAME)" ] && [ -n "$(MAIN_ROUTE_TABLE_ID)" ]

.PHONY: delete-custom-route-table-for-public
delete-custom-route-table-for-public: init-variables-for-create-custom-route-table-for-public
	aws ec2 describe-route-tables --filters Name=vpc-id,Values=$(VPC_ID) \
		| jq --compact-output '.RouteTables[] | select(.RouteTableId != "$(MAIN_ROUTE_TABLE_ID)") | .RouteTableId' \
		| xargs -I {route-table-id} aws ec2 delete-route-table --route-table-id {route-table-id}
