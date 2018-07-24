#!/bin/sh
set +x
set -e

: "${CCG_DOCKER_ORG:=muccg}"
: "${CCG_COMPOSER:=ccg-composer}"
: "${CCG_COMPOSER_VERSION:=latest}"

export CCG_DOCKER_ORG CCG_COMPOSER CCG_COMPOSER_VERSION

# ensure we have an .env file
ENV_FILE_OPT=''
if [ -f .env ]; then
    ENV_FILE_OPT='--env-file .env'
    set +e
    . ./.env > /dev/null 2>&1
    set -e
else
    echo ".env file not found, settings such as project name and proxies will not be set"
fi

TTY_OPTS=
if [ -t 0 ]; then
    TTY_OPTS='--interactive --tty'
fi

ENV_OPTS="$(env | sort | cut -d= -f1 | grep "^CCG_[a-zA-Z0-9_]*$" | awk '{print "-e", $1}')"
# shellcheck disable=SC2086 disable=SC2048
docker run --rm ${TTY_OPTS} ${ENV_FILE_OPT} \
    ${ENV_OPTS} \
    -v /etc/timezone:/etc/timezone:ro \
    -v /var/run/docker.sock:/var/run/docker.sock  \
    -v "$(pwd)":"$(pwd)" \
    -v "${HOME}"/.docker:/data/.docker \
    -w "$(pwd)" \
    "${CCG_DOCKER_ORG}"/"${CCG_COMPOSER}":"${CCG_COMPOSER_VERSION}" \
    "$@"
