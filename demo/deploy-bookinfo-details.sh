#!/bin/bash

set -aueo pipefail
source .env

kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  labels:
    app: samples-bookinfo-details
    type: app
  name: samples-bookinfo-details
  namespace: $DEMO_NAMESPACE
spec:
  ports:
  - port: 8103
    protocol: TCP
    targetPort: 8103
  selector:
    app: samples-bookinfo-details
status:
  loadBalancer: {}
---
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: samples-bookinfo-details
  name: samples-bookinfo-details
  namespace: $DEMO_NAMESPACE
spec:
  replicas: 1
  selector:
    matchLabels:
      app: samples-bookinfo-details
      type: app
  strategy: {}
  template:
    metadata:
      annotations:
        "app.flomesh.io/name": "samples-bookinfo-details"
        "app.flomesh.io/port": "8103"
      labels:
        app: samples-bookinfo-details
        type: app
    spec:
      containers:
      - image: flomesh/samples-bookinfo-details:latest
        name: app
        resources: {}
        ports:
          - containerPort: 8103        
        env:
          - name: K8S_SAMPLES_DISCOVERY_SERVER_HOSTNAME
            value: 'samples-discovery-server'
          - name: K8S_SAMPLES_DISCOVERY_SERVER_PORT
            value: "8761"
          - name: DISCOVERY_PREFER_VIP_ADDRESS
            value: "true"
          - name: JAVA_OPTS
            value: "-Xms2g -Xmx4g" 
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