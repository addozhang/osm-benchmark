#!/bin/bash

set -aueo pipefail
source .env

kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  labels:
    app: samples-config-service
    type: infra
  name: samples-config-service
  namespace: $DEMO_NAMESPACE
spec:
  ports:
  - port: 8888
    protocol: TCP
    targetPort: 8888
  selector:
    app: samples-config-service
status:
  loadBalancer: {}
---
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: samples-config-service
    type: infra
  name: samples-config-service
  namespace: $DEMO_NAMESPACE
spec:
  replicas: 1
  selector:
    matchLabels:
      app: samples-config-service
      type: infra
  strategy: {}
  template:
    metadata:
      labels:
        app: samples-config-service
        type: infra
      annotations:
        openservicemesh.io/sidecar-injection: disabled
    spec:
      containers:
      - image: flomesh/samples-config-service:latest
        name: app
        env:
          - name: K8S_SAMPLES_DISCOVERY_SERVER_HOSTNAME
            value: samples-discovery-server
          - name: K8S_SAMPLES_DISCOVERY_SERVER_PORT
            value: "8761"
          - name: K8S_SAMPLES_BOOKINFO_RATINGS_HOSTNAME
            value: samples-bookinfo-ratings
          - name: K8S_SERVICE_NAME
            value: samples-config-service        
        resources: {}
        ports:
          - containerPort: 8888
status: {}
EOF

sleep 5
kubectl wait --namespace $DEMO_NAMESPACE \
  --for=condition=ready pod \
  --selector=app=samples-config-service \
  --timeout=600s