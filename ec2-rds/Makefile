all:
	@make --no-print-directory 01-create-vpc

.PHONY: 01-create-vpc
01-create-vpc:
	cat input.toml | ./yj -tj | sh 01-create-vpc.sh | ./yj -jt > output-01.toml






.PHONY: cleanup
cleanup:
	export AWS_PAGER="" \
	&& ( \
		aws ec2 describe-vpcs --output json \
		| jq '.Vpcs[].VpcId' \
		| xargs -I {vpc-id} aws ec2 delete-vpc --vpc-id {vpc-id} \
		&& echo done \
	)
