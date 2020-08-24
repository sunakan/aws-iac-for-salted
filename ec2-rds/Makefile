output-01.toml:
	cat input.toml | ./yj -tj | sh 01-create-vpc.sh | ./yj -jt 1> output-01.toml

output-02.toml: output-01.toml
	cat output-01.toml | ./yj -tj | sh 02-revoke-default-security-group-rules.sh | ./yj -jt 1> output-02.toml

output-03.toml: output-02.toml
	cat output-02.toml | ./yj -tj | sh 03-create-subnet-for-public.sh | ./yj -jt 1> output-03.toml

output-04.toml: output-03.toml
	cat output-03.toml | ./yj -tj | sh 04-create-and-attach-internet-gateway.sh | ./yj -jt 1> output-04.toml

output-05.toml: output-04.toml
	cat output-04.toml | ./yj -tj | sh 05-






.PHONY: cleanup
cleanup:
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
