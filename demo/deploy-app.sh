#!/bin/bash

set -aueo pipefail
source .env

# echo "Which demo do you want to install?"
# echo "1 - bookinfo"
# echo "2 - dubbo"
# echo "3 - emojivoto"
# echo ""
# echo "Make your selection: "
# read demo;
demo=$DEMO_TYPE
case $demo in
  1) echo "installing bookinfo demo";
     ./demo/deploy-discovery-server.sh;
     ./demo/deploy-config-service.sh;
     # wait config server's registration
     sleep 30;
     ./demo/deploy-gateway.sh;
      # ./demo/deploy-bookinfo-details.sh
      # ./demo/deploy-bookinfo-productpage.sh
     ./demo/deploy-bookinfo-ratings.sh;
      # ./demo/deploy-bookinfo-reviews.sh
    ;;
  2) echo "installing dubbo demo";
     ./demo/deploy-echo-dubbo-server.sh;
     ./demo/deploy-echo-dubbo-consumer.sh;
     ;;
  3) echo "install emojivoto";
    ./demo/deploy-emojivoto.sh;
    ;;
  *) echo "unknown selection"; exit 1 ;;
esac

sleep 5
kubectl wait --namespace $DEMO_NAMESPACE \
  --for=condition=ready pod \
  --selector=type=app \
  --timeout=600s