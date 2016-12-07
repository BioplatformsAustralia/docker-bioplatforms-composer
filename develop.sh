#!/bin/sh
set +x
set -e

: "${CCG_DOCKER_ORG:=muccg}"
: "${CCG_COMPOSER:=ccg-composer}"
: "${CCG_COMPOSER_VERSION:=latest}"
: "${CCG_PIP_PROXY=0}"
: "${CCG_HTTP_PROXY=0}"

# ensure we have an .env file
ENV_OPT=''
if [ -f .env ]; then
    ENV_OPT='--env-file .env'
    set +e
    . ./.env > /dev/null 2>&1
    set -e
else
    echo ".env file not found, settings such as project name and proxies will not be set"
fi

# Pass through the ip of the host if we can
# There is no docker0 interface on Mac OS, so don't do any proxy detection
if [ "$(uname)" != "Darwin" ]; then
    set +e
    DOCKER_ROUTE=$(ip -4 addr show docker0 | grep -Po 'inet \K[\d.]+')
    set -e
    export DOCKER_ROUTE
fi

# shellcheck disable=SC2086 disable=SC2048
docker run --rm ${ENV_OPT} \
    "$(env | cut -d= -f1 | awk '{print "-e", $1}')" \
    -v /etc/timezone:/etc/timezone:ro \
    -v /var/run/docker.sock:/var/run/docker.sock  \
    -v "$(pwd)":"$(pwd)" \
    -v ${HOME}/.docker:/data/.docker \
    -w "$(pwd)" \
    -it "${CCG_DOCKER_ORG}"/"${CCG_COMPOSER}":"${CCG_COMPOSER_VERSION}" \
    "$@"
