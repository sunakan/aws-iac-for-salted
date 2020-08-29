include ./shared-variables.mk

.PHONY: add-role-to-instance-profile-for-public
add-role-to-instance-profile-for-public: init-variables-for-add-role-to-instance-profile-for-public
	make --no-print-directory remove-roles-from-instance-profile
	aws iam add-role-to-instance-profile --instance-profile-name $(INSTANCE_PROFILE_NAME) --role-name $(IAM_ROLE_NAME)

.PHONY: init-variables-for-add-role-to-instance-profile-for-public
init-variables-for-add-role-to-instance-profile-for-public: input.json
	$(eval IAM_ROLE_NAME := $(shell cat $(IAM_ROLE_FOR_INSTANCE_PROFILE_PUBLIC_JSON_PATH) | jq --raw-output 'select(.RoleName).RoleName'))
	$(eval INSTANCE_PROFILE_NAME := $(shell cat $(INSTANCE_PROFILE_FOR_PUBLIC_JSON_PATH) | jq --raw-output 'select(.InstanceProfileName).InstanceProfileName'))
	@[ -n "$(IAM_ROLE_NAME)" ] && [ -n "$(INSTANCE_PROFILE_NAME)" ]

.PHONY: remove-roles-from-instance-profile
remove-roles-from-instance-profile: init-variables-for-add-role-to-instance-profile-for-public
	aws iam get-instance-profile --instance-profile-name $(INSTANCE_PROFILE_NAME) \
		| jq '.InstanceProfile.Roles[].RoleName' \
		| xargs -I {role-name} aws iam remove-role-from-instance-profile --instance-profile-name $(INSTANCE_PROFILE_NAME) --role-name {role-name}
