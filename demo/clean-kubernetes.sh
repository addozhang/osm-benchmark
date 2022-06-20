#!/bin/bash

set -aueo pipefail

# shellcheck disable=SC1091
source .env

TIMEOUT="${TIMEOUT:-90s}"
INGRESS_PIPY_NAMESPACE="${INGRESS_PIPY_NAMESPACE:-flomesh}"

helm uninstall fsm --namespace "$INGRESS_PIPY_NAMESPACE" || true

osm uninstall mesh -f --mesh-name "$MESH_NAME" --osm-namespace "$K8S_NAMESPACE" --delete-namespace -a
# kubectl delete namespace "$TEST_NAMESPACE" --ignore-not-found --wait --timeout="$TIMEOUT" &

# # Clean up Hashicorp Vault deployment
# kubectl delete deployment vault -n "$K8S_NAMESPACE" --ignore-not-found --wait --timeout="$TIMEOUT" &
# kubectl delete service vault -n "$K8S_NAMESPACE" --ignore-not-found --wait --timeout="$TIMEOUT" &

# kubectl delete deployment vault -n "$INGRESS_PIPY_NAMESPACE" --ignore-not-found --wait --timeout="$TIMEOUT" &
# kubectl delete service vault -n "$INGRESS_PIPY_NAMESPACE" --ignore-not-found --wait --timeout="$TIMEOUT" &
# kubectl delete namespace "$INGRESS_PIPY_NAMESPACE" --ignore-not-found --wait --timeout="$TIMEOUT" &

wait
