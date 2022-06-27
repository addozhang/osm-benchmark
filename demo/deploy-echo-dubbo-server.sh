#!/bin/bash

set -aueo pipefail
source .env

VERSION=${1:-v1}
SVC="echo-dubbo-server-$VERSION"
KUBE_CONTEXT=$(kubectl config current-context)

kubectl apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: "$SVC"
  namespace: $DEMO_NAMESPACE
---
apiVersion: v1
kind: Service
metadata:
  name: $SVC
  namespace: $DEMO_NAMESPACE
  labels:
    app: echo-dubbo-server
    type: app
spec:
  ports:
  - port: 20002
    name: dubbo-port
    appProtocol: tcp
  selector:
    app: $SVC
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $SVC
  namespace: $DEMO_NAMESPACE
spec:
  replicas: 1
  selector:
    matchLabels:
      app: $SVC
      version: $VERSION
      type: app
  template:
    metadata:
      labels:
        app: $SVC
        version: $VERSION
        type: app
    spec:
      serviceAccountName: "$SVC"
      containers:
        - image: cybwan/osm-edge-demo-echo-dubbo-server
          imagePullPolicy: Always
          name: $SVC
          ports:
            - containerPort: 20002
              name: tcp-dubbo
              protocol: TCP
          command: ["/echo-dubbo-server"]
          env:
            - name: IDENTITY
              value: ${SVC}.${KUBE_CONTEXT}
            - name: POD_NAME
              valueFrom:
                fieldRef:
                  apiVersion: v1
                  fieldPath: metadata.name
            - name: POD_NAMESPACE
              valueFrom:
                fieldRef:
                  apiVersion: v1
                  fieldPath: metadata.namespace
            - name: POD_IP
              valueFrom:
                fieldRef:
                  apiVersion: v1
                  fieldPath: status.podIP
            - name: SERVICE_ACCOUNT
              valueFrom:
                fieldRef:
                  apiVersion: v1
                  fieldPath: spec.serviceAccountName
            - name: APP_LOG_CONF_FILE
              value: "/config/log.yml"
            - name: CONF_PROVIDER_FILE_PATH
              value: "/config/server.yml"
EOF

sleep 5
kubectl wait --namespace $DEMO_NAMESPACE \
  --for=condition=ready pod \
  --selector=app=$SVC \
  --timeout=600s