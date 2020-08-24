#!/bin/sh
################################################################################
# Overview
# - Create route table
# - Associate route table to vpc subnet
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
#   "internet_gateway" {
#     "internet_gateway_id": "igw-xxxxxx"
#   },
#   "custom_route_table": {
#     "name": "asahi-route-table"
#   },
#   "vpc_public_subnets": {
#     "subnets": [
#       {"subnet_id": "subnet-xxxxxx"},
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
#   "custom_route_table": {
#     "route_table_id": "-xxxxxx"
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
readonly CUSTOM_ROUTE_TABLE_NAME=$(echo ${INPUT} | jq --raw-output '.custom_route_table.name')
readonly INTERNET_GATEWAY_ID=$(echo ${INPUT} | jq --raw-output '.internet_gateway.internet_gateway_id')

################################################################################
# Environment variables
################################################################################
export AWS_PAGER=""
export AWS_DEFAULT_OUTPUT="json"
export AWS_DEFAULT_REGION=$(echo ${INPUT} | jq --raw-output '.region')

################################################################################
# メイン
################################################################################
aws ec2 create-route-table --vpc-id ${VPC_ID} \
  | jq '.RouteTable.RouteTableId' \
  | xargs -I {route-table-id} aws ec2 create-route --route-table-id {route-table-id} --destination-cidr-block 0.0.0.0/0 --gateway-id ${INTERNET_GATEWAY_ID}
#readonly PUBLIC_SUBNET_IDS=$(echo ${INPUT} | jq '.vpc_public_subnets.subnets[].subnet_id' | jq --slurp --compact-output)
#aws ec2 associate-route-table  --subnet-id subnet-xxxxxx --route-table-id rtb-xxxxxx
#aws ec2 modify-subnet-attribute --subnet-id subnet-xxxxxx --map-public-ip-on-launch
