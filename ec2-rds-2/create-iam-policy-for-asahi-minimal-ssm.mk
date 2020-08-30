include ./shared-variables.mk

.PHONY: create-iam-policy-for-asahi-minimal-ssm
create-iam-policy-for-asahi-minimal-ssm: init-variables-for-create-iam-policy-for-asahi-minimal-ssm
	make --no-print-directory output-iam-policy-for-asahi-minimal-ssm > /dev/null 2>&1 \
	|| ( echo '$(IAM_POLICIES)' | jq --raw-output --compact-output '.[]' | while read iam_policy; do \
		policy_name=$$(echo "$$iam_policy" | jq --raw-output '.name'); \
		iam_policy_file_path=$$(echo "$$iam_policy" | jq --raw-output '.iam_policy_file_path'); \
		aws iam create-policy --policy-name "$$policy_name" --policy-document "file://$$iam_policy_file_path" > /dev/null; \
	done)
	make --no-print-directory output-iam-policy-for-asahi-minimal-ssm

.PHONY: init-variables-for-create-iam-policy-for-asahi-minimal-ssm
init-variables-for-create-iam-policy-for-asahi-minimal-ssm: input.json
	$(eval IAM_POLICIES := $(shell cat input.json | jq --compact-output --raw-output '.public_ec2_instance_profile.iam_role.attached_iam_policies'))
	@[ -n '$(IAM_POLICIES)' ]

.PHONY: output-iam-policy-for-asahi-minimal-ssm
output-iam-policy-for-asahi-minimal-ssm: init-variables-for-create-iam-policy-for-asahi-minimal-ssm
	$(eval CREATED_IAM_POLICIES := $(shell echo '$(IAM_POLICIES)' \
		| jq --raw-output '[.[].name] | @csv' \
		| sed 's/,/|/g' \
		| sed 's/"//g' \
		| xargs -I {policy-names} sh -c "aws iam list-policies --scope Local | jq --compact-output '[.Policies[] | select(.PolicyName | test(\"({policy-names})\"))]'" \
	))
	@[ $(shell echo '$(CREATED_IAM_POLICIES)' | jq 'length') -eq $(shell echo '$(IAM_POLICIES)' | jq 'length') ] \
	&& ( echo '$(CREATED_IAM_POLICIES)' | jq --raw-output > $(IAM_POLICIES_FOR_ROLE_INSTANCE_PROFILE_PUBLIC_JSON_PATH))

# 1. IAM PolicyのDefault Version以外をすべて削除
# 2. IAM Policyを削除
.PHONY: delete-iam-policies-for-asahi-minimal-ssm
delete-iam-policies-for-asahi-minimal-ssm: init-variables-for-create-iam-policy-for-asahi-minimal-ssm
	echo '$(IAM_POLICIES)' \
		| jq --raw-output '[.[].name] | @csv' \
		| sed 's/,/|/g' \
		| sed 's/"//g' \
		| xargs -I {policy-names} sh -c "aws iam list-policies --scope Local | jq --compact-output '[.Policies[] | select(.PolicyName | test(\"({policy-names})\"))]'" \
		| jq '.[].Arn' \
		| xargs -I {policy-arn} sh -c "aws iam list-policy-versions --policy-arn {policy-arn} | jq '.Versions[] | select(.IsDefaultVersion==false).VersionId' | xargs -I {version-id} aws iam delete-policy-version --policy-arn {policy-arn} --version-id {version-id}"
	echo '$(IAM_POLICIES)' \
		| jq --raw-output '[.[].name] | @csv' \
		| sed 's/,/|/g' \
		| sed 's/"//g' \
		| xargs -I {policy-names} sh -c "aws iam list-policies --scope Local | jq --compact-output '[.Policies[] | select(.PolicyName | test(\"({policy-names})\"))]'" \
		| jq '.[].Arn' \
		| xargs -I {policy-arn} aws iam delete-policy --policy-arn {policy-arn}
