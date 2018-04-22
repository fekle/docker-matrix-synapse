FROM ubuntu:latest AS build
WORKDIR /tmp

# variables
ENV SYNAPSE_VERSION='0.27.4' \
  SYNAPSE_DIR='/synapse' \
  SYNAPSE_DATA_DIR='/synapse-data' \
  SYNAPSE_UID='3000' SYNAPSE_GID='3000' SYNAPSE_USER='synapse' SYNAPSE_GROUP='synapse' \
  SYNAPSE_DEPENDENCIES='wget ca-certificates bash python python-pip' SYNAPSE_PIP_DEPENDENCIES='setuptools virtualenv twisted lxml psycopg2-binary bleach jinja2 netaddr cryptography' \
  SYNAPSE_BUILD_DEPENDENCIES='clang make libtool python-dev libffi-dev libjpeg-dev libpng-dev libxml2-dev libxslt1-dev libzip-dev libssl-dev' \
  CFLAGS='-mtune=intel -O3 -pipe' CXXFLAGS='-mtune=intel -O3 -pipe' CC='clang' CXX='clang++'

ENV SYNAPSE_SRC_URL="https://github.com/matrix-org/synapse/archive/v${SYNAPSE_VERSION}.tar.gz"

# add synapse user
RUN groupadd -g "${SYNAPSE_GID}" "${SYNAPSE_GROUP}" && \
  useradd -r -g "${SYNAPSE_GROUP}" -u "${SYNAPSE_UID}" "${SYNAPSE_USER}"

# install dependencies
RUN apt-get update && apt-get install -y ${SYNAPSE_DEPENDENCIES} ${SYNAPSE_BUILD_DEPENDENCIES}
RUN pip install --upgrade --compile pip 
RUN pip install --upgrade --compile setuptools
RUN pip install --upgrade --compile ${SYNAPSE_PIP_DEPENDENCIES}

# install synapse
RUN wget -q --show-progress -O /tmp/synapse.tar.gz "${SYNAPSE_SRC_URL}" && tar xf /tmp/synapse.tar.gz -C /tmp && \
  mv "/tmp/synapse-${SYNAPSE_VERSION}" "${SYNAPSE_DIR}"
RUN pip --no-cache-dir install --upgrade --compile "${SYNAPSE_DIR}" && \
  chown -R "${SYNAPSE_USER}:${SYNAPSE_GROUP}" "${SYNAPSE_DIR}"

# cleanup
RUN apt-get purge -y ${SYNAPSE_BUILD_DEPENDENCIES} && apt-get autoremove -y && apt-get clean -y && apt-get autoclean -y 
RUN rm -rf /tmp /var/cache /root/.cache /home/*/.cache /var/lib/apt /usr/share/man /usr/share/doc

# compile all python packages
RUN /usr/bin/python2.7 -O -m compileall

FROM ubuntu:latest
COPY --from=build / /
ENV SYNAPSE_USER='synapse' SYNAPSE_GROUP='synapse' SYNAPSE_DIR='/synapse' SYNAPSE_DATA_DIR='/synapse-data' SYNAPSE_HEALTHCHECK_URL='https://localhost:8448/_matrix/client/versions'
ENV SYNAPSE_CONFIG_FILE="${SYNAPSE_DATA_DIR}/homeserver.yaml" SYNAPSE_LOG_FILE="${SYNAPSE_DATA_DIR}/homeserver.log"
WORKDIR "${SYNAPSE_DIR}"
HEALTHCHECK --interval=30s --timeout=30s --start-period=30s --retries=3 CMD ['wget', '-q', '${SYNAPSE_HEALTHCHECK_URL}']

# add entrypoint
ADD entrypoint.sh /bin/docker-entrypoint
RUN chmod 0755 /bin/docker-entrypoint

# use tini with entrypoint, set start command
ENTRYPOINT ["/bin/docker-entrypoint"]
CMD ["start"]
