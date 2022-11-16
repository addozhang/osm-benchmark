#!/bin/bash

set -aueo pipefail
source .env

kubectl apply -n $DEMO_NAMESPACE -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: fortio
  labels:
    app: fortio
spec:
  ports:
  - port: 8080
    name: http
  selector:
    app: fortio
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: fortio
spec:
  replicas: 1
  selector:
    matchLabels:
      app: fortio
  template:
    metadata:
      annotations:
        config.linkerd.io/proxy-cpu-limit: "${CPU:-1}"
      labels:
        app: fortio
    spec:
      containers:
      - name: fortio
        image: fortio/fortio:1.38.4
        imagePullPolicy: Always
        ports:
        - containerPort: 8080
          name: http-fortio
        resources: 
          requests:
            cpu: 1
            memory: 1Gi
          limits:
            cpu: 2
            memory: 2Gi          
EOF
