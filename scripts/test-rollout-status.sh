#!/usr/bin/env bash
#
# Runs "oc rollout status" for configured namespace, resource type, and selectors.
#

shopt -s inherit_errexit
set -Eeu -o pipefail

# Namespace to check for "rollout status".
declare -r NAMESPACE="${NAMESPACE:-}"
# Resource type for "rollout status", as in "statefulset" or "deployment".
declare -r RESOURCE_TYPE="${RESOURCE_TYPE:-statefulset}"
# Number of retries to attempt before giving up.
declare -r RETRIES=${RETRIES:-5}

# The "rollout status" selectors, to find the actual resource to check for
# successful rollout.
declare -r -a RESOURCE_SELECTORS=("${@}")

rollout_status() {
    oc rollout status "${RESOURCE_TYPE}" \
        --namespace="${NAMESPACE}" \
        --watch \
        --timeout=10s \
        --selector="${1}"
}

wait_for_resource() {
    for s in "${RESOURCE_SELECTORS[@]}"; do
        echo "# Checking if ${RESOURCE_TYPE} '${s}' is ready..."
        if ! rollout_status "${s}"; then
            echo -en "#\n# WARNING: ${RESOURCE_TYPE} '${s}' is not ready!\n#\n"
            return 1
        fi
        echo "# ${RESOURCE_TYPE} objects with '${s}' selector are ready!"
    done
    return 0
}

usage() {
    cat <<EOF
Usage: 
    \$ export NAMESPACE="namespace"
    \$ export RESOURCE_TYPE="deployment"
    \$ $0 <RESOURCE_SELECTORS>
EOF
    exit 1
}

test_rollout_status() {
    [[ -z "${NAMESPACE}" ]] && usage
    [[ -z "${RESOURCE_TYPE}" ]] && usage
    [[ ${#RESOURCE_SELECTORS[@]} -eq 0 ]] && usage

    for i in $(seq 1 "${RETRIES}"); do
        wait_for_resource &&
            return 0

        wait=$((i * 30))
        echo "### [${i}/${RETRIES}] Waiting for ${wait} seconds before retrying..."
        sleep ${wait}
    done

    echo "# ERROR: '${RESOURCE_TYPE}' are not ready!"
    return 1
}

if test_rollout_status; then
    echo "# ${RESOURCE_TYPE} objects ready: '${RESOURCE_SELECTORS[*]}'"
    exit 0
else
    echo "# ERROR: ${RESOURCE_TYPE} not ready!"
    exit 1
fi
