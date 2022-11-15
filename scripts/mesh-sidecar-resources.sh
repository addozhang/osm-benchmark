#!/bin/bash

set -aueox pipefail
# shellcheck disable=SC1091
source .env

K8S_NAMESPACE="${K8S_NAMESPACE}"

if [[ -v CPU ]]; then
kubectl patch meshconfig osm-mesh-config -n "$K8S_NAMESPACE" \
  -p '{"spec":{"sidecar":{"resources":{"limits":{"cpu":'$CPU'}}}}}' \
  --type=merge
fi