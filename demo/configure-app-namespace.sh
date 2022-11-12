#!/bin/bash

set -aueo pipefail
source .env

# Create namespace
kubectl create namespace "$DEMO_NAMESPACE" --save-config