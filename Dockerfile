FROM ubuntu:rolling AS build
WORKDIR /tmp

# variables
ENV SYNAPSE_VERSION="0.27.0-rc1"\
    SYNAPSE_DATA_DIR="/synapse-data" \
    SYNAPSE_UID=3000 SYNAPSE_GID=3000 SYNAPSE_USER=synapse SYNAPSE_GROUP=synapse \
    SYNAPSE_DEPENDENCIES="ca-certificates bash python-pip python-lxml python-psycopg2 python openssl" \
    SYNAPSE_BUILD_DEPENDENCIES="gcc libffi-dev libjpeg-turbo8-dev libtool libxml2-dev libxslt-dev libzip-dev make python-dev" \
    CFLAGS="-mtune=intel -O2 -pipe"

ENV SYNAPSE_SRC_URL="https://github.com/matrix-org/synapse/archive/v${SYNAPSE_VERSION}.tar.gz" \
    CXXFLAGS="${CFLAGS}"

# add synapse user
RUN groupadd -g ${SYNAPSE_GID} ${SYNAPSE_GROUP} && \
  useradd -r -g ${SYNAPSE_GROUP} -u ${SYNAPSE_UID} ${SYNAPSE_USER}

# install dependencies
RUN apt-get update && apt-get install -y ${SYNAPSE_DEPENDENCIES} ${SYNAPSE_BUILD_DEPENDENCIES}

# install synapse
RUN pip2 install --upgrade --compile pip && pip2 install --upgrade --compile "${SYNAPSE_SRC_URL}"

# cleanup
RUN apt-get purge -y ${SYNAPSE_BUILD_DEPENDENCIES} && apt-get autoremove -y && apt-get clean -y && apt-get autoclean -y && cd / \
 && rm -rf /tmp /var/cache /root/.cache /home/*/.cache /var/lib/apt /usr/share/man /usr/share/doc

FROM ubuntu:rolling
COPY --from=build / /
ENV SYNAPSE_USER=synapse SYNAPSE_DATA_DIR="/synapse-data" SYNAPSE_HEALTHCHECK_URL="https://localhost:8448/_matrix/client/versions"
ENV SYNAPSE_CONFIG_FILE="${SYNAPSE_DATA_DIR}/homeserver.yaml" SYNAPSE_LOG_FILE="${SYNAPSE_DATA_DIR}/homeserver.log"

# add entrypoint
ADD entrypoint.sh /bin/docker-entrypoint
RUN chmod 0755 /bin/docker-entrypoint

# set user and workind directory
USER ${SYNAPSE_USER}
WORKDIR ${SYNAPSE_DATA_DIR}

# healtcheck script
HEALTHCHECK --interval=30s --timeout=30s --start-period=30s --retries=3 CMD ["wget", "-q", "${SYNAPSE_HEALTHCHECK_URL}"]

# use tini with entrypoint, set start command
ENTRYPOINT ["/bin/docker-entrypoint"]
CMD ["start"]
