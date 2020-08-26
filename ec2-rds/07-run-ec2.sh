#!/bin/sh
################################################################################
# Overview
# - Run EC2 instance
#
# Required command tools
# - aws
# - jq
#
# Required input properties example (format: json)
# ----
# {
#   "region": "ap-northeast-1",
#   "vpc_public_subnets": {
#     "subnets": [
#       {
#         "subnet_id": "subnet-id-xxxx"
#       }
#     ]
#   },
#   "ec2": {
#     "name": "asahi-instance",
#     "ami": "ami-xxxxxx",
#     "instance_type": "t2.micro",
#   },
#   "custom_security_group": {
#     "security_group_id": "sg-xxxxxx"
#   }
# }
# ----
#
# Output (format: json)
# ----
# INPUT_JSON + \
# {
#   "ec2": {
#     "instance_id": "i-0ff68a3c6ce1c2dc2"
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
readonly AMI_ID=$(echo ${INPUT} | jq --raw-output '.ec2.ami')
readonly EC2_TYPE=$(echo ${INPUT} | jq --raw-output '.ec2.instance_type')
readonly EC2_NAME=$(echo ${INPUT} | jq --raw-output '.ec2.name')
readonly VPC_SUBNET_ID=$(echo ${INPUT} | jq --raw-output '.vpc_public_subnets.subnets[0].subnet_id')
readonly SECURITY_GROUP_ID=$(echo ${INPUT} | jq --raw-output '.custom_security_group.security_group_id')
readonly KEY_NAME=$(echo ${INPUT} | jq --raw-output '.ssh_key_pair.name')

################################################################################
# Environment variables
################################################################################
export AWS_PAGER=""
export AWS_DEFAULT_OUTPUT="json"
export AWS_DEFAULT_REGION=$(echo ${INPUT} | jq --raw-output '.region')

################################################################################
# Main
################################################################################
readonly ec2_instance_count=$(aws ec2 describe-instances --filter Name=subnet-id,Values=${VPC_SUBNET_ID} --filter Name=tag:Name,Values=${EC2_NAME} --filter Name=instance-state-name,Values=[running,pending] | jq '.Reservations[].Instances | length')
if test -z "${ec2_instance_count}" || test ${ec2_instance_count} -eq 0; then
  aws ec2 run-instances \
    --count 1 \
    --image-id ${AMI_ID} \
    --instance-type ${EC2_TYPE} \
    --security-group-ids ${SECURITY_GROUP_ID} \
    --subnet-id ${VPC_SUBNET_ID} \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=${EC2_NAME}}]" > /dev/null
fi

readonly instance_id=$(aws ec2 describe-instances --filter Name=subnet-id,Values=${VPC_SUBNET_ID} --filter Name=tag:Name,Values=${EC2_NAME} --filter Name=instance-state-name,Values=[running,pending] | jq '.Reservations[].Instances[].InstanceId')
echo ${INPUT} | jq ".ec2 |= .+ {\"instance_id\": ${instance_id}}"
