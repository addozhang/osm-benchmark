#!/bin/bash

set -aueo pipefail
source .env

#install linkerd cli
curl --proto '=https' --tlsv1.2 -sSfL https://run.linkerd.io/install | sh
export PATH=$PATH:$HOME/.linkerd2/bin
linkerd version

# clean up
./demo/clean-kubernetes.sh

# install linkerd
linkerd install --crds | kubectl apply -f -
linkerd install | kubectl apply -f -

# create namespace
kubectl create namespace "$DEMO_NAMESPACE" --save-config
# deploy app
./demo/deploy-app.sh
# deploy ingress
./demo/deploy-ingress-nginx.sh

kubectl get -n "$DEMO_NAMESPACE" deploy samples-api-gateway samples-bookinfo-ratings -o yaml | linkerd inject - | kubectl apply -f -