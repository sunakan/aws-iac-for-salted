#!/bin/sh
set -eu
################################################################################
# 概要
# - VPC作成時に自動で作られるdefault security groupのルールを全削除する
#   - IpPermissionsの削除（インバウンドルール）
#   - IpPermissionsEgressの削除（アウトバウンドルール）
#
# 必須コマンド
# - aws
# - rq
# - jq
#
# 実行方法
# $ sh 02-revoke-default-security-group-rules.sh
################################################################################

################################################################################
# 環境変数
################################################################################
export AWS_PAGER=""

################################################################################
# 変数
################################################################################
readonly AWS_RESOURCE_STATES_FILE_PATH=$(cat ./variables.toml | rq -tJ | jq --raw-output '.aws_resource_states_file_path')
if [ ! -e "${AWS_RESOURCE_STATES_FILE_PATH}" ]; then
  echo "${AWS_RESOURCE_STATES_FILE_PATH}がありません"
  echo "sh 01-up-vpc.sh"
  exit 1
fi

readonly AWS_REGION=$(cat ${AWS_RESOURCE_STATES_FILE_PATH} | rq -tJ | jq --raw-output '.region')
readonly VPC_ID=$(cat ${AWS_RESOURCE_STATES_FILE_PATH}     | rq -tJ | jq --raw-output '.vpc.vpc_id')
if [ "${VPC_ID}" = "null" ]; then
  echo "VPCが未作成のようです"
  echo "sh 01-up-vpc.sh"
  exit 1
fi

# メイン
readonly DEFAULT_SG_ID=$(aws ec2 describe-security-groups --filters "Name=vpc-id,Values=${VPC_ID}" --region ${AWS_REGION} | jq --raw-output '.SecurityGroups[] | select(.GroupName = "default") | .GroupId')
aws ec2 describe-security-groups --output json --group-ids ${DEFAULT_SG_ID} --region ${AWS_REGION} \
  | jq --raw-output --compact-output '.SecurityGroups[].IpPermissions' \
  | awk '$0!="[]"' \
  | xargs -0 -I {ip-permissions} aws ec2 revoke-security-group-ingress --group-id ${DEFAULT_SG_ID} --ip-permissions '{ip-permissions}' --region ${AWS_REGION}

aws ec2 describe-security-groups --output json --group-ids ${DEFAULT_SG_ID} --region ${AWS_REGION} \
  | jq --raw-output --compact-output '.SecurityGroups[].IpPermissionsEgress' \
  | awk '$0!="[]"' \
  | xargs -0 -I {ip-permissions} aws ec2 revoke-security-group-egress --group-id ${DEFAULT_SG_ID} --ip-permissions '{ip-permissions}' --region ${AWS_REGION}

cat ${AWS_RESOURCE_STATES_FILE_PATH} \
  | rq -tJ \
  | jq ".vpc.default_security_group_id |=\"${DEFAULT_SG_ID}\"" \
  | rq -jT \
  | tee ${AWS_RESOURCE_STATES_FILE_PATH}
