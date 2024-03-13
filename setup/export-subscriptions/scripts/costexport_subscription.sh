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
check_execute_month=$CHECK_EXECUTE_MONTH
check_execute_overwrite=$CHECK_EXECUTE_OVERWRITE

##############################################################
# 定数
version='2023-04-01-preview'
baseUrl=https://management.azure.com
##############################################################
# 変数
exportName_daily=${subscriptionId}_daily
targetURL_daily=${baseUrl}/subscriptions/${subscriptionId}/providers/Microsoft.CostManagement/exports/${exportName_daily}?api-version=2023-04-01-preview
current=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")

body_daily=$(printf '{
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

exportName_monthly=${subscriptionId}_monthly
targetURL_monthly=${baseUrl}/subscriptions/${subscriptionId}/providers/Microsoft.CostManagement/exports/${exportName_monthly}?api-version=2023-04-01-preview
targetURLrun_monthly=${baseUrl}/subscriptions/${subscriptionId}/providers/Microsoft.CostManagement/exports/${exportName_monthly}/run?api-version=2023-11-01
body_monthly=$(printf '{
    "properties": {
        "definition": {
            "dataSet": {
                "granularity": "Daily",
                "grouping": []
            },
            "timeframe": "TheLastBillingMonth",
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
            "recurrence": "Monthly",
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
echo "サブスクリプションID: ${subscriptionId} について、毎日、当月分のコストを出力するエクスポート構成を作成します..."
# 既存のexportを取得して、存在しない場合にputを実行する

resource_daily=$(az rest --method get --url "$targetURL_daily" 2>/dev/null || true) # "get"操作を試みる

if [ -z "$resource_daily" ]; then
    az rest --method put --url "$targetURL_daily" --body "$body_daily"
else
  echo "このサブスクリプションはすでにエクスポート構成済みです。"
  if [ "$check_execute_overwrite" = "yes" ]; then
    echo "既存のエクスポート構成を上書きします..."
    az rest --method put --url "$targetURL_daily" --body "$body_daily"
  fi
fi

echo "サブスクリプションID: ${subscriptionId} について、毎月、前月分のコストを出力するエクスポート構成を作成します..."

resource_monthly=$(az rest --method get --url "$targetURL_monthly" 2>/dev/null || true) # "get"操作を試みる

if [ -z "$resource_monthly" ]; then
    az rest --method put --url "$targetURL_monthly" --body "$body_monthly"
else
  echo "このサブスクリプションはすでにエクスポート構成済みです。"
  if [ "$check_execute_overwrite" = "yes" ]; then
    echo "既存のエクスポート構成を上書きします..."
    az rest --method put --url "$targetURL_monthly" --body "$body_monthly"
  fi
fi

if [ "$check_execute_month" = "yes" ]; then
  echo "先月分のコスト出力を指示します..."
  az rest --method post --url "$targetURLrun_monthly"
  echo "先月分のコスト出力が開始されました。ストレージに出力されるまで時間がかかります..."
fi