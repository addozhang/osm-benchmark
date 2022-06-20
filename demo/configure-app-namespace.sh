#!/bin/bash

set -aueo pipefail
source .env

DEMO_NAMESPACE="${DEMO_NAMESPACE}"

# Create namespace
kubectl create namespace "$DEMO_NAMESPACE" --save-config
# Add namespace to mesh
# osm namespace add --mesh-name "$MESH_NAME" "$DEMO_NAMESPACE"
# Enable metrics on namespace
# osm metrics enable --namespace "$DEMO_NAMESPACE"