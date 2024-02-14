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

while IFS=, read subscriptionId
do
    SUBSCRIPTION_ID=$subscriptionId \
    STORAGE_ID=$storage_id \
    CONTAINER_NAME=$containerName \
        bash ./scripts/costexport_subscription.sh
done < subscriptions.csv