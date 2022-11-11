set -aueo pipefail
source .env

#cli
curl -L https://istio.io/downloadIstio | ISTIO_VERSION=$ISTIO_VERSION TARGET_ARCH=x86_64 sh -
sudo cp istio-$ISTIO_VERSION/bin/istioctl /usr/local/bin/istioctl
istioctl x precheck

# clean up
./demo/clean-kubernetes.sh

#install istio
istioctl install -y \
  --set profile=minimal \
  --set values.global.proxy.resources.limits.cpu=2000m \
  --set values.global.proxy.excludeOutboundPorts="8761,8888"


sleep 5
kubectl wait --namespace istio-system \
  --for=condition=ready pod \
  --selector=app=istiod \
  --timeout=600s  

# create namespace
kubectl create namespace "$DEMO_NAMESPACE" --save-config
# mesh namespace
kubectl label namespace "$DEMO_NAMESPACE" istio-injection=enabled
# deploy app
./demo/deploy-app.sh
# deploy ingress
./demo/deploy-ingress-nginx.sh