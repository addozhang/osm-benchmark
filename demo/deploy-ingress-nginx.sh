#!/bin/bash

set -aueo pipefail

# shellcheck disable=SC1091
source .env

nginx_ingress_namespace="$INGRESS_NAMESPACE"
nginx_ingress_service="ingress-nginx-controller"

GATEWAY_SERVICE="samples-api-gateway"
DETAILS_SERVICE="samples-bookinfo-details"
REVIEWS_SERVICE="samples-bookinfo-reviews"
RATINGS_SERVICE="samples-bookinfo-ratings"


helm upgrade --install ingress-nginx ingress-nginx \
  --repo https://kubernetes.github.io/ingress-nginx \
  --namespace $nginx_ingress_namespace --create-namespace \
  --set controller.service.httpPort.port="80"

kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/instance=ingress-nginx \
  --timeout=600s

kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: gateway-ingress
  namespace: $DEMO_NAMESPACE
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

echo "ingress deployed"