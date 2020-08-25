#!/bin/sh
################################################################################
# Overview
# - Create security group
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
#   "custom_security_group": {
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
#   "custom_security_group": {
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
readonly SECURITY_GROUP_NAME=$(echo ${INPUT} | jq --raw-output '.custom_security_group.group_name')
readonly SECURITY_GROUP_TAG_NAME=$(echo ${INPUT} | jq --raw-output '.custom_security_group.name')
readonly SECURITY_GROUP_DESCRIPTION="$(echo ${INPUT} | jq --raw-output '.custom_security_group.description')"

################################################################################
# Environment variables
################################################################################
export AWS_PAGER=""
export AWS_DEFAULT_OUTPUT="json"
export AWS_DEFAULT_REGION=$(echo ${INPUT} | jq --raw-output '.region')

################################################################################
# Main
################################################################################
readonly custom_security_group_count=$(aws ec2 describe-security-groups --filter Name=vpc-id,Values=${VPC_ID} --filter Name=group-name,Values=${SECURITY_GROUP_NAME} | jq '.SecurityGroups | length')
if [ ${custom_security_group_count} -eq 0 ]; then
  aws ec2 create-security-group \
    --group-name ${SECURITY_GROUP_NAME} \
    --description "${SECURITY_GROUP_DESCRIPTION}" \
    --vpc-id ${VPC_ID} \
    --tag-specifications "ResourceType=security-group,Tags=[{Key=Name,Value=${SECURITY_GROUP_TAG_NAME}}]" > /dev/null
fi

readonly security_group_id=$(aws ec2 describe-security-groups --filter Name=vpc-id,Values=${VPC_ID} --filter Name=group-name,Values=${SECURITY_GROUP_NAME} | jq '.SecurityGroups[0].GroupId')
echo ${INPUT} | jq ".custom_security_group |= .+ {\"security_group_id\": ${security_group_id}}"
