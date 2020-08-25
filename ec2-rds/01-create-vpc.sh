#!/bin/sh
################################################################################
# Overview
# - Create VPC
#
# Required input properties example (format: json)
# - aws
# - jq
#
# Required input properties (format: json)
# ----
# {
#   "region": "ap-northeast-1",
#   "vpc": {
#     "name": "asahi",
#     "cidr": "192.168.0.0/16"
#   }
# }
# ----
#
# Output (format: json)
# ----
# INPUT_JSON + \
# {
#   "vpc":
#     "vpc_id": "vpc-xxx"
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
readonly VPC_NAME=$(echo ${INPUT} | jq --raw-output '.vpc.name')
readonly VPC_CIDR=$(echo ${INPUT} | jq --raw-output '.vpc.cidr')

################################################################################
# Environment variables
################################################################################
export AWS_PAGER=""
export AWS_DEFAULT_OUTPUT="json"
export AWS_DEFAULT_REGION=$(echo ${INPUT} | jq --raw-output '.region')

################################################################################
# Main
################################################################################
readonly vpc_id=$(aws ec2 create-vpc --cidr-block ${VPC_CIDR} --tag-specifications "ResourceType=vpc,Tags=[{Key=Name,Value=${VPC_NAME}}]" | jq '.Vpc.VpcId')
echo ${INPUT} | jq ".vpc.vpc_id |= ${vpc_id}"
