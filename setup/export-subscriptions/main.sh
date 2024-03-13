#!/bin/bash

set -o errexit
set -o pipefail
# set -o xtrace # For debugging

if [ -z "$storage_id" ]
then
  echo "ストレージのリソースIDを入力してください:"
  read storage_id
fi

if [ -z "$containerName" ]
then
  echo "ストレージのコンテナ名を入力してください。コンテナは事前に作成しておく必要があります:"
  read containerName
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

while IFS=, read subscriptionId
do
    SUBSCRIPTION_ID=$subscriptionId \
    STORAGE_ID=$storage_id \
    CONTAINER_NAME=$containerName \
    CHECK_EXECUTE_MONTH=$check_execute_month \
    CHECK_EXECUTE_OVERWRITE=$check_execute_overwrite \
        bash ./scripts/costexport_subscription.sh
done < subscriptions.csv