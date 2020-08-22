#!/bin/sh
set -eu
################################################################################
# 概要
# - VPCを作成する
# - AWS_RESOURCE_STATES_FILE_PATHにvpc_idを記録
#
# 必須コマンド
# - aws
# - rq
# - jq
#
# 実行方法
# $ sh 01-up-vpc.sh
################################################################################

################################################################################
# 環境変数
################################################################################
export AWS_PAGER=""

################################################################################
# 固定値
################################################################################
readonly AWS_RESOURCE_STATES_FILE_PATH=$(cat ./variables.toml | rq -tJ | jq --raw-output '.aws_resource_states_file_path')
readonly AWS_REGION=$(cat ./variables.toml | rq -tJ | jq --raw-output '.region')
readonly VPC_NAME=$(cat ./variables.toml   | rq -tJ | jq --raw-output '.vpc.name')
readonly VPC_CIDR=$(cat ./variables.toml   | rq -tJ | jq --raw-output '.vpc.cidr')

# 事前チェック
if [ -f "${AWS_RESOURCE_STATES_FILE_PATH}" ]; then
  readonly VPC_ID=$(cat ${AWS_RESOURCE_STATES_FILE_PATH} | rq -tJ | jq '.vpc.vpc_id')
  if [ "${VPC_ID}" != "null" ]; then
    echo "既に作成済みです"
    echo "$ cat ${AWS_RESOURCE_STATES_FILE_PATH} | rq -tJ | jq --raw-output '{vpc: .vpc}' | rq -jT"
    cat ${AWS_RESOURCE_STATES_FILE_PATH} | rq -tJ | jq --raw-output '{vpc: .vpc}' | rq -jT
    exit 1
  fi
fi

readonly vpc_count=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=${VPC_NAME}" | jq '.Vpcs | length')
if [ ${vpc_count} -gt 0 ] ; then
  echo 既に${VPC_NAME}という名前のVPCが存在するので終わります
  echo '----'
  echo "$ aws ec2 describe-vpcs --filters Name=tag:Name,Values=${VPC_NAME} --filters Name=cidr,Values=${VPC_CIDR} --region ${AWS_REGION} | jq --raw-output '.Vpcs[0].VpcId' | xargs -I {vpc-id} /bin/sh -c \"cat ./variables.toml | rq -tJ | jq '.vpc.vpc_id |= \\\"{vpc-id}\\\"'\" | rq -jT | tee ${AWS_RESOURCE_STATES_FILE_PATH}"
  echo '----'
  exit 1
fi

# メイン
aws ec2 create-vpc --cidr-block ${VPC_CIDR} --tag-specifications "ResourceType=vpc,Tags=[{Key=Name,Value=${VPC_NAME}}]" --output json --region ${AWS_REGION} \
  | jq --raw-output '.Vpc.VpcId' \
  | xargs -I {vpc-id} sh -c "cat ./variables.toml | rq -tJ | jq '.vpc.vpc_id |=\"{vpc-id}\"'" \
  | rq -jT \
  | tee ${AWS_RESOURCE_STATES_FILE_PATH}
