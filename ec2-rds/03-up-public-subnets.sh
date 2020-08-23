#!/bin/sh
set -eu
################################################################################
# 概要
# - パブリックサブネットとなりえるサブネットを作成する
# - AWS_RESOURCE_STATES_FILEにpublic_subnet_idを記録
#
# 必須コマンド
# - aws
# - rq
# - jq
#
# 実行方法
# $ sh 03-up-public-subnets.sh ./variables.toml
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
readonly AWS_RESOURCE_STATES_FILE_PATH=$(cat ${VARIABLES_FILE_PATH} | rq -tJ | jq --raw-output '.aws_resource_states_file_path')

readonly AWS_REGION=$(cat ${AWS_RESOURCE_STATES_FILE_PATH} | rq -tJ | jq --raw-output '.region')
readonly VPC_ID=$(cat ${AWS_RESOURCE_STATES_FILE_PATH}     | rq -tJ | jq --raw-output '.vpc.vpc_id')
readonly VPC_SUBNETS=$(cat ${VARIABLES_FILE_PATH}          | rq -tJ | jq --compact-output --raw-output '.vpc_public_subnets.subnets')

################################################################################
# チェック
################################################################################
# VPC_IDがあるかチェック

################################################################################
# メイン
################################################################################
# 既に作成済みのCIDRのサブネットがあるかもしれない => そこはエラーを許容する(=無視する, set +eする)
set +e
echo ${VPC_SUBNETS} | jq --compact-output '.[]' | while read subnet_info; do
  az=$(echo ${subnet_info}   | jq --raw-output '.az')
  cidr=$(echo ${subnet_info} | jq --raw-output '.cidr')
  name=$(echo ${subnet_info} | jq --raw-output '.name')
  aws ec2 create-subnet --vpc-id ${VPC_ID} --cidr-block ${cidr} --availability-zone ${az} --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=${name}}]" --output json --region ${AWS_REGION} \
    | jq --compact-output --raw-output '.'
done
set -e

# VPC_SUBNETSの情報群にsubnet_idを追加、nameの更新してAWS_RESOURCE_STATES_FILEへ統合させる
# 最初はaという変数が未定義なので、-uのままだと怒られるため解除する
set +u
echo ${VPC_SUBNETS} | jq --compact-output '.[]' | while read subnet_info; do
  cidr=$(echo ${subnet_info} | jq '.cidr')
  aws_subnet_info=$(aws ec2 describe-subnets --filters Name=vpc-id,Values=${VPC_ID} --filters Name=cidr-block,Values=${cidr} --region ${AWS_REGION} | jq --compact-output '.Subnets[0]')
  name=$(echo ${aws_subnet_info} | jq '.Tags[] | select(.Key == "Name").Value')
  subnet_id=$(echo ${aws_subnet_info} | jq '.SubnetId')
  subnet_info=$(echo ${subnet_info} | jq ".name |= ${name}" | jq --compact-output ". |= .+ {\"subnet_id\": ${subnet_id}}")
  a=${a},${subnet_info}
  echo ${a}
done \
  | tail -n 1 \
  | sed 's/^.//' \
  | xargs -0 -I {subnets} sh -c "cat ${AWS_RESOURCE_STATES_FILE_PATH} | rq -tJ | jq '.vpc_public_subnets.subnets |= [{subnets}]' | rq -jT | tee ${AWS_RESOURCE_STATES_FILE_PATH}"
