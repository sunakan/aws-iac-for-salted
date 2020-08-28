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
#   "vpc_database_subnets": {
#     "subnets": [
#       {
#         "name": "asahi-database-a",
#         "cidr": "192.168.140.0/24",
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
readonly VPC_SUBNETS=$(echo ${INPUT} | jq --compact-output --raw-output '.vpc_database_subnets.subnets')

################################################################################
# Environment variables
################################################################################
export AWS_PAGER=""
export AWS_DEFAULT_OUTPUT="json"
export AWS_DEFAULT_REGION=$(echo ${INPUT} | jq --raw-output '.region')

################################################################################
# Main
################################################################################
echo ${VPC_SUBNETS} | jq --compact-output '.[]' | while read subnet; do
  cidr=$(echo ${subnet} | jq --raw-output '.cidr')
  az=$(echo ${subnet}   | jq --raw-output '.az')
  name=$(echo ${subnet} | jq --raw-output '.name')
  aws_subnet_count=$(aws ec2 describe-subnets --filter Name=vpc-id,Values=${VPC_ID} Name=cidr-block,Values=${cidr} | jq '.Subnets | length')
  if [ ${aws_subnet_count} -eq 0 ]; then
    aws ec2 create-subnet --vpc-id ${VPC_ID} --cidr-block ${cidr} --availability-zone ${az} --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=${name}}]" > /dev/null
  fi
done

export TEMP_INPUT="${INPUT}" \
&& echo ${VPC_SUBNETS} | jq --compact-output '.[]' | while read input_subnet; do
  cidr=$(echo ${input_subnet} | jq --raw-output '.cidr')
  subnet=$(aws ec2 describe-subnets --filter Name=vpc-id,Values=${VPC_ID} Name=cidr-block,Values=${cidr} | jq --compact-output '.Subnets[0]')
  name=$(echo ${subnet} | jq '.Tags[] | select(.Key == "Name") | .Value')
  az=$(echo ${subnet} | jq --raw-output '.AvailabilityZone')
  subnet_id=$(echo ${subnet} | jq '.SubnetId')

  b=$(echo ${input_subnet} | jq ".name |= ${name}" | jq --compact-output ". |= .+ {\"subnet_id\": ${subnet_id}}")
  set +u
  a=${a},${b}
  set -u
  echo ${a}
done \
  | tail -n 1 \
  | sed 's/^,//' \
  | xargs -0 -I {subnets} sh -c "echo '${TEMP_INPUT}' | jq '.vpc_database_subnets.subnets |= [{subnets}]'"
