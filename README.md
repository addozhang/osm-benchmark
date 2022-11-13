# Benchmark for OSM and Linkerd

## Setup Environment

Create a K3s cluster:

```shell
export INSTALL_K3S_VERSION=v1.23.8+k3s2
curl -sfL https://get.k3s.io | sh -s - --disable traefik --write-kubeconfig-mode 644 --write-kubeconfig ~/.kube/config
```

Install Helm binary:

```shell
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

Clone code:

```shell
git clone https://github.com/addozhang/osm-benchmark.git
```

Setup monitor:

```shell
# prometheus
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install prometheus prometheus-community/prometheus -n default --set alertmanager.enabled=false,pushgateway.enabled=false,server.global.scrape_interval=10s --namespace metrics --create-namespace
# grafana
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
helm install grafana grafana/grafana --namespace metrics --create-namespace
# grafana admin password
kubectl get secret --namespace metrics grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
```

### Update .env setting

Refer to [`.env`](./.env) file, there are plenty of setting entry, such as demo app types, etc.

## Run demo

Choose any specifed commend of mesh you want to run benchmark for.

```shell
cd osm-benchmark
```

Running osm-edge dmeo:

```shell
./demo/run-edge-demo.sh
```

Running osm demo:

```shell
#osm-envoy
./demo/run-envoy-demo.sh
```

Running Linkerd demo:

```shell
#linkerd
./demo/run-linkerd.sh
```

## Benchmark

### Setup Environment

We will use the used widely load generating tool Apache Jmeter as load generator.

Execute below shell to setup benchmark environment by install JDK and Apache Jmeter.

```shell
cd jmx
./setup.sh
```

### Run standlone benchmark

Execute script:

```shell
# osm-benchmark/jmx
./run-jmeter.sh <edge/linkerd/istio/osm>
```

Short description for benchmark process:

1. When benchmark test running, it will trigger request `ingress->gateway->ratings` for 2 mins warming up.
2. Trigger request `ingress->ratings` for 5 mins.
3. Then, request `ingress-gateway-ratings` for 5 mins.

Among these steps, there is 2 mins cooling down gap, and at last the test summary and results (jtl) can be located in directory `$HOME/jmeter-results`.

### Run batch benchmark

Execult the script `./benchmark.sh` will install mesh, deploy apps and run benchmark automatically.

Please refer to [`benchmark.sh`](./benchmark.sh) for more details. Run benchmark as bellow:

```
DEMO_TYPE=1 CONCURRENCY_COUNT=1000 DURATION=120 COOLDOWN_TIME=60 ./benchmark.sh
```

### Check resource consumption

First execute script to expose Prometheus and Grafana.

```shell
# in root of osm-benchmark
./scripts/expose-prometheus-grafana.sh
```

Open `http://<NODE_IP>:30030` in brower and login with username `admin` and password obtained during monitor setup step. If you miss it, execute `kubectl get secret --namespace metrics grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo` again to extract.

Once authenticated, add Prometheus datasource with address `http://prometheus-server.metrics.svc.cluster.local`.

Next import dashboard by upload json `Kubernetes_pods_dashboard.json` located in root directory.