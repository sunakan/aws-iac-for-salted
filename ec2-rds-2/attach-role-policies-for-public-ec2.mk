include ./shared-variables.mk

.PHONY: attach-role-policies-for-public-ec2
attach-role-policies-for-public-ec2: init-variables-for-attach-role-policies-for-public-ec2
	echo '$(IAM_POLICY_ARNS)' \
	| jq '.[]' \
	| xargs -I {policy-arn} aws iam attach-role-policy --role-name $(IAM_ROLE_NAME) --policy-arn {policy-arn}

.PHONY: init-variables-for-attach-role-policies-for-public-ec2
init-variables-for-attach-role-policies-for-public-ec2:
	$(eval IAM_ROLE_NAME := $(shell cat $(IAM_ROLE_FOR_INSTANCE_PROFILE_PUBLIC_JSON_PATH) | jq --raw-output '.RoleName'))
	$(eval IAM_POLICY_ARNS := $(shell cat $(IAM_POLICIES_FOR_ROLE_INSTANCE_PROFILE_PUBLIC_JSON_PATH) | jq --compact-output --raw-output '[.[] | select(.Arn).Arn]'))
	@[ -n "$(IAM_ROLE_NAME)" ] && [ -n '$(IAM_POLICY_ARNS)' ]

.PHONY: detach-all-policies-from-role-for-public-ec2
detach-all-policies-from-role-for-public-ec2: init-variables-for-attach-role-policies-for-public-ec2
	aws iam list-attached-role-policies --role-name $(IAM_ROLE_NAME) \
		| jq '.AttachedPolicies[].PolicyArn' \
		| xargs -I {policy-name} aws iam detach-role-policy --role-name $(IAM_ROLE_NAME) --policy-arn {policy-name}
