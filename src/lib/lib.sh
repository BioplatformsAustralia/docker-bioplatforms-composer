#!/bin/sh
set -a

: "${DOCKER_BUILD_PROXY:=--build-arg http_proxy}"
: "${DOCKER_USE_HUB:=0}"
: "${DOCKER_IMAGE:=${DOCKER_ORG}/${PROJECT_NAME}}"
: "${DOCKER_NO_CACHE:=0}"
: "${DOCKER_PULL:=0}"

# Do not set these, they are vars used below
DOCKER_BUILD_OPTS=''
#DOCKER_RUN_OPTS='-e PIP_INDEX_URL -e PIP_TRUSTED_HOST'
DOCKER_COMPOSE_BUILD_OPTS=''


info () {
  printf "\r  [\033[00;34mINFO\033[0m] %s\n" "$1"
}

warn () {
  printf "\r  [\033[00;33mWARN\033[0m] %s\n" "$1"
}

success () {
  printf "\r\033[2K  [\033[00;32m OK \033[0m] %s\n" "$1"
}


fail () {
  printf "\r\033[2K  [\033[0;31mFAIL\033[0m] %s\n" "$1"
  echo ''
  exit 1
}


docker_options() {
    if [ "${DOCKER_PULL}" = "1" ]; then
         DOCKER_BUILD_PULL="--pull=true"
         DOCKER_COMPOSE_BUILD_PULL="--pull"
    else
         DOCKER_BUILD_PULL="--pull=false"
         DOCKER_COMPOSE_BUILD_PULL=""
    fi

    if [ "${DOCKER_NO_CACHE}" = "1" ]; then
         DOCKER_BUILD_NOCACHE="--no-cache=true"
         DOCKER_COMPOSE_BUILD_NOCACHE="--no-cache"
    else
         DOCKER_BUILD_NOCACHE="--no-cache=false"
         DOCKER_COMPOSE_BUILD_NOCACHE=""
    fi

    DOCKER_BUILD_OPTS="${DOCKER_BUILD_OPTS} ${DOCKER_BUILD_NOCACHE} ${DOCKER_BUILD_PROXY} ${DOCKER_BUILD_PULL} ${DOCKER_BUILD_PIP_PROXY}"

    # compose does not expose all docker functionality, so we can't use compose to build in all cases
    DOCKER_COMPOSE_BUILD_OPTS="${DOCKER_COMPOSE_BUILD_OPTS} ${DOCKER_COMPOSE_BUILD_NOCACHE} ${DOCKER_COMPOSE_BUILD_PULL}"
}
