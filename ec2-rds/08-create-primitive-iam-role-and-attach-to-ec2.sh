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
#       "name": "asahi-role",
#       "assume_role_policy_file_path": "./asahi-assume-role-policy-document.json",
#       "attached_iam_policies": [
#         {
#           "iam_policy_name": "asahi-policy",
#           "iam_policy_file_path": "./asahi-iam-policy.json"
#         }
#       ]
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
readonly ASSUME_ROLE_POLICY_FILE_PATH=$(echo ${INPUT} | jq --raw-output '.ec2.iam_role.assume_role_policy_file_path')
readonly ATTACHED_IAM_POLICIES=$(echo ${INPUT} | jq --raw-output '.ec2.iam_role.assume_role_policy_file_path')

################################################################################
# Environment variables
################################################################################
export AWS_PAGER=""
export AWS_DEFAULT_OUTPUT="json"
export AWS_DEFAULT_REGION=$(echo ${INPUT} | jq --raw-output '.region')

################################################################################
# Main
################################################################################

#aws iam create-role --role-name ${IAM_ROLE_NAME} --assume-role-policy-document file://./asahi-assume-role-policy-document.json
#aws iam attach-role-policy --policy-arn arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM --role-name ${IAM_ROLE_NAME}

echo ${INPUT} | jq --compact-output '.ec2.iam_role.attached_iam_policies[]' | while read iam_policy; do
  policy_name=$(echo "${iam_policy}" | jq --raw-output '.iam_policy_name')
  policy_file_path=$(echo "${iam_policy}" | jq --raw-output '.iam_policy_file_path')
  aws iam create-policy --policy-name ${policy_name} --policy-document file://${policy_file_path}
done
