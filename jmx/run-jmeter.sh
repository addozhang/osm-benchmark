#!/bin/bash

set -aueo pipefail
source .env

export PATH=$HOME/apache-jmeter-5.5/bin:$PATH
case $DEMO_TYPE in
  1) echo "run benchmark for spring cloud bookinfo";
    FULL_PATH=/bookinfo-ratings/ratings/2099a055-1e21-46ef-825e-9e0de93554ea;
    SINGLE_PATH=/ratings/2099a055-1e21-46ef-825e-9e0de93554ea;
    ;;
  2) echo "run benchmark for dubbo samples";
    ;;
  3) echo "run benchmark for linkerd emojiviot";
    FULL_PATH=/emoji/leaderboard;
    SINGLE_PATH=/emoji/api/vote?choice=:nerd_face:;
    ;;
  4) echo "run benchmark for istio bookinfo";
    FULL_PATH=/productpage?u=test;
    ;;
esac
INGRESS_PORT=80
HOST=$REMOTE_ADDR

PREFIX=$1
THREAD_COUNT=${CONCURRENCY_COUNT:-300}
DURATION=${DURATION:-300}
RESULT_PATH=~/jmeter-results

COOLDOWN_TIME=${COOLDOWN_TIME:-60s}

mkdir $HOME/jmeter-results || true

# check service online
if [[ -v SINGLE_PATH ]]; then
  while [[ "$(curl -s -o /dev/null -w ''%{http_code}'' $HOST:$INGRESS_PORT$SINGLE_PATH)" != "200" ]]; do 
    echo service $SINGLE_PATH is NOT online yet, retrying after 1s;
    sleep 1;
  done
fi
if [[ -v FULL_PATH ]]; then
  while [[ "$(curl -s -o /dev/null -w ''%{http_code}'' $HOST:$INGRESS_PORT$FULL_PATH)" != "200" ]]; do 
    echo service $FULL_PATH is NOT online yet, retrying after 1s;
    sleep 1;
  done
fi
# warming
echo "warming up" 
jmeter -Jthread.count="100" -Jthread.duration="30" -Jhttp.host="${HOST}" -Jhttp.port="${INGRESS_PORT}" -Jhttp.path="${FULL_PATH}" -n -t jmx/bookinfo.jmx

# testing start
if [[ -v SINGLE_PATH ]]; then
echo "cooling"
sleep $COOLDOWN_TIME
echo "running on path: $SINGLE_PATH"
ts=`date '+%Y-%m-%d-%H-%M-%S'`
echo "start at $ts"
jmeter -Jthread.count="${THREAD_COUNT}" -Jthread.duration="${DURATION}" -Jhttp.host="${HOST}" -Jhttp.port="${INGRESS_PORT}" -Jhttp.path="${SINGLE_PATH}" -n -t jmx/bookinfo.jmx -l "${RESULT_PATH}"/"${PREFIX}"-single-path-c"${THREAD_COUNT}"-d"${DURATION}"-"${ts}".jtl > "${RESULT_PATH}"/"${PREFIX}"-single-path-c"${THREAD_COUNT}"-d"${DURATION}"-"${ts}".summary
fi

if [[ -v FULL_PATH ]]; then
echo "cooling"
sleep $COOLDOWN_TIME
echo "running on path: $FULL_PATH"
ts=`date '+%Y-%m-%d-%H-%M-%S'`
echo "start at $ts"
jmeter -Jthread.count="${THREAD_COUNT}" -Jthread.duration="${DURATION}" -Jhttp.host="${HOST}" -Jhttp.port="${INGRESS_PORT}" -Jhttp.path="${FULL_PATH}" -n -t jmx/bookinfo.jmx -l "${RESULT_PATH}"/"${PREFIX}"-full-path-c"${THREAD_COUNT}"-d"${DURATION}"-"${ts}".jtl > "${RESULT_PATH}"/"${PREFIX}"-full-path-c"${THREAD_COUNT}"-d"${DURATION}"-"${ts}".summary
fi