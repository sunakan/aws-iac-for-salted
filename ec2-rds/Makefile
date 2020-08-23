all:
	sh ./01-up-vpc.sh                              ./variables.toml
	sh ./02-revoke-default-security-group-rules.sh ./variables.toml
	sh ./03-up-public-subnets.sh                   ./variables.toml
	sh ./04-setup-internet-gateway.sh              ./variables.toml
