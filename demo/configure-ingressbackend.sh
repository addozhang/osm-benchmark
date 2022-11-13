#!/bin/bash

#### For OSM family only ####
set -aueo pipefail

source .env

nginx_ingress_namespace="$INGRESS_NAMESPACE"
nginx_ingress_service="ingress-nginx-controller"

GATEWAY_SERVICE="samples-api-gateway"
DETAILS_SERVICE="samples-bookinfo-details"
REVIEWS_SERVICE="samples-bookinfo-reviews"
RATINGS_SERVICE="samples-bookinfo-ratings"
EMOJIVOTO_SERVICE="web-svc"

kubectl apply -f - <<EOF
kind: IngressBackend
apiVersion: policy.openservicemesh.io/v1alpha1
metadata:
  name: gateway-ingress-backend
  namespace: $DEMO_NAMESPACE
spec:
  backends:
  - name: $DETAILS_SERVICE
    port:
      number: 8103
      protocol: http
  - name: $REVIEWS_SERVICE
    port:
      number: 8102
      protocol: http
  - name: $RATINGS_SERVICE
    port:
      number: 8101
      protocol: http
  - name: $EMOJIVOTO_SERVICE
    port:
      number: 80
      protocol: http
  - name: $GATEWAY_SERVICE
    port:
      number: 10000
      protocol: http
  sources:
  sources:
  - kind: Service
    namespace: "$nginx_ingress_namespace"
    name: "$nginx_ingress_service"
EOF