while IFS=, read subscriptionId
do
    SUBSCRIPTION_ID=$subscriptionId
    bash ./scripts/costexport_subscription.sh
done < subscriptions.csv