#!/bin/bash

set -aueo pipefail
source .env

VERSION=${1:-v1}
SVC="echo-dubbo-consumer-$VERSION"
KUBE_CONTEXT=$(kubectl config current-context)

kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: cm-client-yaml
  namespace: $DEMO_NAMESPACE
data:
  client.yml: |
    # dubbo client yaml configure file
    check: true
    # client
    request_timeout : "3s"
    # connect timeout
    connect_timeout : "3s"

    # application config
    application:
      organization : "flomesh.io"
      name : "osm-edge demo"
      module : "osm-edge echo server by dubbo"
      version : "0.0.1"
      owner : "cybwan"
      environment : "develop"


    references:
      "EchoProvider":
        interface : "io.flemsh.osm.Echo.EchoProvider"
        cluster: "failover"
        url:  "dubbo://echo-dubbo-server-v1.$DEMO_NAMESPACE.svc.cluster.local:20002"
        methods :
          - name: "GetEcho"
            retries: 3

    protocol_conf:
      dubbo:
        reconnect_interval: 0
        connection_number: 2
        heartbeat_period: "5s"
        session_timeout: "20s"
        pool_size: 64
        pool_ttl: 600
        getty_session_param:
          compress_encoding: false
          tcp_no_delay: true
          tcp_keep_alive: true
          keep_alive_period: "120s"
          tcp_r_buf_size: 262144
          tcp_w_buf_size: 65536
          pkg_rq_size: 1024
          pkg_wq_size: 512
          tcp_read_timeout: "5s"
          tcp_write_timeout: "5s"
          wait_timeout: "1s"
          max_msg_len: 10240
          session_name: "client"
---
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
    app: echo-dubbo-consumer
    type: app
spec:
  ports:
  - port: 8090
    name: http
    appProtocol: tcp
  - port: 8080
    name: tcp
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
        - image: cybwan/osm-edge-demo-echo-dubbo-consumer
          imagePullPolicy: Always
          name: $SVC
          volumeMounts:
          - name: client-yml
            mountPath: /config/client.yml
            subPath: client.yml
          ports:
            - name: http
              containerPort: 8090
              protocol: TCP
            - containerPort: 8080
              protocol: TCP
          command: ["/echo-dubbo-consumer"]
          env:
            - name: IDENTITY
              value: ${SVC}.${KUBE_CONTEXT}
            - name: GIN_MODE
              value: debug
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
            - name: CONF_CONSUMER_FILE_PATH
              value: "/config/client.yml"
      volumes:
      - name: client-yml
        configMap:
          name: cm-client-yaml
EOF

sleep 5
kubectl wait --namespace $DEMO_NAMESPACE \
  --for=condition=ready pod \
  --selector=app=$SVC \
  --timeout=600s