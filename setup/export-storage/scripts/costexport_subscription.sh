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
PutURL=${baseUrl}/subscriptions/${subscriptionId}/providers/Microsoft.CostManagement/exports/${exportName}?api-version=${version}
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
echo "PutURL: $PutURL"
echo $body
az rest --method put --url "$PutURL" --body "$body"
