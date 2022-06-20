#!/bin/bash

# shellcheck disable=SC1091
source .env

K8S_NAMESPACE="${K8S_NAMESPACE}"

kubectl patch meshconfig osm-mesh-config -n $K8S_NAMESPACE \
  -p '{"spec":{"traffic":{"outboundPortExclusionList":[8761,8888], "inboundPortExclusionList":[9080,10000]}}}' \
  --type=merge