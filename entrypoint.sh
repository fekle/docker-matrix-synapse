#!/bin/bash
set -euf

cd "${SYNAPSE_DATA_DIR}"

case "${1:-}" in
start)
  rm -rf homeserver.pid &>/dev/null || true
  exec env LD_PRELOAD="${SYNAPSE_DATA_DIR}/stack.so" python2 -m synapse.app.homeserver -c "${SYNAPSE_CONFIG_FILE}" --report-stats no
  ;;
bash)
  exec bash ${@:2}
  ;;
*)
  printf 'usage: %s <start|bash> \n' "${0}"
  ;;
esac
