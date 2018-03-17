#!/bin/bash
set -euf

cd "${SYNAPSE_DIR}"

case "${1:-}" in
start)
  printf 'starting matrix-synapse at %s\n' "$(date)"
  rm -rf "${SYNAPSE_DATA_DIR}/homeserver.pid" &>/dev/null || echo "WARNING: deleted homeserver.pid"
  exec /usr/bin/python2.7 -O -m synapse.app.homeserver -c "${SYNAPSE_CONFIG_FILE}" --report-stats no
  ;;
bash)
  printf 'starting bash at %s\n' "$(date)"
  exec bash ${@:2}
  ;;
*)
  printf 'usage: %s <start|bash> \n' "${0}"
  ;;
esac
