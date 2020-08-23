#!/bin/sh
set -eu
################################################################################
# 概要
# - VPC作成時に自動で作られるdefault security groupのルールを全削除する
#   - IpPermissionsの削除（インバウンドルール）
#   - IpPermissionsEgressの削除（アウトバウンドルール）
# - AWS_RESOURCE_STATES_FILEにdefault_security_group_idを記録
#
# 必須コマンド
# - aws
# - yj
# - jq
#
# 実行方法
# $ sh 02-revoke-default-security-group-rules.sh ./variables.toml
#
# 補足：メイン以下でよくわからなくなった場合
#   - 最終行をコメントアウトして実行するとわかる
################################################################################

################################################################################
# 環境変数
################################################################################
export AWS_PAGER=""

################################################################################
# 変数
################################################################################
readonly VARIABLES_FILE_PATH=$1
readonly AWS_RESOURCE_STATES_FILE_PATH=$(cat ${VARIABLES_FILE_PATH} | ./yj -tj | jq --raw-output '.aws_resource_states_file_path')
readonly AWS_REGION=$(cat ${AWS_RESOURCE_STATES_FILE_PATH}          | ./yj -tj | jq --raw-output '.region')
readonly VPC_ID=$(cat ${AWS_RESOURCE_STATES_FILE_PATH}              | ./yj -tj | jq --raw-output '.vpc.vpc_id')
readonly DEFAULT_SG_ID=$(aws ec2 describe-security-groups --filters "Name=vpc-id,Values=${VPC_ID}" --region ${AWS_REGION} | jq --raw-output '.SecurityGroups[] | select(.GroupName = "default") | .GroupId')

################################################################################
# チェック
################################################################################
if [ ! -f "${AWS_RESOURCE_STATES_FILE_PATH}" ]; then
  echo "${AWS_RESOURCE_STATES_FILE_PATH}がありません"
  echo '----'
  grep '$ sh 01' 01-up-vpc.sh | sed -e "s/# //g"
  echo '----'
  exit 1
fi
aws ec2 describe-vpcs --vpc-id ${VPC_ID} --region ${AWS_REGION} > /dev/null \
  || ( \
    echo '構成ドリフトが起きてる可能性があります' \
    && echo '----' \
    && echo "$ rm ${AWS_RESOURCE_STATES_FILE_PATH}" \
    && echo '----' \
    && exit 1 \
  )

################################################################################
# メイン
################################################################################
aws ec2 describe-security-groups --output json --group-ids ${DEFAULT_SG_ID} --region ${AWS_REGION} \
  | jq --raw-output --compact-output '.SecurityGroups[].IpPermissions' \
  | awk '$0!="[]"' \
  | xargs -0 -I {ip-permissions} aws ec2 revoke-security-group-ingress --group-id ${DEFAULT_SG_ID} --ip-permissions '{ip-permissions}' --region ${AWS_REGION}

aws ec2 describe-security-groups --output json --group-ids ${DEFAULT_SG_ID} --region ${AWS_REGION} \
  | jq --raw-output --compact-output '.SecurityGroups[].IpPermissionsEgress' \
  | awk '$0!="[]"' \
  | xargs -0 -I {ip-permissions} aws ec2 revoke-security-group-egress --group-id ${DEFAULT_SG_ID} --ip-permissions '{ip-permissions}' --region ${AWS_REGION}

cat ${AWS_RESOURCE_STATES_FILE_PATH} \
  | ./yj -tj \
  | jq ".vpc.default_security_group_id |=\"${DEFAULT_SG_ID}\"" \
  | ./yj -jt \
  | tee ${AWS_RESOURCE_STATES_FILE_PATH}
