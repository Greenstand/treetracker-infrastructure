#!/usr/bin/env bash
# Never trace commands that handle a secret, even when invoked with bash -x.
set +x
set -euo pipefail
umask 077

RESOURCE_NAME=''
KEY_NAME=''
SECRET_VALUE=''
export -n SECRET_VALUE
NAMESPACE=''
CONTEXT=''
TEMP_OUTPUT=''

die() {
    printf 'Error: %s\n' "$1" >&2
    exit 1
}

cleanup() {
    if [[ -n "$TEMP_OUTPUT" ]]; then
        rm -f -- "$TEMP_OUTPUT"
    fi
}

trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

while getopts ':r:k:s:n:c:h' flag; do
    case "$flag" in
        r) RESOURCE_NAME=$OPTARG ;;
        k) KEY_NAME=$OPTARG ;;
        s)
            SECRET_VALUE=$OPTARG
            printf 'Warning: -s exposes the value in shell history and process arguments; prefer the hidden prompt.\n' >&2
            ;;
        n) NAMESPACE=$OPTARG ;;
        c) CONTEXT=$OPTARG ;;
        h)
            printf 'Usage: %s [-r name] [-k key] [-n namespace] [-c context]\n' "$0"
            exit 0
            ;;
        :) die "Option -$OPTARG requires a value." ;;
        \?) die "Unknown option: -$OPTARG" ;;
    esac
done
shift "$((OPTIND - 1))"
[[ $# -eq 0 ]] || die 'Unexpected positional arguments.'

for command in kubectl kubeseal; do
    command -v "$command" >/dev/null 2>&1 || die "$command is required."
done

if [[ -z "$NAMESPACE" ]]; then
    printf 'Namespace: ' >&2
    IFS= read -r NAMESPACE || die 'No namespace provided.'
fi
if [[ -z "$RESOURCE_NAME" ]]; then
    printf 'Secret resource name: ' >&2
    IFS= read -r RESOURCE_NAME || die 'No resource name provided.'
fi
if [[ -z "$KEY_NAME" ]]; then
    printf 'Key name: ' >&2
    IFS= read -r KEY_NAME || die 'No key name provided.'
fi

[[ ${#NAMESPACE} -le 63 && "$NAMESPACE" =~ ^[a-z0-9]([-a-z0-9]*[a-z0-9])?$ ]] || die 'Invalid namespace.'
[[ ${#RESOURCE_NAME} -le 253 && "$RESOURCE_NAME" =~ ^[a-z0-9]([-a-z0-9]*[a-z0-9])?(\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*$ ]] || die 'Invalid secret resource name.'
[[ "$KEY_NAME" =~ ^[a-zA-Z0-9._-]+$ ]] || die 'Invalid key name.'

CONTEXTS=$(kubectl config get-contexts -o name) || die 'Could not list Kubernetes contexts.'
if [[ -z "$CONTEXT" ]]; then
    printf 'Available Kubernetes contexts:\n%s\n' "$CONTEXTS" >&2
    printf 'kubectl context: ' >&2
    IFS= read -r CONTEXT || die 'No context provided.'
fi
[[ -n "$CONTEXT" ]] || die 'No context provided.'
printf '%s\n' "$CONTEXTS" | grep -Fx -- "$CONTEXT" >/dev/null || die 'Unknown Kubernetes context.'

OUTPUT="${RESOURCE_NAME}-sealed-secret.yaml"
[[ ! -e "$OUTPUT" && ! -L "$OUTPUT" ]] || die "Output already exists: $OUTPUT"

if [[ -z "$SECRET_VALUE" ]]; then
    printf 'Secret value (input hidden): ' >&2
    IFS= read -r -s SECRET_VALUE || die 'No secret value provided.'
    printf '\n' >&2
fi
[[ -n "$SECRET_VALUE" ]] || die 'Secret value must not be empty.'

TEMP_OUTPUT=$(mktemp "./.${RESOURCE_NAME}-sealed-secret.XXXXXX")
# Stream the raw Secret directly to kubeseal; never write it to disk.
# Suppress tool diagnostics that could include the raw Secret on failure.
if ! printf '%s' "$SECRET_VALUE" |
    kubectl --context "$CONTEXT" --namespace "$NAMESPACE" create secret generic "$RESOURCE_NAME" \
        --dry-run=client --from-file="${KEY_NAME}=/dev/stdin" -o json 2>/dev/null |
    kubeseal --context "$CONTEXT" --namespace "$NAMESPACE" --format yaml \
        > "$TEMP_OUTPUT" 2>/dev/null; then
    unset SECRET_VALUE
    die 'Secret creation or sealing failed; no output was published. Check the context, controller, and permissions.'
fi
unset SECRET_VALUE
[[ -s "$TEMP_OUTPUT" ]] || die 'kubeseal returned empty output.'
# A hard link publishes only complete output and cannot overwrite an existing file.
ln -- "$TEMP_OUTPUT" "$OUTPUT" || die 'Could not publish output without overwriting an existing file.'
printf 'Created %s for namespace %s using context %s. No resources were applied.\n' "$OUTPUT" "$NAMESPACE" "$CONTEXT"
