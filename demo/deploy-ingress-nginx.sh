#!/bin/bash

set -aueo pipefail

# shellcheck disable=SC1091
source .env


K8S_NAMESPACE="${K8S_NAMESPACE:-osm-edge-system}"
MESH_NAME="${MESH_NAME:-osm-edge}"
nginx_ingress_namespace="ingress-nginx"
nginx_ingress_service="ingress-nginx-controller"
TEST_NAMESPACE="${DEMO_NAMESPACE:-app-edge}"
GATEWAY_SERVICE="samples-api-gateway"
DETAILS_SERVICE="samples-bookinfo-details"
REVIEWS_SERVICE="samples-bookinfo-reviews"
RATINGS_SERVICE="samples-bookinfo-ratings"


helm upgrade --install ingress-nginx ingress-nginx \
  --repo https://kubernetes.github.io/ingress-nginx \
  --namespace $nginx_ingress_namespace --create-namespace \
  --set controller.service.httpPort.port="80"



nginx_ingress_host="$(kubectl -n "$nginx_ingress_namespace" get service "$nginx_ingress_service" -o jsonpath='{.status.loadBalancer.ingress[0].ip}')"
nginx_ingress_port="$(kubectl -n "$nginx_ingress_namespace" get service "$nginx_ingress_service" -o jsonpath='{.spec.ports[?(@.name=="http")].port}')"

if [ "$MESH_ENABLED" = true ]; then
  osm namespace add "$nginx_ingress_namespace" --mesh-name "$MESH_NAME" --disable-sidecar-injection
fi  

kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/instance=ingress-nginx \
  --timeout=600s

kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: gateway-ingress
  namespace: $TEST_NAMESPACE
spec:
  ingressClassName: nginx
  rules:
  - http:
      paths:
      - path: /details
        pathType: Prefix
        backend:
          service:
            name: $DETAILS_SERVICE
            port:
              number: 8103
      - path: /reviews
        pathType: Prefix
        backend:
          service:
            name: $REVIEWS_SERVICE
            port:
              number: 8102
      - path: /ratings
        pathType: Prefix
        backend:
          service:
            name: $RATINGS_SERVICE
            port:
              number: 8101
      - path: /
        pathType: Prefix
        backend:
          service:
            name: $GATEWAY_SERVICE
            port:
              number: 10000
EOF

if [ "$MESH_ENABLED" = true ]; then
  kubectl apply -f - <<EOF
kind: IngressBackend
apiVersion: policy.openservicemesh.io/v1alpha1
metadata:
  name: gateway-ingress-backend
  namespace: $TEST_NAMESPACE
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
fi
echo "ingress deployed"