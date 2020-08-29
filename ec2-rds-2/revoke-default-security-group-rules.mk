include ./shared-variables.mk

# 特に標準出力しない
.PHONY: revoke-default-security-group-rules
revoke-default-security-group-rules: init-variables-for-revoke-default-security-group-rules ## VPC作成時、デフォルトセキュリティグループのルールを削除
	$(eval SECURITY_GROUP_ID := $(shell aws ec2 describe-security-groups --filters Name=vpc-id,Values=$(VPC_ID) | jq --raw-output '.SecurityGroups[] | select(.GroupName = "default" ) | .GroupId'))
	aws ec2 describe-security-groups --group-id $(SECURITY_GROUP_ID) \
		| jq --raw-output --compact-output '.SecurityGroups[].IpPermissions' \
		| awk '$$0!="[]"' \
		| xargs --delimiter "\n" -I {ip-permissions} aws ec2 revoke-security-group-ingress --group-id $(SECURITY_GROUP_ID) --ip-permissions '{ip-permissions}'
	aws ec2 describe-security-groups --group-id $(SECURITY_GROUP_ID) \
		| jq --raw-output --compact-output '.SecurityGroups[].IpPermissionsEgress' \
		| awk '$$0!="[]"' \
		| xargs --delimiter "\n" -I {ip-permissions-egress} aws ec2 revoke-security-group-egress --group-id $(SECURITY_GROUP_ID) --ip-permissions '{ip-permissions-egress}'

.PHONY: init-variables-for-revoke-default-security-group-rules
init-variables-for-revoke-default-security-group-rules:
	$(eval VPC_ID := $(shell cat $(VPC_JSON_PATH) | jq --compact-output --raw-output 'select(.VpcId).VpcId'))
	@[ -n "$(VPC_ID)" ]
