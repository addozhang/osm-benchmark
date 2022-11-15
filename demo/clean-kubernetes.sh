#!/bin/bash

set -aueo pipefail

# shellcheck disable=SC1091
source .env

TIMEOUT="${TIMEOUT:-90s}"

# uninstall ingress pipy
INGRESS_PIPY_NAMESPACE="${INGRESS_PIPY_NAMESPACE:-flomesh}"
helm uninstall fsm --namespace "$INGRESS_PIPY_NAMESPACE" || true
# uninstall ingress nginx
nginx_ingress_namespace="ingress-nginx"
helm uninstall ingress-nginx -n "$nginx_ingress_namespace" || true
# delete demo namespace
kubectl delete ns "$DEMO_NAMESPACE" || true
kubectl wait --for=delete ns/$DEMO_NAMESPACE --timeout=120s
# uninstall osm
osm uninstall mesh -f --mesh-name "$MESH_NAME" --osm-namespace "$K8S_NAMESPACE" --delete-namespace -a || true
kubectl delete ns $MESH_NAME --wait || true
# uninstall linkerd
linkerd viz uninstall | kubectl delete -f - || true
linkerd uninstall | kubectl delete -f - || true
kubectl delete ns linkerd --wait || true
# uninstall istio
istioctl uninstall --purge -y || true
kubectl delete ns istio-system --wait || true
wait