#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail
if [[ "${TRACE-0}" == "1" ]]; then
    set -o xtrace
fi

if [[ "${1-}" =~ ^-*h(elp)?$ ]]; then
    echo 'Usage: ./remote_iex.sh <environment_name> <pod (api|web|indexer)> <suffix (optional)> <pattern (optional)>

Create a remote shell connection to a running blockscout pod. Assumes that the appropriate k8s context is active. Will connect
to the first matching pod when multiple exist, which may not be what you want.

Examples:

    ./remote_iex.sh alfajores indexer 3
    ./remote_iex.sh rc1staging web
    ./remote_iex.sh rc1 indexer 1
    ./remote_iex.sh alfajores web 2 55d8cff9dd-z27cc
'
    exit
fi

get_cookie() {
    local suffix=${2:-}
    local secret_name="$1-blockscout$suffix-erlangCookie"

    local secret=$(gcloud secrets versions access "latest" --secret "$secret_name")

    echo "$secret"
}

get_pod() {
    local namespace="$1"
    local pod="$2"
    local suffix="${3:-}"
    local pod_pattern="${4:-}"

    local search_pattern="blockscout$suffix-$pod"

    local name

    if [[ ! -z "$pod_pattern"  ]]; then
      name=$(kubectl get pods -n "$namespace" -o name | grep "$search_pattern" | grep "$pod_pattern" | head -1)
    else
      name=$(kubectl get pods -n "$namespace" -o name | grep "$search_pattern" | head -1)
    fi

    echo "$name"
}

get_pod_ip() {
    local namespace="${1:-}"
    local pod_name="${2:-}"

    local ip=$(kubectl get -n "$namespace" "$pod_name"  --template='{{.status.podIP}}')

    echo "$ip"
}

get_context() {
    kubectl config current-context  
}

pod_pattern="${4:-}"
suffix="${3:-}"
pod="${2:-}"
namespace="${1:-}"

main() {
    local current_context=$(get_context)
    echo "Looking for pod on $current_context cluster in namespace $namespace"

    local pod_name=$(get_pod "$namespace" "$pod" "$suffix" "$pod_pattern")

    if [[ -z "${pod_name}" ]]; then
        echo "Couldn't find a matching pod"
        return 1
    else
        echo "Found matching pod: $pod_name"
    fi

    local blockscout_ip=$(get_pod_ip "$namespace" "$pod_name")
    echo "Cluster IP: $blockscout_ip"

    local cookie=$(get_cookie "$namespace" "$suffix")
    echo "Got cookie"

    echo "Connecting to $pod_name in $namespace..."
    exec kubectl exec -i -t -n "$namespace" "$pod_name" -c "blockscout-$pod" -- sh -c "iex --name dh3@0.0.0.0 --cookie $cookie --remsh blockscout@$blockscout_ip"
}

main "$@"
