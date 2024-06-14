#!/bin/bash

set -o errexit
set -o pipefail
# set -o xtrace # For debugging

if [ -z "$storage_id" ]
then
  echo "ストレージのリソースIDを入力してください:"
  read storage_id
fi

# 入力確認
if [ -z "$storage_id" ]; then
  echo "リソースIDの入力が確認できませんでした。"
  exit 1
fi

if [ -z "$containerName" ]
then
  echo "ストレージのコンテナ名を入力してください。コンテナは事前に作成しておく必要があります。"
  echo "未入力の場合はcost-managementが指定されます:"
  read containerName
fi
if [ -z "$containerName" ]; then
  echo "未入力のため cost-management が指定されました
"
  containerName='cost-management'
fi

if [ -z "$check_execute_month" ]
then
  echo "先月のコスト出力を実行する場合は、yesを入力してください。それ以外の場合は何も入力せずにEnterを押してください:"
  read check_execute_month
fi

if [ -z "$check_execute_overwrite" ]
then
  echo "既存のエクスポート設定を上書きする場合は、yesを入力してください。それ以外の場合は何も入力せずにEnterを押してください:"
  read check_execute_overwrite
fi

if [ -z "$input_hour" ]
then
  echo "0から23の数字でエクスポート予定時刻を入力してください (例: 0)。"
  echo "未入力の場合は0が指定されます:"
  read input_hour
fi
# 入力が空の場合は0を設定
if [ -z "$input_hour" ]; then
  echo "未入力のため0時が指定されました
"
  input_hour=0
fi

# 入力が数字かどうかを確認
if ! [[ "$input_hour" =~ ^[0-9]+$ ]]; then
  echo "無効な入力です。数字を入力してください。"
  exit 1
fi

# 時間が0から23の範囲内か確認
if [ "$input_hour" -lt 0 ] || [ "$input_hour" -gt 23 ]; then
  echo "無効な入力です。0から23の範囲内の数字を入力してください。"
  exit 1
fi

# 現在のJSTの日付と時間を取得
current_date=$(date -d "9 hours" +%Y-%m-%d)
current_hour=$(date -d "9 hours" +%H)

# 翌日の日付を取得
next_date=$(date -d "$current_date +1 day" +%Y-%m-%d)

# 入力された時間が現在の時間より前の場合は翌日の日付を使用
if [ "$input_hour" -le "$current_hour" ]; then
  jst_datetime="$next_date $input_hour:00:00 +0900"
else
  jst_datetime="$current_date $input_hour:00:00 +0900"
fi

# JSTの日付時刻を表示
echo "JSTの日付時刻: $jst_datetime"

# JSTの日付時刻をUTCに変換
utc_datetime=$(date -d "$jst_datetime" -u +"%Y-%m-%dT%H:%M:%SZ")

echo "スケジュールは $jst_datetime (UTC: $utc_datetime ) に実行されます。Azure の負荷状況によりずれる場合があります

"

while IFS=, read subscriptionId
do
    SUBSCRIPTION_ID=$subscriptionId \
    STORAGE_ID=$storage_id \
    CONTAINER_NAME=$containerName \
    CHECK_EXECUTE_MONTH=$check_execute_month \
    CHECK_EXECUTE_OVERWRITE=$check_execute_overwrite \
    TARGET_DATETIME=$utc_datetime \
        bash ./scripts/costexport_subscription.sh
done < subscriptions.csv

echo "エクスポート設定が完了しました。"

