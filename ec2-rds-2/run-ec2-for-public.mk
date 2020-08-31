include ./shared-variables.mk

.PHONY: run-ec2-for-public
run-ec2-for-public: init-variables-for-run-ec2-for-public
	make --no-print-directory output-run-ec2-for-public-if-running > /dev/null 2>&1 \
	|| aws ec2 run-instances --count 1 --image-id $(AMI_ID) --instance-type $(EC2_TYPE) --security-group-ids $(SECURITY_GROUP_ID) --subnet-id $(VPC_SUBNET_ID) --iam-instance-profile Name=$(INSTANCE_PROFILE_NAME) --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$(EC2_TAG_NAME)}]" > /dev/null
	make --no-print-directory output-run-ec2-for-public-if-running

.PHONY: output-run-ec2-for-public-if-running
output-run-ec2-for-public-if-running: init-variables-for-run-ec2-for-public
	$(eval EC2 := $(shell aws ec2 describe-instances --filter Name=subnet-id,Values=$(VPC_SUBNET_ID) Name=tag:Name,Values=$(EC2_TAG_NAME) Name=instance-state-name,Values=[running,pending] Name=iam-instance-profile.arn,Values=$(INSTANCE_PROFILE_ARN) \
		| jq --compact-output --raw-output '.Reservations | select( length > 0 ) | .[0] | .Instances | select( length > 0 ) | .[0]' \
	))
	@[ -n '$(EC2)' ] && ( echo '$(EC2)' | jq '.' > $(EC2_FOR_PUBLIC_JSON_PATH) )

.PHONY: init-variables-for-run-ec2-for-public
init-variables-for-run-ec2-for-public: input.json
	$(eval AMI_ID := $(shell cat input.json | jq --raw-output 'select(.ec2.ami).ec2.ami'))
	$(eval EC2_TYPE := $(shell cat input.json | jq --raw-output 'select(.ec2.instance_type).ec2.instance_type'))
	$(eval EC2_TAG_NAME := $(shell cat input.json | jq --raw-output 'select(.ec2.name).ec2.name'))
	$(eval VPC_SUBNET_ID := $(shell cat $(VPC_SUBNETS_FOR_PUBLIC_JSON_PATH) | jq --raw-output '.[0] | select(.SubnetId).SubnetId'))
	$(eval SECURITY_GROUP_ID := $(shell cat $(SECURITY_GROUP_FOR_PUBLIC_JSON_PATH) | jq --raw-output 'select(.GroupId).GroupId'))
	$(eval INSTANCE_PROFILE_NAME := $(shell cat $(INSTANCE_PROFILE_FOR_PUBLIC_JSON_PATH) | jq --raw-output 'select(.InstanceProfileName).InstanceProfileName'))
	$(eval INSTANCE_PROFILE_ARN := $(shell cat $(INSTANCE_PROFILE_FOR_PUBLIC_JSON_PATH) | jq --raw-output 'select(.InstanceProfileName).Arn'))
	@[ -n "$(AMI_ID)" ] && [ -n "$(EC2_TYPE)" ] && [ -n "$(EC2_TAG_NAME)" ] && [ -n "$(VPC_SUBNET_ID)" ] \
	&& [ -n "$(SECURITY_GROUP_ID)" ] && [ -n "$(INSTANCE_PROFILE_NAME)" ] && [ -n "$(INSTANCE_PROFILE_ARN)" ]

.PHONY: terminate-ec2-for-public
terminate-ec2-for-public: init-variables-for-run-ec2-for-public
	aws ec2 describe-instances --filter Name=subnet-id,Values=$(VPC_SUBNET_ID) Name=tag:Name,Values=$(EC2_TAG_NAME) Name=instance-state-name,Values=[running,pending] Name=iam-instance-profile.arn,Values=$(INSTANCE_PROFILE_ARN) \
		| jq --compact-output --raw-output '.Reservations[].Instances[] | select(.InstanceId).InstanceId' \
		| xargs -I {instance-id} sh -c 'aws ec2 terminate-instances --instance-ids {instance-id} > /dev/null && echo {instance-id}' \
		| while read instance_id; do \
			while :; do \
				sleep 1; \
				status=$$(aws ec2 describe-instances --instance-ids "$$instance_id" | jq --compact-output --raw-output ".Reservations[].Instances[] | select(.State.Name).State.Name"); \
				echo "$$status"; \
				[ "$$status" = "terminated" ] && break; \
			done; \
			echo "Terminated $$instance_id"; \
		done
