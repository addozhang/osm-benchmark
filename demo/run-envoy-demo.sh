#!/bin/bash

set -aueo pipefail
source .env

K8S_NAMESPACE="${K8S_NAMESPACE:-osm-system}"
MESH_NAME="${MESH_NAME:-osm}"
IMAGE_PULL_POLICY="${IMAGE_PULL_POLICY:-IfNotPresent}"
SIDECAR_LOG_LEVEL="${SIDECAR_LOG_LEVEL:-error}"
TIMEOUT="${TIMEOUT:-300s}"

# clean up
./demo/clean-kubernetes.sh

# delete previous download
rm -rf ./Linux-amd64 ./linux-amd64

release=v1.1.0
curl -sL https://github.com/openservicemesh/osm/releases/download/${release}/osm-${release}-linux-amd64.tar.gz | tar -vxzf -
cp ./linux-amd64/osm /usr/local/bin/osm

osm install \
    --mesh-name "$MESH_NAME" \
    --osm-namespace "$K8S_NAMESPACE" \
    --verbose \
    --set=osm.enablePermissiveTrafficPolicy=true \
    --set=osm.enableDebugServer="false" \
    --set=osm.enableEgress="false" \
    --set=osm.enableReconciler="false" \
    --set=osm.deployGrafana="false" \
    --set=osm.deployJaeger="false" \
    --set=osm.tracing.enable="false" \
    --set=osm.enableFluentbit="false" \
    --set=osm.deployPrometheus="false" \
    --set=osm.controllerLogLevel="trace" \
    --timeout="$TIMEOUT"    

# enable permissive traffic mode
./scripts/mesh-enable-permissive-traffic-mode.sh
# exclude eureka, config server port from sidecar traffic intercept
./scripts/mesh-port-exclusion.sh
# change cpu limit of sidecar resources
./scripts/mesh-sidecar-resources.sh
# create app namespace and involve it in mesh
./demo/configure-app-namespace.sh
# deploy app
./demo/deploy-app.sh
# deploy ingress
./demo/deploy-ingress-nginx.sh
# ./demo/deploy-ingress-pipy.sh