#!/bin/sh
#
# common definitons shared between projects
#
set -a

DATE=$(date +%Y.%m.%d)

: "${DOCKER_BUILD_PROXY:=--build-arg http_proxy}"
: "${DOCKER_USE_HUB:=0}"
: "${DOCKER_IMAGE:=${DOCKER_ORG}/${PROJECT_NAME}}"
: "${DOCKER_NO_CACHE:=0}"
: "${DOCKER_PULL:=0}"

# Do not set these, they are vars used below
DOCKER_BUILD_OPTS=''
DOCKER_RUN_OPTS='-e PIP_INDEX_URL -e PIP_TRUSTED_HOST'
DOCKER_COMPOSE_BUILD_OPTS=''


info () {
  printf "\r  [ \033[00;34mINFO\033[0m ] %s\n" "$1"
}

warn () {
  printf "\r  [ \033[00;33mWARN\033[0m ] %s\n" "$1"
}

success () {
  printf "\r\033[2K  [ \033[00;32m OK \033[0m ] %s\n" "$1"
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

    if [ ${DOCKER_NO_CACHE} = "1" ]; then
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


docker_warm_cache() {
    # attempt to warm up docker cache by pulling next_release tag
    if [ ${DOCKER_USE_HUB} = "1" ]; then
        info 'warming docker cache'
        set -x
        docker pull ${DOCKER_IMAGE}:next_release || true
        success "$(docker images | grep ${DOCKER_IMAGE} | grep next_release | sed 's/  */ /g')"
        set +x
    fi
}


# ssh setup for ci
_ci_ssh_agent() {
    info 'ci ssh config'

    ssh-agent > /tmp/agent.env.sh
    . /tmp/agent.env.sh
    success "started ssh-agent"

    # load key if defined by bamboo
    if [ -z ${bamboo_CI_SSH_KEY+x} ]; then
        info "loading default ssh keys"
        ssh-add || true
    else
        info "loading bamboo_CI_SSH_KEY ssh keys"
        ssh-add ${bamboo_CI_SSH_KEY} || true
    fi

    # some private projects had a deployment key
    if [ -f docker-build.key ]; then
        chmod 600 docker-build.key
        ssh-add docker-build.key
    fi

    ssh-add -l
}


ci_docker_login() {
    info 'Docker login'

    if [ -z ${DOCKER_USERNAME+x} ]; then
        DOCKER_USERNAME=${bamboo_DOCKER_USERNAME}
    fi
    if [ -z ${DOCKER_PASSWORD+x} ]; then
        DOCKER_PASSWORD=${bamboo_DOCKER_PASSWORD}
    fi

    if [ -z ${DOCKER_USERNAME} ] || [ -z ${DOCKER_PASSWORD} ]; then
        fail "Docker credentials not available"
    fi

    docker login -u ${DOCKER_USERNAME} --password="${DOCKER_PASSWORD}"
    success "Docker login"
}


# figure out what branch/tag we are on
git_tag() {
    if [ -d .git ]; then
        info 'Found a git repo'
    else
        info "Not a git repo"
        return
    fi

    set +e
    GIT_TAG=$(git describe --abbrev=0 --tags 2> /dev/null)
    set -e

    # jenksins sets BRANCH_NAME, so we use that
    # otherwise ask git
    GIT_BRANCH="${BRANCH_NAME}"
    if [ -z "${GIT_BRANCH}" ]; then
        GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2> /dev/null)
    fi
    info "Git branch: ${GIT_BRANCH}"

    # fail when we don't know branch
    if [ "${GIT_BRANCH}" = "HEAD" ]; then
        fail 'Git clone is in detached HEAD state and BRANCH_NAME not set'
    fi

    # only use tags when on master (prod) branch
    if [ "${GIT_BRANCH}" != "master" ]; then
        info 'Ignoring tags, not on master branch'
        GIT_TAG=${GIT_BRANCH}
    fi

    # if no git tag, then use branch name
    if [ "x${GIT_TAG}" == "x" ]; then
        info 'No git tag set, using branch name'
        GIT_TAG=${GIT_BRANCH}
    fi

    export GIT_TAG

    success "Git tag: ${GIT_TAG}"
}


_start_test_stack() {
    info 'test stack up'
    mkdir -p data/tests
    chmod o+rwx data/tests


    set -x
    docker-compose --project-name ${PROJECT_NAME} -f docker-compose-teststack.yml stop
    docker-compose --project-name ${PROJECT_NAME} -f docker-compose-teststack.yml rm --all -v --force
    docker-compose --project-name ${PROJECT_NAME} -f docker-compose-teststack.yml up $@
    set +x
    success 'test stack up'
}


_stop_test_stack() {
    info 'test stack down'
    set -x
    docker-compose --project-name ${PROJECT_NAME} -f docker-compose-teststack.yml stop
    set +x
    success 'test stack down'
}


start_test_stack() {
    _start_test_stack --force-recreate
}


_start_prod_stack() {
    info 'prod stack up'
    mkdir -p data/prod
    chmod o+rwx data/prod


    set -x
    docker-compose --project-name ${PROJECT_NAME} -f docker-compose-prod.yml stop
    docker-compose --project-name ${PROJECT_NAME} -f docker-compose-prod.yml rm --all -v --force
    docker-compose --project-name ${PROJECT_NAME} -f docker-compose-prod.yml up $@
    set +x
    success 'prod stack up'
}


_stop_prod_stack() {
    info 'prod stack down'
    set -x
    docker-compose --project-name ${PROJECT_NAME} -f docker-compose-prod.yml stop
    set +x
    success 'prod stack down'
}


_purge_dir() {
    rm --recursive --force -v $@ || true
    mkdir -p $@
    chmod o+rwx $@ || true
}


_start_selenium() {
    info 'selenium stack up'

    # remove any previous build artifacts from top level selenium dir
    _purge_dir data/selenium/dev
    _purge_dir data/selenium/dev/scratch
    _purge_dir data/selenium/dev/log
    _purge_dir data/selenium/prod
    _purge_dir data/selenium/prod/scratch
    _purge_dir data/selenium/prod/log

    set -x
    docker-compose --project-name ${PROJECT_NAME} -f docker-compose-selenium.yml pull --ignore-pull-failures
    docker-compose --project-name ${PROJECT_NAME} -f docker-compose-selenium.yml up $@
    set +x
    success 'selenium stack up'
}


_stop_selenium() {
    info 'selenium stack down'
    set -x
    docker-compose --project-name ${PROJECT_NAME} -f docker-compose-selenium.yml stop
    set +x
    success 'selenium stack down'
}


_start_aloetests() {
    set -x
    # ensure previous data containers are removed
    docker-compose --project-name ${PROJECT_NAME} -f docker-compose-aloe.yml stop
    docker-compose --project-name ${PROJECT_NAME} -f docker-compose-aloe.yml rm --all -v --force
    docker-compose --project-name ${PROJECT_NAME} -f docker-compose-aloe.yml $@
    local rval=$?
    set +x

    info 'artifacts'
    ls -laRth data/selenium/ || true

    return $rval
}
