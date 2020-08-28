#!/bin/sh
################################################################################
# Overview
# - Create security group for database
# - Add rule
#
# Required command tools
# - aws
# - jq
#
# Required input properties example (format: json)
# ----
# {
#   "region": "ap-northeast-1",
#   "vpc": {
#     "vpc_id": "vpc-xxxxxxx"
#   },
#   "custom_security_group_for_database": {
#     "name": "asahi-sg",
#     "group_name": "asahi-sg",
#     "description": "For asahi only."
#   }
# }
# ----
#
# Output (format: json)
# ----
# INPUT_JSON + \
# {
#   "custom_security_group_for_database": {
#     "security_group_id": "sg-xxxxxx"
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
readonly VPC_CIDR=$(echo ${INPUT} | jq --raw-output '.vpc.cidr')
readonly SECURITY_GROUP_NAME=$(echo ${INPUT}         | jq --raw-output '.custom_security_group_for_database.group_name')
readonly SECURITY_GROUP_TAG_NAME=$(echo ${INPUT}     | jq --raw-output '.custom_security_group_for_database.name')
readonly SECURITY_GROUP_DESCRIPTION="$(echo ${INPUT} | jq --raw-output '.custom_security_group_for_database.description')"

################################################################################
# Environment variables
################################################################################
export AWS_PAGER=""
export AWS_DEFAULT_OUTPUT="json"
export AWS_DEFAULT_REGION=$(echo ${INPUT} | jq --raw-output '.region')

################################################################################
# Main
################################################################################

readonly custom_security_group_count=$(aws ec2 describe-security-groups --filter Name=vpc-id,Values=${VPC_ID} Name=group-name,Values=${SECURITY_GROUP_NAME} | jq '.SecurityGroups | length')
if [ "${custom_security_group_count}" -eq 0 ]; then
  aws ec2 create-security-group \
    --group-name ${SECURITY_GROUP_NAME} \
    --description "${SECURITY_GROUP_DESCRIPTION}" \
    --vpc-id ${VPC_ID} \
    --tag-specifications "ResourceType=security-group,Tags=[{Key=Name,Value=${SECURITY_GROUP_TAG_NAME}}]" > /dev/null
fi

readonly security_group="$(aws ec2 describe-security-groups --filter Name=vpc-id,Values=${VPC_ID} Name=group-name,Values=${SECURITY_GROUP_NAME} | jq --raw-output --compact-output '.SecurityGroups[0]' | xargs -d '\n' -I {} echo {})"
readonly security_group_id=$(echo "${security_group}" | jq --raw-output --compact-output '.GroupId')
readonly security_group_ippermissions_count=$(echo ${security_group} | jq '.IpPermissions | length')

if [ "$security_group_ippermissions_count" -eq 0 ]; then
  aws ec2 authorize-security-group-ingress --group-id ${security_group_id} --protocol tcp --port 3306 --cidr ${VPC_CIDR}
fi

echo ${INPUT} | jq ".custom_security_group_for_database |= .+ {\"security_group_id\": \"${security_group_id}\"}"
