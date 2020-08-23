#!/bin/sh
set -eu
################################################################################
# 概要
# - インターネットゲートウェイの作成
# - インターネットゲートウェイをVPCにアタッチ
# - インターネットゲートウェイのigw-idを記録
#
# 必須コマンド
# - aws
# - yj
# - jq
#
# 実行方法
# $ sh 04-create-internet-gateway.sh ./variables.toml
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

readonly AWS_REGION=$(cat ${AWS_RESOURCE_STATES_FILE_PATH}  | ./yj -tj | jq --raw-output '.region')
readonly VPC_ID=$(cat ${AWS_RESOURCE_STATES_FILE_PATH}      | ./yj -tj | jq --raw-output '.vpc.vpc_id')
readonly INTERNET_GATEWAY_NAME=$(cat ${VARIABLES_FILE_PATH} | ./yj -tj | jq --raw-output '.internet_gateway.name')

################################################################################
# チェック
################################################################################
readonly internet_gateways=$( \
  aws ec2 describe-vpcs --vpc-ids ${VPC_ID} --region ${AWS_REGION} \
  | jq '.Vpcs[].VpcId' \
  | xargs -I {vpc-id} aws ec2 describe-internet-gateways --filters Name=attachment.vpc-id,Values=${VPC_ID} \
  | jq --compact-output '.InternetGateways' \
)
if [ "${internet_gateways}" != "[]" ]; then
  echo VPCにInternetGatewayが既にアタッチされています
  echo ${internet_gateways}
  exit 1
fi

################################################################################
# メイン
################################################################################
aws ec2 create-internet-gateway --tag-specifications "ResourceType=internet-gateway,Tags=[{Key=Name,Value=${INTERNET_GATEWAY_NAME}}]" --output json --region ${AWS_REGION} \
  | jq '.InternetGateway.InternetGatewayId' \
  | xargs -I {igw-id} sh -c "aws ec2 attach-internet-gateway --vpc-id ${VPC_ID} --internet-gateway-id {igw-id} && echo {igw-id}" \
  | xargs -I {igw-id} sh -c "cat ${AWS_RESOURCE_STATES_FILE_PATH} | ./yj -tj | jq '.internet_gateway |= .+ {\"internet_gateway_id\": \"{igw-id}\"}' | ./yj -jt | tee ${AWS_RESOURCE_STATES_FILE_PATH}"
