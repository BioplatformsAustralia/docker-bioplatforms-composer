#!/bin/sh
trap exit SIGHUP SIGINT SIGTERM

CCG_BUILD_DATE=$(date +%Y.%m.%d)
: "${DOCKER_BUILD_OPTS:=}"
: "${DOCKER_RUN_OPTS:=--rm}"
: "${USERID=1000}"
: "${GROUPID=1000}"
: "${DOCKER_GID=999}"


export CCG_BUILD_DATE USERID GROUPID DOCKER_GID
export DOCKER_NO_CACHE DOCKER_PULL
export DOCKER_BUILD_OPTS DOCKER_RUN_OPTS

add-ccg-user
. "${CCG_COMPOSER_HOME}"/lib/http-proxy
http_proxy
. "${CCG_COMPOSER_HOME}"/lib/pip-proxy
pip_proxy

# shellcheck disable=SC2086 disable=SC2048
exec su-exec ccg "$@"
