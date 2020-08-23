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
# $ sh 05-setup-route-table.sh ./variables.toml
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

################################################################################
# チェック
################################################################################

################################################################################
# メイン
################################################################################
#aws ec2 create-route-table --vpc-id vpc-xxxxxxx
#aws ec2 create-route --route-table-id rtb-xxxxxx --destination-cidr-block 0.0.0.0/0 --gateway-id igw-xxxxxx
#aws ec2 associate-route-table  --subnet-id subnet-xxxxxx --route-table-id rtb-xxxxxx
#aws ec2 modify-subnet-attribute --subnet-id subnet-xxxxxx --map-public-ip-on-launch
