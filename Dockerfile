FROM docker/compose:1.22.0
LABEL maintainer "https://github.com/bioplatformsaustralia/"

ENV BIOPLATFORMS_COMPOSER_HOME /usr/local/bioplatforms-composer
ENV PATH ${BIOPLATFORMS_COMPOSER_HOME}/bin:$PATH

RUN cat /etc/issue
RUN apk add --no-cache --update \
  curl \
  diffutils \
  git \
  su-exec
RUN git --version
RUN env | sort

COPY docker-entrypoint.sh /docker-entrypoint.sh

RUN mkdir -p ${BIOPLATFORMS_COMPOSER_HOME}
COPY src/ ${BIOPLATFORMS_COMPOSER_HOME}/

WORKDIR /data
ENV HOME /data

VOLUME ["/data"]

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["usage"]
