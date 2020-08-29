include ./shared-variables.mk

# 特に標準出力しない
.PHONY: revoke-default-security-group-rules
revoke-default-security-group-rules: init-variables-for-revoke-default-security-group-rules ## VPC作成時、デフォルトセキュリティグループのルールを削除
	$(eval security-group-id := $(shell aws ec2 describe-security-groups --filters Name=vpc-id,Values=$(vpc-id) | jq --raw-output '.SecurityGroups[] | select(.GroupName = "default" ) | .GroupId'))
	aws ec2 describe-security-groups --group-id $(security-group-id) \
		| jq --raw-output --compact-output '.SecurityGroups[].IpPermissions' \
		| awk '$$0!="[]"' \
		| xargs --delimiter "\n" -I {ip-permissions} aws ec2 revoke-security-group-ingress --group-id $(security-group-id) --ip-permissions '{ip-permissions}'
	aws ec2 describe-security-groups --group-id $(security-group-id) \
		| jq --raw-output --compact-output '.SecurityGroups[].IpPermissionsEgress' \
		| awk '$$0!="[]"' \
		| xargs --delimiter "\n" -I {ip-permissions-egress} aws ec2 revoke-security-group-egress --group-id $(security-group-id) --ip-permissions '{ip-permissions-egress}'

.PHONY: init-variables-for-revoke-default-security-group-rules
init-variables-for-revoke-default-security-group-rules:
	$(eval vpc-id := $(shell cat $(VPC_JSON_PATH) | jq --compact-output --raw-output '.VpcId'))
	@[ -n "$(vpc-id)" ] || false
