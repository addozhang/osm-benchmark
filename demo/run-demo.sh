#!/bin/bash

set -aueo pipefail
source .env

# clean up
./demo/clean-kubernetes.sh
# namespace
./demo/configure-app-namespace.sh
# deploy app
./demo/deploy-app.sh
# deploy ingress
./demo/deploy-ingress-nginx.sh
# ./demo/deploy-ingress-pipy.sh