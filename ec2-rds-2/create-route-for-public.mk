include ./shared-variables.mk

.PHONY: create-route-for-public
create-route-for-public: init-variables-for-create-route-for-public
	aws ec2 create-route --route-table-id $(CUSTOM_ROUTE_TABLE_ID) --destination-cidr-block 0.0.0.0/0 --gateway-id $(INTERNET_GATEWAY_ID) > /dev/null
	make --no-print-directory output-custom-route-table-for-public-if-created

.PHONY: init-variables-for-create-route-for-public
init-variables-for-create-route-for-public:
	$(eval INTERNET_GATEWAY_ID   := $(shell cat $(INTERNET_GATEWAY_JSON_PATH)              | jq --compact-output --raw-output 'select(.InternetGatewayId!=null).InternetGatewayId'))
	$(eval CUSTOM_ROUTE_TABLE_ID := $(shell cat $(CUSTOM_ROUTE_TABLE_FOR_PUBLIC_JSON_PATH) | jq --compact-output --raw-output 'select(.RouteTableId).RouteTableId'))
	@[ -n "$(INTERNET_GATEWAY_ID)" ] && [ -n "$(CUSTOM_ROUTE_TABLE_ID)" ]
