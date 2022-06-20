
#!/bin/bash

set -aueo pipefail

# shellcheck disable=SC1091
source .env

kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  labels:
    app: grafana
  name: grafana-host
  namespace: $METRICS_NAMESPACE
spec:
  ports:
  - port: 3000
    protocol: TCP
    targetPort: 3000
    nodePort: 30030
  selector:
    app.kubernetes.io/instance: grafana
    app.kubernetes.io/name: grafana
  type: NodePort
EOF

kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: prometheus-host
  namespace: $METRICS_NAMESPACE
  labels:
    app: prometheus
spec:
  ports:
  - port: 7070
    protocol: TCP
    targetPort: 9090
    nodePort: 30090
  selector:
    app: prometheus
    component: server
  type: NodePort
EOF