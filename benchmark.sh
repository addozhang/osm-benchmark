#!/bin/bash

set -aueo pipefail

export DEMO_TYPE=${DEMO_TYPE:-4} # 1-springcloud_bookinfo 2-dubbo 3-linkerd_emojiviot 4-istio_bookinfo 5-fortio
export CONCURRENCY_COUNT=${CONCURRENCY_COUNT:-100}
export DURATION=${DURATION:-30}
export COOLDOWN_TIME=${COOLDOWN_TIME:-10}

./demo/run-demo.sh
./jmx/run-jmeter.sh non-mesh
./demo/run-edge-demo.sh
./jmx/run-jmeter.sh edge
./demo/run-istio-demo.sh
./jmx/run-jmeter.sh istio
./demo/run-linkerd-demo.sh
./jmx/run-jmeter.sh linkerd