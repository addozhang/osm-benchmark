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
     ./demo/deploy-sc-bookinfo.sh;
    ;;
  2) echo "installing dubbo demo";
     ./demo/deploy-dubbo;
     ;;
  3) echo "install emojivoto";
    ./demo/deploy-emojivoto.sh;
    ;;
  4) echo "install bookinfo";
    ./demo/deploy-bookinfo.sh;
    ;;
  5) echo "install fortio";
    ./demo/deploy-fortio.sh;
    ;;
  *) echo "unknown selection"; exit 1 ;;
esac

sleep 5
kubectl wait --namespace $DEMO_NAMESPACE \
  --for=condition=ready pod \
  --all \
  --timeout=600s