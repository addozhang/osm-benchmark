#!/bin/bash

set -aueo pipefail
source .env

CTR_REGISTRY="${CTR_REGISTRY:-flomesh}"
CTR_TAG="${CTR_TAG:-$OSM_EDGE_VERSION}"

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
curl -sL https://github.com/flomesh-io/osm-edge/releases/download/v$OSM_EDGE_VERSION/osm-edge-v$OSM_EDGE_VERSION-linux-$ARCH.tar.gz | tar -vxzf -
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
    --set=osm.controllerLogLevel="trace" \
    --set=osm.image.registry="$CTR_REGISTRY" \
    --set=osm.image.tag="$CTR_TAG" \
    --set=osm.sidecarImage="flomesh/pipy-nightly:202211101057" \
    --set=osm.pipyRepoImage="flomesh/pipy-repo-nightly:latest" \

# enable permissive traffic mode
./scripts/mesh-enable-permissive-traffic-mode.sh
# exclude eureka, config server port from sidecar traffic intercept
./scripts/mesh-port-exclusion.sh
# change cpu limit of sidecar resources
./scripts/mesh-sidecar-resources.sh
# create app namespace and involve it in mesh
./demo/configure-app-namespace.sh
# Add namespace to mesh
osm namespace add --mesh-name "$MESH_NAME" "$DEMO_NAMESPACE"
# Enable metrics on namespace
osm metrics enable --namespace "$DEMO_NAMESPACE"
# deploy app
./demo/deploy-app.sh
# deploy ingress
./demo/deploy-ingress-nginx.sh
osm namespace add "$INGRESS_NAMESPACE" --mesh-name "$MESH_NAME" --disable-sidecar-injection
# ./demo/deploy-ingress-pipy.sh
./demo/configure-ingressbackend.sh