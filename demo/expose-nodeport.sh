set -auo pipefail

# shellcheck disable=SC1091
source .env

kubectl apply -f <<EOF
apiVersion: v1
kind: Service
metadata:
  creationTimestamp: null
  labels:
    app: samples-bookinfo-ratings
    type: app
  name: samples-bookinfo-ratings-node
  namespace: $DEMO_NAMESPACE
spec:
  ports:
  - port: 8101
    protocol: TCP
    targetPort: 8101
    nodePort: 30101
  selector:
    app: samples-bookinfo-ratings
    type: app
  type: NodePort
status:
  loadBalancer: {}
---
apiVersion: v1
kind: Service
metadata:
  creationTimestamp: null
  labels:
    app: samples-bookinfo-reviews
    type: app
  name: samples-bookinfo-reviews-node
  namespace: $DEMO_NAMESPACE
spec:
  ports:
  - port: 8102
    protocol: TCP
    targetPort: 8102
    nodePort: 30102
  selector:
    app: samples-bookinfo-reviews
    type: app
  type: NodePort
status:
  loadBalancer: {}
---
apiVersion: v1
kind: Service
metadata:
  creationTimestamp: null
  labels:
    app: samples-bookinfo-details
    type: app
  name: samples-bookinfo-details-node
  namespace: $DEMO_NAMESPACE
spec:
  ports:
  - port: 8103
    protocol: TCP
    targetPort: 8103
    nodePort: 30103
  selector:
    app: samples-bookinfo-details
    type: app
  type: NodePort
status:
  loadBalancer: {}
---
EOF