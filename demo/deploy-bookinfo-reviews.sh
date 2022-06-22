#!/bin/bash

set -aueo pipefail
source .env

kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  labels:
    app: samples-bookinfo-reviews
  name: samples-bookinfo-reviews
  namespace: $DEMO_NAMESPACE
spec:
  ports:
  - port: 8102
    protocol: TCP
    targetPort: 8102
  selector:
    app: samples-bookinfo-reviews
---
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: samples-bookinfo-reviews
    type: app
  name: samples-bookinfo-reviews
  namespace: $DEMO_NAMESPACE
spec:
  replicas: 1
  selector:
    matchLabels:
      app: samples-bookinfo-reviews
      type: app
  strategy: {}
  template:
    metadata:
      annotations:
        "app.flomesh.io/name": "samples-bookinfo-reviews"
        "app.flomesh.io/port": "8102"
      labels:
        app: samples-bookinfo-reviews
        type: app
    spec:
      containers:
      - image: flomesh/samples-bookinfo-reviews:latest
        name: app
        resources: 
          requests:
            cpu: 1
            memory: 2Gi
          limits:
            cpu: 2
            memory: 4Gi
        ports:
          - containerPort: 8102      
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