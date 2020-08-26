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
#   "ec2": {
#     "instance_id": "i-xxxxxx",
#     "iam_role": {
#       "name": "asahi-role"
#     }
#   },
# }
# ----
#
# Output (format: json)
# ----
# INPUT_JSON + \
# {
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
readonly IAM_ROLE_NAME=$(echo ${INPUT} | jq --raw-output '.ec2.iam_role.name')

################################################################################
# Environment variables
################################################################################
export AWS_PAGER=""
export AWS_DEFAULT_OUTPUT="json"
export AWS_DEFAULT_REGION=$(echo ${INPUT} | jq --raw-output '.region')

################################################################################
# Main
################################################################################
aws iam create-role --role-name ${IAM_ROLE_NAME} --assume-role-policy-document ""
#aws iam attach-role-policy --policy-arn arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM --role-name ${IAM_ROLE_NAME}


