#!/bin/sh
################################################################################
# Overview
# - Create IAM role for ec2 instance profile
#
# Required command tools
# - aws
# - jq
#
# Required input properties example (format: json)
# ----
# {
#   "ec2_instance_profile": {
#     "iam_role": {
#       "name": "asahi-ec2-instance-role",
#       "assume_role_policy_file_path": "./ec2-role-trust-policy.json"
#     }
#   }
# }
# ----
#
# Output (format: json)
# ----
# INPUT_JSON + \
# {
#   "ec2_instance_profile": {
#     "iam_role": {
#       "iam_role_id": "xxxxxx"
#     }
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
readonly IAM_ROLE_NAME=$(echo ${INPUT} | jq --raw-output '.ec2_instance_profile.iam_role.name')
readonly ASSUME_ROLE_POLICY_FILE_PATH=$(echo ${INPUT} | jq --raw-output '.ec2_instance_profile.iam_role.assume_role_policy_file_path')

################################################################################
# Environment variables
################################################################################
export AWS_PAGER=""
export AWS_DEFAULT_OUTPUT="json"
export AWS_DEFAULT_REGION=$(echo ${INPUT} | jq --raw-output '.region')

################################################################################
# Main
################################################################################
set +e
aws iam get-role --role-name ${IAM_ROLE_NAME} > /dev/null 2>&1
if [ $? != 0 ]; then
  aws iam create-role --role-name ${IAM_ROLE_NAME} --assume-role-policy-document file://${ASSUME_ROLE_POLICY_FILE_PATH} > /dev/null
fi
set -e
readonly iam_role_id=$(aws iam get-role --role-name ${IAM_ROLE_NAME} | jq '.Role.RoleId')
echo ${INPUT} | jq ".ec2_instance_profile.iam_role |= .+ {\"iam_role_id\": ${iam_role_id}}"
