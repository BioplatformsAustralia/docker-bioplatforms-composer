#!/bin/sh
trap exit SIGHUP SIGINT SIGTERM

BIOPLATFORMS_BUILD_DATE=$(date +%Y.%m.%d)
: "${DOCKER_BUILD_OPTS:=}"
: "${DOCKER_RUN_OPTS:=--rm}"
: "${USERID=1000}"
: "${GROUPID=1000}"


export BIOPLATFORMS_BUILD_DATE USERID GROUPID
export DOCKER_NO_CACHE DOCKER_PULL
export DOCKER_BUILD_OPTS DOCKER_RUN_OPTS

add-bioplatforms-user

# shellcheck disable=SC2086 disable=SC2048
exec su-exec bioplatforms "$@"
