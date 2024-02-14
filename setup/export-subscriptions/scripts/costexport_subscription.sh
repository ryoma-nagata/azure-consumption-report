#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace # For debugging

#############################################################
# 引数
subscriptionId=$SUBSCRIPTION_ID
storageId=$STORAGE_ID
containerName=$CONTAINER_NAME

##############################################################
# 定数
version='2023-04-01-preview'
baseUrl=https://management.azure.com
##############################################################
# 変数
exportName=${subscriptionId}_daily
targetURL=${baseUrl}/subscriptions/${subscriptionId}/providers/Microsoft.CostManagement/exports/${exportName}?api-version=${version}
current=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")

body=$(printf '{
    "properties": {
        "definition": {
            "dataSet": {
                "granularity": "Daily",
                "grouping": []
            },
            "timeframe": "MonthToDate",
            "type": "ActualCost"
        },
        "deliveryInfo": {
            "destination": {
                "container": "%s",
                "rootFolderPath": "export",
                "resourceId": "%s"
            }
        },
        "format": "Csv",
        "partitionData": true,
        "schedule": {
            "recurrence": "Daily",
            "recurrencePeriod": {
                "from": "%s",
                "to": "2050-01-01T00:00:00.000Z"
            },
            "status": "Active"
        }
    },
    "type": "Microsoft.CostManagement/reports",
    "identity": {
        "type": "systemAssigned"
    },
    "location": "global"
}' $containerName $storageId $current)

##############################################################

# echo "targetURL: $targetURL"
# echo "body: $body"
echo "サブスクリプションID: ${subscriptionId} のエクスポート構成を作成します"
# 既存のexportを取得して、存在しない場合にputを実行する

resource=$(az rest --method get --url "$targetURL" 2>/dev/null || true) # "get"操作を試みる
if [ -z "$resource" ]; then
    az rest --method put --url "$targetURL" --body "$body"
else
  echo "このサブスクリプションはすでにエクスポート構成済みです"
fi
