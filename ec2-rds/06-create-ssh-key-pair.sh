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
SSH_KEY_PAIR_NAME=$(echo ${INPUT} | jq --raw-output '.ssh_key_pair.name')
SECRET_KEY_PATH=$(echo ${INPUT} | jq --raw-output '.ssh_key_pair.secret_key_path')

################################################################################
# Environment variables
################################################################################
export AWS_PAGER=""
export AWS_DEFAULT_OUTPUT="json"
export AWS_DEFAULT_REGION=$(echo ${INPUT} | jq --raw-output '.region')

################################################################################
# Main
################################################################################
readonly key_pair_id=$(aws ec2 describe-key-pairs --key-names ${SSH_KEY_PAIR_NAME} --query 'KeyPairs[0].KeyPairId' 2> /dev/null || echo 'nothing')
if [ "${key_pair_id}" = "nothing" ]; then
  aws ec2 create-key-pair --key-name ${SSH_KEY_PAIR_NAME} --query 'KeyMaterial' --output text > ${SECRET_KEY_PATH}
  echo $(aws ec2 describe-key-pairs --key-names ${SSH_KEY_PAIR_NAME} --query 'KeyPairs[0].KeyPairId')
else
  echo ${key_pair_id}
fi
