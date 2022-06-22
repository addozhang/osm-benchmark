#!/bin/bash

set -auo pipefail

# shellcheck disable=SC1091
source .env
MESH_NAME="${MESH_NAME:-osm-edge}"
INGRESS_PIPY_NAMESPACE="${INGRESS_PIPY_NAMESPACE:-flomesh}"
PIPY_INGRESS_SERVICE=${PIPY_INGRESS_SERVICE:-ingress-pipy-controller}
TEST_NAMESPACE="${TEST_NAMESPACE:-app-edge}"

GATEWAY_SERVICE="samples-api-gateway"
DETAILS_SERVICE="samples-bookinfo-details"
REVIEWS_SERVICE="samples-bookinfo-reviews"
RATINGS_SERVICE="samples-bookinfo-ratings"

K8S_INGRESS_NODE="${K8S_INGRESS_NODE:-ingress-node}"

kubectl label node "$K8S_INGRESS_NODE" ingress-ready=true --overwrite=true

helm repo add fsm https://flomesh-io.github.io/fsm

helm install fsm fsm/fsm --namespace "$INGRESS_PIPY_NAMESPACE" --create-namespace \
  --set=fsm.pipy.imageName=pipy-nightly \
  --set=fsm.pipy.tag=latest
  
sleep 5

kubectl wait --namespace "$INGRESS_PIPY_NAMESPACE" \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/instance=ingress-pipy \
  --timeout=600s

kubectl patch deployment -n "$INGRESS_PIPY_NAMESPACE" ingress-pipy -p \
'{
  "spec": {
    "template": {
      "spec": {
        "containers": [
          {
            "name": "ingress",
            "ports": [
              {
                "containerPort": 8000,
                "name": "ingress",
                "protocol": "TCP"
              }
            ]
          }
        ],
        "nodeSelector": {
          "ingress-ready": "true"
        }
      }
    }
  }
}'

kubectl wait --namespace "$INGRESS_PIPY_NAMESPACE" \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/instance=ingress-pipy \
  --timeout=600s

kubectl patch service -n "$INGRESS_PIPY_NAMESPACE" "$PIPY_INGRESS_SERVICE" -p '{"spec":{"type":"NodePort"}}'

if [ "$MESH_ENABLED" = true ]; then
  osm namespace add "$INGRESS_PIPY_NAMESPACE" --mesh-name "$MESH_NAME" --disable-sidecar-injection
fi

kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: gateway-ingress
  namespace: $TEST_NAMESPACE
spec:
  ingressClassName: pipy
  rules:
  - http:
      paths:
      - path: /details/*
        pathType: Prefix
        backend:
          service:
            name: $DETAILS_SERVICE
            port:
              number: 8103
      - path: /reviews/*
        pathType: Prefix
        backend:
          service:
            name: $REVIEWS_SERVICE
            port:
              number: 8102
      - path: /ratings/*
        pathType: Prefix
        backend:
          service:
            name: $RATINGS_SERVICE
            port:
              number: 8101
      - path: /*
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
    namespace: "$INGRESS_PIPY_NAMESPACE"
    name: "$PIPY_INGRESS_SERVICE"
EOF
fi
echo "ingress deployed"