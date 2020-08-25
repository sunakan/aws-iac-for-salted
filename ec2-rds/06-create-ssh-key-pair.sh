#!/bin/sh
################################################################################
# Overview
# - Create key pair
#
# Required command tools
# - aws
# - jq
#
# Required input properties example (format: json)
# ----
# {
#   "region": "ap-northeast-1",
#   "ssh_key_pair": {
#     "key_name": "asahi-key"
#   }
# }
# ----
#
# Output (format: json)
# ----
# INPUT_JSON + \
# {
#   "ssh_key_pair": {
#     "key_pair_id": "key-xxxxxx"
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
readonly SSH_KEY_PAIR_NAME=$(echo ${INPUT} | jq --raw-output '.ssh_key_pair.name')
readonly SECRET_KEY_PATH=$(echo ${INPUT} | jq --raw-output '.ssh_key_pair.secret_key_path')

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
aws ec2 describe-key-pairs --key-names ${SSH_KEY_PAIR_NAME} > /dev/null 2>&1
if [ $? -ne 0 ]; then
  set -e
  aws ec2 create-key-pair --key-name ${SSH_KEY_PAIR_NAME} --query 'KeyMaterial' --output text > ${SECRET_KEY_PATH}
fi
set -e
readonly key_pair_id=$(aws ec2 describe-key-pairs --key-names ${SSH_KEY_PAIR_NAME} | jq '.KeyPairs[0].KeyPairId')
echo ${INPUT} | jq ".ssh_key_pair |= .+ {\"key_pair_id\": ${key_pair_id}}"
