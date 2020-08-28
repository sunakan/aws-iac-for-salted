#!/bin/sh
################################################################################
# Overview
# - Create subnet for public
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
#   "vpc_public_subnets": {
#     "subnets": [
#       {
#         "name": "asahi-public-a",
#         "cidr": "192.168.1.0/24",
#         "az": "ap-northeast-1a"
#       },
#       ...
#     ]
#   }
# }
# ----
#
# Output (format: json)
# ----
# INPUT_JSON + \
# {
#   "vpc_public_subnets": {
#     "subnets": [
#       {
#         "name": "updated-name-aaa"
#         "subnet_id": "subnet-id-xxxxxx"
#       },
#       ...
#     ]
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
readonly VPC_SUBNETS=$(echo ${INPUT} | jq --compact-output --raw-output '.vpc_public_subnets.subnets')

################################################################################
# Environment variables
################################################################################
export AWS_PAGER=""
export AWS_DEFAULT_OUTPUT="json"
export AWS_DEFAULT_REGION=$(echo ${INPUT} | jq --raw-output '.region')

################################################################################
# Main
################################################################################
echo ${VPC_SUBNETS} | jq --compact-output '.[]' | while read subnet_info; do
  cidr=$(echo ${subnet_info} | jq --raw-output '.cidr')
  az=$(echo ${subnet_info}   | jq --raw-output '.az')
  name=$(echo ${subnet_info} | jq --raw-output '.name')
  aws_subnet_count=$(aws ec2 describe-subnets --filters Name=cidr-block,Values=${cidr} Name=vpc-id,Values=${VPC_ID} | jq --raw-output '.Subnets | length')
  if [ ${aws_subnet_count} -eq 0 ]; then
    aws ec2 create-subnet --vpc-id ${VPC_ID} --cidr-block ${cidr} --availability-zone ${az} --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=${name}}]" > /dev/null
  fi
done

export TEMP_INPUT="${INPUT}" \
&& echo ${VPC_SUBNETS} | jq --compact-output '.[]' | while read subnet_info; do
  cidr=$(echo ${subnet_info} | jq '.cidr')
  aws_subnet_info=$(aws ec2 describe-subnets --filters Name=vpc-id,Values=${VPC_ID} Name=cidr-block,Values=${cidr} | jq --compact-output '.Subnets[0]')
  name=$(echo ${aws_subnet_info} | jq '.Tags[] | select(.Key == "Name") | .Value')
  subnet_id=$(echo ${aws_subnet_info} | jq '.SubnetId')
  subnet_info=$(echo ${subnet_info} | jq ".name |= ${name}" | jq --compact-output ". |= .+ {\"subnet_id\": ${subnet_id}}")
  set +u
  a=${a},${subnet_info}
  set -u
  echo ${a}
done \
  | tail -n 1 \
  | sed 's/^.//' \
  | xargs -0 -I {subnets} sh -c "echo '${TEMP_INPUT}' | jq '.vpc_public_subnets.subnets |= [{subnets}]'"
