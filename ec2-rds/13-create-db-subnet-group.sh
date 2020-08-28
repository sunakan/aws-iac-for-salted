#!/bin/sh
################################################################################
# Overview
# - Create database subnet group
#
# Required command tools
# - aws
# - jq
#
# Required input properties example (format: json)
# ----
# {
#   "region": "ap-northeast-1",
#   "vpc": {
#   },
#   "custom_security_group_for_database": {
#   }
# }
# ----
#
# Output (format: json)
# ----
# INPUT_JSON
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
readonly DB_SUBNET_GROUP_NAME=$(echo ${INPUT} | jq --raw-output '.database_subnet_group.group_name')
readonly DB_SUBNET_GROUP_DESCRIPTION="$(echo ${INPUT} | jq --raw-output '.database_subnet_group.description')"
readonly SUBNET_IDS="$(echo ${INPUT} | jq --compact-output --raw-output '[.vpc_database_subnets.subnets[].subnet_id'])"
readonly DB_SUBNET_GROUP_TAG_NAME=$(echo ${INPUT} | jq --raw-output '.database_subnet_group.name')

################################################################################
# Environment variables
################################################################################
export AWS_PAGER=""
export AWS_DEFAULT_OUTPUT="json"
export AWS_DEFAULT_REGION=$(echo ${INPUT} | jq --raw-output '.region')

################################################################################
# Main
################################################################################
readonly same_group_name_count=$(aws rds describe-db-subnet-groups | jq ".DBSubnetGroups[] | [select(.DBSubnetGroupName == \"${DB_SUBNET_GROUP_NAME}\")] | length")

if [ -z ${same_group_name_count} ]; then
  aws rds create-db-subnet-group \
    --db-subnet-group-name ${DB_SUBNET_GROUP_NAME} \
    --db-subnet-group-description "${DB_SUBNET_GROUP_DESCRIPTION}" \
    --subnet-ids ${SUBNET_IDS} \
    --tags Key=Name,Value=${DB_SUBNET_GROUP_TAG_NAME} > /dev/null
fi

echo ${INPUT} | jq '.'
