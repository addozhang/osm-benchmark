#!/bin/bash

set -aueo pipefail
source .env

kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  labels:
    app: samples-discovery-server
  name: samples-discovery-server
  namespace: $DEMO_NAMESPACE
spec:
  ports:
  - port: 8761
    protocol: TCP
    targetPort: 8761
  selector:
    app: samples-discovery-server
status:
  loadBalancer: {}
---
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: samples-discovery-server
    type: infra
  name: samples-discovery-server
  namespace: $DEMO_NAMESPACE
spec:
  replicas: 1
  selector:
    matchLabels:
      app: samples-discovery-server
      type: infra
  strategy: {}
  template:
    metadata:
      labels:
        app: samples-discovery-server
        type: infra
      annotations:
        openservicemesh.io/sidecar-injection: disabled
    spec:
      containers:
      - image: flomesh/samples-discovery-server:latest
        name: app
        resources: {}
        env:
          - name: eureka.server.enableSelfPreservation
            value: 'false'
        ports:
          - containerPort: 8761        
status: {}
EOF

sleep 5
kubectl wait --namespace $DEMO_NAMESPACE \
  --for=condition=ready pod \
  --selector=app=samples-discovery-server \
  --timeout=600s