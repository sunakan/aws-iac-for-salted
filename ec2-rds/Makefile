output-01.toml:
	cat input.toml | ./yj -tj | sh 01-create-vpc.sh | ./yj -jt 1> output-01.toml

output-02.toml: output-01.toml
	cat output-01.toml | ./yj -tj | sh 02-revoke-default-security-group-rules.sh | ./yj -jt 1> output-02.toml

output-03.toml: output-02.toml
	cat output-02.toml | ./yj -tj | sh 03-create-subnet-for-public.sh | ./yj -jt 1> output-03.toml

output-04.toml: output-03.toml
	cat output-03.toml | ./yj -tj | sh 04-create-and-attach-internet-gateway.sh | ./yj -jt 1> output-04.toml

output-05.toml: output-04.toml
	cat output-04.toml | ./yj -tj | sh 05-create-and-associate-route-table.sh | ./yj -jt 1> output-05.toml

output-06.toml: output-05.toml
	cat output-05.toml | ./yj -tj | sh 06-create-security-group.sh | ./yj -jt 1> output-06.toml

output-07.toml: output-06.toml
	cat output-06.toml | ./yj -tj | sh 07-create-instance-profile.sh | ./yj -jt 1> output-07.toml

output-08.toml: output-07.toml
	cat output-07.toml | ./yj -tj | sh 08-create-iam-role-and-attach-to-instance-profile.sh | ./yj -jt 1> output-08.toml

output-09.toml: output-08.toml
	cat output-08.toml | ./yj -tj | sh 09-run-ec2.sh | ./yj -jt 1> output-09.toml

output-10.toml: output-09.toml
	cat output-09.toml | ./yj -tj | sh 10-create-iam-policy-and-attach-to-role.sh | ./yj -jt 1> output-10.toml

output-11.toml: output-10.toml
	cat output-10.toml | ./yj -tj | sh 11-create-subnet-for-database.sh | ./yj -jt 1> output-11.toml

output-12.toml: output-11.toml
	cat output-11.toml | ./yj -tj | sh 12-create-security-group-for-database.sh | ./yj -jt 1> output-12.toml

output-13.toml: output-12.toml
	cat output-12.toml | ./yj -tj | sh 13-create-db-subnet-group.sh #| ./yj -jt 1> output-13.toml




.PHONY: cleanup
cleanup:
	@echo '---------------------------------------------[delete database subnet group]'
	aws rds describe-db-subnet-groups | jq '.DBSubnetGroups[].DBSubnetGroupName' | xargs -I {db-subnet-group-name} aws rds delete-db-subnet-group --db-subnet-group-name {db-subnet-group-name}
	@echo '---------------------------------------------[delete ec2 instances]'
	aws ec2 describe-instances --filter Name=instance-state-name,Values=[running,pending] | jq '.Reservations[].Instances[].InstanceId' | xargs -I {instance-id} aws ec2 terminate-instances --instance-ids {instance-id}
	@echo '---------------------------------------------[delete custom security group]'
	aws ec2 describe-security-groups | jq '.SecurityGroups[] | select(.GroupName != "default") | .GroupId' | xargs -I {group-id} aws ec2 delete-security-group --group-id {group-id}
	@echo '---------------------------------------------[delete key pairs]'
	aws ec2 describe-key-pairs | jq '.KeyPairs[].KeyPairId' | xargs -I {key-pair-id} aws ec2 delete-key-pair --key-pair-id {key-pair-id}
	@echo '---------------------------------------------[delete route table associations]'
	aws ec2 describe-route-tables --filter Name=association.main,Values=false | jq '.RouteTables[].Associations[].RouteTableAssociationId' | xargs -I {association-id} aws ec2 disassociate-route-table --association-id {association-id}
	@echo '---------------------------------------------[delete route tables]'
	aws ec2 describe-route-tables | jq '.RouteTables[]' | jq 'select((.Associations | length == 0) or (.Associations[].Main==false))' | jq --raw-output '.RouteTableId' | uniq | xargs -I {route-table-id} aws ec2 delete-route-table --route-table-id {route-table-id}
	@echo '---------------------------------------------[detach internet gateways]'
	export AWS_PAGER="" \
	&& ( aws ec2 describe-internet-gateways | jq '.InternetGateways[] | select(.Attachments[].VpcId != null) | .Attachments[].VpcId, .InternetGatewayId' | xargs -n 2 sh -c 'aws ec2 detach-internet-gateway --vpc-id $$0 --internet-gateway-id $$1 || echo done' )
	@echo '---------------------------------------------[delete internet gateways]'
	aws ec2 describe-internet-gateways | jq '.InternetGateways[].InternetGatewayId' | xargs -I {igw-id} aws ec2 delete-internet-gateway --internet-gateway-id {igw-id}
	@echo '---------------------------------------------[delete internet gateways]'
	aws ec2 describe-subnets | jq '.Subnets[].SubnetId' | xargs -I {subnet-id} aws ec2 delete-subnet --subnet-id {subnet-id}
	@echo '---------------------------------------------[delete vpcs]'
	aws ec2 describe-vpcs | jq '.Vpcs[].VpcId' | xargs -I {vpc-id} aws ec2 delete-vpc --vpc-id {vpc-id}
	rm -f output*.toml

.PHONY: latest-ami
latest-ami:
	@aws ec2 describe-images \
		--query 'reverse(sort_by(Images, &CreationDate))[:1]' \
		--owners amazon \
		--filters 'Name=name,Values=amzn2-ami-hvm-2.0.*-x86_64-gp2'

.PHONY: ssm
ssm: output-10.toml
	rm -f ~/.aws/cli/cache/*
	$(eval EC2_INSTANCE_ID := $(shell cat output-10.toml | ./yj -tj | jq --raw-output '.ec2.instance_id'))
	aws ssm start-session --target $(EC2_INSTANCE_ID)

asahi-minimal-ssm-iam-policy.json:
	aws iam get-policy --policy-arn arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM \
		| jq '.Policy.DefaultVersionId' \
		| xargs -I {version} aws iam get-policy-version --policy-arn arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM --version-id {version} \
		| jq '.PolicyVersion.Document' > asahi-minimal-ssm-iam-policy.json

update-iam-policy: output-10.toml
	cat output-10.toml | ./yj -tj | jq --raw-output '.ec2_instance_profile.iam_role.attached_iam_policies[0].arn' | xargs -I {arn} aws iam create-policy-version --policy-arn {arn} --policy-document file://./asahi-minimal-ssm-iam-policy.json --set-as-default

state-ec2:
	aws ec2 describe-instance-status
