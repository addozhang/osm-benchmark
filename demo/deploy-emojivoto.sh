#!/bin/bash

set -aueo pipefail
source .env

kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: $DEMO_NAMESPACE
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: emoji
  namespace: $DEMO_NAMESPACE
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: voting
  namespace: $DEMO_NAMESPACE
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: web
  namespace: $DEMO_NAMESPACE
---
apiVersion: v1
kind: Service
metadata:
  name: emoji-svc
  namespace: $DEMO_NAMESPACE
spec:
  ports:
  - name: grpc
    port: 8080
    targetPort: 8080
    appProtocol: grpc
  - name: prom
    port: 8801
    targetPort: 8801
  selector:
    app: emoji-svc
---
apiVersion: v1
kind: Service
metadata:
  name: voting-svc
  namespace: $DEMO_NAMESPACE
spec:
  ports:
  - name: grpc
    port: 8080
    targetPort: 8080
    appProtocol: grpc
  - name: prom
    port: 8801
    targetPort: 8801
  selector:
    app: voting-svc
---
apiVersion: v1
kind: Service
metadata:
  name: web-svc
  namespace: $DEMO_NAMESPACE
spec:
  ports:
  - name: http
    port: 8080
    targetPort: 8080
    nodePort: 30101
  selector:
    app: web-svc
  type: NodePort
---
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app.kubernetes.io/name: emoji
    app.kubernetes.io/part-of: emojivoto
    app.kubernetes.io/version: v11
  name: emoji
  namespace: $DEMO_NAMESPACE
spec:
  replicas: 1
  selector:
    matchLabels:
      app: emoji-svc
      version: v11
  template:
    metadata:
      annotations:
        config.linkerd.io/proxy-cpu-limit: "${CPU:-1}"    
      labels:
        app: emoji-svc
        version: v11
    spec:
      containers:
      - env:
        - name: GRPC_PORT
          value: "8080"
        - name: PROM_PORT
          value: "8801"
        image: docker.l5d.io/buoyantio/emojivoto-emoji-svc:v11
        name: emoji-svc
        ports:
        - containerPort: 8080
          name: grpc
        - containerPort: 8801
          name: prom
        resources:
          requests:
            cpu: 100m
      serviceAccountName: emoji
---
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app.kubernetes.io/name: vote-bot
    app.kubernetes.io/part-of: emojivoto
    app.kubernetes.io/version: v11
  name: vote-bot
  namespace: $DEMO_NAMESPACE
spec:
  replicas: 1
  selector:
    matchLabels:
      app: vote-bot
      version: v11
  template:
    metadata:
      annotations:
        config.linkerd.io/proxy-cpu-limit: "${CPU:-1}"    
      labels:
        app: vote-bot
        version: v11
    spec:
      containers:
      - command:
        - emojivoto-vote-bot
        env:
        - name: WEB_HOST
          value: web-svc.emojivoto:80
        image: docker.l5d.io/buoyantio/emojivoto-web:v11
        name: vote-bot
        resources:
          requests:
            cpu: 10m
---
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app.kubernetes.io/name: voting
    app.kubernetes.io/part-of: emojivoto
    app.kubernetes.io/version: v11
  name: voting
  namespace: $DEMO_NAMESPACE
spec:
  replicas: 1
  selector:
    matchLabels:
      app: voting-svc
      version: v11
  template:
    metadata:
      annotations:
        config.linkerd.io/proxy-cpu-limit: "${CPU:-1}"    
      labels:
        app: voting-svc
        version: v11
    spec:
      containers:
      - env:
        - name: GRPC_PORT
          value: "8080"
        - name: PROM_PORT
          value: "8801"
        image: docker.l5d.io/buoyantio/emojivoto-voting-svc:v11
        name: voting-svc
        ports:
        - containerPort: 8080
          name: grpc
        - containerPort: 8801
          name: prom
        resources:
          requests:
            cpu: 100m
      serviceAccountName: voting
---
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app.kubernetes.io/name: web
    app.kubernetes.io/part-of: emojivoto
    app.kubernetes.io/version: v11
  name: web
  namespace: $DEMO_NAMESPACE
spec:
  replicas: 1
  selector:
    matchLabels:
      app: web-svc
      version: v11
  template:
    metadata:
      annotations:
        config.linkerd.io/proxy-cpu-limit: "${CPU:-1}"    
      labels:
        app: web-svc
        version: v11
    spec:
      containers:
      - env:
        - name: WEB_PORT
          value: "8080"
        - name: EMOJISVC_HOST
          value: emoji-svc.emojivoto:8080
        - name: VOTINGSVC_HOST
          value: voting-svc.emojivoto:8080
        - name: INDEX_BUNDLE
          value: dist/index_bundle.js
        image: docker.l5d.io/buoyantio/emojivoto-web:v11
        name: web-svc
        ports:
        - containerPort: 8080
          name: http
        resources:
          requests:
            cpu: 100m
      serviceAccountName: web
EOF