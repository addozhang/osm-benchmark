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
EMOJIVOTO_SERVICE="web-svc"
PRODUCTPAGE_SERVICE="productpage"
FORTIO_SERVICE="fortio"


helm upgrade --install ingress-nginx ingress-nginx \
  --repo https://kubernetes.github.io/ingress-nginx \
  --namespace $nginx_ingress_namespace --create-namespace \
  --set controller.service.httpPort.port="80"

kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/instance=ingress-nginx \
  --timeout=600s

if [[ DEMO_TYPE -eq 3 ]]; then
  echo "Creating ingress rule for Emojivoto\n";
  kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: gateway-ingress
  namespace: $DEMO_NAMESPACE
  annotations:
    nginx.ingress.kubernetes.io/service-upstream: "true"
spec:
  ingressClassName: nginx
  defaultBackend:
    service:
      name: $EMOJIVOTO_SERVICE
      port:
        number: 8080

EOF
elif [[ DEMO_TYPE -eq 5 ]]; then
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: gateway-ingress
  namespace: $DEMO_NAMESPACE
spec:
  ingressClassName: nginx
  defaultBackend:
    service:
      name: $FORTIO_SERVICE
      port:
        number: 8080  
  # rules:
  # - http:
  #     paths:
  #     - path: /
  #       pathType: Prefix
  #       backend:
  #         service:
  #           name: $FORTIO_SERVICE
  #           port:
  #             number: 8080
EOF
else
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
      - path: /emoji
        pathType: Prefix
        backend:
          service:
            name: $EMOJIVOTO_SERVICE
            port:
              number: 80
      - path: /productpage
        pathType: Prefix
        backend:
          service:
            name: $PRODUCTPAGE_SERVICE
            port:
              number: 9080                           
      - path: /
        pathType: Prefix
        backend:
          service:
            name: $GATEWAY_SERVICE
            port:
              number: 10000
EOF
fi

echo "ingress deployed"