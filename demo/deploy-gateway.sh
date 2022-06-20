#!/bin/bash

set -aueo pipefail
source .env

kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  labels:
    app: samples-api-gateway
  name: samples-api-gateway
  namespace: $DEMO_NAMESPACE
spec:
  ports:
  - name: app
    port: 10000
    protocol: TCP
    targetPort: 10000
  selector:
    app: samples-api-gateway
status:
  loadBalancer: {}

---
apiVersion: v1
kind: Service
metadata:
  labels:
    app: samples-api-gateway
  name: samples-api-gateway-node
  namespace: $DEMO_NAMESPACE
spec:
  type: NodePort
  ports:
  - name: sidecar
    port: 10000
    protocol: TCP
    targetPort: 10000
    nodePort: 30010
  selector:
    app: samples-api-gateway
---
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: samples-api-gateway
    type: infra
  name: samples-api-gateway
  namespace: $DEMO_NAMESPACE
spec:
  replicas: 1
  selector:
    matchLabels:
      app: samples-api-gateway
      type: infra
  strategy: {}
  template:
    metadata:
      annotations:
        "app.flomesh.io/name": "samples-api-gateway"
        "app.flomesh.io/port": "10000"
      labels:
        app: samples-api-gateway
        type: infra
    spec:
      containers:
      - image: flomesh/samples-api-gateway:latest
        name: app
        resources: {}
        ports:
          - containerPort: 10000   
        env:
          - name: K8S_SAMPLES_DISCOVERY_SERVER_HOSTNAME
            value: 'samples-discovery-server'
          - name: K8S_SAMPLES_DISCOVERY_SERVER_PORT
            value: "8761"
          - name: JAVA_OPTS
            value: "-Xms2g -Xmx4g" 
          - name: DISCOVERY_PREFER_VIP_ADDRESS
            value: "true"
          - name: SERVICE_NAME
            valueFrom:
              fieldRef:
                apiVersion: v1
                fieldPath: metadata.annotations['app.flomesh.io/name']
          - name: NAMESPACE
            valueFrom:
              fieldRef:
                apiVersion: v1
                fieldPath: metadata.namespace
          - name: eureka.instance.metadataMap.fqdn
            value: "\$(SERVICE_NAME).\$(NAMESPACE)"
status: {}
EOF