#!/bin/bash

set -aueo pipefail

export PATH=/root/apache-jmeter-5.5/bin:$PATH

RATING_NODE_PORT=30101
REVIEWS_NODE_PORT=30102
GATEWAY_NODE_PORT=30010

GATEWAY_REVIEWS_PATH=/bookinfo-reviews/reviews/2099a055-1e21-46ef-825e-9e0de93554ea
GATEWAY_RATINGS_PATH=/bookinfo-ratings/ratings/2099a055-1e21-46ef-825e-9e0de93554ea
REVIEWS_PATH=/reviews/2099a055-1e21-46ef-825e-9e0de93554ea
RATING_PATH=/ratings/2099a055-1e21-46ef-825e-9e0de93554ea

INGRESS_PORT=80
HOST=192.168.10.71

THREAD_COUND=200
DURATION=60
RESULT_PATH=~/jmeter-results

## warming

ts=`date '+%Y-%m-%d-%H-%M-%S'`
jmeter -Jthread.cound="${THREAD_COUND}" -Jthread.duration="${DURATION}" -Jhttp.host="${HOST}" -Jhttp.port="${INGRESS_PORT}" -Jhttp.path="${RATING_PATH}" -n -t bookinfo.jmx -l "${RESULT_PATH}"/ingress-ratings-"${ts}".jtl

ts=`date '+%Y-%m-%d-%H-%M-%S'`
jmeter -Jthread.cound="${THREAD_COUND}" -Jthread.duration="${DURATION}" -Jhttp.host="${HOST}" -Jhttp.port="${INGRESS_PORT}" -Jhttp.path="${GATEWAY_RATINGS_PATH}" -n -t bookinfo.jmx -l "${RESULT_PATH}"/ingress-gateway-ratings-"${ts}".jtl