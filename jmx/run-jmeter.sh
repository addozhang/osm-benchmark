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

THREAD_COUNT=200
DURATION=300
RESULT_PATH=~/jmeter-results

## warming
# echo "warming up"
# jmeter -Jthread.count="${THREAD_COUNT}" -Jthread.duration="10" -Jhttp.host="${HOST}" -Jhttp.port="${INGRESS_PORT}" -Jhttp.path="${GATEWAY_RATINGS_PATH}" -n -t bookinfo.jmx > /dev/null

# sleep 120s

# testing start
ts=`date '+%Y-%m-%d-%H-%M-%S'`
echo "start at $ts"
jmeter -Jthread.count="${THREAD_COUNT}" -Jthread.duration="${DURATION}" -Jhttp.host="${HOST}" -Jhttp.port="${INGRESS_PORT}" -Jhttp.path="${RATING_PATH}" -n -t bookinfo.jmx -l "${RESULT_PATH}"/ingress-ratings-c"${THREAD_COUNT}"-d"${DURATION}"-"${ts}".jtl

# sleep 120s

ts=`date '+%Y-%m-%d-%H-%M-%S'`
echo "start at $ts"
jmeter -Jthread.count="${THREAD_COUNT}" -Jthread.duration="${DURATION}" -Jhttp.host="${HOST}" -Jhttp.port="${INGRESS_PORT}" -Jhttp.path="${GATEWAY_RATINGS_PATH}" -n -t bookinfo.jmx -l "${RESULT_PATH}"/ingress-gateway-ratings-c"${THREAD_COUNT}"-d"${DURATION}"-"${ts}".jtl