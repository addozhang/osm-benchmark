#!/bin/bash

set -aueo pipefail
source .env

kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  labels:
    app: samples-bookinfo-ratings 
  name: samples-bookinfo-ratings
  namespace: $DEMO_NAMESPACE
spec:
  ports:
  - port: 8101
    protocol: TCP
    targetPort: 8101
  selector:
    app: samples-bookinfo-ratings
---
apiVersion: v1
kind: Service
metadata:
  labels:
    app: samples-bookinfo-ratings 
  name: samples-bookinfo-ratings-node
  namespace: $DEMO_NAMESPACE
spec:
  type: NodePort
  ports:
  - port: 8101
    protocol: TCP
    targetPort: 8101
    nodePort: 30101
  selector:
    app: samples-bookinfo-ratings
---
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: samples-bookinfo-ratings
    type: app
  name: samples-bookinfo-ratings
  namespace: $DEMO_NAMESPACE
spec:
  replicas: 1
  selector:
    matchLabels:
      app: samples-bookinfo-ratings
      type: app
  strategy: {}
  template:
    metadata:
      annotations:
        "app.flomesh.io/name": "samples-bookinfo-ratings"
        "app.flomesh.io/port": "8101"
      labels:
        app: samples-bookinfo-ratings
        type: app
    spec:
      containers:
      - image: flomesh/samples-bookinfo-ratings:latest
        name: app
        resources: 
          requests:
            cpu: 1
            memory: 2Gi
          limits:
            cpu: 2
            memory: 4Gi
        ports:
          - containerPort: 8101        
        env:
          - name: K8S_SAMPLES_DISCOVERY_SERVER_HOSTNAME
            value: 'samples-discovery-server'
          - name: K8S_SAMPLES_DISCOVERY_SERVER_PORT
            value: "8761"
          - name: JAVA_OPTS
            value: "-Xmx4g -Xms2g"
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