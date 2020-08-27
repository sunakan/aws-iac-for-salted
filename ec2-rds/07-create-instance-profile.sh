#!/bin/sh
################################################################################
# Overview
# - Create IAM instance profile
#
# Required command tools
# - aws
# - jq
#
# Required input properties example (format: json)
# ----
# {
#   "ec2_instance_profile": {
#     "name": "asahi-instance-profile"
#   }
# }
# ----
#
# Output (format: json)
# ----
# INPUT_JSON + \
# {
#   "ec2_instance_profile": {
#     "instance_profile_id": ""
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
readonly IAM_INSTANCE_PROFILE_NAME=$(echo ${INPUT} | jq --raw-output '.ec2_instance_profile.name')

################################################################################
# Environment variables
################################################################################
export AWS_PAGER=""
export AWS_DEFAULT_OUTPUT="json"

################################################################################
# Main
################################################################################
set +e
aws iam get-instance-profile --instance-profile-name ${IAM_INSTANCE_PROFILE_NAME} > /dev/null 2>&1
if [ $? != 0 ]; then
  aws iam create-instance-profile --instance-profile-name ${IAM_INSTANCE_PROFILE_NAME}
fi
set -e
readonly instance_profile_id=$(aws iam get-instance-profile --instance-profile-name ${IAM_INSTANCE_PROFILE_NAME} | jq '.InstanceProfile.InstanceProfileId')
echo ${INPUT} | jq ".ec2_instance_profile |= .+ {\"instance_profile_id\": ${instance_profile_id}}"
