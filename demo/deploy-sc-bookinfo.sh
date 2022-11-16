#!/bin/bash

set -aueo pipefail
source .env

###########Discovery###########
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
        sidecar.istio.io/inject: disabled
        linkerd.io/inject: disabled
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

###########Config###########
kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  labels:
    app: samples-config-service
    type: infra
  name: samples-config-service
  namespace: $DEMO_NAMESPACE
spec:
  ports:
  - port: 8888
    protocol: TCP
    targetPort: 8888
  selector:
    app: samples-config-service
status:
  loadBalancer: {}
---
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: samples-config-service
    type: infra
  name: samples-config-service
  namespace: $DEMO_NAMESPACE
spec:
  replicas: 1
  selector:
    matchLabels:
      app: samples-config-service
      type: infra
  strategy: {}
  template:
    metadata:
      labels:
        app: samples-config-service
        type: infra
      annotations:
        openservicemesh.io/sidecar-injection: disabled
        sidecar.istio.io/inject: disabled
        linkerd.io/inject: disabled
    spec:
      containers:
      - image: flomesh/samples-config-service:latest
        name: app
        env:
          - name: K8S_SAMPLES_DISCOVERY_SERVER_HOSTNAME
            value: samples-discovery-server
          - name: K8S_SAMPLES_DISCOVERY_SERVER_PORT
            value: "8761"
          - name: K8S_SAMPLES_BOOKINFO_RATINGS_HOSTNAME
            value: samples-bookinfo-ratings
          - name: K8S_SERVICE_NAME
            value: samples-config-service        
        resources: {}
        ports:
          - containerPort: 8888
status: {}
EOF

sleep 5
kubectl wait --namespace $DEMO_NAMESPACE \
  --for=condition=ready pod \
  --selector=app=samples-config-service \
  --timeout=600s
###########Ratings###########
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
        config.linkerd.io/proxy-cpu-limit: "${CPU:-1}"        
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
###########Reviews###########
# kubectl apply -f - <<EOF
# apiVersion: v1
# kind: Service
# metadata:
#   labels:
#     app: samples-bookinfo-reviews
#   name: samples-bookinfo-reviews
#   namespace: $DEMO_NAMESPACE
# spec:
#   ports:
#   - port: 8102
#     protocol: TCP
#     targetPort: 8102
#   selector:
#     app: samples-bookinfo-reviews
# ---
# apiVersion: apps/v1
# kind: Deployment
# metadata:
#   labels:
#     app: samples-bookinfo-reviews
#     type: app
#   name: samples-bookinfo-reviews
#   namespace: $DEMO_NAMESPACE
# spec:
#   replicas: 1
#   selector:
#     matchLabels:
#       app: samples-bookinfo-reviews
#       type: app
#   strategy: {}
#   template:
#     metadata:
#       annotations:
#         "app.flomesh.io/name": "samples-bookinfo-reviews"
#         "app.flomesh.io/port": "8102"
#       labels:
#         app: samples-bookinfo-reviews
#         type: app
#     spec:
#       containers:
#       - image: flomesh/samples-bookinfo-reviews:latest
#         name: app
#         resources: 
#           requests:
#             cpu: 1
#             memory: 2Gi
#           limits:
#             cpu: 2
#             memory: 4Gi
#         ports:
#           - containerPort: 8102      
#         env:
#           - name: K8S_SAMPLES_DISCOVERY_SERVER_HOSTNAME
#             value: 'samples-discovery-server'
#           - name: K8S_SAMPLES_DISCOVERY_SERVER_PORT
#             value: "8761"
#           - name: JAVA_OPTS
#             value: "-Xms2g -Xmx4g"    
#           - name: DISCOVERY_PREFER_VIP_ADDRESS
#             value: "true"
#           - name: SERVICE_NAME
#             valueFrom:
#               fieldRef:
#                 apiVersion: v1
#                 fieldPath: metadata.annotations['app.flomesh.io/name']
#           - name: NAMESPACE
#             valueFrom:
#               fieldRef:
#                 apiVersion: v1
#                 fieldPath: metadata.namespace
#           - name: eureka.instance.metadataMap.fqdn
#             value: "\$(SERVICE_NAME).\$(NAMESPACE)"
# status: {}
# EOF
###########Details###########
# kubectl apply -f - <<EOF
# apiVersion: v1
# kind: Service
# metadata:
#   labels:
#     app: samples-bookinfo-details
#     type: app
#   name: samples-bookinfo-details
#   namespace: $DEMO_NAMESPACE
# spec:
#   ports:
#   - port: 8103
#     protocol: TCP
#     targetPort: 8103
#   selector:
#     app: samples-bookinfo-details
# status:
#   loadBalancer: {}
# ---
# apiVersion: apps/v1
# kind: Deployment
# metadata:
#   labels:
#     app: samples-bookinfo-details
#   name: samples-bookinfo-details
#   namespace: $DEMO_NAMESPACE
# spec:
#   replicas: 1
#   selector:
#     matchLabels:
#       app: samples-bookinfo-details
#       type: app
#   strategy: {}
#   template:
#     metadata:
#       annotations:
#         "app.flomesh.io/name": "samples-bookinfo-details"
#         "app.flomesh.io/port": "8103"
#       labels:
#         app: samples-bookinfo-details
#         type: app
#     spec:
#       containers:
#       - image: flomesh/samples-bookinfo-details:latest
#         name: app
#         resources: 
#           requests:
#             cpu: 1
#             memory: 2Gi
#           limits:
#             cpu: 2
#             memory: 4Gi
#         ports:
#           - containerPort: 8103        
#         env:
#           - name: K8S_SAMPLES_DISCOVERY_SERVER_HOSTNAME
#             value: 'samples-discovery-server'
#           - name: K8S_SAMPLES_DISCOVERY_SERVER_PORT
#             value: "8761"
#           - name: DISCOVERY_PREFER_VIP_ADDRESS
#             value: "true"
#           - name: JAVA_OPTS
#             value: "-Xms2g -Xmx4g" 
#           - name: SERVICE_NAME
#             valueFrom:
#               fieldRef:
#                 apiVersion: v1
#                 fieldPath: metadata.annotations['app.flomesh.io/name']
#           - name: NAMESPACE
#             valueFrom:
#               fieldRef:
#                 apiVersion: v1
#                 fieldPath: metadata.namespace
#           - name: eureka.instance.metadataMap.fqdn
#             value: "\$(SERVICE_NAME).\$(NAMESPACE)"
# status: {}

