include ./shared-variables.mk

.PHONY: ssm
ssm: init-variables-for-ssm
	aws ssm start-session --target $(INSTANCE_ID)

.PHONY: init-variables-for-ssm
init-variables-for-ssm:
	$(eval INSTANCE_ID := $(shell cat $(EC2_FOR_PUBLIC_JSON_PATH) | jq --raw-output '.InstanceId'))
	@[ -n "$(INSTANCE_ID)" ]
