#!/bin/sh
################################################################################
# Overview
# - Delete default security group's rules
#   - Delete default security group's IpPermissions
#   - Delete default security group's IpPermissionsEgress
#
# Required input properties example (format: json)
# - aws
# - jq
#
# Required input properties example (format: json)
# {
#   "region": "ap-northeast-1",
#   "vpc": {
#     "vpc_id": "vpc-xxxxxxx"
#   }
# }
#
# Output (format: json)
# ----
# INPUT_JSON + \
# {
#   "vpc": {
#     "default_security_group_id": "sg-xxxxxxx"
#   }
# }
# ----

################################################################################

set -eu
################################################################################
# Input
################################################################################
read INPUT
readonly INPUT

################################################################################
# Variables
################################################################################
readonly VPC_ID=$(echo ${INPUT} | jq --raw-output '.vpc.vpc_id')
readonly DEFAULT_SECURITY_GROUP_ID=$(aws ec2 describe-security-groups --filters "Name=vpc-id,Values=${VPC_ID}" | jq --raw-output '.SecurityGroups[] | select(.GroupName = "default") | .GroupId')

################################################################################
# Environment variables
################################################################################
export AWS_PAGER=""
export AWS_DEFAULT_OUTPUT="json"
export AWS_DEFAULT_REGION=$(echo ${INPUT} | jq --raw-output '.region')

################################################################################
# Main
################################################################################
aws ec2 describe-security-groups --group-ids ${DEFAULT_SECURITY_GROUP_ID} \
  | jq --raw-output --compact-output '.SecurityGroups[].IpPermissions' \
  | awk '$0!="[]"' \
  | xargs -0 -I {ip-permissions} aws ec2 revoke-security-group-ingress --group-id ${DEFAULT_SECURITY_GROUP_ID} --ip-permissions '{ip-permissions}'

aws ec2 describe-security-groups --group-ids ${DEFAULT_SECURITY_GROUP_ID} \
  | jq --raw-output --compact-output '.SecurityGroups[].IpPermissionsEgress' \
  | awk '$0!="[]"' \
  | xargs -0 -I {ip-permissions} aws ec2 revoke-security-group-egress --group-id ${DEFAULT_SECURITY_GROUP_ID} --ip-permissions '{ip-permissions}'

echo ${INPUT} | jq ".vpc.default_security_group_id |=\"${DEFAULT_SECURITY_GROUP_ID}\""
