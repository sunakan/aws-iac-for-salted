#!/bin/sh
################################################################################
# Overview
# - Create internet gateway
# - Attach internet gateway to VPC
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
#   "internet_gateway": {
#     "name": "asahi-gateway"
#   }
# }
# ----
#
# Output (format: json)
# ----
# INPUT_JSON + \
# {
#   "internet_gateway": {
#     "internet_gateway_id": "igw-xxxxxx"
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
readonly INTERNET_GATEWAY_NAME=$(echo ${INPUT} | jq --raw-output '.internet_gateway.name')

################################################################################
# Environment variables
################################################################################
export AWS_PAGER=""
export AWS_DEFAULT_OUTPUT="json"
export AWS_DEFAULT_REGION=$(echo ${INPUT} | jq --raw-output '.region')

################################################################################
# Main
################################################################################
readonly internet_gateways=$(aws ec2 describe-internet-gateways --filters Name=attachment.vpc-id,Values=${VPC_ID} | jq --compact-output '.InternetGateways')
if [ "${internet_gateways}" = "[]" ]; then
  aws ec2 create-internet-gateway --tag-specifications "ResourceType=internet-gateway,Tags=[{Key=Name,Value=${INTERNET_GATEWAY_NAME}}]" \
    | jq '.InternetGateway.InternetGatewayId' \
    | xargs -I {igw-id} aws ec2 attach-internet-gateway --vpc-id ${VPC_ID} --internet-gateway-id {igw-id}
fi
readonly internet_gateway_id=$(aws ec2 describe-internet-gateways --filters Name=attachment.vpc-id,Values=${VPC_ID} | jq '.InternetGateways[].InternetGatewayId')
echo ${INPUT} | jq ".internet_gateway |= .+ {\"internet_gateway_id\": ${internet_gateway_id}}"
