include ./shared-variables.mk

.PHONY: associate-route-table-and-modify-subnets-for-public
associate-route-table-and-modify-subnets-for-public: init-variables-for-associate-route-table-and-modify-subnets-for-public
	echo '$(VPC_SUBNET_IDS)' | jq --raw-output '.[]' | while read subnet_id; do \
		aws ec2 associate-route-table --subnet-id "$${subnet_id}" --route-table-id $(CUSTOM_ROUTE_TABLE_ID) > /dev/null; \
		aws ec2 modify-subnet-attribute --subnet-id "$${subnet_id}" --map-public-ip-on-launch; \
	done
	make --no-print-directory output-custom-route-table-for-public-if-created
	make --no-print-directory output-subnets-for-public-json

.PHONY: init-variables-for-associate-route-table-and-modify-subnets-for-public
init-variables-for-associate-route-table-and-modify-subnets-for-public: input.json
	$(eval CUSTOM_ROUTE_TABLE_ID := $(shell cat $(CUSTOM_ROUTE_TABLE_FOR_PUBLIC_JSON_PATH) | jq --compact-output --raw-output 'select(.RouteTableId).RouteTableId'))
	$(eval VPC_SUBNET_IDS := $(shell cat $(VPC_SUBNETS_FOR_PUBLIC_JSON_PATH) | jq --compact-output --raw-output '[.[].SubnetId]'))
	@[ -n "$(CUSTOM_ROUTE_TABLE_ID)" ] && [ -n "$(VPC_SUBNET_IDS)" ]

.PHONY: delete-associations-of-public-route-table
delete-associations-of-public-route-table: init-variables-for-associate-route-table-and-modify-subnets-for-public
	aws ec2 describe-route-tables --filters Name=route-table-id,Values=$(CUSTOM_ROUTE_TABLE_ID) \
		| jq --raw-output '.RouteTables[].Associations[].RouteTableAssociationId' \
		| xargs -I {association-id} aws ec2 disassociate-route-table --association-id {association-id}
	echo '$(VPC_SUBNET_IDS)' \
		| jq --raw-output '.[]' \
		| xargs -I {subnet-id} aws ec2 modify-subnet-attribute --subnet-id {subnet-id} --no-map-public-ip-on-launch
