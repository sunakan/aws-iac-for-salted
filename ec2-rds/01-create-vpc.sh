#!/bin/sh
################################################################################
# Overview
# - Create VPC
#
# Required command
# - aws
# - jq
#
# Required input properties (format: json)
# ----
# {
#   "region": string(ex: "ap-northeast-1"),
#   "vpc": {
#     "name": string(ex: "asahi"),
#     "cidr": string(ex: "192.168.0.0/16")
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
#
# How to run
# $ cat input.json | sh 01-up-vpc.sh
################################################################################

set -eu
################################################################################
# Environment variables
################################################################################
export AWS_PAGER=""
export AWS_DEFAULT_OUTPUT="json"

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
# Main
################################################################################
aws ec2 create-vpc \
  --cidr-block ${VPC_CIDR} \
  --tag-specifications "ResourceType=vpc,Tags=[{Key=Name,Value=${VPC_NAME}}]" \
  | jq '.Vpc.VpcId' \
  | xargs -I {vpc-id} sh -c "echo '${INPUT}' | jq '.vpc.vpc_id |= \"{vpc-id}\"'"
