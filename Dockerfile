FROM alpine:3.7
WORKDIR /tmp

# variables
ENV CFLAGS="-mtune=intel -O3 -pipe -fstack-protector-strong"
ENV CXXFLAGS="${CFLAGS}"
ENV SYNAPSE_VERSION="0.26.0"
ENV SYNAPSE_SRC_URL="https://github.com/matrix-org/synapse/archive/v${SYNAPSE_VERSION}.tar.gz"
ENV SYNAPSE_DATA_DIR="/synapse-data"
ENV SYNAPSE_ETC_DIR="/etc/synapse"
ENV SYNAPSE_UID=3000
ENV SYNAPSE_GID=3000
ENV SYNAPSE_USER=synapse
ENV SYNAPSE_GROUP=synapse
ENV SYNAPSE_CONFIG_FILE="${SYNAPSE_DATA_DIR}/homeserver.yaml"
ENV SYNAPSE_LOG_FILE="${SYNAPSE_DATA_DIR}/homeserver.log"
ENV SYNAPSE_HEALTHCHECK_URL="https://localhost:8448/_matrix/client/versions"
ENV SYNAPSE_DEPENDENCIES="ca-certificates build-base bash libressl py2-pip py-libxslt python2 libjpeg-turbo libpq libffi libxml2 libxslt libzip"
ENV SYNAPSE_BUILD_DEPENDENCIES="gcc libffi-dev libjpeg-turbo-dev libressl-dev libtool libxml2-dev libxslt-dev libzip-dev linux-headers make musl-dev postgresql-dev python2-dev"
ENV SYNAPSE_PIP_DEPENDENCIES="psycopg2 lxml"

# install tini and add synapse user
RUN apk add --no-cache tini && \
  addgroup -g ${SYNAPSE_GID} ${SYNAPSE_GROUP} && \
  adduser -S -G ${SYNAPSE_GROUP} -u ${SYNAPSE_UID} ${SYNAPSE_USER}

# install dependencies
RUN apk add --no-cache ${SYNAPSE_DEPENDENCIES} ${SYNAPSE_BUILD_DEPENDENCIES}

# install synapse
RUN pip2 install --upgrade --compile pip && pip2 install --upgrade --compile "${SYNAPSE_SRC_URL}" && pip2 install --upgrade --compile ${SYNAPSE_PIP_DEPENDENCIES} && \
  mkdir -p "${SYNAPSE_ETC_DIR}" && printf "${SYNAPSE_VERSION}" > "${SYNAPSE_ETC_DIR}/version"

# really hacky fix for musl segfault, see https://github.com/esnme/ultrajson/issues/254#issuecomment-314862445
ADD /files/stack.c stack.c
RUN mkdir -p "${SYNAPSE_ETC_DIR}/stackfix" && gcc -shared -fPIC ${CFLAGS} stack.c -o "${SYNAPSE_ETC_DIR}/stackfix/stack.so"

# cleanup
RUN apk del --no-cache --purge -r ${SYNAPSE_BUILD_DEPENDENCIES} && cd / && rm -rf /tmp /var/cache /root/.cache /home/*/.cache

# add entrypoi
ADD entrypoint.sh /bin/docker-entrypoint
RUN chmod 0755 /bin/docker-entrypoint

# set user and workind directory
USER ${SYNAPSE_USER}
WORKDIR ${SYNAPSE_DATA_DIR}

# healtcheck script
HEALTHCHECK --interval=30s --timeout=30s --start-period=30s --retries=3 CMD ["wget", "-q", "${SYNAPSE_HEALTHCHECK_URL}"]

# use tini with entrypoint, set start command
ENTRYPOINT ["/sbin/tini", "--", "/bin/docker-entrypoint"]
CMD ["start"]
