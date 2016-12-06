#!/bin/sh
trap exit SIGHUP SIGINT SIGTERM

: "${USERID=1000}"
: "${GROUPID=1000}"
: "${DOCKER_GID=999}"

export USERID GROUPID DOCKER_GID

add-ccg-user
. "${CCG_COMPOSER_HOME}"/lib/http-proxy
http_proxy
. "${CCG_COMPOSER_HOME}"/lib/pip-proxy
pip_proxy

# shellcheck disable=SC2086 disable=SC2048
exec su-exec ccg "$@"
