FROM docker/compose:1.15.0
LABEL maintainer "https://github.com/muccg/"

ENV CCG_COMPOSER_HOME /usr/local/ccg-composer
ENV PATH ${CCG_COMPOSER_HOME}/bin:$PATH

RUN cat /etc/issue
RUN apk add --no-cache --update \
  curl \
  diffutils \
  git \
  su-exec
RUN git --version
RUN env | sort

COPY docker-entrypoint.sh /docker-entrypoint.sh

RUN mkdir -p ${CCG_COMPOSER_HOME}
COPY src/ ${CCG_COMPOSER_HOME}/

WORKDIR /data
ENV HOME /data

VOLUME ["/data"]

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["usage"]
