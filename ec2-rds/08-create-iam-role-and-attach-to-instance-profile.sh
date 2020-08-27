#!/bin/sh
################################################################################
# Overview
# - Create IAM role for ec2 instance profile
# - Attach IAM role to instance profile
#
# Required command tools
# - aws
# - jq
#
# Required input properties example (format: json)
# ----
# {
#   "ec2_instance_profile": {
#     "name": "asahi-instance-profile",
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
readonly INSTANCE_PROFILE_NAME=$(echo ${INPUT} | jq --raw-output '.ec2_instance_profile.name')
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

readonly instance_profile_roles_count=$(aws iam get-instance-profile --instance-profile-name ${INSTANCE_PROFILE_NAME} | jq '.InstanceProfile.Roles | length')
if [ ${instance_profile_roles_count} -eq 0 ]; then
  aws iam add-role-to-instance-profile --instance-profile-name ${INSTANCE_PROFILE_NAME} --role-name ${IAM_ROLE_NAME}
fi

readonly iam_role_id=$(aws iam get-role --role-name ${IAM_ROLE_NAME} | jq '.Role.RoleId')
echo ${INPUT} | jq ".ec2_instance_profile.iam_role |= .+ {\"iam_role_id\": ${iam_role_id}}"
