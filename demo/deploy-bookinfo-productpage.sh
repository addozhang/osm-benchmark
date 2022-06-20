#!/bin/bash

set -aueo pipefail
source .env

kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  labels:
    app: samples-bookinfo-productpage
  name: samples-bookinfo-productpage
  namespace: $DEMO_NAMESPACE
spec:
  type: NodePort
  ports:
  - port: 9080
    protocol: TCP
    targetPort: 9080
    nodePort: 30080
  selector:
    app: samples-bookinfo-productpage
status:
  loadBalancer: {}
---
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: samples-bookinfo-productpage
    type: app
  name: samples-bookinfo-productpage
  namespace: $DEMO_NAMESPACE
spec:
  replicas: 1
  selector:
    matchLabels:
      app: samples-bookinfo-productpage
      type: app
  strategy: {}
  template:
    metadata:
      annotations:
        "app.flomesh.io/name": "samples-bookinfo-productpage"
        "app.flomesh.io/port": "9080"
      labels:
        app: samples-bookinfo-productpage
        type: app
    spec:
      containers:
      - image: flomesh/samples-bookinfo-productpage:latest
        name: app
        env:
          - name: SERVICES_DOMAIN
            value: springboot.svc
          - name: K8S_SAMPLES_API_GATEWAY_HOSTNAME
            value: samples-api-gateway
          - name: K8S_SAMPLES_API_GATEWAY_PORT
            value: "10000"
        resources: {}
        ports:
          - containerPort: 9080
status: {}
EOF