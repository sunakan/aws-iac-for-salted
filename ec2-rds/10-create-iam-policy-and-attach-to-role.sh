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
#   "ec2_instance_profile": {
#     "iam_role" {
#       "name": "asahi-ec2-instance-role",
#       "attached_iam_policies": [
#         {
#           "name": "asahi-minimal-ssm-iam-policy",
#           "iam_policy_file_path": "./asahi-minimal-ssm-iam-policy.json"
#         }
#       ]
#     }
#   }
# }
# ----
#
# Output (format: json)
# ----
# INPUT_JSON + \
# {
#   "ec2": {
#     "instance_id": "i-xxxxxx"
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
readonly IAM_POLICIES=$(echo ${INPUT} | jq --compact-output --raw-output '.ec2_instance_profile.iam_role.attached_iam_policies')

################################################################################
# Environment variables
################################################################################
export AWS_PAGER=""
export AWS_DEFAULT_OUTPUT="json"
export AWS_DEFAULT_REGION=$(echo ${INPUT} | jq --raw-output '.region')

################################################################################
# Main
################################################################################
export TEMP_INPUT="${INPUT}" \
&& echo "${IAM_POLICIES}" | jq --compact-output '.[]' | while read inputted_iam_policy; do
  #{"name":"asahi-minimal-ssm-iam-policy","iam_policy_file_path":"./asahi-minimal-ssm-iam-policy.json"}
  readonly iam_policy_name=$(echo ${inputted_iam_policy} | jq --raw-output '.name')
  readonly iam_policy_file_path=$(echo ${inputted_iam_policy} | jq --raw-output '.iam_policy_file_path')
  iam_policy="$(aws iam list-policies --scope Local | jq --compact-output ".Policies[] | select(.PolicyName == \"${iam_policy_name}\")")"
  if [ -z ${iam_policy} ]; then
    aws iam create-policy --policy-name ${iam_policy_name} --policy-document file://${iam_policy_file_path}
  fi
  iam_policy="$(aws iam list-policies --scope Local | jq --compact-output ".Policies[] | select(.PolicyName == \"${iam_policy_name}\")")"
  iam_policy_arn=$(echo ${iam_policy} | jq --raw-output '.Arn')
  aws iam attach-role-policy --role-name ${IAM_ROLE_NAME} --policy-arn ${iam_policy_arn}

  b=$(echo ${inputted_iam_policy} | jq ". |= .+ {\"arn\": \"${iam_policy_arn}\"}")
  set +u
  if [ -z "${a}" ]; then
    a=${b}
  else
    a=${a},${b}
  fi
  set -u
  echo ${a}
done \
  | tail -n 1 \
  | xargs -0 -I {iam_policies} sh -c "echo '${TEMP_INPUT}' | jq '.ec2_instance_profile.iam_role.attached_iam_policies |= [{iam_policies}]'"