# EOF
###########Gateway###########
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
        config.linkerd.io/proxy-cpu-limit: "${CPU:-1}"        
      labels:
        app: samples-api-gateway
        type: infra
    spec:
      containers:
      - image: flomesh/samples-api-gateway:latest
        name: app
        resources: 
          requests:
            cpu: 4
            memory: 2Gi
          limits:
            cpu: 6
            memory: 4Gi
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
          - name: zuul.semaphore.maxSemaphores
            value: "200"
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
###########Product page###########
# kubectl apply -f - <<EOF
# apiVersion: v1
# kind: Service
# metadata:
#   labels:
#     app: samples-bookinfo-productpage
#   name: samples-bookinfo-productpage
#   namespace: $DEMO_NAMESPACE
# spec:
#   type: NodePort
#   ports:
#   - port: 9080
#     protocol: TCP
#     targetPort: 9080
#     nodePort: 30080
#   selector:
#     app: samples-bookinfo-productpage
# status:
#   loadBalancer: {}
# ---
# apiVersion: apps/v1
# kind: Deployment
# metadata:
#   labels:
#     app: samples-bookinfo-productpage
#     type: app
#   name: samples-bookinfo-productpage
#   namespace: $DEMO_NAMESPACE
# spec:
#   replicas: 1
#   selector:
#     matchLabels:
#       app: samples-bookinfo-productpage
#       type: app
#   strategy: {}
#   template:
#     metadata:
#       annotations:
#         "app.flomesh.io/name": "samples-bookinfo-productpage"
#         "app.flomesh.io/port": "9080"
#       labels:
#         app: samples-bookinfo-productpage
#         type: app
#     spec:
#       containers:
#       - image: flomesh/samples-bookinfo-productpage:latest
#         name: app
#         env:
#           - name: SERVICES_DOMAIN
#             value: springboot.svc
#           - name: K8S_SAMPLES_API_GATEWAY_HOSTNAME
#             value: samples-api-gateway
#           - name: K8S_SAMPLES_API_GATEWAY_PORT
#             value: "10000"
#         resources: {}
#         ports:
#           - containerPort: 9080
# status: {}
# EOF

sleep 5
kubectl wait --namespace $DEMO_NAMESPACE \
  --for=condition=ready pod \
  --selector=type=app \
  --timeout=600s