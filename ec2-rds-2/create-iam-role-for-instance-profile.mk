include ./shared-variables.mk

.PHONY: create-iam-role-for-instance-profile
create-iam-role-for-instance-profile: init-variables-for-create-iam-role-for-instance-profile
	( make --no-print-directory output-iam-role-for-instance-profile-if-created > /dev/null 2>&1 ) \
	|| aws iam create-role --role-name $(IAM_ROLE_NAME) --assume-role-policy-document file://$(ASSUME_ROLE_POLICY_FILE_PATH) > /dev/null
	make --no-print-directory output-iam-role-for-instance-profile-if-created

.PHONY: output-iam-role-for-instance-profile-if-created
output-iam-role-for-instance-profile-if-created: init-variables-for-create-iam-role-for-instance-profile
	( aws iam get-role --role-name $(IAM_ROLE_NAME) > /dev/null 2>&1 ) \
	&& aws iam get-role --role-name $(IAM_ROLE_NAME) | jq '.' > $(IAM_ROLE_FOR_INSTANCE_PROFILE_PUBLIC_JSON_PATH)

.PHONY: init-variables-for-create-iam-role-for-instance-profile
init-variables-for-create-iam-role-for-instance-profile: input.json
	$(eval IAM_ROLE_NAME := $(shell cat input.json | jq --raw-output '.public_ec2_instance_profile.iam_role.name'))
	@[ -n "$(IAM_ROLE_NAME)" ]

.PHONY: delete-iam-role-for-instance-profile
delete-iam-role-for-instance-profile: init-variables-for-create-iam-role-for-instance-profile
	aws iam list-attached-role-policies --role-name $(IAM_ROLE_NAME) \
		| jq '.AttachedPolicies[].PolicyArn' \
		| xargs -I {policy-name} aws iam detach-role-policy --role-name $(IAM_ROLE_NAME) --policy-arn {policy-name}
	aws iam delete-role --role-name $(IAM_ROLE_NAME)
