include ./shared-variables.mk

.PHONY: create-instance-profile-for-public
create-instance-profile-for-public: init-variables-for-create-instance-profile-for-public
	make --no-print-directory output-instance-profile-for-public-if-created > /dev/null 2>&1 \
	|| aws iam create-instance-profile --instance-profile-name $(IAM_INSTANCE_PROFILE_NAME) > /dev/null
	make --no-print-directory output-instance-profile-for-public-if-created

.PHONY: output-instance-profile-for-public-if-created
output-instance-profile-for-public-if-created: init-variables-for-create-instance-profile-for-public
	$(eval INSTANCE_PROFILE := $(shell aws iam get-instance-profile --instance-profile-name $(IAM_INSTANCE_PROFILE_NAME) | jq --compact-output '.InstanceProfile'))
	@[ -n '$(INSTANCE_PROFILE)' ] && ( echo '$(INSTANCE_PROFILE)' | jq '.' > $(INSTANCE_PROFILE_FOR_PUBLIC_JSON_PATH) )

.PHONY: init-variables-for-create-instance-profile-for-public
init-variables-for-create-instance-profile-for-public: input.json
	$(eval IAM_INSTANCE_PROFILE_NAME := $(shell cat input.json | jq --raw-output '.public_ec2_instance_profile.name'))
	@[ -n "$(IAM_INSTANCE_PROFILE_NAME)" ]

.PHONY: delete-instance-profile-for-public
delete-instance-profile-for-public: init-variables-for-create-instance-profile-for-public
	aws iam get-instance-profile --instance-profile-name $(IAM_INSTANCE_PROFILE_NAME) \
		| jq '.InstanceProfile.Roles[].RoleName' \
		| xargs -I {role-name} aws iam remove-role-from-instance-profile --instance-profile-name $(IAM_INSTANCE_PROFILE_NAME) --role-name {role-name}
	aws iam delete-instance-profile --instance-profile-name $(IAM_INSTANCE_PROFILE_NAME)
