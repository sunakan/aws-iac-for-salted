include ./shared-variables.mk

.PHONY: add-ingress-rule-to-security-group-for-database
add-ingress-rule-to-security-group-for-database: init-variables-for-add-ingress-rule-to-security-group-for-database
	aws ec2 authorize-security-group-ingress --group-id $(SECURITY_GROUP_ID) --protocol tcp --port 3306 --cidr $(VPC_CIDR) || true
	aws ec2 authorize-security-group-ingress --group-id $(SECURITY_GROUP_ID) --protocol tcp --port 5432 --cidr $(VPC_CIDR) || true
	make --no-print-directory output-security-group-for-database

.PHONY: init-variables-for-add-ingress-rule-to-security-group-for-database
init-variables-for-add-ingress-rule-to-security-group-for-database: input.json
	$(eval VPC_CIDR := $(shell cat $(VPC_JSON_PATH) | jq --raw-output '.CidrBlock'))
	$(eval SECURITY_GROUP_ID := $(shell cat $(SECURITY_GROUP_FOR_DATABASE_JSON_PATH) | jq --raw-output '.GroupId' ))
	@[ -n '$(VPC_CIDR)' ] && [ -n '$(SECURITY_GROUP_ID)' ]

.PHONY: revoke-ingress-rules-from-database-security-group
revoke-ingress-rules-from-database-security-group: init-variables-for-add-ingress-rule-to-security-group-for-database
	aws ec2 describe-security-groups --group-id $(SECURITY_GROUP_ID) \
		| jq --raw-output --compact-output '.SecurityGroups[].IpPermissions' \
		| awk '$$0!="[]"' \
		| xargs --delimiter "\n" -I {ip-permissions} aws ec2 revoke-security-group-ingress --group-id $(SECURITY_GROUP_ID) --ip-permissions '{ip-permissions}'
