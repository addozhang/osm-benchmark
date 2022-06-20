#!/bin/bash

set -aueo pipefail
source .env

./demo/deploy-discovery-server.sh
./demo/deploy-config-service.sh
./demo/deploy-gateway.sh
./demo/deploy-bookinfo-details.sh
./demo/deploy-bookinfo-productpage.sh
./demo/deploy-bookinfo-ratings.sh
./demo/deploy-bookinfo-reviews.sh

sleep 10
kubectl wait --namespace $DEMO_NAMESPACE \
  --for=condition=ready pod \
  --selector=type=app \
  --timeout=600s