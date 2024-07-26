#!/usr/bin/env bash
#
# Tests if the requested resources are available on the cluster.
#

shopt -s inherit_errexit
set -Eeu -o pipefail

set -x

declare -r RESOURCE="${1:-}"
declare -r NAMESPACE="${2:-}"
declare -r NAME="${3:-}"

usage() {
    echo "Usage: $0 RESOURCE NAMESPACE NAME"
}

retry() {
    for i in {1..20}; do
        $1 &&
            return 0

        wait=$((i * 3))
        echo "### [${i}/20] Waiting for ${wait} seconds before retrying..."
        sleep ${wait}
    done
    return 1
}

# Tests if the resource is available on the cluster, returns true when
# found, otherwise false.
resource_available() {
    SUCCESS=0
    echo "# Checking in namespace '${NAMESPACE}' for resource '${RESOURCE}' named named '${NAME}'..."
    if (! oc get "${RESOURCE}" -n "${NAMESPACE}" "${NAME}" >/dev/null); then
        echo -e "${RESOURCE}# ERROR: Resource not found."
        SUCCESS=1
    fi
    echo "# Resource found."
    return "$SUCCESS"
}

# Verifies the availability of the resource, retrying a few times.
test_resources() {
    if [[ -z "${RESOURCE}" || -z "${NAME}" ]]; then
        usage
        exit 1
    fi

    retry resource_available || return 1
}

#
# Main
#

if test_resources; then
    echo "# Success"
    exit 0
else
    echo "# ERROR: Resource not available!"
    exit 1
fi
