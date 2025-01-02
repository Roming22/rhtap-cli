#!/usr/bin/env bash
#
# Runs "oc rollout status" for configured namespace, resource type, and selectors.
#

shopt -s inherit_errexit
set -Eeu -o pipefail
set -x

# Number of retries to attempt before giving up.
declare -r RETRIES=${RETRIES:-20}

status() {
    items=$(
        oc get secret \
            --ignore-not-found \
            --namespace="openshift-pipelines" \
            --output=jsonpath="{.data}" \
        "signing-secrets" | sed 's:",":\n:' | grep -c '":"'
    )
    if [ "$items" -lt 2 ]; then
        return 1
    fi
    return 0
}

usage() {
    cat <<EOF
Usage:
    \$ $0
EOF
    exit 1
}

test_signing_secrets() {
    for i in $(seq 0 "${RETRIES}"); do
        wait=$(( i * 5))
        [[ $wait -gt 30  ]] && wait=30
        echo "### [${i}/${RETRIES}] Waiting for ${wait} seconds before retrying..."
        sleep ${wait}

        status &&
            return 0
    done
    return 1
}

if test_signing_secrets; then
    echo "# signing-secrets ready"
    exit 0
else
    echo "# ERROR: signing-secrets not ready!"
    exit 1
fi
