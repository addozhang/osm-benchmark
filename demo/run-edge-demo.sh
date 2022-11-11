#!/bin/bash

set -aueo pipefail
source .env

CTR_REGISTRY="${CTR_REGISTRY:-flomesh}"
CTR_TAG="${CTR_TAG:-latest}"

K8S_NAMESPACE="${K8S_NAMESPACE:-osm-edge-system}"
MESH_NAME="${MESH_NAME:-osm-edge}"
IMAGE_PULL_POLICY="${IMAGE_PULL_POLICY:-Always}"
SIDECAR_LOG_LEVEL="${SIDECAR_LOG_LEVEL:-error}"
TIMEOUT="${TIMEOUT:-300s}"
ARCH=$(dpkg --print-architecture)
# clean up
./demo/clean-kubernetes.sh

# delete previous download
rm -rf ./Linux-$ARCH ./linux-$ARCH
curl -sL https://github.com/flomesh-io/osm-edge/releases/download/$OSM_EDGE_VERSION/osm-edge-$OSM_EDGE_VERSION-linux-$ARCH.tar.gz | tar -vxzf -
sudo cp ./linux-$ARCH/osm /usr/local/bin/osm

osm install \
    --mesh-name "$MESH_NAME" \
    --osm-namespace "$K8S_NAMESPACE" \
    --verbose \
    --set=osm.enablePermissiveTrafficPolicy=true \
    --set=osm.image.pullPolicy="$IMAGE_PULL_POLICY" \
    --set=osm.enableDebugServer="false" \
    --set=osm.enableEgress="false" \
    --set=osm.enableReconciler="false" \
    --set=osm.deployGrafana="false" \
    --set=osm.deployJaeger="false" \
    --set=osm.tracing.enable="false" \
    --set=osm.enableFluentbit="false" \
    --set=osm.deployPrometheus="false" \
    --set=osm.sidecarLogLevel="$SIDECAR_LOG_LEVEL" \
    --set=osm.controllerLogLevel="trace"

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
osm namespace add "$INGRESS_NAMESPACE" --mesh-name "$MESH_NAME" --disable-sidecar-injection
./demo/deploy-ingress-nginx.sh
# ./demo/deploy-ingress-pipy.sh
./demo/configure-ingressbackend.sh