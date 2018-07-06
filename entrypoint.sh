#!/bin/bash
set -euf

cd "${SYNAPSE_DIR}"

case "${1:-}" in
start)
  printf 'updating permissions...\n'
  mkdir -p "${SYNAPSE_DATA_DIR}"
  du -hd1 "${SYNAPSE_DATA_DIR}"
  chown -R "${SYNAPSE_USER}:${SYNAPSE_GROUP}" "${SYNAPSE_DATA_DIR}" "${SYNAPSE_DIR}"
  chmod 0775 "${SYNAPSE_DATA_DIR}" "${SYNAPSE_DIR}"

  printf 'starting matrix-synapse at %s\n' "$(date)"
  if [[ -f "${SYNAPSE_DATA_DIR}/homeserver.pid" ]]; then
    echo "WARNING: deleted homeserver.pid"
    rm -rf "${SYNAPSE_DATA_DIR}/homeserver.pid" || true
  fi

  chroot --skip-chdir --userspec="${SYNAPSE_USER}" / /usr/bin/python2.7 -O -m synapse.app.homeserver -c "${SYNAPSE_CONFIG_FILE}" --report-stats no
  ;;
bash)
  printf 'starting bash at %s\n' "$(date)"
  exec bash ${@:2}
  ;;
*)
  printf 'usage: %s <start|bash> \n' "${0}"
  ;;
esac
