FROM ubuntu:18.04 AS base

ENV SYNAPSE_VERSION='0.33.1' \
  SYNAPSE_DIR='/synapse' \
  SYNAPSE_DATA_DIR='/synapse-data' \
  SYNAPSE_CONFIG_FILE='homeserver.yaml' \
  SYNAPSE_LOG_FILE='homeserver.log' \
  SYNAPSE_UID='3000' \
  SYNAPSE_USER='synapse' \
  SYNAPSE_HEALTHCHECK_URL='https://localhost:8448/_matrix/client/versions' \
  SYNAPSE_DEPENDENCIES='ca-certificates bash python python-six python-pip python-setuptools'

RUN apt-get update && apt-get dist-upgrade -y && apt-get install --no-install-recommends -y ${SYNAPSE_DEPENDENCIES} \
  && apt-get autoremove --purge -y && apt-get clean -y && \
  groupadd -g "${SYNAPSE_UID}" "${SYNAPSE_USER}" && \
  useradd -r -g "${SYNAPSE_USER}" -u "${SYNAPSE_UID}" "${SYNAPSE_USER}"

FROM base as build
WORKDIR /tmp

# variables
ENV SYNAPSE_BUILD_DEPENDENCIES='build-essential gcc g++ make python-pip wget libtool python-dev libffi-dev libjpeg-dev libpng-dev libxml2-dev libxslt1-dev libzip-dev libssl-dev' \
  SYNAPSE_PIP_DEPENDENCIES='setuptools virtualenv twisted lxml psycopg2-binary bleach jinja2 netaddr cryptography' \
  CFLAGS='-mtune=intel -O3 -pipe -flto' \
  CXXFLAGS='-mtune=intel -O3 -pipe -flto'

# install dependencies
RUN apt-get update && apt-get install -y ${SYNAPSE_BUILD_DEPENDENCIES} && \
  pip --no-cache-dir install --upgrade --compile ${SYNAPSE_PIP_DEPENDENCIES}

# install synapse
RUN wget -q --show-progress -O /tmp/synapse.tar.gz "https://github.com/matrix-org/synapse/archive/v${SYNAPSE_VERSION}.tar.gz" && tar xf /tmp/synapse.tar.gz -C /tmp && \
  mv "/tmp/synapse-${SYNAPSE_VERSION}" "${SYNAPSE_DIR}"
RUN pip --no-cache-dir install --upgrade --compile "${SYNAPSE_DIR}" && \
  chown -R "${SYNAPSE_USER}:${SYNAPSE_USER}" "${SYNAPSE_DIR}"

# compile all python packages
RUN /usr/bin/python2.7 -O -m compileall

FROM base
HEALTHCHECK --interval=30s --timeout=30s --start-period=30s --retries=3 CMD ['wget', '-q', '${SYNAPSE_HEALTHCHECK_URL}']

COPY --from=build ${SYNAPSE_DIR} ${SYNAPSE_DIR}
COPY --from=build /usr/share/python /usr/share/python
COPY --from=build /usr/local/lib/python2.7 /usr/local/lib/python2.7

ADD entrypoint.sh /bin/docker-entrypoint
RUN chmod 0755 /bin/docker-entrypoint

WORKDIR "${SYNAPSE_DIR}"
ENTRYPOINT ["/bin/docker-entrypoint"]
CMD ["start"]
