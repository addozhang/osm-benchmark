#!/bin/bash

set -aueo pipefail
source .env

#install linkerd cli
if [ ! command -v linkerd &> /dev/null ] || [ ! "$(printf '%s' "$LINKERD2_VERSION")" = $(linkerd version | head -n1 | cut -d":" -f2) ]
then
  echo "Downloading and installing Linkerd $LINKERD2_VERSION"
  curl --proto '=https' --tlsv1.2 -sSfL https://run.linkerd.io/install | LINKERD2_VERSION=$LINKERD2_VERSION sh
  sudo cp $HOME/.linkerd2/bin/linkerd /usr/local/bin/linkerd
  linkerd version
else
  echo "Skipping - Linkderd version $LINKERD2_VERSION already exists"
fi

# clean up
./demo/clean-kubernetes.sh

# install linkerd
linkerd install --crds | kubectl apply -f -
linkerd install | kubectl apply -f -

sleep 5
kubectl wait --namespace linkerd \
  --for=condition=ready pod \
  --selector=linkerd.io/control-plane-ns=linkerd \
  --timeout=600s  

# create namespace
./demo/configure-app-namespace.sh
kubectl annotate namespace "$DEMO_NAMESPACE" linkerd.io/inject=enabled
# deploy app
./demo/deploy-app.sh
# deploy ingress
./demo/deploy-ingress-nginx.sh